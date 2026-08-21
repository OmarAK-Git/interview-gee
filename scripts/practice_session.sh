#!/usr/bin/env bash
# Practice harness: start | answer | end. Monday allowlist. No demo K=3 retry.
set -euo pipefail

_practice_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
# shellcheck source=scripts/practice_common.sh
source "${_practice_dir}/practice_common.sh"
# shellcheck source=scripts/weakness_memory.sh
source "${_practice_dir}/weakness_memory.sh"
# shellcheck source=scripts/stage_candidate_skill.sh
source "${_practice_dir}/stage_candidate_skill.sh"

crossfire_practice_state_path() {
  printf '%s/%s/practice.state' "$CROSSFIRE_RUNS_DIR" "${CROSSFIRE_RUN_ID:?run_id required}"
}

crossfire_practice_load_state() {
  local f
  f=$(crossfire_practice_state_path)
  [ -f "$f" ] || fail_closed "no practice session; run start"
  # shellcheck disable=SC1090
  source "$f"
}

crossfire_practice_save_state() {
  local f dir
  dir="${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}"
  mkdir -p "$dir/spool" "$dir/transcript" "$dir/skipped"
  f="${dir}/practice.state"
  cat >"$f" <<EOF
CROSSFIRE_RUN_ID=${CROSSFIRE_RUN_ID}
CROSSFIRE_SESSION_ID=${CROSSFIRE_SESSION_ID:-}
CROSSFIRE_TURN=${CROSSFIRE_TURN:-0}
HERMES_HOME=${HERMES_HOME}
EOF
}

crossfire_practice_ensure_skill() {
  local dest="${HERMES_SKILLS_DIR}/crossfire-interviewer"
  mkdir -p "$dest" "${HERMES_HOME}/memories"
  cp "${CROSSFIRE_SKILL_PATH}/SKILL.md" "${dest}/SKILL.md"
  if [ -f "${CROSSFIRE_SKILL_PATH}/questions.md" ]; then
    cp "${CROSSFIRE_SKILL_PATH}/questions.md" "${dest}/questions.md"
  fi
}

crossfire_practice_kv() {
  printf '%s=%s\n' "$1" "$2"
}

crossfire_practice_append_transcript() {
  local role="${1:-}" text="${2:-}"
  local f="${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/transcript/session.txt"
  {
    printf '%s\n' "--- ${role} ---"
    printf '%s\n' "$text"
  } >>"$f"
}

crossfire_practice_start() {
  local question attribution="none" target_source="none"
  local stdout stderr sid

  crossfire_require_monday_home
  CROSSFIRE_RUN_ID=$(crossfire_allocate_run_id)
  CROSSFIRE_TURN=0
  CROSSFIRE_SESSION_ID=""
  export CROSSFIRE_RUN_ID
  mkdir -p "${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/spool"
  crossfire_practice_ensure_skill

  if [ -f "$HERMES_MEMORY_MD" ] && grep -q 'CROSSFIRE-WEAKNESSES:START' "$HERMES_MEMORY_MD" \
    && grep -q 'weakness_id:' "$HERMES_MEMORY_MD"; then
    attribution=$(crossfire_print_opener_attribution)
    # $(...) is a subshell — re-select so stub wording sees opener fields
    crossfire_select_newest_weakness "$HERMES_MEMORY_MD" >/dev/null
    target_source="${CROSSFIRE_OPENER_TARGET_SOURCE:-MEMORY.md}"
  fi

  if [ "${CROSSFIRE_PRACTICE_STUB:-0}" = "1" ]; then
    CROSSFIRE_SESSION_ID="sess_stub_practice"
    if [ "$target_source" = "MEMORY.md" ]; then
      question=$(crossfire_stub_opener_question "${CROSSFIRE_OPENER_FAMILY}" "${CROSSFIRE_OPENER_MISSING_CSV}")
    else
      question="Walk through how Praetor decides not to contain. What is the advisory boundary, and how would you know the decision was wrong?"
    fi
  else
    stdout=$(mktemp)
    stderr=$(mktemp)
    if [ "$target_source" = "MEMORY.md" ]; then
      cmdline=$(crossfire_build_opener_cmdline \
        "$CROSSFIRE_OPENER_WEAKNESS_ID" "$CROSSFIRE_OPENER_FAMILY" \
        "$CROSSFIRE_OPENER_MISSING_CSV" MEMORY.md \
        "${HERMES_SKILLS_DIR}/crossfire-interviewer")
    else
      cmdline="hermes chat -Q --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "${HERMES_SKILLS_DIR}/crossfire-interviewer") --source tool -q $(printf '%q' "You are the Crossfire interviewer. Ask ONE interview question from the McCain / Mastercard / Praetor / ALTER_EGO source material. Reply with the question only.")"
    fi
    if ! crossfire_hermes_invoke "$cmdline" "$stdout" "$stderr"; then
      rm -f "$stdout" "$stderr"
      fail_closed "practice start: Hermes invoke failed"
    fi
    CROSSFIRE_SESSION_ID=$(crossfire_parse_session_id_from_stderr "$stderr")
    CROSSFIRE_SESSION_ID="${CROSSFIRE_SESSION_ID:-sess_live_practice}"
    question=$(crossfire_extract_spoken_question "$(cat "$stdout")")
    if [ -z "$question" ]; then
      question=$(printf '%s\n' "$(cat "$stdout")" | tr -d '\r' | grep -E '\?' | tail -1 | sed 's/^[[:space:]]*//' || true)
    fi
    rm -f "$stdout" "$stderr"
  fi

  crossfire_practice_save_state
  crossfire_practice_append_transcript "interviewer" "$question"
  crossfire_practice_kv event start
  crossfire_practice_kv run_id "$CROSSFIRE_RUN_ID"
  crossfire_practice_kv session_id "$CROSSFIRE_SESSION_ID"
  crossfire_practice_kv opening_target_source "$target_source"
  printf '%s\n' "$attribution" | sed 's/^/attribution_line=/'
  crossfire_practice_kv question "$question"
  crossfire_practice_kv tts_text "$question"
}

