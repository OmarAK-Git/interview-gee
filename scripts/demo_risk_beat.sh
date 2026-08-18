#!/usr/bin/env bash
# Optional honesty beat: load unverified candidate after session-two opener (spec §7 step 7, §14).
set -euo pipefail

_risk_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
# shellcheck source=scripts/demo_common.sh
source "${_risk_dir}/demo_common.sh"
# shellcheck source=scripts/stage_candidate_skill.sh
source "${_risk_dir}/stage_candidate_skill.sh"
# shellcheck source=scripts/activate_candidate_skill.sh
source "${_risk_dir}/activate_candidate_skill.sh"

CROSSFIRE_RISK_BEAT_LABEL='UNVERIFIED LEARNING RISK DEMO'
CROSSFIRE_RISK_BEAT_WARNING='WARNING: The next follow-up is shaped by an auto-generated skill marked status: unverified. It was trained on a bad answer and is not promoted or validated.'

crossfire_print_risk_beat_label() {
  printf '=== %s ===\n' "$CROSSFIRE_RISK_BEAT_LABEL"
  printf '%s\n' "$CROSSFIRE_RISK_BEAT_WARNING"
}

crossfire_risk_beat_missing_csv_from_skill() {
  local skill_path="${1:-}"
  local line csv
  [ -f "$skill_path" ] || return 1
  line=$(grep -E '^missing_elements:' "$skill_path" | head -1 || true)
  csv=${line#missing_elements: }
  csv=${csv//[\[\] ]/}
  [ -n "$csv" ] || return 1
  printf '%s' "$csv"
}

crossfire_risk_beat_family_from_skill() {
  local skill_path="${1:-}"
  local line family
  [ -f "$skill_path" ] || return 1
  line=$(grep -E '^target_family:' "$skill_path" | head -1 || true)
  family=${line#target_family: }
  family=${family// /}
  [ -n "$family" ] || return 1
  printf '%s' "$family"
}

crossfire_risk_beat_followup_stub() {
  local skill_path="${1:-}"
  local family missing_csv
  family=$(crossfire_risk_beat_family_from_skill "$skill_path")
  missing_csv=$(crossfire_risk_beat_missing_csv_from_skill "$skill_path")
  crossfire_candidate_followup_sentence "$family" "$missing_csv"
}

crossfire_build_risk_beat_cmdline() {
  local skill_path="${1:-}" family="${2:-}" missing_csv="${3:-}"
  local interviewer_ref="${4:-$(crossfire_ensure_isolated_skill)}"
  local candidate_dir qtext qqtext qinterviewer qcandidate cmd=""
  candidate_dir=$(dirname "$skill_path")
  qtext=$(printf '%s' \
    "Unverified-learning risk beat follow-up. family=${family} missing_elements=[${missing_csv// /}]. Ask one corrective follow-up question that requests the recorded missing elements. Do not praise the prior bad answer." \
    | tr '\n' ' ')
  qqtext=$(printf '%q' "$qtext")
  qinterviewer=$(printf '%q' "$interviewer_ref")
  qcandidate=$(printf '%q' "$candidate_dir")
  cmd="hermes chat -Q -q ${qqtext} --max-turns 1 --toolsets skills --skills ${qinterviewer},${qcandidate} --source tool"
  printf '%s' "$cmd"
}

crossfire_risk_beat_live_followup() {
  local skill_path="${1:-}"
  local family missing_csv cmdline stdout stderr question session_id
  family=$(crossfire_risk_beat_family_from_skill "$skill_path")
  missing_csv=$(crossfire_risk_beat_missing_csv_from_skill "$skill_path")
  cmdline=$(crossfire_build_risk_beat_cmdline "$skill_path" "$family" "$missing_csv")
  stdout=$(mktemp)
  stderr=$(mktemp)
  if crossfire_hermes_invoke "$cmdline" "$stdout" "$stderr"; then
    session_id=$(crossfire_parse_session_id_from_stderr "$stderr")
    question=$(tr -d '\r' <"$stdout" | sed '/^$/d' | head -1)
    if [ -n "$question" ]; then
      CROSSFIRE_RISK_BEAT_SESSION_ID="${session_id:-sess_risk_live}"
      rm -f "$stdout" "$stderr"
      printf '%s' "$question"
      return 0
    fi
  fi
  cat "$stderr" >&2 || true
  rm -f "$stdout" "$stderr"
  return 1
}

crossfire_risk_beat_run_followup_in_new_process() {
  local skill_path="${1:-}"
  local mode="${2:-${CROSSFIRE_RISK_BEAT:-stub}}"
  local child_pid question session_id=""

  (
    if [ "$mode" = "live" ]; then
      crossfire_discover_hermes_or_fail_closed || exit 1
      question=$(crossfire_risk_beat_live_followup "$skill_path") || exit 1
      session_id="${CROSSFIRE_RISK_BEAT_SESSION_ID:-sess_risk_live}"
    else
      question=$(crossfire_risk_beat_followup_stub "$skill_path")
      session_id="${CROSSFIRE_STUB_RISK_SESSION_ID:-sess_risk_stub}"
    fi
    printf 'CROSSFIRE_RISK_BEAT_CHILD_PID=%s\n' "$$"
    printf 'CROSSFIRE_RISK_BEAT_SESSION_ID=%s\n' "$session_id"
    printf 'Follow-up: %s\n' "$question"
  ) &
  child_pid=$!
  wait "$child_pid"
}

crossfire_risk_beat_main() {
  local run_id="${CROSSFIRE_RUN_ID:-}"
  local family="${CROSSFIRE_OPENER_FAMILY:-behavioral}"
  local mode="${CROSSFIRE_RISK_BEAT:-stub}"
  local live_path=""

  crossfire_require_isolated_hermes_home
  crossfire_require_opener_complete "$run_id"

  if [ "$mode" = "live" ]; then
    crossfire_discover_hermes_or_fail_closed || fail_closed "live risk beat requires Hermes binary"
  fi

  crossfire_print_risk_beat_label

  live_path=$(crossfire_activate_candidate_skill "$run_id" "$family")
  printf 'candidate_live_path=%s\n' "$live_path"
  grep -E '^(id|name|status|weakness_id|source_session_id|answer_ref|observation_count|target_family|missing_elements):' \
    "$live_path" || true

  printf 'skill_loading_timing: %s — starting new process for candidate load (documented-fallback)\n' \
    "$SKILL_LOADING_TIMING"
  printf 'CROSSFIRE_RISK_BEAT_PID=%s\n' "$$"

  crossfire_risk_beat_run_followup_in_new_process "$live_path" "$mode"
}

if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  crossfire_risk_beat_main "$@"
  exit $?
fi
