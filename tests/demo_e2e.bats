#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  DEMO_SCRIPT="$REPO_ROOT/scripts/demo.sh"
  DEMO_COMMON="$REPO_ROOT/scripts/demo_common.sh"
  TEST_ROOT="$(mktemp -d "${BATS_TMPDIR:-/tmp}/crossfire-e2e.XXXXXX")"
  export HERMES_HOME="${TEST_ROOT}/.crossfire/profiles/test"
  export CROSSFIRE_RUNS_DIR="${TEST_ROOT}/runs"
  export CROSSFIRE_CANDIDATE_SKILLS_ROOT="${TEST_ROOT}/.crossfire/candidate-skills"
  export CROSSFIRE_ASSESSOR=stub
  export CROSSFIRE_OPENER=stub
  export CROSSFIRE_RISK_BEAT=stub
  export CROSSFIRE_HERMES_DISCOVERY=0
  export CROSSFIRE_STUB_SESSION_ID=sess_e2e_s1
  MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"
  # shellcheck disable=SC1091
  source "$DEMO_COMMON"
  crossfire_require_isolated_hermes_home
}

teardown() {
  rm -rf "$TEST_ROOT"
}

e2e_run_demo() {
  env HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
    CROSSFIRE_CANDIDATE_SKILLS_ROOT="$CROSSFIRE_CANDIDATE_SKILLS_ROOT" \
    CROSSFIRE_ASSESSOR=stub CROSSFIRE_OPENER=stub CROSSFIRE_RISK_BEAT=stub \
    CROSSFIRE_HERMES_DISCOVERY=0 CROSSFIRE_STUB_SESSION_ID=sess_e2e_s1 \
    "$@"
}

e2e_run_prepare() {
  e2e_run_demo bash "$DEMO_SCRIPT" --prepare
}

@test "demo.sh exists and sources isolation contract" {
  [ -f "$DEMO_SCRIPT" ]
  grep -q 'crossfire_require_isolated_hermes_home' "$DEMO_SCRIPT"
  grep -q 'demo_session_1.sh' "$DEMO_SCRIPT"
  grep -q 'demo_session_2.sh' "$DEMO_SCRIPT"
  grep -q 'demo_risk_beat.sh' "$DEMO_SCRIPT"
}

@test "demo fails closed on real HERMES_HOME with recovery instruction" {
  run bash -c "
    export HERMES_HOME='/home/fish/.hermes'
    export REAL_HERMES_WSL='/home/fish/.hermes'
    export REAL_HERMES_WIN=''
    bash '$DEMO_SCRIPT'
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"HERMES_HOME points at real profile"* ]] || [[ "$output" == *"DEMO FAIL"* ]]
  [[ "$output" == *"Recovery:"* ]] || [[ "$output" == *"--prepare"* ]]
}

@test "demo_prepare restores disposable profile only" {
  mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills/stray"
  echo 'stray' >"${HERMES_HOME}/skills/stray/SKILL.md"
  echo 'old weakness' >"$MEMORY_MD"
  mkdir -p "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}/unverified-behavioral-followup"
  echo 'staged' >"${CROSSFIRE_CANDIDATE_SKILLS_ROOT}/unverified-behavioral-followup/SKILL.md"

  CROSSFIRE_PATHS_ONLY=1 source "$DEMO_COMMON"
  win_was_absent=0
  wsl_was_absent=0
  if [ -n "${REAL_HERMES_WIN:-}" ] && [ ! -e "$REAL_HERMES_WIN" ]; then win_was_absent=1; fi
  if [ ! -e "$REAL_HERMES_WSL" ]; then wsl_was_absent=1; fi

  run e2e_run_prepare
  [ "$status" -eq 0 ]
  [[ "$output" == *"demo_prepare"* ]]
  grep -q 'Personal Memory' "$MEMORY_MD"
  ! grep -q 'old weakness' "$MEMORY_MD"
  [ ! -f "${HERMES_HOME}/skills/stray/SKILL.md" ]
  [ ! -f "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}/unverified-behavioral-followup/SKILL.md" ]

  if [ "$win_was_absent" -eq 1 ] && [ -n "${REAL_HERMES_WIN:-}" ] && [ -e "$REAL_HERMES_WIN" ]; then
    echo "created REAL_HERMES_WIN: $REAL_HERMES_WIN" >&2
    return 1
  fi
  if [ "$wsl_was_absent" -eq 1 ] && [ -e "$REAL_HERMES_WSL" ]; then
    echo "created REAL_HERMES_WSL: $REAL_HERMES_WSL" >&2
    return 1
  fi
}

