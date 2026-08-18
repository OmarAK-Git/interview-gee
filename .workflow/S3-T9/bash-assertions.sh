#!/usr/bin/env bash
# S3-T9 bash-equivalent assertions (mirrors tests/risk_beat.bats)
set -u
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
cd "$REPO_ROOT"
passed=0
failed=0

ok() { passed=$((passed + 1)); echo "PASS: $1"; }
fail() { failed=$((failed + 1)); echo "FAIL: $1"; }

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/crossfire-rb-bash.XXXXXX")"
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

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills" "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}"

# shellcheck disable=SC1091
source "$DEMO_COMMON"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/weakness_memory.sh"
# shellcheck disable=SC1091
source "$STAGE_SCRIPT"
# shellcheck disable=SC1091
source "$ACTIVATE_SCRIPT"
set +e
crossfire_require_isolated_hermes_home

rb_stage_behavioral_candidate() {
  local run_id="$1"
  crossfire_stage_candidate_skill \
    "$run_id" behavioral w-deadbeeffeed sess_stub \
    "${run_id}/q_behavioral_01/0" 1 "action,result" >/dev/null
  crossfire_write_candidate_barrier_flag "$run_id" \
    "$(crossfire_candidate_skill_path behavioral)"
}

# isolation fail-closed
iso_out=$(bash -c "
  export HERMES_HOME='/home/fish/.hermes'
  export REAL_HERMES_WSL='/home/fish/.hermes'
  export REAL_HERMES_WIN=''
  source '$ACTIVATE_SCRIPT'
  crossfire_require_isolated_hermes_home
" 2>&1) || true
if grep -q 'HERMES_HOME points at real profile' <<<"$iso_out"; then
  ok isolation_fail_closed
else
  fail isolation_fail_closed
fi

# activation before opener fails
run_id="run_no_opener_bash"
rb_stage_behavioral_candidate "$run_id"
act_out=$(crossfire_activate_candidate_skill "$run_id" behavioral 2>&1) || true
if grep -q 'opener not complete' <<<"$act_out"; then
  ok activation_before_opener
else
  fail activation_before_opener
fi
[ ! -f "${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md" ] && ok no_live_before_opener || fail no_live_before_opener

# label + warning before influence
run_id="run_label_bash"
rb_stage_behavioral_candidate "$run_id"
crossfire_mark_opener_complete "$run_id" >/dev/null
crossfire_ensure_isolated_skill >/dev/null
risk_out=$(env HERMES_HOME="$HERMES_HOME" \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  CROSSFIRE_CANDIDATE_SKILLS_ROOT="$CROSSFIRE_CANDIDATE_SKILLS_ROOT" \
  CROSSFIRE_HERMES_DISCOVERY=0 CROSSFIRE_RISK_BEAT=stub \
  CROSSFIRE_RUN_ID="$run_id" CROSSFIRE_OPENER_FAMILY=behavioral \
  bash "$RISK_SCRIPT" 2>&1) || true
label_line=$(grep -n 'UNVERIFIED LEARNING RISK DEMO' <<<"$risk_out" | head -1 | cut -d: -f1)
live_line=$(grep -n 'candidate_live_path=' <<<"$risk_out" | head -1 | cut -d: -f1)
if [ -n "$label_line" ] && [ -n "$live_line" ] && [ "$label_line" -lt "$live_line" ] && \
   grep -q 'WARNING:' <<<"$risk_out" && grep -qi 'unverified' <<<"$risk_out"; then
  ok label_warning_before_influence
else
  fail label_warning_before_influence
fi

# namespaced live path
run_id="run_namespaced_bash"
rb_stage_behavioral_candidate "$run_id"
crossfire_mark_opener_complete "$run_id" >/dev/null
crossfire_ensure_isolated_skill >/dev/null
live_path=$(crossfire_activate_candidate_skill "$run_id" behavioral)
if [[ "$live_path" == *"/skills/unverified-behavioral-followup/SKILL.md" ]] && \
   [ -f "$live_path" ] && \
   [ -f "${HERMES_SKILLS_DIR}/crossfire-interviewer/SKILL.md" ] && \
   [[ "$live_path" != *"/crossfire-interviewer/"* ]]; then
  ok namespaced_live_path
else
  fail namespaced_live_path
fi

# unverified metadata preserved
live="${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md"
meta_ok=1
grep -q '^id: crossfire.candidate.behavioral' "$live" || meta_ok=0
grep -q '^name: unverified-behavioral-followup' "$live" || meta_ok=0
grep -q '^status: unverified' "$live" || meta_ok=0
grep -q '^weakness_id: w-deadbeeffeed' "$live" || meta_ok=0
grep -q 'Do not praise or imitate' "$live" || meta_ok=0
[ "$meta_ok" -eq 1 ] && ok unverified_metadata || fail unverified_metadata

# startup-only new process
if grep -q 'startup-only' <<<"$risk_out" && grep -qi 'new process' <<<"$risk_out" && \
   grep -q 'CROSSFIRE_RISK_BEAT_PID=' <<<"$risk_out"; then
  ok startup_only_new_process
else
  fail startup_only_new_process
fi

# follow-up references missing elements
if grep -q 'Follow-up:' <<<"$risk_out" && \
   ( grep -qi 'action' <<<"$risk_out" || grep -qi 'result' <<<"$risk_out" ); then
  ok followup_missing_elements
else
  fail followup_missing_elements
fi

# candidate persists after beat
if [ -f "${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md" ] && \
   grep -q '^status: unverified' "${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md"; then
  ok candidate_persists
else
  fail candidate_persists
fi

# CROSSFIRE_OPENER_COMPLETE=1 env gate
run_id="run_env_opener_bash"
TEST_ROOT2="$(mktemp -d "${TMPDIR:-/tmp}/crossfire-rb-env.XXXXXX")"
export HERMES_HOME="${TEST_ROOT2}/.crossfire/profiles/test"
export CROSSFIRE_RUNS_DIR="${TEST_ROOT2}/runs"
export CROSSFIRE_CANDIDATE_SKILLS_ROOT="${TEST_ROOT2}/.crossfire/candidate-skills"
mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills" "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}"
crossfire_require_isolated_hermes_home
crossfire_stage_candidate_skill \
  "$run_id" behavioral w-deadbeeffeed sess_stub \
  "${run_id}/q_behavioral_01/0" 1 "action,result" >/dev/null
export CROSSFIRE_OPENER_COMPLETE=1
if crossfire_activate_candidate_skill "$run_id" behavioral >/dev/null && \
   [ -f "${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md" ]; then
  ok env_opener_complete
else
  fail env_opener_complete
fi
unset CROSSFIRE_OPENER_COMPLETE
rm -rf "$TEST_ROOT2"

echo "passed=$passed failed=$failed"
[ "$failed" -eq 0 ]
