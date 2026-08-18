#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TEST_ROOT="$(mktemp -d "${BATS_TMPDIR:-/tmp}/crossfire-rb.XXXXXX")"
  export HERMES_HOME="${TEST_ROOT}/.crossfire/profiles/test"
  export CROSSFIRE_RUNS_DIR="${TEST_ROOT}/runs"
  export CROSSFIRE_CANDIDATE_SKILLS_ROOT="${TEST_ROOT}/.crossfire/candidate-skills"
  export CROSSFIRE_HERMES_DISCOVERY=0
  export CROSSFIRE_RISK_BEAT=stub
  MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"
  ACTIVATE_SCRIPT="$REPO_ROOT/scripts/activate_candidate_skill.sh"
  RISK_SCRIPT="$REPO_ROOT/scripts/demo_risk_beat.sh"
  STAGE_SCRIPT="$REPO_ROOT/scripts/stage_candidate_skill.sh"
  DEMO_COMMON="$REPO_ROOT/scripts/demo_common.sh"
  mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills" "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}"
  # shellcheck disable=SC1091
  source "$DEMO_COMMON"
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/weakness_memory.sh"
  # shellcheck disable=SC1091
  source "$STAGE_SCRIPT"
  # shellcheck disable=SC1091
  source "$ACTIVATE_SCRIPT"
  crossfire_require_isolated_hermes_home
}

teardown() {
  rm -rf "$TEST_ROOT"
}

rb_stage_behavioral_candidate() {
  local run_id="$1"
  crossfire_stage_candidate_skill \
    "$run_id" behavioral w-deadbeeffeed sess_stub \
    "${run_id}/q_behavioral_01/0" 1 "action,result" >/dev/null
  crossfire_write_candidate_barrier_flag "$run_id" \
    "$(crossfire_candidate_skill_path behavioral)"
}

rb_mark_opener_complete() {
  local run_id="$1"
  crossfire_mark_opener_complete "$run_id"
}

rb_run_risk_beat() {
  env HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
    CROSSFIRE_CANDIDATE_SKILLS_ROOT="$CROSSFIRE_CANDIDATE_SKILLS_ROOT" \
    CROSSFIRE_HERMES_DISCOVERY=0 \
    CROSSFIRE_RISK_BEAT=stub \
    CROSSFIRE_RUN_ID="${1:-run_rb_test}" \
    CROSSFIRE_OPENER_FAMILY=behavioral \
    "$@"
}

@test "isolation fail-closed when HERMES_HOME is real profile path" {
  run bash -c "
    export HERMES_HOME='/home/fish/.hermes'
    export REAL_HERMES_WSL='/home/fish/.hermes'
    export REAL_HERMES_WIN=''
    source '$ACTIVATE_SCRIPT'
    crossfire_require_isolated_hermes_home
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"HERMES_HOME points at real profile"* ]]
}

@test "activation fails before opener completes" {
  local run_id="run_no_opener"
  rb_stage_behavioral_candidate "$run_id"
  run crossfire_activate_candidate_skill "$run_id" behavioral
  [ "$status" -ne 0 ]
  [[ "$output" == *"opener not complete"* ]]
  [ ! -f "${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md" ]
}

@test "risk beat prints label and warning before candidate influence" {
  local run_id="run_label"
  rb_stage_behavioral_candidate "$run_id"
  rb_mark_opener_complete "$run_id"
  crossfire_ensure_isolated_skill >/dev/null
  run rb_run_risk_beat bash "$RISK_SCRIPT"
  [ "$status" -eq 0 ]
  local pos_label pos_live
  pos_label=$(grep -n 'UNVERIFIED LEARNING RISK DEMO' <<<"$output" | head -1 | cut -d: -f1)
  pos_live=$(grep -n 'candidate_live_path=' <<<"$output" | head -1 | cut -d: -f1)
  [ -n "$pos_label" ] && [ -n "$pos_live" ]
  [ "$pos_label" -lt "$pos_live" ]
  [[ "$output" == *"WARNING:"* ]]
  [[ "$output" == *"unverified"* ]]
}

@test "candidate installs to namespaced live path not crossfire-interviewer" {
  local run_id="run_namespaced"
  rb_stage_behavioral_candidate "$run_id"
  rb_mark_opener_complete "$run_id"
  crossfire_ensure_isolated_skill >/dev/null
  local live_path
  live_path=$(crossfire_activate_candidate_skill "$run_id" behavioral)
  [[ "$live_path" == *"/skills/unverified-behavioral-followup/SKILL.md" ]]
  [ -f "$live_path" ]
  [ -f "${HERMES_SKILLS_DIR}/crossfire-interviewer/SKILL.md" ]
  [[ "$live_path" != *"/crossfire-interviewer/"* ]]
}

@test "active candidate preserves unverified metadata" {
  local run_id="run_metadata"
  rb_stage_behavioral_candidate "$run_id"
  rb_mark_opener_complete "$run_id"
  crossfire_activate_candidate_skill "$run_id" behavioral >/dev/null
  local live="${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md"
  grep -q '^id: crossfire.candidate.behavioral' "$live"
  grep -q '^name: unverified-behavioral-followup' "$live"
  grep -q '^status: unverified' "$live"
  grep -q '^weakness_id: w-deadbeeffeed' "$live"
  grep -q '^source_session_id: sess_stub' "$live"
  grep -q "^answer_ref: ${run_id}/q_behavioral_01/0" "$live"
  grep -q '^observation_count: 1' "$live"
  grep -q 'Do not praise or imitate' "$live"
}

@test "startup-only documents new process for candidate load" {
  local run_id="run_newproc"
  rb_stage_behavioral_candidate "$run_id"
  rb_mark_opener_complete "$run_id"
  crossfire_ensure_isolated_skill >/dev/null
  run rb_run_risk_beat bash "$RISK_SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"startup-only"* ]]
  [[ "$output" == *"new process"* ]]
  [[ "$output" == *"CROSSFIRE_RISK_BEAT_PID="* ]]
}

@test "stub follow-up requests missing elements from candidate skill" {
  local run_id="run_followup"
  rb_stage_behavioral_candidate "$run_id"
  rb_mark_opener_complete "$run_id"
  crossfire_ensure_isolated_skill >/dev/null
  run rb_run_risk_beat bash "$RISK_SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Follow-up:"* ]]
  [[ "$output" == *"action"* ]] || [[ "$output" == *"result"* ]]
}

@test "activated candidate remains available after risk beat" {
  local run_id="run_persist"
  rb_stage_behavioral_candidate "$run_id"
  rb_mark_opener_complete "$run_id"
  crossfire_ensure_isolated_skill >/dev/null
  rb_run_risk_beat bash "$RISK_SCRIPT" >/dev/null
  [ -f "${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md" ]
  grep -q '^status: unverified' "${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md"
}

@test "CROSSFIRE_OPENER_COMPLETE=1 allows activation without flag file" {
  local run_id="run_env_opener"
  rb_stage_behavioral_candidate "$run_id"
  export CROSSFIRE_OPENER_COMPLETE=1
  run crossfire_activate_candidate_skill "$run_id" behavioral
  [ "$status" -eq 0 ]
  [ -f "${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md" ]
}