crossfire_practice_answer() {
  local answer="${1:-}"
  local stdout stderr proposal qid status="ok" persist="false" question=""
  local spool_file skip_file cmdline skill

  [ -n "$answer" ] || fail_closed "empty answer"
  : "${CROSSFIRE_RUN_ID:?}"
  crossfire_practice_load_state
  crossfire_require_monday_home
  CROSSFIRE_TURN=$((CROSSFIRE_TURN + 1))
  qid="q_live_$(printf '%02d' "$CROSSFIRE_TURN")"
  crossfire_practice_append_transcript "operator" "$answer"

  skill="${HERMES_SKILLS_DIR}/crossfire-interviewer"
  stdout=$(mktemp)
  stderr=$(mktemp)

  if [ "${CROSSFIRE_PRACTICE_STUB:-0}" = "1" ]; then
    if [ -n "${CROSSFIRE_STUB_ASSESS_STDOUT:-}" ]; then
      printf '%s\n' "$CROSSFIRE_STUB_ASSESS_STDOUT" >"$stdout"
    elif [[ "$answer" == *dashboard* ]]; then
      cat >"$stdout" <<'EOF'
family: behavioral
missing_elements: [action, result]
evidence:
  kind: quote
  value: "I just kind of watched the dashboard."
persist_recommended: true
Tell me what action you took after that, and what changed as a result?
EOF
    else
      cat >"$stdout" <<'EOF'
family: technical
missing_elements: []
evidence:
  kind: quote
  value: "hash-chained ledger"
persist_recommended: false
For Mastercard Agent Suite (R-281517), how would you sequence rollout when a false positive could freeze a merchant?
EOF
    fi
    CROSSFIRE_SESSION_ID="${CROSSFIRE_SESSION_ID:-sess_stub_practice}"
    : >"$stderr"
    echo "session_id: ${CROSSFIRE_SESSION_ID}" >>"$stderr"
  else
    [ -n "$CROSSFIRE_SESSION_ID" ] || fail_closed "missing session_id"
    cmdline="hermes chat -Q --resume $(printf '%q' "$CROSSFIRE_SESSION_ID") --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "$skill") --source tool -q $(printf '%q' "Operator answer: ${answer}

Assess against exactly one family checklist. Emit propose-only YAML (family, missing_elements, evidence, persist_recommended) then ask ONE follow-up interview question. One model pass. Do not ask the operator to confirm persistence. Do not write MEMORY.md.")"
    if ! crossfire_hermes_invoke "$cmdline" "$stdout" "$stderr"; then
      # Keep the user text; skip assessment; continue.
      status="skipped"
      skip_file="${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/skipped/${qid}.stdout"
      mkdir -p "$(dirname "$skip_file")"
      cat "$stdout" >"$skip_file" || true
      cat "$stderr" >>"$skip_file" || true
      question="I missed that — say a bit more about what you just described?"
      rm -f "$stdout" "$stderr"
      crossfire_practice_save_state
      crossfire_practice_append_transcript "interviewer" "$question"
      crossfire_practice_kv event answer
      crossfire_practice_kv assessment_status "$status"
      crossfire_practice_kv persist_recommended false
      crossfire_practice_kv question "$question"
      crossfire_practice_kv tts_text "$question"
      return 0
    fi
    sid=$(crossfire_parse_session_id_from_stderr "$stderr" || true)
    [ -n "$sid" ] && CROSSFIRE_SESSION_ID="$sid"
  fi

  if proposal=$(crossfire_normalize_live_proposal "$(cat "$stdout")" "$qid" "$answer" "$CROSSFIRE_RUN_ID" "$CROSSFIRE_SESSION_ID"); then
    spool_file="${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/spool/${qid}.yaml"
    printf '%s\n' "$proposal" >"$spool_file"
    if crossfire_spool_should_persist "$spool_file"; then
      persist="true"
    fi
    status="ok"
  else
    status="skipped"
    skip_file="${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/skipped/${qid}.stdout"
    mkdir -p "$(dirname "$skip_file")"
    cat "$stdout" >"$skip_file"
    persist="false"
  fi

  question=$(crossfire_extract_spoken_question "$(cat "$stdout")")
  if [ -z "$question" ]; then
    question="Tell me more — what happened next?"
  fi
  rm -f "$stdout" "$stderr"

  crossfire_practice_save_state
  crossfire_practice_append_transcript "interviewer" "$question"
  crossfire_practice_kv event answer
  crossfire_practice_kv assessment_status "$status"
  crossfire_practice_kv persist_recommended "$persist"
  crossfire_practice_kv question "$question"
  crossfire_practice_kv tts_text "$question"
}

