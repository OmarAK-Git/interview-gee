#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  DEMO_SCRIPT="$REPO_ROOT/scripts/demo_session_2.sh"
  DEMO_ONE="$REPO_ROOT/scripts/demo_session_1.sh"
  DEMO_COMMON="$REPO_ROOT/scripts/demo_common.sh"
  FIXTURE_THREE="$REPO_ROOT/tests/fixtures/memory-three-weaknesses.md"
  TEST_ROOT="$(mktemp -d "${BATS_TMPDIR:-/tmp}/crossfire-s2.XXXXXX")"
  export HERMES_HOME="${TEST_ROOT}/.crossfire/profiles/test"
  mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills"
  export CROSSFIRE_RUNS_DIR="${TEST_ROOT}/runs"
  export CROSSFIRE_CANDIDATE_SKILLS_ROOT="${TEST_ROOT}/.crossfire/candidate-skills"
  export CROSSFIRE_ASSESSOR=stub
  export CROSSFIRE_OPENER=stub
  export CROSSFIRE_HERMES_DISCOVERY=0
  export CROSSFIRE_STUB_SESSION_ID=sess_stub_s2
  MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"
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

s2_run_harness() {
  env HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
    CROSSFIRE_CANDIDATE_SKILLS_ROOT="$CROSSFIRE_CANDIDATE_SKILLS_ROOT" \
    CROSSFIRE_OPENER=stub CROSSFIRE_HERMES_DISCOVERY=0 \
    CROSSFIRE_STUB_SESSION_ID=sess_stub_s2 \
    "$@"
}

s2_copy_fixture_memory() {
  cp "$FIXTURE_THREE" "$MEMORY_MD"
}

s2_write_tie_memory() {
  cat >"$MEMORY_MD" <<'EOF'
<!-- CROSSFIRE-WEAKNESSES:START -->
```yaml
version: 1
weaknesses:
  - weakness_id: w-zzzzzzzzzzzz
    family: behavioral
    topic: tie older
    topic_key: tie-older
    missing_elements: [action, result]
    first_seen: 2026-08-15T12:00:00Z
    last_seen: 2026-08-16T12:00:00Z
    observation_count: 1
    source_session_id: sess_tie_a
    answer_ref: run_t/a/0
    evidence:
      kind: quote
      value: "watched"
  - weakness_id: w-aaaaaaaaaaaa
    family: technical
    topic: tie winner obs
    topic_key: tie-winner-obs
    missing_elements: [tradeoff, verification]
    first_seen: 2026-08-15T12:00:00Z
    last_seen: 2026-08-16T12:00:00Z
    observation_count: 3
    source_session_id: sess_tie_b
    answer_ref: run_t/b/0
    evidence:
      kind: quote
      value: "skipped"
  - weakness_id: w-bbbbbbbbbbbb
    family: product
    topic: tie id asc
    topic_key: tie-id-asc
    missing_elements: [metric, decision]
    first_seen: 2026-08-15T12:00:00Z
    last_seen: 2026-08-16T12:00:00Z
    observation_count: 1
    source_session_id: sess_tie_c
    answer_ref: run_t/c/0
    evidence:
      kind: quote
      value: "no metric"
```
<!-- CROSSFIRE-WEAKNESSES:END -->
EOF
}

s2_run_session_one_persist() {
  env HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
    CROSSFIRE_ASSESSOR=stub CROSSFIRE_HERMES_DISCOVERY=0 \
    bash "$DEMO_ONE" >/dev/null
}

@test "demo_session_2 sources demo_common and fails closed on real HERMES_HOME" {
  run bash -c "
    export HERMES_HOME='/home/fish/.hermes'
    export REAL_HERMES_WSL='/home/fish/.hermes'
    export REAL_HERMES_WIN=''
    source '$DEMO_COMMON'
    crossfire_require_isolated_hermes_home
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"HERMES_HOME points at real profile"* ]]
}