@test "stub full-sequence smoke completes preflight through risk beat" {
  run e2e_run_demo bash "$DEMO_SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"preflight:"* ]]
  [[ "$output" == *"CROSSFIRE q_technical_01"* ]]
  [[ "$output" == *"CROSSFIRE: session one finalized"* ]]
  [[ "$output" == *"artifact_evidence:"* ]]
  [[ "$output" == *"opening_target_source=MEMORY.md"* ]]
  [[ "$output" == *"Question:"* ]]
  [[ "$output" == *"UNVERIFIED LEARNING RISK DEMO"* ]]
  [[ "$output" == *"Follow-up:"* ]]
  [[ "$output" == *"demo: complete"* ]]
}

@test "full sequence prints distinct session and process IDs" {
  run e2e_run_demo bash "$DEMO_SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"CROSSFIRE_SESSION_ONE_PID="* ]]
  [[ "$output" == *"CROSSFIRE_SESSION_TWO_PID="* ]]
  [[ "$output" == *"session_identifiability: distinct"* ]]
  local s1_pid s2_pid
  s1_pid=$(grep '^CROSSFIRE_SESSION_ONE_PID=' <<<"$output" | head -1 | cut -d= -f2)
  s2_pid=$(grep '^CROSSFIRE_SESSION_TWO_PID=' <<<"$output" | head -1 | cut -d= -f2)
  [ -n "$s1_pid" ] && [ -n "$s2_pid" ]
  [ "$s1_pid" != "$s2_pid" ]
}

@test "full sequence prints layer attribution labels" {
  run e2e_run_demo bash "$DEMO_SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"layer_attribution:"* ]]
  [[ "$output" == *"opening_target=MEMORY.md"* ]]
  [[ "$output" == *"opener_wording=stable_interviewer_skill"* ]]
  [[ "$output" == *"candidate_excluded_from_opener"* ]]
  [[ "$output" == *"target selected by prompt memory"* ]]
}

@test "scripted bad answer persists with at least two missing elements" {
  run e2e_run_demo bash "$DEMO_SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"I just kind of watched the dashboard"* ]]
  grep -q 'missing_elements: \[action, result\]' "$MEMORY_MD" || \
    grep -q 'missing_elements: \[action,result\]' "$MEMORY_MD" || \
    grep -q 'action, result' "$MEMORY_MD"
  local run_id spool_file
  run_id=$(grep '^CROSSFIRE_RUN_ID=' <<<"$output" | tail -1 | cut -d= -f2)
  [ -n "$run_id" ]
  spool_file="${CROSSFIRE_RUNS_DIR}/${run_id}/spool/q_behavioral_01.yaml"
  [ -f "$spool_file" ]
  grep -q 'missing_elements: \[action, result\]' "$spool_file"
}

@test "failure exits early with recovery instruction on invalid profile path" {
  run env HERMES_HOME="${TEST_ROOT}/not-crossfire/profile" \
    CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
    bash "$DEMO_SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Recovery:"* ]]
  [[ "$output" == *"DEMO FAIL"* ]]
  [[ "$output" == *"non-disposable HERMES_HOME"* ]] || [[ "$output" == *"real profile"* ]]
}

@test "CROSSFIRE_SKIP_RISK_BEAT=1 skips optional beat but completes opener demo" {
  run env CROSSFIRE_SKIP_RISK_BEAT=1 \
    HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
    CROSSFIRE_CANDIDATE_SKILLS_ROOT="$CROSSFIRE_CANDIDATE_SKILLS_ROOT" \
    CROSSFIRE_ASSESSOR=stub CROSSFIRE_OPENER=stub \
    CROSSFIRE_HERMES_DISCOVERY=0 CROSSFIRE_STUB_SESSION_ID=sess_e2e_s1 \
    bash "$DEMO_SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Question:"* ]]
  [[ "$output" == *"demo: complete"* ]]
  ! [[ "$output" == *"UNVERIFIED LEARNING RISK DEMO"* ]]
}

@test "demo does not exec hermes directly" {
  local direct
  direct=$(grep -vE '^\s*#' "$DEMO_SCRIPT" | grep -E '(^|[;&|])[[:space:]]*hermes[[:space:]]' || true)
  [ -z "$direct" ]
}
