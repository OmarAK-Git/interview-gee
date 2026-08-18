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

CROSSFIRE_RUNS_DIR="${CROSSFIRE_RUNS_DIR:-${REPO_ROOT}/.crossfire/runs}"
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
  grep -E "^${field}:" "$file" 2>/dev/null | head -1 | sed -E "s/^${field}:[[:space:]]*//" || true
}

crossfire_extract_yaml_from_live_stdout() {
  local raw="${1:-}"
  [ -n "$raw" ] || return 1
  printf '%s\n' "$raw" | awk '
    BEGIN { in_fence=0; block=""; last="" }
    function is_family_line(line) {
      return line ~ /^family: (behavioral|technical|product)$/
    }
    function is_yaml_line(line) {
      if (line ~ /^$/) return 1
      if (line ~ /^  /) return 1
      if (is_family_line(line)) return 1
      if (line ~ /^(missing_elements|evidence|persist_recommended|question_id|answer_ref|source_session_id|submitted_answer):/) return 1
      return 0
    }
    function save_block() {
      if (block != "") last=block
      block=""
      in_block=0
    }
    /^```/ {
      if (in_fence) {
        in_fence=0
        if (in_block) save_block()
        next
      }
      in_fence=1
      if (in_block) save_block()
      next
    }
    {
      if (in_fence || 1) {
        if (is_family_line($0)) {
          if (in_block) save_block()
          in_block=1
          block=$0
          next
        }
        if (in_block) {
          if (is_yaml_line($0)) {
            block=block ORS $0
          } else {
            save_block()
          }
        }
      }
    }
    END {
      if (in_block) save_block()
      if (last != "") print last
    }
  '
}

crossfire_strip_spool_harness_fields() {
  awk '
    BEGIN { in_sub=0 }
    /^submitted_answer:/ { in_sub=1; next }
    in_sub {
      if ($0 ~ /^[^ ]/) { in_sub=0 } else { next }
    }
    /^(question_id|answer_ref|source_session_id):/ { next }
    { print }
  '
}

crossfire_overlay_spool_harness_fields() {
  local yaml="${1:-}" qid="${2:-}" answer="${3:-}" run_id="${4:-}" session_id="${5:-}"
  local answer_ref stripped
  [ -n "$yaml" ] || return 1
  [ -n "$qid" ] || return 1
  [ -n "$run_id" ] || return 1
  answer_ref="${run_id}/${qid}/0"
  session_id="${session_id:-sess_live}"
  stripped=$(printf '%s\n' "$yaml" | crossfire_strip_spool_harness_fields)
  printf '%s\n' "$stripped"
  printf 'question_id: %s\n' "$qid"
  printf 'answer_ref: %s\n' "$answer_ref"
  printf 'source_session_id: %s\n' "$session_id"
  printf 'submitted_answer: |\n'
  printf '%s\n' "$answer" | sed 's/^/  /'
}

crossfire_normalize_live_proposal() {
  local raw="${1:-}" qid="${2:-}" answer="${3:-}" run_id="${4:-}" session_id="${5:-}"
  local extracted=""
  extracted=$(crossfire_extract_yaml_from_live_stdout "$raw") || return 1
  [ -n "$extracted" ] || return 1
  crossfire_overlay_spool_harness_fields "$extracted" "$qid" "$answer" "$run_id" "$session_id"
}

# Session-two opener helpers (spec §9 selection, §13 directive). Requires weakness_memory.sh sourced.
crossfire_weakness_sort_key_select() {
  local record="$1"
  local last_seen obs wid
  last_seen=$(crossfire_weakness_record_field "$record" 7)
  obs=$(crossfire_weakness_record_field "$record" 8)
  wid=$(crossfire_weakness_record_field "$record" 1)
  printf '%s\t%s\t%s\t%s\n' "$last_seen" "$obs" "$wid" "$record"
}

crossfire_select_newest_weakness() {
  local memory_md="${1:-$HERMES_MEMORY_MD}"
  local before block after record line
  local -a records=()

  [ -f "$memory_md" ] || fail_closed "MEMORY.md missing: $memory_md"

  before=$(mktemp)
  block=$(mktemp)
  after=$(mktemp)

  crossfire_weakness_split_memory_file "$memory_md" "$before" "$block" "$after"
  while IFS= read -r line || [ -n "$line" ]; do
    [ -n "$line" ] && records+=("$line")
  done < <(crossfire_weakness_parse_block_records "$block")

  rm -f "$before" "$block" "$after"

  if [ "${#records[@]}" -eq 0 ]; then
    fail_closed "no weaknesses in MEMORY.md block"
  fi

  record=$(
    for line in "${records[@]}"; do
      crossfire_weakness_sort_key_select "$line"
    done | sort -t $'\t' -k1,1r -k2,2nr -k3,3 | head -1 | cut -f4-
  )
  [ -n "$record" ] || fail_closed "could not select newest weakness"

  CROSSFIRE_OPENER_TARGET_SOURCE=MEMORY.md
  CROSSFIRE_OPENER_WEAKNESS_ID=$(crossfire_weakness_record_field "$record" 1)
  CROSSFIRE_OPENER_FAMILY=$(crossfire_weakness_record_field "$record" 2)
  CROSSFIRE_OPENER_MISSING_CSV=$(crossfire_weakness_record_field "$record" 5)
  CROSSFIRE_OPENER_SOURCE_SESSION_ID=$(crossfire_weakness_record_field "$record" 9)
  export CROSSFIRE_OPENER_TARGET_SOURCE CROSSFIRE_OPENER_WEAKNESS_ID
  export CROSSFIRE_OPENER_FAMILY CROSSFIRE_OPENER_MISSING_CSV CROSSFIRE_OPENER_SOURCE_SESSION_ID

  printf 'opening_target_source=%s\n' "$CROSSFIRE_OPENER_TARGET_SOURCE"
  printf 'weakness_id=%s\n' "$CROSSFIRE_OPENER_WEAKNESS_ID"
  printf 'family=%s\n' "$CROSSFIRE_OPENER_FAMILY"
  printf 'missing_elements=%s\n' "$CROSSFIRE_OPENER_MISSING_CSV"
  printf 'source_session_id=%s\n' "$CROSSFIRE_OPENER_SOURCE_SESSION_ID"
}

crossfire_print_opener_attribution() {
  crossfire_select_newest_weakness "$HERMES_MEMORY_MD" >/dev/null
  printf 'opening_target_source=%s\n' "$CROSSFIRE_OPENER_TARGET_SOURCE"
  printf 'weakness_id=%s\n' "$CROSSFIRE_OPENER_WEAKNESS_ID"
  printf 'family=%s\n' "$CROSSFIRE_OPENER_FAMILY"
  printf 'source_session_id=%s\n' "$CROSSFIRE_OPENER_SOURCE_SESSION_ID"
  printf '%s\n' 'target selected by prompt memory; wording generated under stable interviewer procedure'
}

crossfire_build_opener_cmdline() {
  local weakness_id="${1:-}" family="${2:-}" missing_csv="${3:-}"
  local opening_target_source="${4:-MEMORY.md}"
  local skill_ref="${5:-${CROSSFIRE_SKILL_PATH}}"
  local qtext qqtext qskill cmd=""
  qtext=$(printf '%s' \
    "Session-two opener. opening_target_source=${opening_target_source} weakness_id=${weakness_id} family=${family} missing_elements=[${missing_csv// /}]. Turn this directive into one interview question that targets the missing elements for the ${family} family. Do not name weakness_id or ask the operator to pick a topic." \
    | tr '\n' ' ')
  qqtext=$(printf '%q' "$qtext")
  qskill=$(printf '%q' "$skill_ref")
  cmd="hermes chat -Q -q ${qqtext} --max-turns 1 --toolsets skills --skills ${qskill} --source tool"
  printf '%s' "$cmd"
}

crossfire_stub_opener_question() {
  local family="${1:-}" missing_csv="${2:-}"
  case "$family" in
    behavioral)
      if [[ "$missing_csv" == *action* ]] && [[ "$missing_csv" == *result* ]]; then
        printf '%s' 'Tell me about a time a detection you owned was wrong — specifically, what action did you take and what measurable result followed?'
      else
        printf '%s' "For this behavioral follow-up, cover the missing elements (${missing_csv// /, }) with concrete situation, task, action, and result."
      fi
      ;;
    technical)
      printf '%s' "Walk through the technical gap around ${missing_csv// /, }: state the problem, your approach, the tradeoffs you weighed, and how you would verify the outcome."
      ;;
    product)
      printf '%s' "For the product decision gap (${missing_csv// /, }), who is the user, what constraint bound you, what did you decide, and which metric would prove it worked?"
      ;;
    *)
      fail_closed "unknown opener family: $family"
      ;;
  esac
}

crossfire_assert_distinct_process_and_session() {
  local s2_pid="${1:-$$}"
  local s2_sid="${2:-}"
  local s1_pid="${CROSSFIRE_SESSION_ONE_PID:-}"
  local s1_sid="${CROSSFIRE_SESSION_ONE_ID:-}"

  if [ -n "$s1_pid" ] && [ "$s1_pid" = "$s2_pid" ]; then
    fail_closed "session two process ID must differ from session one (${s1_pid})"
  fi
  if [ -n "$s1_sid" ] && [ -n "$s2_sid" ] && [ "$s1_sid" = "$s2_sid" ]; then
    fail_closed "session two session ID must differ from session one (${s1_sid})"
  fi
  printf 'session_identifiability: distinct process=%s session=%s (session_one=%s/%s)\n' \
    "$s2_pid" "$s2_sid" "${s1_pid:-unset}" "${s1_sid:-unset}"
}

# Artifact evidence (spec §7 step 4, plan task 8): bounded waits, reviewer-facing prints.
CROSSFIRE_WEAKNESS_BLOCK_START='<!-- CROSSFIRE-WEAKNESSES:START -->'
CROSSFIRE_WEAKNESS_BLOCK_END='<!-- CROSSFIRE-WEAKNESSES:END -->'
CROSSFIRE_ARTIFACT_TIMEOUT_SEC="${CROSSFIRE_ARTIFACT_TIMEOUT_SEC:-8}"
CROSSFIRE_ARTIFACT_POLL_SEC="${CROSSFIRE_ARTIFACT_POLL_SEC:-0.2}"

crossfire_artifact_memory_before_path() {
  local run_id="${1:-}"
  [ -n "$run_id" ] || return 1
  printf '%s/%s/memory-before.md' "$CROSSFIRE_RUNS_DIR" "$run_id"
}

crossfire_artifact_candidate_skills_root() {
  if declare -F crossfire_candidate_skills_root >/dev/null 2>&1; then
    crossfire_candidate_skills_root
  elif [ -n "${CROSSFIRE_CANDIDATE_SKILLS_ROOT:-}" ]; then
    printf '%s' "$CROSSFIRE_CANDIDATE_SKILLS_ROOT"
  else
    printf '%s' "${REPO_ROOT}/.crossfire/candidate-skills"
  fi
}

crossfire_snapshot_memory_md_before() {
  local run_id="${1:-}" memory_md="${2:-$HERMES_MEMORY_MD}"
  local dest run_dir

  [ -n "$run_id" ] || fail_closed "run_id required for memory before-snapshot"
  crossfire_require_isolated_hermes_home
  run_dir="${CROSSFIRE_RUNS_DIR}/${run_id}"
  mkdir -p "$run_dir"
  dest=$(crossfire_artifact_memory_before_path "$run_id")
  if [ -f "$memory_md" ]; then
    cp -f "$memory_md" "$dest"
  else
    : >"$dest"
  fi
  printf '%s\n' "$dest"
}

crossfire_extract_weakness_block_to_file() {
  local src="${1:-}" dest="${2:-}"
  local start="$CROSSFIRE_WEAKNESS_BLOCK_START" end="$CROSSFIRE_WEAKNESS_BLOCK_END"

  [ -n "$src" ] || return 1
  [ -n "$dest" ] || return 1
  : >"$dest"
  [ -f "$src" ] || return 0

  awk -v start="$start" -v end="$end" -v dest="$dest" '
    BEGIN { in_block=0 }
    {
      sub(/\r$/, "")
      if ($0 == start) { in_block=1; print > dest; next }
      if ($0 == end) { if (in_block) print > dest; in_block=0; next }
      if (in_block) print > dest
    }
  ' "$src"
}

crossfire_memory_weakness_block_changed() {
  local before_snapshot="${1:-}" memory_md="${2:-$HERMES_MEMORY_MD}"
  local b1 b2

  [ -f "$before_snapshot" ] || return 1
  b1=$(mktemp)
  b2=$(mktemp)
  crossfire_extract_weakness_block_to_file "$before_snapshot" "$b1"
  crossfire_extract_weakness_block_to_file "$memory_md" "$b2"
  if cmp -s "$b1" "$b2" 2>/dev/null; then
    rm -f "$b1" "$b2"
    return 1
  fi
  rm -f "$b1" "$b2"
  return 0
}

crossfire_resolve_run_candidate_skill() {
  local run_id="${1:-}"
  local flag line root candidate

  [ -n "$run_id" ] || return 1
  flag="${CROSSFIRE_RUNS_DIR}/${run_id}/candidate-excluded.flag"
  if [ -f "$flag" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
      [ -n "$line" ] || continue
      if [ -f "$line" ]; then
        printf '%s' "$line"
        return 0
      fi
    done <"$flag"
    return 1
  fi

  root=$(crossfire_artifact_candidate_skills_root)
  while IFS= read -r candidate; do
    [ -f "$candidate" ] || continue
    if grep -qE "^answer_ref: ${run_id}/" "$candidate" 2>/dev/null; then
      printf '%s' "$candidate"
      return 0
    fi
  done < <(find "$root" -name 'SKILL.md' -type f 2>/dev/null)
  return 1
}

crossfire_run_candidate_skill_ready() {
  local run_id="${1:-}"
  local path=""
  path=$(crossfire_resolve_run_candidate_skill "$run_id" 2>/dev/null) || return 1
  [ -n "$path" ] && [ -f "$path" ]
}

crossfire_wait_for_artifact() {
  local label="${1:-artifact}"
  local timeout_sec="${2:-${CROSSFIRE_ARTIFACT_TIMEOUT_SEC:-8}}"
  shift 2
  local start_ts now_ts elapsed

  [ "$#" -gt 0 ] || return 1
  start_ts=$(date +%s 2>/dev/null || date -u +%s)
  while true; do
    if "$@"; then
      return 0
    fi
    now_ts=$(date +%s 2>/dev/null || date -u +%s)
    elapsed=$((now_ts - start_ts))
    if [ "$elapsed" -ge "$timeout_sec" ]; then
      echo "artifact_evidence: timeout waiting for ${label} after ${timeout_sec}s" >&2
      return 1
    fi
    sleep "$CROSSFIRE_ARTIFACT_POLL_SEC"
  done
}

crossfire_print_weakness_block_diff() {
  local before_snapshot="${1:-}" memory_md="${2:-$HERMES_MEMORY_MD}"
  local before_block after_block

  [ -f "$before_snapshot" ] || {
    echo "artifact_evidence: before-snapshot missing: ${before_snapshot}" >&2
    return 1
  }
  before_block=$(mktemp)
  after_block=$(mktemp)
  crossfire_extract_weakness_block_to_file "$before_snapshot" "$before_block"
  crossfire_extract_weakness_block_to_file "$memory_md" "$after_block"
  printf 'artifact_evidence: MEMORY.md weakness-block diff\n'
  if [ ! -s "$before_block" ] && [ ! -s "$after_block" ]; then
    printf '(no weakness block in before or after)\n'
  elif cmp -s "$before_block" "$after_block" 2>/dev/null; then
    printf '(weakness block unchanged)\n'
  else
    diff -u --label 'memory-before (weakness block)' --label 'memory-after (weakness block)' \
      "$before_block" "$after_block" || true
  fi
  rm -f "$before_block" "$after_block"
}

crossfire_print_candidate_artifact() {
  local skill_path="${1:-}"

  [ -n "$skill_path" ] || {
    echo "artifact_evidence: candidate skill path required" >&2
    return 1
  }
  [ -f "$skill_path" ] || {
    echo "artifact_evidence: candidate skill missing: ${skill_path}" >&2
    return 1
  }

  printf 'artifact_evidence: staged candidate skill\n'
  printf 'candidate_path=%s\n' "$skill_path"
  grep -E '^(id|name|status|weakness_id|source_session_id|answer_ref|observation_count|target_family|missing_elements):' \
    "$skill_path" || true
  printf '%s\n' '--- candidate SKILL.md ---'
  cat "$skill_path"
}

crossfire_print_artifact_evidence() {
  local run_id="${1:-}" memory_md="${2:-$HERMES_MEMORY_MD}"
  local before_snapshot candidate_path timeout_sec

  [ -n "$run_id" ] || fail_closed "run_id required for artifact evidence"
  crossfire_require_isolated_hermes_home
  timeout_sec="${CROSSFIRE_ARTIFACT_TIMEOUT_SEC:-8}"
  before_snapshot=$(crossfire_artifact_memory_before_path "$run_id")

  if [ ! -f "$before_snapshot" ]; then
    echo "artifact_evidence: missing before-snapshot (call crossfire_snapshot_memory_md_before first): ${before_snapshot}" >&2
    return 1
  fi

  if ! crossfire_wait_for_artifact "MEMORY.md weakness-block change" "$timeout_sec" \
    crossfire_memory_weakness_block_changed "$before_snapshot" "$memory_md"; then
    return 1
  fi

  if ! crossfire_wait_for_artifact "staged candidate SKILL.md" "$timeout_sec" \
    crossfire_run_candidate_skill_ready "$run_id"; then
    return 1
  fi

  candidate_path=$(crossfire_resolve_run_candidate_skill "$run_id")
  crossfire_print_weakness_block_diff "$before_snapshot" "$memory_md"
  crossfire_print_candidate_artifact "$candidate_path"
}
