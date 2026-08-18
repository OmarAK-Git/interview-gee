#!/usr/bin/env bash
# Session-two memory-only opener harness (spec §9 selection, §13 opener).
set -euo pipefail

_session_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
# shellcheck source=scripts/demo_common.sh
source "${_session_dir}/demo_common.sh"
# shellcheck source=scripts/weakness_memory.sh
source "${_session_dir}/weakness_memory.sh"
# shellcheck source=scripts/stage_candidate_skill.sh
source "${_session_dir}/stage_candidate_skill.sh"

crossfire_session_two_check_barrier_flag() {
  local run_id="${1:-${CROSSFIRE_RUN_ID:-}}"
  local flag=""
  [ -n "$run_id" ] || return 0
  flag="${CROSSFIRE_RUNS_DIR}/${run_id}/candidate-excluded.flag"
  if [ -f "$flag" ]; then
    printf 'CROSSFIRE: candidate-excluded.flag present for run %s\n' "$run_id"
  fi
}

crossfire_live_opener_once() {
  local weakness_id="${1:-}" family="${2:-}" missing_csv="${3:-}"
  local opening_target_source="${4:-MEMORY.md}"
  local skill_ref stdout stderr session_id cmdline question
  local -a skill_candidates=()

  skill_candidates+=("$CROSSFIRE_SKILL_PATH")
  skill_candidates+=("$(crossfire_ensure_isolated_skill)")

  stdout=$(mktemp)
  stderr=$(mktemp)

  for skill_ref in "${skill_candidates[@]}"; do
    cmdline=$(crossfire_build_opener_cmdline \
      "$weakness_id" "$family" "$missing_csv" "$opening_target_source" "$skill_ref")
    if crossfire_hermes_invoke "$cmdline" "$stdout" "$stderr"; then
      session_id=$(crossfire_parse_session_id_from_stderr "$stderr")
      question=$(tr -d '\r' <"$stdout" | sed '/^$/d' | head -1)
      if [ -n "$question" ]; then
        CROSSFIRE_LIVE_OPENER_SESSION_ID="${session_id:-sess_live_s2}"
        rm -f "$stdout" "$stderr"
        printf '%s' "$question"
        return 0
      fi
    fi
  done

  cat "$stderr" >&2 || true
  rm -f "$stdout" "$stderr"
  return 1
}

crossfire_session_two_ask_opener() {
  local mode="${CROSSFIRE_OPENER:-stub}"
  local question="" session_id=""

  case "$mode" in
    stub)
      question=$(crossfire_stub_opener_question \
        "$CROSSFIRE_OPENER_FAMILY" "$CROSSFIRE_OPENER_MISSING_CSV")
      session_id="${CROSSFIRE_STUB_SESSION_ID:-sess_stub_s2}"
      ;;
    live)
      crossfire_discover_hermes_or_fail_closed || fail_closed "live opener requires Hermes binary"
      question=$(crossfire_live_opener_once \
        "$CROSSFIRE_OPENER_WEAKNESS_ID" \
        "$CROSSFIRE_OPENER_FAMILY" \
        "$CROSSFIRE_OPENER_MISSING_CSV" \
        "$CROSSFIRE_OPENER_TARGET_SOURCE") || fail_closed "live opener failed"
      session_id="${CROSSFIRE_LIVE_OPENER_SESSION_ID:-sess_live_s2}"
      ;;
    *)
      fail_closed "unknown CROSSFIRE_OPENER mode: $mode"
      ;;
  esac

  printf 'CROSSFIRE_SESSION_TWO_PID=%s\n' "$$"
  printf 'CROSSFIRE_SESSION_TWO_ID=%s\n' "$session_id"
  printf 'Question: %s\n\n' "$question"
  crossfire_assert_distinct_process_and_session "$$" "$session_id"
}

crossfire_session_two_main() {
  crossfire_require_isolated_hermes_home

  if [ "${CROSSFIRE_LIVE:-0}" = "1" ]; then
    export CROSSFIRE_OPENER=live
    crossfire_discover_hermes_or_fail_closed
  elif [ "${CROSSFIRE_OPENER:-stub}" = "live" ]; then
    crossfire_discover_hermes_or_fail_closed || \
      fail_closed "live opener selected but Hermes binary not discoverable"
  fi

  crossfire_session_two_check_barrier_flag
  crossfire_assert_candidates_excluded_from_live

  crossfire_print_opener_attribution
  crossfire_session_two_ask_opener
}

if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  crossfire_session_two_main "$@"
  exit $?
fi
