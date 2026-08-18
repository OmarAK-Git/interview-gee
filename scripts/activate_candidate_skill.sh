#!/usr/bin/env bash
# Activate staged candidate skill to namespaced live path (spec §14, after opener only).
set -euo pipefail

_activate_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
# shellcheck source=scripts/demo_common.sh
source "${_activate_dir}/demo_common.sh"
# shellcheck source=scripts/stage_candidate_skill.sh
source "${_activate_dir}/stage_candidate_skill.sh"

crossfire_opener_complete_flag_path() {
  local run_id="${1:-}"
  [ -n "$run_id" ] || return 1
  printf '%s/%s/opener-complete.flag' "$CROSSFIRE_RUNS_DIR" "$run_id"
}

crossfire_mark_opener_complete() {
  local run_id="${1:-}"
  local flag_dir flag_file

  [ -n "$run_id" ] || fail_closed "run_id required to mark opener complete"
  crossfire_require_isolated_hermes_home
  flag_dir="${CROSSFIRE_RUNS_DIR}/${run_id}"
  mkdir -p "$flag_dir"
  flag_file=$(crossfire_opener_complete_flag_path "$run_id")
  : >"$flag_file"
  printf '%s\n' "$flag_file"
}

crossfire_require_opener_complete() {
  local run_id="${1:-${CROSSFIRE_RUN_ID:-}}"
  local flag=""

  if [ "${CROSSFIRE_OPENER_COMPLETE:-}" = "1" ]; then
    return 0
  fi

  [ -n "$run_id" ] || fail_closed "candidate activation blocked: session-two opener not complete (no run_id)"

  flag=$(crossfire_opener_complete_flag_path "$run_id")
  if [ -f "$flag" ]; then
    return 0
  fi

  fail_closed "candidate activation blocked: session-two opener not complete"
}

crossfire_resolve_staged_candidate_skill() {
  local run_id="${1:-}" family="${2:-}"
  local staged=""

  if [ -n "$family" ]; then
    staged=$(crossfire_candidate_skill_path "$family" 2>/dev/null || true)
    if [ -n "$staged" ] && [ -f "$staged" ]; then
      printf '%s' "$staged"
      return 0
    fi
  fi

  if [ -n "$run_id" ]; then
    staged=$(crossfire_resolve_run_candidate_skill "$run_id" 2>/dev/null || true)
    if [ -n "$staged" ] && [ -f "$staged" ]; then
      printf '%s' "$staged"
      return 0
    fi
  fi

  fail_closed "staged candidate skill not found for run_id=${run_id} family=${family}"
}

crossfire_candidate_live_skill_path() {
  local family="${1:-}"
  local dir=""

  dir=$(crossfire_candidate_skill_dir_name "$family") || return 1
  printf '%s/%s/SKILL.md' "$HERMES_SKILLS_DIR" "$dir"
}

crossfire_activate_candidate_skill() {
  local run_id="${1:-${CROSSFIRE_RUN_ID:-}}"
  local family="${2:-${CROSSFIRE_OPENER_FAMILY:-}}"
  local staged live_path live_dir tmp

  crossfire_require_isolated_hermes_home
  crossfire_require_opener_complete "$run_id"

  [ -n "$family" ] || fail_closed "target_family required for candidate activation"

  staged=$(crossfire_resolve_staged_candidate_skill "$run_id" "$family")
  live_path=$(crossfire_candidate_live_skill_path "$family")
  live_dir=$(dirname "$live_path")

  case "$live_dir" in
    "${HERMES_SKILLS_DIR}/crossfire-interviewer" | "${HERMES_SKILLS_DIR}/crossfire-interviewer"/*)
      fail_closed "refusing to replace crossfire-interviewer with candidate skill"
      ;;
  esac

  mkdir -p "$live_dir"
  tmp=$(mktemp "${live_path}.XXXXXX")
  cp -f "$staged" "$tmp"
  mv -f "$tmp" "$live_path"

  grep -q '^status: unverified' "$live_path" || \
    fail_closed "activated candidate missing status: unverified"
  grep -qE '^name: unverified-' "$live_path" || \
    fail_closed "activated candidate missing unverified name prefix"

  if [ ! -f "${HERMES_SKILLS_DIR}/crossfire-interviewer/SKILL.md" ]; then
    crossfire_ensure_isolated_skill >/dev/null
  fi

  printf '%s\n' "$live_path"
}

if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  crossfire_activate_candidate_skill "$@"
  exit $?
fi
