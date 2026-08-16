#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  DEMO_SCRIPT="$REPO_ROOT/scripts/demo_session_1.sh"
  DEMO_COMMON="$REPO_ROOT/scripts/demo_common.sh"
  ANSWERS_TXT="$REPO_ROOT/tests/fixtures/demo-answers.txt"
  TEST_ROOT="$(mktemp -d "${BATS_TMPDIR:-/tmp}/crossfire-s1.XXXXXX")"
  export HERMES_HOME="${TEST_ROOT}/.crossfire/profiles/test"
  mkdir -p "${HERMES_HOME}/memories"
  export CROSSFIRE_ASSESSOR=stub
  export CROSSFIRE_HERMES_DISCOVERY=0
  # shellcheck disable=SC1091
  source "$DEMO_COMMON"
  crossfire_require_isolated_hermes_home
}

teardown() {
  rm -rf "$TEST_ROOT"
}

demo_memory_fp() {
  crossfire_memory_md_fingerprint "$HERMES_MEMORY_MD"
}

demo_run_harness() {
  env HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_ASSESSOR=stub CROSSFIRE_HERMES_DISCOVERY=0 \
    bash "$DEMO_SCRIPT"
}

demo_run_defer_finalize() {
  env HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_ASSESSOR=stub CROSSFIRE_HERMES_DISCOVERY=0 \
    CROSSFIRE_DEFER_FINALIZE=1 \
    bash "$DEMO_SCRIPT"
}

demo_finalize_run() {
  local run_id="$1"
  env HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_ASSESSOR=stub CROSSFIRE_HERMES_DISCOVERY=0 \
    CROSSFIRE_FINALIZE_RUN_ID="$run_id" \
    bash "$DEMO_SCRIPT"
}

