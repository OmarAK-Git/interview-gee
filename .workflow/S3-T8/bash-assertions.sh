#!/usr/bin/env bash
# S3-T8 bash-equivalent assertions (mirrors tests/artifact_evidence.bats)
set -u
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
cd "$REPO_ROOT"
passed=0
failed=0

ok() { passed=$((passed + 1)); echo "PASS: $1"; }
fail() { failed=$((failed + 1)); echo "FAIL: $1"; }

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/crossfire-ae-bash.XXXXXX")"
export HERMES_HOME="${TEST_ROOT}/.crossfire/profiles/test"
export CROSSFIRE_RUNS_DIR="${TEST_ROOT}/runs"
export CROSSFIRE_CANDIDATE_SKILLS_ROOT="${TEST_ROOT}/.crossfire/candidate-skills"
export CROSSFIRE_HERMES_DISCOVERY=0
MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"
DEMO_COMMON="$REPO_ROOT/scripts/demo_common.sh"
WM_SCRIPT="$REPO_ROOT/scripts/weakness_memory.sh"
STAGE_SCRIPT="$REPO_ROOT/scripts/stage_candidate_skill.sh"

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills" "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}"

# shellcheck disable=SC1091
source "$DEMO_COMMON"
# shellcheck disable=SC1091
source "$WM_SCRIPT"
# shellcheck disable=SC1091
source "$STAGE_SCRIPT"
set +e
crossfire_require_isolated_hermes_home

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

# snapshot stores run-scoped before file
run_id="run_snap_bash"
cp "$REPO_ROOT/tests/fixtures/memory-empty.md" "$MEMORY_MD"
snap=$(crossfire_snapshot_memory_md_before "$run_id" "$MEMORY_MD")
if [ -f "$snap" ] && [[ "$snap" == *"/runs/${run_id}/memory-before.md" ]] && cmp -s "$MEMORY_MD" "$snap"; then
  ok snapshot_before
else
  fail snapshot_before
fi

# success path
run_id="run_success_bash"
cp "$REPO_ROOT/tests/fixtures/memory-empty.md" "$MEMORY_MD"
crossfire_snapshot_memory_md_before "$run_id" "$MEMORY_MD" >/dev/null
ae_finalize_run "$run_id"
success_out=$(crossfire_print_artifact_evidence "$run_id" "$MEMORY_MD" 2>&1)
success_rc=$?
if [ "$success_rc" -eq 0 ] && \
   [[ "$success_out" == *"artifact_evidence: MEMORY.md weakness-block diff"* ]] && \
   [[ "$success_out" == *"CROSSFIRE-WEAKNESSES:START"* ]] && \
   [[ "$success_out" == *"artifact_evidence: staged candidate skill"* ]] && \
   [[ "$success_out" == *"candidate_path="* ]] && \
   [[ "$success_out" == *"unverified-behavioral-followup/SKILL.md"* ]] && \
   [[ "$success_out" == *"status: unverified"* ]] && \
   [[ "$success_out" == *"source_session_id: sess_ae"* ]] && \
   [[ "$success_out" == *"Do not praise or imitate"* ]] && \
   [[ "$success_out" != *"Personal Memory"* ]] && \
   [[ "$success_out" != *"favorite prompt"* ]]; then
  ok success_evidence
else
  fail success_evidence
fi

# set -e direct call (not command substitution) — must print full SKILL.md body
run_id="run_sete_direct_bash"
sete_root="$(mktemp -d "${TMPDIR:-/tmp}/crossfire-ae-sete.XXXXXX")"
sete_out="${sete_root}/sete-direct.out"
sete_rc=0
bash -c "
  set -euo pipefail
  export HERMES_HOME='${sete_root}/.crossfire/profiles/test'
  export CROSSFIRE_RUNS_DIR='${sete_root}/runs'
  export CROSSFIRE_CANDIDATE_SKILLS_ROOT='${sete_root}/.crossfire/candidate-skills'
  export CROSSFIRE_HERMES_DISCOVERY=0
  mkdir -p \"\${HERMES_HOME}/memories\" \"\${HERMES_HOME}/skills\" \"\${CROSSFIRE_CANDIDATE_SKILLS_ROOT}\"
  MEMORY_MD=\"\${HERMES_HOME}/memories/MEMORY.md\"
  source '$DEMO_COMMON'
  source '$WM_SCRIPT'
  source '$STAGE_SCRIPT'
  cp '$REPO_ROOT/tests/fixtures/memory-empty.md' \"\$MEMORY_MD\"
  crossfire_snapshot_memory_md_before '$run_id' \"\$MEMORY_MD\" >/dev/null
  cp '$REPO_ROOT/tests/fixtures/memory-empty.md' \"\$MEMORY_MD\"
  cat >>\"\$MEMORY_MD\" <<'EOF'

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
      value: \"I just kind of watched the dashboard.\"
