#!/usr/bin/env bash
# Practice entry: source crossfire_lib (no landmine), allowlist exactly
# canonical WSL $HOME/.hermes. Always refuse Windows %USERPROFILE%\.hermes.
set -euo pipefail

_practice_common_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
# shellcheck source=scripts/crossfire_lib.sh
source "${_practice_common_dir}/crossfire_lib.sh"

crossfire_is_windows_hermes_path() {
  local path
  path=$(normalize_path "${1:-}")
  [ -n "$path" ] || return 1
  case "$path" in
    /mnt/[a-zA-Z]/Users/*/.hermes | /mnt/[a-zA-Z]/Users/*/.hermes/* | /mnt/[a-zA-Z]/Users/*/.hermes)
      return 0
      ;;
    [A-Za-z]:*)
      return 0
      ;;
  esac
  if [ -n "${REAL_HERMES_WIN:-}" ]; then
    if [ "$path" = "$(normalize_path "$REAL_HERMES_WIN")" ]; then
      return 0
    fi
    case "$path" in
      "$(normalize_path "$REAL_HERMES_WIN")"/*) return 0 ;;
    esac
  fi
  return 1
}

crossfire_monday_allowed_path() {
  local home_dir monday
  home_dir="${HOME:-/home/${WSL_USER:-fish}}"
  if crossfire_is_windows_hermes_path "${home_dir}/.hermes"; then
    printf ''
    return 1
  fi
  case "$(normalize_path "$home_dir")" in
    /mnt/[a-zA-Z]/Users/* | [A-Za-z]:*)
      printf ''
      return 1
      ;;
  esac
  monday="${home_dir}/.hermes"
  if command -v realpath >/dev/null 2>&1; then
    realpath -m "$monday" 2>/dev/null || printf '%s' "$monday"
  else
    printf '%s' "$monday"
  fi
}

crossfire_resolve_existing() {
  local path="${1:-}"
  if [ -e "$path" ] && command -v realpath >/dev/null 2>&1; then
    realpath "$path"
  elif command -v realpath >/dev/null 2>&1; then
    realpath -m "$path" 2>/dev/null || normalize_path "$path"
  else
    normalize_path "$path"
  fi
}

crossfire_require_monday_home() {
  local allowed resolved
  allowed=$(crossfire_monday_allowed_path) || allowed=""
  [ -n "$allowed" ] || fail_closed "practice Monday path is not a WSL \$HOME/.hermes (HOME=${HOME:-unset})"

  if [ -z "${HERMES_HOME:-}" ]; then
    HERMES_HOME="$allowed"
  fi
  resolved=$(crossfire_resolve_existing "$HERMES_HOME")
  resolved=$(normalize_path "$resolved")
  allowed=$(normalize_path "$allowed")

  if crossfire_is_windows_hermes_path "$resolved" || crossfire_is_windows_hermes_path "$HERMES_HOME"; then
    fail_closed "practice refuses Windows Hermes home: ${HERMES_HOME}"
  fi
  if [ "$resolved" != "$allowed" ]; then
    fail_closed "practice HERMES_HOME must be WSL \$HOME/.hermes (${allowed}); got ${resolved}"
  fi
  export HERMES_HOME
  crossfire_apply_hermes_derived_paths
}

crossfire_extract_spoken_question() {
  local raw="${1:-}" line=""
  line=$(printf '%s\n' "$raw" | tr -d '\r' | grep -E '[^[:space:]].*\?' | grep -viE 'reasoning|weakness_id' | tail -1 | sed 's/^[[:space:]]*//' || true)
  printf '%s' "$line"
}

crossfire_practice_resolve_inference() {
  local v
  v=$(printf '%s' "${CROSSFIRE_INFERENCE:-nous}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
  case "$v" in
    "" | nous) printf '%s' "nous" ;;
    codex | openai-codex) printf '%s' "codex" ;;
    *) fail_closed "CROSSFIRE_INFERENCE must be nous or codex (got ${CROSSFIRE_INFERENCE:-})" ;;
  esac
}

crossfire_practice_inference_flags() {
  local kind provider model
  kind=$(crossfire_practice_resolve_inference)
  case "$kind" in
    nous)
      provider="nous"
      model="${CROSSFIRE_NOUS_MODEL:-stepfun/step-3.7-flash:free}"
      ;;
    *)
      provider="openai-codex"
      model="${CROSSFIRE_CODEX_MODEL:-gpt-5.4}"
      ;;
  esac
  printf -- '--provider %s --model %s' "$provider" "$model"
}

crossfire_practice_inject_inference() {
  local cmd="${1:-}" flags
  flags=$(crossfire_practice_inference_flags)
  printf '%s' "${cmd/hermes chat/hermes chat ${flags}}"
}

# Practice never inherits demo K=3 persist retry.
CROSSFIRE_LIVE_ASSESSOR_RETRIES=1
export CROSSFIRE_LIVE_ASSESSOR_RETRIES
