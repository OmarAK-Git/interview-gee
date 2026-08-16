#!/usr/bin/env bash
# Isolation contract (Task 1b): every harness script and test must source this
# file (or scripts/start-wsl-isolated.sh) before writing under HERMES_HOME.
# Call crossfire_require_isolated_hermes_home before any write; sourcing
# fail-closed when HERMES_HOME points at a real profile.
# Product scripts never mkdir REAL_HERMES_WIN or REAL_HERMES_WSL; the only
# mkdir is under disposable HERMES_HOME in crossfire_harness_write_probe.
# tests/isolation.bats snapshots absence of real homes in-process and fails
# if a previously absent REAL_HERMES_* path appears.
set -euo pipefail

demo_common_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$demo_common_dir/.." && pwd)

WSL_DISTRO="${WSL_DISTRO:-Ubuntu}"
WSL_USER="${WSL_USER:-fish}"

crossfire_resolve_real_hermes_paths() {
  REAL_HERMES_WSL="${REAL_HERMES_WSL:-/home/${WSL_USER}/.hermes}"
  if [ -n "${USERPROFILE:-}" ]; then
    REAL_HERMES_WIN="${USERPROFILE}/.hermes"
  elif [ -r /proc/version ] && grep -qi microsoft /proc/version; then
    win_cmd="cmd.exe"
    if ! command -v "$win_cmd" >/dev/null 2>&1; then
      win_cmd="/mnt/c/Windows/System32/cmd.exe"
    fi
    if [ -x "$win_cmd" ] || command -v cmd.exe >/dev/null 2>&1; then
      win_profile=$("$win_cmd" /c "echo %USERPROFILE%" 2>/dev/null | tr -d '\r' || true)
    else
      win_profile=""
    fi
    if [ -n "$win_profile" ]; then
      REAL_HERMES_WIN=$(wslpath -u "$win_profile" 2>/dev/null || printf '%s' "$win_profile")
      REAL_HERMES_WIN="${REAL_HERMES_WIN}/.hermes"
    else
      REAL_HERMES_WIN=""
    fi
  elif [ -n "${HOME:-}" ]; then
    REAL_HERMES_WIN="${HOME}/.hermes"
  else
    REAL_HERMES_WIN=""
  fi
}

crossfire_resolve_real_hermes_paths

