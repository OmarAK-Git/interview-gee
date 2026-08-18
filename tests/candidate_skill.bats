#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TEST_ROOT="$(mktemp -d "${BATS_TMPDIR:-/tmp}/crossfire-cs.XXXXXX")"
  export HERMES_HOME="${TEST_ROOT}/.crossfire/profiles/test"
  export CROSSFIRE_RUNS_DIR="${TEST_ROOT}/runs"
  export CROSSFIRE_CANDIDATE_SKILLS_ROOT="${TEST_ROOT}/.crossfire/candidate-skills"
  mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills" "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}"
  MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"
  STAGE_SCRIPT="$REPO_ROOT/scripts/stage_candidate_skill.sh"
  DEMO_SCRIPT="$REPO_ROOT/scripts/demo_session_1.sh"
  # shellcheck disable=SC1091
  source "$STAGE_SCRIPT"
  crossfire_require_isolated_hermes_home
}

teardown() {
  rm -rf "$TEST_ROOT"
}

cs_write_behavioral_spool() {
  local run_id="$1" qid="$2"
  local spool_dir="${CROSSFIRE_RUNS_DIR}/${run_id}/spool"
  mkdir -p "$spool_dir"
  cat >"${spool_dir}/${qid}.yaml" <<EOF
family: behavioral
missing_elements: [action, result]
evidence:
  kind: quote
  value: "I just kind of watched the dashboard."
persist_recommended: true
question_id: ${qid}
answer_ref: ${run_id}/${qid}/0
source_session_id: sess_stub
submitted_answer: |
  I just kind of watched the dashboard.
EOF
}

cs_persist_from_spool() {
  local run_id="$1"
  env HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
    CROSSFIRE_ASSESSOR=stub CROSSFIRE_HERMES_DISCOVERY=0 \
    CROSSFIRE_FINALIZE_RUN_ID="$run_id" \
    bash "$DEMO_SCRIPT" >/dev/null
}

cs_candidate_root() {
  printf '%s' "$CROSSFIRE_CANDIDATE_SKILLS_ROOT"
}

@test "repo .crossfire/candidate-skills/.gitkeep exists" {
  [ -f "$REPO_ROOT/.crossfire/candidate-skills/.gitkeep" ]
}

@test "crossfire_assert_candidates_excluded_from_live fails on live candidate SKILL.md" {
  mkdir -p "${HERMES_SKILLS_DIR}/unverified-behavioral-followup"
  cat >"${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md" <<'EOF'
---
id: crossfire.candidate.behavioral
name: unverified-behavioral-followup
status: unverified
---
EOF
  run crossfire_assert_candidates_excluded_from_live
  [ "$status" -ne 0 ]
  [[ "$output" == *"candidate skill material found under live skills dir"* ]]
}

@test "crossfire_assert_candidates_excluded_from_live allows crossfire-interviewer only" {
  crossfire_ensure_isolated_skill >/dev/null
  run crossfire_assert_candidates_excluded_from_live
  [ "$status" -eq 0 ]
}

@test "crossfire_stage_candidate_skill writes under candidate-skills not live dir" {
  local run_id="run_stage_test"
  local staged
  staged=$(crossfire_stage_candidate_skill \
    "$run_id" behavioral w-deadbeeffeed sess_stub \
    "${run_id}/q_behavioral_01/0" 1 "action,result")
  [[ "$staged" == *"/.crossfire/candidate-skills/unverified-behavioral-followup/SKILL.md" ]]
  [ ! -e "${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md" ]
  grep -q '^id: crossfire.candidate.behavioral' "$staged"
  grep -q '^status: unverified' "$staged"
  grep -q '^weakness_id: w-deadbeeffeed' "$staged"
  grep -q '^source_session_id: sess_stub' "$staged"
  grep -q "^answer_ref: ${run_id}/q_behavioral_01/0" "$staged"
  grep -q '^observation_count: 1' "$staged"
  grep -q 'missing_elements: \[action,result\]' "$staged"
}

@test "candidate body does not praise or imitate submitted bad answer" {
  local run_id="run_body_test"
  cs_write_behavioral_spool "$run_id" "q_behavioral_01"
  cs_persist_from_spool "$run_id"
  crossfire_stage_candidates_for_run "$run_id" "$MEMORY_MD" >/dev/null
  local skill="${CROSSFIRE_CANDIDATE_SKILLS_ROOT}/unverified-behavioral-followup/SKILL.md"
  [ -f "$skill" ]
  grep -q 'Do not praise or imitate' "$skill"
  grep -q '^source_session_id: sess_stub' "$skill"
  grep -q "^answer_ref: ${run_id}/q_behavioral_01/0" "$skill"
  ! grep -q 'I just kind of watched the dashboard' "$skill"
  ! grep -q 'good answer' "$skill"
  ! grep -q 'model answer' "$skill"
}

@test "crossfire_stage_candidates_for_run writes barrier flag" {
  local run_id="run_flag_test"
  cs_write_behavioral_spool "$run_id" "q_behavioral_01"
  cs_persist_from_spool "$run_id"
  crossfire_stage_candidates_for_run "$run_id" "$MEMORY_MD" >/dev/null
  [ -f "${CROSSFIRE_RUNS_DIR}/${run_id}/candidate-excluded.flag" ]
  grep -q 'unverified-behavioral-followup/SKILL.md' \
    "${CROSSFIRE_RUNS_DIR}/${run_id}/candidate-excluded.flag"
}

