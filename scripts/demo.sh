#!/usr/bin/env bash
# Full ~90s demo orchestrator (spec §7). Composes session scripts; no duplicated session logic.
set -euo pipefail

_demo_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
REPO_ROOT_EARLY=$(CDPATH= cd -- "$_demo_dir/.." && pwd)

CROSSFIRE_DEMO_RECOVERY='Run: bash scripts/demo.sh --prepare  (resets the disposable profile under HERMES_HOME and retries)'

crossfire_demo_fail_early() {
  echo "DEMO FAIL: $*" >&2
  echo "Recovery: ${CROSSFIRE_DEMO_RECOVERY}" >&2
  exit 1
}

crossfire_demo_is_real_home_early() {
  local path="${1:-}"
  local wsl_user="${WSL_USER:-fish}"
  local real_wsl="/home/${wsl_user}/.hermes"
  local real_win=""
  path=$(printf '%s' "$path" | tr '\\' '/')
  [ -n "$path" ] || return 1
  if [ -n "${USERPROFILE:-}" ]; then
    real_win="${USERPROFILE}/.hermes"
  elif [ -n "${HOME:-}" ]; then
    real_win="${HOME}/.hermes"
  fi
  real_wsl=$(printf '%s' "$real_wsl" | tr '\\' '/')
  real_win=$(printf '%s' "$real_win" | tr '\\' '/')
  if [ "$path" = "$real_wsl" ] || { [ -n "$real_win" ] && [ "$path" = "$real_win" ]; }; then
    return 0
  fi
  case "$path" in
    */.hermes|*/.hermes/*)
      case "$path" in
        *"/.crossfire/profiles/"*) return 1 ;;
        *) return 0 ;;
      esac
      ;;
  esac
  return 1
}

_demo_home="${HERMES_HOME:-${REPO_ROOT_EARLY}/.crossfire/profiles/stage}"
if crossfire_demo_is_real_home_early "$_demo_home"; then
  crossfire_demo_fail_early "HERMES_HOME points at real profile: ${_demo_home}"
fi
unset _demo_home REPO_ROOT_EARLY

# shellcheck source=scripts/demo_common.sh
source "${_demo_dir}/demo_common.sh"
# shellcheck source=scripts/weakness_memory.sh
source "${_demo_dir}/weakness_memory.sh"
# shellcheck source=scripts/stage_candidate_skill.sh
source "${_demo_dir}/stage_candidate_skill.sh"
# shellcheck source=scripts/activate_candidate_skill.sh
source "${_demo_dir}/activate_candidate_skill.sh"

CROSSFIRE_DEMO_RECOVERY='Run: bash scripts/demo.sh --prepare  (resets the disposable profile under HERMES_HOME and retries)'

crossfire_demo_sanitize_path() {
  local clean="" part
  IFS=':'
  for part in $PATH; do
    case "$part" in
      *WindowsApps*) continue ;;
      *) clean="${clean:+$clean:}$part" ;;
    esac
  done
  PATH="$clean"
  export PATH
}

crossfire_demo_fail() {
  echo "DEMO FAIL: $*" >&2
  echo "Recovery: ${CROSSFIRE_DEMO_RECOVERY}" >&2
  exit 1
}

crossfire_demo_validate_disposable_profile() {
  crossfire_require_isolated_hermes_home
  case "$HERMES_HOME" in
    */.crossfire/profiles/*) ;;
    *)
      crossfire_demo_fail "demo_prepare refuses non-disposable HERMES_HOME: ${HERMES_HOME}"
      ;;
  esac
}

crossfire_demo_safe_to_wipe_tree() {
  local path="${1:-}"
  [ -n "$path" ] || return 1
  if is_real_hermes_home "$path"; then
    return 1
  fi
  case "$path" in
    */.hermes|*/.hermes/*)
      case "$path" in
        */.crossfire/profiles/*|*/.crossfire/candidate-skills*) ;;
        *) return 1 ;;
      esac
      ;;
  esac
  return 0
}