crossfire_practice_end() {
  local spool_dir f persisted=0
  : "${CROSSFIRE_RUN_ID:?}"
  crossfire_practice_load_state
  crossfire_require_monday_home
  spool_dir="${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/spool"
  mkdir -p "$(dirname "$HERMES_MEMORY_MD")"

  shopt -s nullglob
  for f in "${spool_dir}"/*.yaml; do
    [ -f "$f" ] || continue
    if ! crossfire_spool_should_persist "$f"; then
      continue
    fi
    family=$(crossfire_spool_field "$f" family)
    topic=$(crossfire_spool_field "$f" question_id)
    [ -n "$topic" ] || topic="$family"
    topic="${topic} practice gap"
    missing=$(crossfire_spool_field "$f" missing_elements)
    missing=${missing//[\[\]]/}
    missing=${missing// /}
    last_seen=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    source_sid=$(crossfire_spool_field "$f" source_session_id)
    answer_ref=$(crossfire_spool_field "$f" answer_ref)
    ev_kind=$(awk '/^evidence:/{getline; if ($0 ~ /kind:/) {sub(/^  kind: /,""); print; exit}}' "$f")
    ev_val=$(awk '/^evidence:/{getline; getline; if ($0 ~ /value:/) {sub(/^  value: /,""); gsub(/^"/,""); gsub(/"$/,""); print; exit}}' "$f")
    submitted=$(awk '/^submitted_answer:/{capture=1; next} capture && /^[^ ]/{exit} capture {sub(/^  /,""); print}' "$f")
    if crossfire_persist_weakness \
      "$HERMES_MEMORY_MD" "$family" "$topic" "$missing" "$last_seen" \
      "$source_sid" "$answer_ref" "${ev_kind:-quote}" "${ev_val:-}" "$submitted"; then
      persisted=$((persisted + 1))
      wid=$(crossfire_compute_weakness_id "$family" "$(crossfire_normalize_topic_key "$topic")")
      dest="${REPO_ROOT}/.crossfire/candidate-skills/unverified-${family}-followup/SKILL.md"
      mkdir -p "$(dirname "$dest")"
      if declare -F crossfire_render_candidate_skill_md >/dev/null 2>&1; then
        crossfire_render_candidate_skill_md \
          "$family" "$wid" "$source_sid" "$answer_ref" 1 "$missing" >"$dest" || true
      fi
    else
      echo "practice_session: persist skipped/failed for ${topic}" >&2
    fi
    trap - RETURN 2>/dev/null || true
  done
  shopt -u nullglob

  crossfire_practice_kv event end
  crossfire_practice_kv persisted_count "$persisted"
  crossfire_practice_kv ack ok
}

usage() {
  echo "usage: $0 start | answer <text> | end" >&2
  echo "  Requires CROSSFIRE_RUN_ID for answer/end (printed by start)." >&2
  exit 2
}

cmd="${1:-}"
shift || true
case "$cmd" in
  start) crossfire_practice_start ;;
  answer)
    CROSSFIRE_RUN_ID="${CROSSFIRE_RUN_ID:?set CROSSFIRE_RUN_ID from start}"
    crossfire_practice_answer "${1:-}"
    ;;
  end)
    CROSSFIRE_RUN_ID="${CROSSFIRE_RUN_ID:?set CROSSFIRE_RUN_ID from start}"
    crossfire_practice_end
    ;;
  *) usage ;;
esac