@test "only one candidate per target_family" {
  local run_id="run_dup_family"
  cs_write_behavioral_spool "$run_id" "q_behavioral_01"
  cs_write_behavioral_spool "$run_id" "q_behavioral_02"
  run crossfire_stage_candidates_for_run "$run_id" "$MEMORY_MD"
  [ "$status" -ne 0 ]
  [[ "$output" == *"more than one persist-eligible spool entry for family behavioral"* ]]
}

@test "stage snapshots live stray then writes staged candidate" {
  local run_id="run_stage_with_stray"
  mkdir -p "${HERMES_SKILLS_DIR}/unverified-behavioral-followup"
  cat >"${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md" <<'EOF'
---
id: crossfire.candidate.behavioral
name: unverified-behavioral-followup
status: unverified
---
EOF
  cs_write_behavioral_spool "$run_id" "q_behavioral_01"
  cs_persist_from_spool "$run_id"
  crossfire_stage_candidates_for_run "$run_id" "$MEMORY_MD" >/dev/null
  [ ! -e "${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md" ]
  [ -f "${CROSSFIRE_RUNS_DIR}/${run_id}/live-skill-snapshot/unverified-behavioral-followup/SKILL.md" ]
  local skill="${CROSSFIRE_CANDIDATE_SKILLS_ROOT}/unverified-behavioral-followup/SKILL.md"
  [ -f "$skill" ]
  grep -q '^source_session_id: sess_stub' "$skill"
  grep -q "^answer_ref: ${run_id}/q_behavioral_01/0" "$skill"
}

@test "snapshot fallback moves live candidate out of HERMES_SKILLS_DIR" {
  local run_id="run_snapshot"
  mkdir -p "${HERMES_SKILLS_DIR}/unverified-behavioral-followup"
  cat >"${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md" <<'EOF'
---
id: crossfire.candidate.behavioral
name: unverified-behavioral-followup
status: unverified
---
EOF
  crossfire_snapshot_live_candidates_if_any "$run_id"
  [ ! -e "${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md" ]
  [ -f "${CROSSFIRE_RUNS_DIR}/${run_id}/live-skill-snapshot/unverified-behavioral-followup/SKILL.md" ]
  run crossfire_assert_candidates_excluded_from_live
  [ "$status" -eq 0 ]
}

@test "isolation fail-closed when HERMES_HOME is real profile path" {
  run bash -c "
    export HERMES_HOME='/home/fish/.hermes'
    export REAL_HERMES_WSL='/home/fish/.hermes'
    export REAL_HERMES_WIN=''
    source '$REPO_ROOT/scripts/stage_candidate_skill.sh'
    crossfire_require_isolated_hermes_home
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"HERMES_HOME points at real profile"* ]]
}

@test "weakness_id matches persist computation from spool topic" {
  local run_id="run_wid"
  cs_write_behavioral_spool "$run_id" "q_behavioral_01"
  local expected
  expected=$(crossfire_candidate_weakness_id_from_spool \
    "${CROSSFIRE_RUNS_DIR}/${run_id}/spool/q_behavioral_01.yaml")
  cs_persist_from_spool "$run_id"
  crossfire_stage_candidates_for_run "$run_id" "$MEMORY_MD" >/dev/null
  grep -q "weakness_id: ${expected}" \
    "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}/unverified-behavioral-followup/SKILL.md"
}

@test "optional live: unverified name absent from hermes skills list" {
  if [ "${CROSSFIRE_LIVE:-0}" != "1" ]; then
    skip "CROSSFIRE_LIVE not set"
  fi
  crossfire_discover_hermes_or_fail_closed
  local run_id="run_live_list"
  cs_write_behavioral_spool "$run_id" "q_behavioral_01"
  cs_persist_from_spool "$run_id"
  crossfire_stage_candidates_for_run "$run_id" "$MEMORY_MD" >/dev/null
  local list_out
  list_out=$(mktemp)
  crossfire_hermes_invoke "hermes skills list --source local" "$list_out" /dev/null
  ! grep -q 'unverified-' "$list_out"
}

@test "optional live: --skills on staged path errors Unknown skill" {
  if [ "${CROSSFIRE_LIVE:-0}" != "1" ]; then
    skip "CROSSFIRE_LIVE not set"
  fi
  crossfire_discover_hermes_or_fail_closed
  local run_id="run_live_reject"
  cs_write_behavioral_spool "$run_id" "q_behavioral_01"
  cs_persist_from_spool "$run_id"
  crossfire_stage_candidates_for_run "$run_id" "$MEMORY_MD" >/dev/null
  local staged_dir
  staged_dir=$(dirname "$(crossfire_candidate_skill_path behavioral)")
  local err_out
  err_out=$(mktemp)
  run crossfire_hermes_invoke \
    "hermes chat -Q -q ping --max-turns 0 --toolsets skills --skills ${staged_dir} --source tool" \
    /dev/null "$err_out"
  [ "$status" -ne 0 ]
  grep -q 'Unknown skill' "$err_out"
}