\`\`\`
<!-- CROSSFIRE-WEAKNESSES:END -->
EOF
  crossfire_stage_candidate_skill \
    '$run_id' behavioral w-deadbeeffeed sess_ae \
    '${run_id}/q_behavioral_01/0' 1 'action,result' >/dev/null
  crossfire_write_candidate_barrier_flag '$run_id' \
    \"\$(crossfire_candidate_skill_path behavioral)\"
  crossfire_print_artifact_evidence '$run_id' \"\$MEMORY_MD\"
  printf '%s\n' REACHED_AFTER_PRINT
" >"$sete_out" 2>&1 || sete_rc=$?
sete_text=$(cat "$sete_out" 2>/dev/null || true)
if [ "$sete_rc" -eq 0 ] && \
   [[ "$sete_text" == *"Do not praise or imitate"* ]] && \
   [[ "$sete_text" == *"--- candidate SKILL.md ---"* ]] && \
   [[ "$sete_text" == *"REACHED_AFTER_PRINT"* ]] && \
   [[ "$sete_text" != *"printf: --: invalid option"* ]]; then
  ok sete_direct_print
else
  fail sete_direct_print
fi
rm -rf "$sete_root"

# timeout: weakness block never changes
run_id="run_timeout_mem_bash"
cp "$REPO_ROOT/tests/fixtures/memory-empty.md" "$MEMORY_MD"
crossfire_snapshot_memory_md_before "$run_id" "$MEMORY_MD" >/dev/null
export CROSSFIRE_ARTIFACT_TIMEOUT_SEC=1
timeout_mem_out=$(crossfire_print_artifact_evidence "$run_id" "$MEMORY_MD" 2>&1)
timeout_mem_rc=$?
if [ "$timeout_mem_rc" -ne 0 ] && [[ "$timeout_mem_out" == *"timeout"* ]] && \
   [[ "$timeout_mem_out" == *"MEMORY.md weakness-block"* ]]; then
  ok timeout_memory
else
  fail timeout_memory
fi

# timeout: candidate missing
run_id="run_timeout_cand_bash"
cp "$REPO_ROOT/tests/fixtures/memory-empty.md" "$MEMORY_MD"
crossfire_snapshot_memory_md_before "$run_id" "$MEMORY_MD" >/dev/null
ae_write_memory_with_behavioral_weakness "$run_id"
export CROSSFIRE_ARTIFACT_TIMEOUT_SEC=1
timeout_cand_out=$(crossfire_print_artifact_evidence "$run_id" "$MEMORY_MD" 2>&1)
timeout_cand_rc=$?
if [ "$timeout_cand_rc" -ne 0 ] && [[ "$timeout_cand_out" == *"timeout"* ]] && \
   [[ "$timeout_cand_out" == *"candidate"* ]]; then
  ok timeout_candidate
else
  fail timeout_candidate
fi

# isolation fail-closed
iso_out=$(bash -c "
  export HERMES_HOME='/home/fish/.hermes'
  export REAL_HERMES_WSL='/home/fish/.hermes'
  export REAL_HERMES_WIN=''
  source '$DEMO_COMMON'
  crossfire_print_artifact_evidence run_x 2>&1
" 2>&1)
iso_rc=$?
if [ "$iso_rc" -ne 0 ] && [[ "$iso_out" == *"HERMES_HOME points at real profile"* ]]; then
  ok isolation_fail_closed
else
  fail isolation_fail_closed
fi

echo "passed=$passed failed=$failed"
[ "$failed" -eq 0 ]