if [ "${CROSSFIRE_PATHS_ONLY:-}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi

HERMES_HOME="${HERMES_HOME:-${REPO_ROOT}/.crossfire/profiles/test}"
HERMES_MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"
HERMES_SKILLS_DIR="${HERMES_HOME}/skills"
HERMES_STATE_DB="${HERMES_HOME}/state.db"
HERMES_CONFIG="${HERMES_HOME}/config.yaml"

CURATOR_STRATEGY="isolated"
MEMORY_WRITER="agent-direct"
PERSISTENCE_BRANCH="probe-pending"
PERSISTENCE_BRANCH_FIRST_ATTEMPT="memory-md-block"
SKILL_LOADING_TIMING="startup-only"
SESSION_SEARCH_OBSERVABILITY="documented-fallback"

HERMES_BIN="${HERMES_BIN:-}"
HERMES_VERSION="${HERMES_VERSION:-}"

fail_closed() {
  echo "PREFLIGHT FAIL: $*" >&2
  exit 1
}

normalize_path() {
  printf '%s' "${1:-}" | tr '\\' '/'
}

is_real_hermes_home() {
  local path="${1:-}"
  local real_wsl real_win
  path=$(normalize_path "$path")
  [ -n "$path" ] || return 1
  real_wsl=$(normalize_path "$REAL_HERMES_WSL")
  real_win=$(normalize_path "$REAL_HERMES_WIN")
  if [ -n "$real_wsl" ] && [ "$path" = "$real_wsl" ]; then
    return 0
  fi
  if [ -n "$real_win" ] && [ "$path" = "$real_win" ]; then
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

wsl_runner() {
  if command -v wsl.exe >/dev/null 2>&1; then
    printf '%s\n' "wsl.exe"
    return 0
  fi
  if command -v wsl >/dev/null 2>&1; then
    printf '%s\n' "wsl"
    return 0
  fi
  return 1
}

discover_hermes_bin() {
  local candidate=""
  local runner=""
  local qcandidate=""

  if [ "${CROSSFIRE_HERMES_DISCOVERY:-1}" = "0" ]; then
    return 1
  fi

  if command -v hermes >/dev/null 2>&1; then
    candidate=$(command -v hermes)
    candidate=$(normalize_path "$candidate")
    if [ -x "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    return 1
  fi

  runner=$(wsl_runner) || return 1
  candidate=$("$runner" -e bash -c 'command -v hermes' 2>/dev/null || true)
  candidate=${candidate//$'\r'/}
  candidate=${candidate%%$'\n'*}
  candidate=$(normalize_path "$candidate")
  if [[ "$candidate" != /* ]]; then
    return 1
  fi
  qcandidate=$(printf '%q' "$candidate")
  if ! "$runner" -e bash -c "test -x ${qcandidate}" 2>/dev/null; then
    return 1
  fi
  printf '%s\n' "$candidate"
  return 0
}

discover_hermes_version() {
  local bin="${1:-}"
  local version=""
  local runner=""
  local qbin=""

  [ -n "$bin" ] || return 1
  bin=$(normalize_path "$bin")

  if [[ "$bin" == /* ]] && ! command -v hermes >/dev/null 2>&1; then
    runner=$(wsl_runner) || return 1
    qbin=$(printf '%q' "$bin")
    version=$("$runner" -e bash -c "${qbin} --version" 2>/dev/null) || return 1
  else
    if [ ! -x "$bin" ]; then
      return 1
    fi
    version=$("$bin" --version 2>/dev/null) || return 1
  fi

  version=${version//$'\r'/}
  version=${version%%$'\n'*}
  [ -n "$version" ] || return 1
  printf '%s\n' "$version"
}

preflight_check_paths() {
  [ -n "$HERMES_HOME" ] || fail_closed "HERMES_HOME unset"
  [ -n "$HERMES_MEMORY_MD" ] || fail_closed "HERMES_MEMORY_MD unset"
  [ -n "$HERMES_SKILLS_DIR" ] || fail_closed "HERMES_SKILLS_DIR unset"
  if is_real_hermes_home "$HERMES_HOME"; then
    fail_closed "HERMES_HOME points at real profile: $HERMES_HOME"
  fi
  if is_real_hermes_home "$(dirname "$HERMES_MEMORY_MD")"; then
    fail_closed "HERMES_MEMORY_MD points at real profile tree"
  fi
  if is_real_hermes_home "$HERMES_SKILLS_DIR"; then
    fail_closed "HERMES_SKILLS_DIR points at real profile tree"
  fi
}

preflight_check_session_identifiability() {
  if [ -z "${HERMES_BIN:-}" ]; then
    echo "session_identifiability: fail-closed (no Hermes binary; cannot verify distinct session/process IDs)"
    return 1
  fi
  if is_real_hermes_home "$(dirname "$HERMES_STATE_DB")"; then
    fail_closed "HERMES_STATE_DB would live under real profile"
  fi
  echo "session_identifiability: could_use state_db=${HERMES_STATE_DB} (unsupported until throwaway probe)"
  return 0
}

preflight_skill_loading_timing_note() {
  echo "skill_loading_timing: ${SKILL_LOADING_TIMING} (public-doc: memory injection startup-frozen; live reload not measured — documented-fallback: start new process)"
}

preflight_learning_loop_note() {
  echo "learning_loop_latency: documented-fallback (not measured; spec: pre-persist before timed run)"
}

crossfire_apply_isolation_env() {
  export HERMES_HOME="${HERMES_HOME:-${REPO_ROOT}/.crossfire/profiles/test}"
  export HERMES_MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"
  export HERMES_SKILLS_DIR="${HERMES_HOME}/skills"
  export HERMES_STATE_DB="${HERMES_HOME}/state.db"
  export HERMES_CONFIG="${HERMES_HOME}/config.yaml"
}

crossfire_require_isolated_hermes_home() {
  crossfire_apply_isolation_env
  preflight_check_paths
}

crossfire_harness_write_probe() {
  crossfire_require_isolated_hermes_home
  local probe="${HERMES_HOME}/.crossfire-harness-probe"
  mkdir -p "$(dirname "$probe")"
  printf 'crossfire-isolation-probe\n' >"$probe"
}

if is_real_hermes_home "${HERMES_HOME}"; then
  fail_closed "HERMES_HOME points at real profile: $HERMES_HOME"
fi

CROSSFIRE_RUNS_DIR="${REPO_ROOT}/.crossfire/runs"
CROSSFIRE_DEMO_ANSWERS="${REPO_ROOT}/tests/fixtures/demo-answers.txt"
CROSSFIRE_SKILL_PATH="${REPO_ROOT}/skills/crossfire-interviewer"
CROSSFIRE_LIVE_ASSESSOR_RETRIES="${CROSSFIRE_LIVE_ASSESSOR_RETRIES:-3}"

crossfire_allocate_run_id() {
  local stamp rand
  stamp=$(date -u +%Y%m%d_%H%M%S 2>/dev/null || date -u +%Y%m%d_%H%M%S)
  if [ -r /proc/sys/kernel/random/uuid ]; then
    rand=$(cut -c1-6 /proc/sys/kernel/random/uuid)
  else
    rand=$(printf '%06x' "$RANDOM")
  fi
  printf '%s_%s' "$stamp" "$rand"
}

crossfire_memory_md_fingerprint() {
  local file="${1:-}"
  local mtime size
  if [ ! -e "$file" ]; then
    printf 'absent:0'
    return 0
  fi
  mtime=$(stat -c '%Y' "$file" 2>/dev/null || stat -f '%m' "$file")
  size=$(wc -c <"$file" | tr -d ' ')
  printf '%s:%s' "$mtime" "$size"
}

crossfire_demo_question_entry() {
  local index="${1:-0}"
  case "$index" in
    0) printf '%s' 'q_technical_01|technical|Walk through how Praetor decides not to contain. What is the advisory boundary, and how would you know the decision was wrong?' ;;
    1) printf '%s' 'q_behavioral_01|behavioral|Tell me about a time a detection you owned was wrong. What did you do, and what changed afterward?' ;;
    2) printf '%s' 'q_product_01|product|For Mastercard Agent Suite (R-281517), how would you sequence rollout when a false positive could freeze a merchant?' ;;
    *) return 1 ;;
  esac
}

crossfire_read_demo_answers() {
  local fixture="${1:-${CROSSFIRE_DEMO_ANSWERS}}"
  local -n _out="${2:-crossfire_demo_answers_arr}"
  local line current_id="" current_buf=""
  _out=()
  [ -f "$fixture" ] || fail_closed "demo answers fixture missing: $fixture"
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '# q_technical_01'* )
        [ -z "$current_id" ] || _out+=("$current_buf")
        current_id=q_technical_01
        current_buf=""
        ;;
      '# q_behavioral_01'* )
        [ -z "$current_id" ] || _out+=("$current_buf")
        current_id=q_behavioral_01
        current_buf=""
        ;;
      '# q_product_01'* )
        [ -z "$current_id" ] || _out+=("$current_buf")
        current_id=q_product_01
        current_buf=""
        ;;
      '')
        if [ -n "$current_buf" ]; then
          current_buf="${current_buf}"$'\n'
        fi
        ;;
      *)
        if [ -z "$current_buf" ]; then
          current_buf="$line"
        else
          current_buf="${current_buf}"$'\n'"${line}"
        fi
        ;;
    esac
  done <"$fixture"
  if [ -n "$current_id" ]; then
    _out+=("$current_buf")
  fi
  if [ "${#_out[@]}" -ne 3 ]; then
    fail_closed "demo answers fixture must contain exactly three answers (got ${#_out[@]})"
  fi
}

crossfire_ensure_isolated_skill() {
  local dest="${HERMES_SKILLS_DIR}/crossfire-interviewer"
  if [ -d "$dest" ] && [ -f "${dest}/SKILL.md" ]; then
    printf '%s\n' "$dest"
    return 0
  fi
  mkdir -p "$dest"
  cp "${CROSSFIRE_SKILL_PATH}/SKILL.md" "${dest}/SKILL.md"
  printf '%s\n' "$dest"
}

crossfire_hermes_home_wsl_path() {
  local home="${1:-$HERMES_HOME}"
  local drive rest
  home=$(normalize_path "$home")
  [ -n "$home" ] || return 1
  case "$home" in
    /mnt/*)
      printf '%s' "$home"
      ;;
    [A-Za-z]:*)
      drive=$(printf '%s' "$home" | cut -c1 | tr '[:upper:]' '[:lower:]')
      rest=$(printf '%s' "$home" | cut -c3-)
      printf '/mnt/%s%s' "$drive" "$rest"
      ;;
    *)
      if command -v wslpath >/dev/null 2>&1; then
        wslpath -u "$home" 2>/dev/null || printf '%s' "$home"
      else
        printf '%s' "$home"
      fi
      ;;
  esac
}

crossfire_build_assessor_cmdline() {
  local qid="${1:-}" family="${2:-}" question="${3:-}" answer="${4:-}"
  local skill_ref="${5:-${CROSSFIRE_SKILL_PATH}}"
  local resume_flag="${6:-}"
  local qtext qqtext qskill qresume cmd=""
  qtext=$(printf '%s' "Assess this interview Q+A; emit propose-only YAML per crossfire-interviewer skill. question_id=${qid} family=${family} question=${question} answer=${answer}" | tr '\n' ' ')
  qqtext=$(printf '%q' "$qtext")
  qskill=$(printf '%q' "$skill_ref")
  cmd="hermes chat -Q -q ${qqtext} --max-turns 1 --toolsets skills --skills ${qskill} --source tool"
  if [ -n "$resume_flag" ]; then
    qresume=$(printf '%q' "$resume_flag")
    cmd="${cmd} --resume ${qresume}"
  fi
  printf '%s' "$cmd"
}

crossfire_hermes_invoke() {
  local cmdline="${1:-}"
  local stdout_file="${2:-}" stderr_file="${3:-}"
  local runner="" qhome="" qcmd=""
  [ -n "$cmdline" ] || return 1

  export CROSSFIRE_HERMES_CMDLINE="$cmdline"

  if [ "${CROSSFIRE_LOG_CMDLINE_ONLY:-0}" = "1" ]; then
    printf '%s\n' "$cmdline"
    return 0
  fi

  if command -v hermes >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    eval "$cmdline" >"${stdout_file:-/dev/stdout}" 2>"${stderr_file:-/dev/stderr}"
    return $?
  fi

  runner=$(wsl_runner) || return 1
  qhome=$(printf '%q' "$(crossfire_hermes_home_wsl_path "$HERMES_HOME")")
  qcmd=$(printf '%q' "$cmdline")
  "$runner" -e bash -lc "export HOME=/home/${WSL_USER} PATH=/home/${WSL_USER}/.local/bin:\$PATH HERMES_HOME=${qhome}; ${qcmd}" \
    >"${stdout_file:-/dev/stdout}" 2>"${stderr_file:-/dev/stderr}"
}

crossfire_discover_hermes_or_fail_closed() {
  local bin=""
  if [ "${CROSSFIRE_HERMES_DISCOVERY:-1}" = "0" ]; then
    if [ "${CROSSFIRE_LIVE:-0}" = "1" ]; then
      fail_closed "CROSSFIRE_LIVE=1 but Hermes binary not discoverable (CROSSFIRE_HERMES_DISCOVERY=0)"
    fi
    return 1
  fi
  bin=$(discover_hermes_bin) || {
    if [ "${CROSSFIRE_LIVE:-0}" = "1" ]; then
      fail_closed "CROSSFIRE_LIVE=1 but Hermes binary not discoverable"
    fi
    return 1
  }
  HERMES_BIN="$bin"
  export HERMES_BIN
  return 0
}

crossfire_parse_session_id_from_stderr() {
  local file="${1:-}"
  grep -E '^session_id:' "$file" 2>/dev/null | head -1 | sed -E 's/^session_id:[[:space:]]*//'
}

crossfire_spool_should_persist() {
  local spool_file="${1:-}"
  local persist_line missing_line missing_csv count
  [ -f "$spool_file" ] || return 1
  persist_line=$(grep -E '^persist_recommended:' "$spool_file" | head -1 || true)
  if [[ "$persist_line" == *'true'* ]]; then
    return 0
  fi
  missing_line=$(grep -E '^missing_elements:' "$spool_file" | head -1 || true)
  missing_csv=${missing_line#missing_elements: }
  missing_csv=${missing_csv//[\[\] ]/}
  if [ -z "$missing_csv" ]; then
    return 1
  fi
  count=$(printf '%s' "$missing_csv" | awk -F, '{print NF}')
  [ "$count" -ge 2 ]
}

crossfire_spool_field() {
  local file="${1:-}" field="${2:-}"
  grep -E "^${field}:" "$file" 2>/dev/null | head -1 | sed -E "s/^${field}:[[:space:]]*//"
}