@test "select_newest picks highest last_seen from three-weakness fixture" {
  s2_copy_fixture_memory
  run crossfire_select_newest_weakness "$MEMORY_MD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"weakness_id=w-b2f32d5ee0be"* ]]
  [[ "$output" == *"family=product"* ]]
  [[ "$output" == *"source_session_id=sess_c"* ]]
  [[ "$output" == *"opening_target_source=MEMORY.md"* ]]
}

@test "select_newest tie-break prefers higher observation_count" {
  s2_write_tie_memory
  run crossfire_select_newest_weakness "$MEMORY_MD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"weakness_id=w-aaaaaaaaaaaa"* ]]
  [[ "$output" == *"source_session_id=sess_tie_b"* ]]
}

@test "select_newest tie-break prefers lower weakness_id when last_seen and obs equal" {
  cat >"$MEMORY_MD" <<'EOF'
<!-- CROSSFIRE-WEAKNESSES:START -->
```yaml
version: 1
weaknesses:
  - weakness_id: w-cccccccccccc
    family: behavioral
    topic: id lose
    topic_key: id-lose
    missing_elements: [action, result]
    first_seen: 2026-08-16T12:00:00Z
    last_seen: 2026-08-16T12:00:00Z
    observation_count: 2
    source_session_id: sess_id_lose
    answer_ref: run_i/l/0
    evidence:
      kind: quote
      value: "lose"
  - weakness_id: w-aaaaaaaaaaaa
    family: product
    topic: id win
    topic_key: id-win
    missing_elements: [metric, decision]
    first_seen: 2026-08-16T12:00:00Z
    last_seen: 2026-08-16T12:00:00Z
    observation_count: 2
    source_session_id: sess_id_win
    answer_ref: run_i/w/0
    evidence:
      kind: quote
      value: "win"
```
<!-- CROSSFIRE-WEAKNESSES:END -->
EOF
  run crossfire_select_newest_weakness "$MEMORY_MD"
  [ "$status" -eq 0 ]
  [[ "$output" == *"weakness_id=w-aaaaaaaaaaaa"* ]]
}

@test "harness prints directive fields before Question line" {
  s2_copy_fixture_memory
  run s2_run_harness bash "$DEMO_SCRIPT"
  [ "$status" -eq 0 ]
  local pos_src pos_q
  pos_src=$(grep -n 'opening_target_source=MEMORY.md' <<<"$output" | head -1 | cut -d: -f1)
  pos_q=$(grep -n '^Question:' <<<"$output" | head -1 | cut -d: -f1)
  [ -n "$pos_src" ] && [ -n "$pos_q" ]
  [ "$pos_src" -lt "$pos_q" ]
  [[ "$output" == *"weakness_id=w-b2f32d5ee0be"* ]]
  [[ "$output" == *"family=product"* ]]
  [[ "$output" == *"source_session_id=sess_c"* ]]
  [[ "$output" == *"target selected by prompt memory; wording generated under stable interviewer procedure"* ]]
}

@test "harness fails when candidate skill is in live dir" {
  s2_copy_fixture_memory
  mkdir -p "${HERMES_HOME}/skills/unverified-behavioral-followup"
  cat >"${HERMES_HOME}/skills/unverified-behavioral-followup/SKILL.md" <<'EOF'
---
id: crossfire.candidate.behavioral
name: unverified-behavioral-followup
status: unverified
---
EOF
  run s2_run_harness bash "$DEMO_SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"candidate skill material found under live skills dir"* ]]
}

@test "harness fails when session two session ID equals session one" {
  s2_copy_fixture_memory
  run s2_run_harness \
    env CROSSFIRE_SESSION_ONE_ID=sess_stub_s2 \
    bash "$DEMO_SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"session ID must differ"* ]]
}

@test "harness passes distinct session IDs from session one" {
  s2_copy_fixture_memory
  run s2_run_harness \
    env CROSSFIRE_SESSION_ONE_ID=sess_one_distinct \
    bash "$DEMO_SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"CROSSFIRE_SESSION_TWO_ID=sess_stub_s2"* ]]
  [[ "$output" == *"session_identifiability: distinct"* ]]
}