crossfire_demo_prepare() {
  local mem_fixture="${REPO_ROOT}/tests/fixtures/memory-empty.md"
  local cand_root skills_dir item

  crossfire_demo_validate_disposable_profile

  cand_root=$(crossfire_candidate_skills_root)
  if crossfire_demo_safe_to_wipe_tree "$cand_root"; then
    rm -rf "${cand_root:?}"/*
  fi

  if crossfire_demo_safe_to_wipe_tree "$CROSSFIRE_RUNS_DIR"; then
    rm -rf "${CROSSFIRE_RUNS_DIR:?}"/*
  fi

  skills_dir="${HERMES_SKILLS_DIR}"
  if [ -d "$skills_dir" ]; then
    crossfire_snapshot_live_candidates_if_any "demo_prepare" 2>/dev/null || true
    rm -rf "${skills_dir:?}"/*
  fi
  mkdir -p "${HERMES_HOME}/memories" "$skills_dir"

  if [ -f "$mem_fixture" ]; then
    cp -f "$mem_fixture" "$HERMES_MEMORY_MD"
  else
    : >"$HERMES_MEMORY_MD"
  fi

  rm -f "${HERMES_STATE_DB:-}" "${HERMES_CONFIG:-}" 2>/dev/null || true

  crossfire_ensure_isolated_skill >/dev/null
  crossfire_assert_candidates_excluded_from_live

  printf 'demo_prepare: disposable profile restored at %s\n' "$HERMES_HOME"
}

crossfire_demo_preflight() {
  preflight_check_paths
  crossfire_ensure_isolated_skill >/dev/null

  if [ "${CROSSFIRE_LIVE:-0}" = "1" ] || [ "${CROSSFIRE_ASSESSOR:-stub}" = "live" ] \
    || [ "${CROSSFIRE_OPENER:-stub}" = "live" ] || [ "${CROSSFIRE_RISK_BEAT:-stub}" = "live" ]; then
    bash "${_demo_dir}/preflight.sh"
    return $?
  fi

  if [ "${CROSSFIRE_HERMES_DISCOVERY:-1}" = "0" ]; then
    echo "preflight: pass (stub smoke; isolation verified; Hermes optional)"
    preflight_skill_loading_timing_note
    preflight_learning_loop_note
    return 0
  fi

  if crossfire_discover_hermes_or_fail_closed; then
    echo "preflight: pass (Hermes discoverable; stub assessor/opener permitted)"
    preflight_skill_loading_timing_note
    return 0
  fi

  echo "preflight: pass (stub smoke; Hermes not required for assessor=${CROSSFIRE_ASSESSOR:-stub})"
  preflight_skill_loading_timing_note
  return 0
}

crossfire_demo_print_layer_attribution() {
  printf 'layer_attribution: opening_target=MEMORY.md\n'
  printf 'layer_attribution: opener_wording=stable_interviewer_skill\n'
  printf 'layer_attribution: candidate_excluded_from_opener_selection=true\n'
  if [ "${CROSSFIRE_SKIP_RISK_BEAT:-0}" = "1" ]; then
    printf 'layer_attribution: risk_beat=skipped (time-cut policy)\n'
  else
    printf 'layer_attribution: risk_beat_shows_unverified_learning=true\n'
  fi
}

crossfire_demo_run_session_one() {
  local out_file="${1:-}"
  local assessor="${CROSSFIRE_ASSESSOR:-stub}"
  local stub_sid="${CROSSFIRE_STUB_SESSION_ID:-sess_demo_s1}"
  local rc=0

  crossfire_demo_sanitize_path
  [ -n "$out_file" ] || crossfire_demo_fail "session one output file required"

  set +e
  env HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
    CROSSFIRE_CANDIDATE_SKILLS_ROOT="${CROSSFIRE_CANDIDATE_SKILLS_ROOT:-}" \
    CROSSFIRE_ASSESSOR="$assessor" \
    CROSSFIRE_HERMES_DISCOVERY="${CROSSFIRE_HERMES_DISCOVERY:-0}" \
    CROSSFIRE_STUB_SESSION_ID="$stub_sid" \
    bash "${_demo_dir}/demo_session_1.sh" >"$out_file" 2>&1
  rc=$?
  set -e

  cat "$out_file"
  [ "$rc" -eq 0 ] || crossfire_demo_fail "session one failed (see output above)"
}

crossfire_demo_run_session_two() {
  local s1_pid="${1:-}" s1_sid="${2:-}" out_file="${3:-}"
  local opener="${CROSSFIRE_OPENER:-stub}"
  local stub_s2_sid="${CROSSFIRE_STUB_SESSION_TWO_ID:-sess_demo_s2}"
  local rc=0

  crossfire_demo_sanitize_path
  [ -n "$out_file" ] || crossfire_demo_fail "session two output file required"
  [ -n "$s1_pid" ] || crossfire_demo_fail "session one PID required for process separation"
  [ -n "$s1_sid" ] || crossfire_demo_fail "session one session ID required"

  set +e
  env HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
    CROSSFIRE_CANDIDATE_SKILLS_ROOT="${CROSSFIRE_CANDIDATE_SKILLS_ROOT:-}" \
    CROSSFIRE_OPENER="$opener" \
    CROSSFIRE_HERMES_DISCOVERY="${CROSSFIRE_HERMES_DISCOVERY:-0}" \
    CROSSFIRE_STUB_SESSION_ID="$stub_s2_sid" \
    CROSSFIRE_SESSION_ONE_PID="$s1_pid" \
    CROSSFIRE_SESSION_ONE_ID="$s1_sid" \
    bash "${_demo_dir}/demo_session_2.sh" >"$out_file" 2>&1
  rc=$?
  set -e

  cat "$out_file"
  [ "$rc" -eq 0 ] || crossfire_demo_fail "session two failed (see output above)"
}

crossfire_demo_run_risk_beat() {
  local run_id="${1:-}" family="${2:-behavioral}"
  local mode="${CROSSFIRE_RISK_BEAT:-stub}"
  local rc=0

  crossfire_demo_sanitize_path
  [ -n "$run_id" ] || crossfire_demo_fail "run_id required for risk beat"

  set +e
  env HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
    CROSSFIRE_CANDIDATE_SKILLS_ROOT="${CROSSFIRE_CANDIDATE_SKILLS_ROOT:-}" \
    CROSSFIRE_HERMES_DISCOVERY="${CROSSFIRE_HERMES_DISCOVERY:-0}" \
    CROSSFIRE_RISK_BEAT="$mode" \
    CROSSFIRE_RUN_ID="$run_id" \
    CROSSFIRE_OPENER_FAMILY="$family" \
    CROSSFIRE_OPENER_COMPLETE=1 \
    bash "${_demo_dir}/demo_risk_beat.sh"
  rc=$?
  set -e

  [ "$rc" -eq 0 ] || crossfire_demo_fail "risk beat failed"
}

crossfire_demo_assert_bad_answer_gaps() {
  local run_id="${1:-}"
  local spool_file=""

  [ -n "$run_id" ] || crossfire_demo_fail "run_id required for bad-answer check"
  spool_file="${CROSSFIRE_RUNS_DIR}/${run_id}/spool/q_behavioral_01.yaml"
  [ -f "$spool_file" ] || crossfire_demo_fail "behavioral spool missing for bad-answer check"

  if ! grep -qE 'missing_elements: \[(action, result|action,result)\]' "$spool_file"; then
    crossfire_demo_fail "scripted bad answer must be missing >=2 elements (expected action, result)"
  fi
}

crossfire_demo_main() {
  local s1_out s2_out run_id s1_pid s1_sid s2_sid family
  local -a staged_paths=()

  if [ "${1:-}" = "--prepare" ]; then
    crossfire_demo_prepare
    exit 0
  fi

  crossfire_demo_prepare
  crossfire_demo_preflight

  s1_out=""
  s2_out=""
  before_snap=""
  trap 'rm -f "${s1_out:-}" "${s2_out:-}" "${before_snap:-}"' EXIT

  s1_out=$(mktemp)
  s2_out=$(mktemp)
  before_snap=$(mktemp)

  cp -f "$HERMES_MEMORY_MD" "$before_snap"

  crossfire_demo_run_session_one "$s1_out" &
  s1_pid=$!
  if ! wait "$s1_pid"; then
    crossfire_demo_fail "session one failed (see output above)"
  fi

  run_id=$(grep '^CROSSFIRE_RUN_ID=' "$s1_out" | tail -1 | sed -E 's/^CROSSFIRE_RUN_ID=//')
  [ -n "$run_id" ] || crossfire_demo_fail "session one did not emit CROSSFIRE_RUN_ID"

  mkdir -p "${CROSSFIRE_RUNS_DIR}/${run_id}"
  cp -f "$before_snap" "$(crossfire_artifact_memory_before_path "$run_id")"

  crossfire_demo_assert_bad_answer_gaps "$run_id"

  printf 'CROSSFIRE_SESSION_ONE_PID=%s\n' "$s1_pid"
  s1_sid="${CROSSFIRE_STUB_SESSION_ID:-sess_demo_s1}"
  printf 'CROSSFIRE_SESSION_ONE_ID=%s\n' "$s1_sid"

  while IFS= read -r line; do
    [ -n "$line" ] && staged_paths+=("$line")
  done < <(crossfire_stage_candidates_for_run "$run_id" "$HERMES_MEMORY_MD")

  if [ "${#staged_paths[@]}" -eq 0 ]; then
    crossfire_demo_fail "no candidate skill staged after session one finalize"
  fi

  crossfire_assert_candidates_excluded_from_live

  crossfire_print_artifact_evidence "$run_id" "$HERMES_MEMORY_MD" \
    || crossfire_demo_fail "artifact evidence display failed"

  family=$(crossfire_select_newest_weakness "$HERMES_MEMORY_MD" 2>/dev/null | grep '^family=' | head -1 | cut -d= -f2)
  family="${family:-behavioral}"

  crossfire_demo_run_session_two "$s1_pid" "$s1_sid" "$s2_out"

  crossfire_demo_print_layer_attribution

  crossfire_mark_opener_complete "$run_id" >/dev/null

  if [ "${CROSSFIRE_SKIP_RISK_BEAT:-0}" != "1" ]; then
    crossfire_demo_run_risk_beat "$run_id" "$family"
  else
    printf 'demo: risk beat skipped (CROSSFIRE_SKIP_RISK_BEAT=1)\n'
  fi

  printf 'demo: complete run_id=%s\n' "$run_id"
}

if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  crossfire_demo_main "$@"
fi