@test "demo_session_1 sources demo_common and fails closed on real HERMES_HOME" {
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

@test "HERMES_HOME stays under .crossfire/profiles during harness run" {
  [[ "$HERMES_HOME" == *".crossfire/profiles/"* ]]
  demo_run_harness
  [[ "$HERMES_HOME" == *".crossfire/profiles/"* ]]
}

@test "harness never mkdir or write REAL_HERMES paths" {
  CROSSFIRE_PATHS_ONLY=1 source "$DEMO_COMMON"
  win_was_absent=0
  wsl_was_absent=0
  if [ -n "${REAL_HERMES_WIN:-}" ] && [ ! -e "$REAL_HERMES_WIN" ]; then win_was_absent=1; fi
  if [ ! -e "$REAL_HERMES_WSL" ]; then wsl_was_absent=1; fi
  demo_run_harness
  if [ "$win_was_absent" -eq 1 ] && [ -n "${REAL_HERMES_WIN:-}" ] && [ -e "$REAL_HERMES_WIN" ]; then
    echo "created REAL_HERMES_WIN: $REAL_HERMES_WIN" >&2
    return 1
  fi
  if [ "$wsl_was_absent" -eq 1 ] && [ -e "$REAL_HERMES_WSL" ]; then
    echo "created REAL_HERMES_WSL: $REAL_HERMES_WSL" >&2
    return 1
  fi
}

@test "demo-answers.txt exists with exactly three answers" {
  [ -f "$ANSWERS_TXT" ]
  local count
  count=$(grep -c '^# q_' "$ANSWERS_TXT" || true)
  [ "$count" -eq 3 ]
}

@test "harness prints three spec section 11 questions in order" {
  run demo_run_harness
  [ "$status" -eq 0 ]
  [[ "$output" == *"q_technical_01"* ]]
  [[ "$output" == *"Praetor decides not to contain"* ]]
  local pos1 pos2 pos3
  pos1=$(grep -n 'q_technical_01' <<<"$output" | head -1 | cut -d: -f1)
  pos2=$(grep -n 'q_behavioral_01' <<<"$output" | head -1 | cut -d: -f1)
  pos3=$(grep -n 'q_product_01' <<<"$output" | head -1 | cut -d: -f1)
  [ "$pos1" -lt "$pos2" ]
  [ "$pos2" -lt "$pos3" ]
}

@test "harness reads answers from demo-answers.txt not operator input" {
  run demo_run_harness
  [ "$status" -eq 0 ]
  [[ "$output" == *"never-contain"* ]] || [[ "$output" == *"hash-chained"* ]]
  [[ "$output" == *"I just kind of watched the dashboard"* ]]
  [[ "$output" == *"false-freeze rate"* ]]
}

@test "each assessment lands in spool before finalize" {
  run demo_run_defer_finalize
  [ "$status" -eq 0 ]
  local run_id spool_dir
  run_id=$(grep '^CROSSFIRE_RUN_ID=' <<<"$output" | tail -1 | cut -d= -f2)
  [ -n "$run_id" ]
  spool_dir="${REPO_ROOT}/.crossfire/runs/${run_id}/spool"
  [ -d "$spool_dir" ]
  [ -f "${spool_dir}/q_technical_01.yaml" ]
  [ -f "${spool_dir}/q_behavioral_01.yaml" ]
  [ -f "${spool_dir}/q_product_01.yaml" ]
}

@test "MEMORY.md fingerprint unchanged until finalize" {
  local fp_before fp_mid fp_after run_id
  fp_before=$(demo_memory_fp)
  run demo_run_defer_finalize
  [ "$status" -eq 0 ]
  fp_mid=$(demo_memory_fp)
  [ "$fp_before" = "$fp_mid" ]
  run_id=$(grep '^CROSSFIRE_RUN_ID=' <<<"$output" | tail -1 | cut -d= -f2)
  run demo_finalize_run "$run_id"
  [ "$status" -eq 0 ]
  fp_after=$(demo_memory_fp)
  [ -f "$HERMES_MEMORY_MD" ]
  [ "$fp_before" != "$fp_after" ]
}

@test "post-Q3 auto-finalize prints ack" {
  run demo_run_harness
  [ "$status" -eq 0 ]
  [[ "$output" == *"CROSSFIRE: session one finalized"* ]]
}

@test "/done finalize uses same function as post-Q3 auto-finalize" {
  grep -q 'crossfire_session_one_finalize' "$DEMO_SCRIPT"
  local count
  count=$(grep -c 'crossfire_session_one_finalize' "$DEMO_SCRIPT" || true)
  [ "$count" -ge 2 ]
  run demo_run_defer_finalize
  [ "$status" -eq 0 ]
  local run_id
  run_id=$(grep '^CROSSFIRE_RUN_ID=' <<<"$output" | tail -1 | cut -d= -f2)
  run demo_finalize_run "$run_id"
  [ "$status" -eq 0 ]
  [[ "$output" == *"CROSSFIRE: session one finalized"* ]]
}

@test "stub q_behavioral_01 bad answer persists on finalize" {
  demo_run_harness
  grep -q "I just kind of watched the dashboard" "$HERMES_MEMORY_MD"
  grep -q "sess_stub" "$HERMES_MEMORY_MD"
}

@test "stub strong answers do not persist" {
  demo_run_harness
  local blocks
  blocks=$(grep -c 'weakness_id:' "$HERMES_MEMORY_MD" 2>/dev/null || echo 0)
  [ "$blocks" -eq 1 ]
  grep -q "behavioral" "$HERMES_MEMORY_MD"
  ! grep -q "never-contain" "$HERMES_MEMORY_MD"
  ! grep -q "false-freeze rate" "$HERMES_MEMORY_MD"
}

@test "harness output has no persist confirmation prompt" {
  run demo_run_harness
  [ "$status" -eq 0 ]
  ! [[ "$output" =~ [Pp]lease.*confirm ]]
  ! [[ "$output" =~ [Cc]onfirm.*persist ]]
}

@test "assessor command line omits memory file and terminal toolsets" {
  run env HERMES_HOME="$HERMES_HOME" CROSSFIRE_ASSESSOR=live \
    CROSSFIRE_HERMES_DISCOVERY=0 CROSSFIRE_LOG_CMDLINE_ONLY=1 \
    bash -c "
      source '$DEMO_COMMON'
      crossfire_build_assessor_cmdline 'q_behavioral_01' behavioral 'question' 'answer'
    "
  [ "$status" -eq 0 ]
  [[ "$output" == *"--toolsets skills"* ]]
  ! [[ "$output" == *"--toolsets"*memory* ]]
  ! [[ "$output" == *"--toolsets"*file* ]]
  ! [[ "$output" == *"--toolsets"*terminal* ]]
}

@test "CROSSFIRE_LIVE=1 with discovery disabled fails closed" {
  run env CROSSFIRE_LIVE=1 CROSSFIRE_HERMES_DISCOVERY=0 HERMES_HOME="$HERMES_HOME" \
    bash "$DEMO_SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *"FAIL CLOSED"* ]] || [[ "$output" == *"not discoverable"* ]]
}

@test "live skip when Hermes missing is not documented as E2E pass" {
  grep -q 'Skip is not proof' "$REPO_ROOT/skills/crossfire-interviewer/SKILL.md"
  grep -q 'fail closed' "$REPO_ROOT/skills/crossfire-interviewer/SKILL.md"
}

@test "demo_session_1.bats uses discover_hermes_bin not direct hermes exec in tests" {
  grep -q 'discover_hermes_bin' "$BATS_TEST_FILENAME"
  local direct
  direct=$(grep -vE '^\s*#' "$BATS_TEST_FILENAME" | grep -E '(^|[;&|])[[:space:]]*hermes[[:space:]]' || true)
  [ -z "$direct" ]
}