@test "harness fails when process ID equals session one PID" {
  s2_copy_fixture_memory
  run bash -c "
    export HERMES_HOME='$HERMES_HOME'
    export CROSSFIRE_RUNS_DIR='$CROSSFIRE_RUNS_DIR'
    export CROSSFIRE_CANDIDATE_SKILLS_ROOT='$CROSSFIRE_CANDIDATE_SKILLS_ROOT'
    export CROSSFIRE_OPENER=stub CROSSFIRE_HERMES_DISCOVERY=0
    export CROSSFIRE_STUB_SESSION_ID=sess_stub_s2
    export CROSSFIRE_SESSION_ONE_PID=\$\$
    bash '$DEMO_SCRIPT'
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"process ID must differ"* ]]
}

@test "opener command line uses skills toolset only without resume" {
  run env HERMES_HOME="$HERMES_HOME" CROSSFIRE_LOG_CMDLINE_ONLY=1 \
    bash -c "
      source '$DEMO_COMMON'
      source '$REPO_ROOT/scripts/weakness_memory.sh'
      crossfire_build_opener_cmdline 'w-test' behavioral 'action,result' MEMORY.md
    "
  [ "$status" -eq 0 ]
  [[ "$output" == *"--toolsets skills"* ]]
  ! [[ "$output" == *"session_search"* ]]
  ! [[ "$output" == *"--resume"* ]]
}

@test "stub opener question does not name weakness_id" {
  s2_copy_fixture_memory
  run s2_run_harness bash "$DEMO_SCRIPT"
  [ "$status" -eq 0 ]
  local question_line
  question_line=$(grep '^Question:' <<<"$output" | head -1)
  ! [[ "$question_line" == *"w-b2f32d5ee0be"* ]]
  ! [[ "$output" =~ [Nn]ame.*weakness ]]
  ! [[ "$output" =~ [Ww]hich.*weakness ]]
}

@test "integration session one persist then session two targets behavioral weakness" {
  s2_run_session_one_persist
  grep -q "behavioral" "$MEMORY_MD"
  run s2_run_harness \
    env CROSSFIRE_SESSION_ONE_ID=sess_stub \
    bash "$DEMO_SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"family=behavioral"* ]]
  [[ "$output" == *"source_session_id=sess_stub"* ]]
  [[ "$output" == *"action"* ]] || [[ "$output" == *"result"* ]]
}

@test "CROSSFIRE_RUNS_DIR override preserved when exported before source" {
  local custom="${TEST_ROOT}/custom-runs-override"
  run bash -c "
    export CROSSFIRE_RUNS_DIR='$custom'
    export HERMES_HOME='$HERMES_HOME'
    source '$DEMO_COMMON'
    printf '%s' \"\$CROSSFIRE_RUNS_DIR\"
  "
  [ "$status" -eq 0 ]
  [ "$output" = "$custom" ]
}

@test "CROSSFIRE_RUNS_DIR defaults to repo .crossfire/runs when unset" {
  run bash -c "
    unset CROSSFIRE_RUNS_DIR
    export HERMES_HOME='$HERMES_HOME'
    source '$DEMO_COMMON'
    printf '%s' \"\$CROSSFIRE_RUNS_DIR\"
  "
  [ "$status" -eq 0 ]
  [[ "$output" == *"/.crossfire/runs" ]]
}

@test "CROSSFIRE_LIVE=1 with discovery disabled fails closed on session two" {
  s2_copy_fixture_memory
  run env CROSSFIRE_LIVE=1 CROSSFIRE_HERMES_DISCOVERY=0 CROSSFIRE_OPENER=live \
    HERMES_HOME="$HERMES_HOME" CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
    bash "$DEMO_SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"PREFLIGHT FAIL"* ]] || [[ "$output" == *"not discoverable"* ]]
}
