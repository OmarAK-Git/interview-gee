#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TEST_ROOT="$(mktemp -d "${BATS_TMPDIR:-/tmp}/crossfire-ae.XXXXXX")"
  export HERMES_HOME="${TEST_ROOT}/.crossfire/profiles/test"
  export CROSSFIRE_RUNS_DIR="${TEST_ROOT}/runs"
  export CROSSFIRE_CANDIDATE_SKILLS_ROOT="${TEST_ROOT}/.crossfire/candidate-skills"
  export CROSSFIRE_HERMES_DISCOVERY=0
  mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills" "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}"
  MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"
  DEMO_COMMON="$REPO_ROOT/scripts/demo_common.sh"
  # shellcheck disable=SC1091
  source "$DEMO_COMMON"
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/weakness_memory.sh"
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/stage_candidate_skill.sh"
  crossfire_require_isolated_hermes_home
}

teardown() {
  rm -rf "$TEST_ROOT"
}

ae_write_memory_with_behavioral_weakness() {
  local run_id="$1"
  cp "$REPO_ROOT/tests/fixtures/memory-empty.md" "$MEMORY_MD"
  cat >>"$MEMORY_MD" <<EOF

<!-- CROSSFIRE-WEAKNESSES:START -->
\`\`\`yaml
version: 1
weaknesses:
  - weakness_id: w-deadbeeffeed
    family: behavioral
    topic: q_behavioral_01 demo gap
    topic_key: q-behavioral-01-demo-gap
    missing_elements: [action, result]
    first_seen: 2026-08-16T18:01:02Z
    last_seen: 2026-08-16T18:01:02Z
    observation_count: 1
    source_session_id: sess_ae
    answer_ref: ${run_id}/q_behavioral_01/0
    evidence:
      kind: quote
      value: "I just kind of watched the dashboard."
\`\`\`
<!-- CROSSFIRE-WEAKNESSES:END -->
EOF
}

ae_finalize_run() {
  local run_id="$1"
  ae_write_memory_with_behavioral_weakness "$run_id"
  crossfire_stage_candidate_skill \
    "$run_id" behavioral w-deadbeeffeed sess_ae \
    "${run_id}/q_behavioral_01/0" 1 "action,result" >/dev/null
  crossfire_write_candidate_barrier_flag "$run_id" \
    "$(crossfire_candidate_skill_path behavioral)"
}

@test "crossfire_snapshot_memory_md_before stores run-scoped before file" {
  local run_id="run_snap_test"
  cp "$REPO_ROOT/tests/fixtures/memory-empty.md" "$MEMORY_MD"
  local snap
  snap=$(crossfire_snapshot_memory_md_before "$run_id" "$MEMORY_MD")
  [ -f "$snap" ]
  [[ "$snap" == *"/runs/${run_id}/memory-before.md" ]]
  cmp -s "$MEMORY_MD" "$snap"
}

@test "artifact evidence success prints weakness-block diff and candidate metadata" {
  local run_id="run_success"
  cp "$REPO_ROOT/tests/fixtures/memory-empty.md" "$MEMORY_MD"
  crossfire_snapshot_memory_md_before "$run_id" "$MEMORY_MD" >/dev/null
  ae_finalize_run "$run_id"
  run crossfire_print_artifact_evidence "$run_id" "$MEMORY_MD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"artifact_evidence: MEMORY.md weakness-block diff"* ]]
  [[ "$output" == *"CROSSFIRE-WEAKNESSES:START"* ]]
  [[ "$output" == *"weakness_id:"* ]]
  [[ "$output" == *"artifact_evidence: staged candidate skill"* ]]
  [[ "$output" == *"candidate_path="* ]]
  [[ "$output" == *"/.crossfire/candidate-skills/unverified-behavioral-followup/SKILL.md"* ]]
  [[ "$output" == *"status: unverified"* ]]
  [[ "$output" == *"weakness_id:"* ]]
  [[ "$output" == *"source_session_id: sess_ae"* ]]
  [[ "$output" == *"Do not praise or imitate"* ]]
  [[ "$output" != *"Personal Memory"* ]]
  [[ "$output" != *"favorite prompt"* ]]
}

@test "artifact evidence direct set -e call prints full SKILL.md body" {
  local run_id="run_sete_direct"
  local out_file="${TEST_ROOT}/sete-direct.out"
  cp "$REPO_ROOT/tests/fixtures/memory-empty.md" "$MEMORY_MD"
  crossfire_snapshot_memory_md_before "$run_id" "$MEMORY_MD" >/dev/null
  ae_finalize_run "$run_id"
  crossfire_print_artifact_evidence "$run_id" "$MEMORY_MD" >"$out_file" 2>&1
  [[ "$(cat "$out_file")" == *"Do not praise or imitate"* ]]
  [[ "$(cat "$out_file")" == *"--- candidate SKILL.md ---"* ]]
  ! grep -q 'printf: --: invalid option' "$out_file"
}

@test "artifact evidence timeout when weakness block never changes" {
  local run_id="run_timeout_mem"
  cp "$REPO_ROOT/tests/fixtures/memory-empty.md" "$MEMORY_MD"
  crossfire_snapshot_memory_md_before "$run_id" "$MEMORY_MD" >/dev/null
  export CROSSFIRE_ARTIFACT_TIMEOUT_SEC=1
  run crossfire_print_artifact_evidence "$run_id" "$MEMORY_MD"
  [ "$status" -ne 0 ]
  [[ "$output" == *"timeout"* ]] || [[ "$stderr" == *"timeout"* ]]
  [[ "$output$stderr" == *"MEMORY.md weakness-block"* ]]
}

@test "artifact evidence timeout when candidate skill missing" {
  local run_id="run_timeout_cand"
  cp "$REPO_ROOT/tests/fixtures/memory-empty.md" "$MEMORY_MD"
  crossfire_snapshot_memory_md_before "$run_id" "$MEMORY_MD" >/dev/null
  ae_write_memory_with_behavioral_weakness "$run_id"
  export CROSSFIRE_ARTIFACT_TIMEOUT_SEC=1
  run crossfire_print_artifact_evidence "$run_id" "$MEMORY_MD"
  [ "$status" -ne 0 ]
  [[ "$output$stderr" == *"timeout"* ]]
  [[ "$output$stderr" == *"candidate"* ]]
}

@test "artifact evidence rejects real HERMES_HOME fail-closed" {
  run bash -c "
    export HERMES_HOME='/home/fish/.hermes'
    export REAL_HERMES_WSL='/home/fish/.hermes'
    export REAL_HERMES_WIN=''
    source '$DEMO_COMMON'
    crossfire_print_artifact_evidence run_x
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"HERMES_HOME points at real profile"* ]]
}
