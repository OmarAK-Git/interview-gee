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
  local f ctx
  f=$(crossfire_practice_state_path)
  [ -f "$f" ] || fail_closed "no practice session; run start"
  # shellcheck disable=SC1090
  source "$f"
  if [ -z "${CROSSFIRE_JD_CONTEXT:-}" ]; then
    ctx="${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/jd-context.md"
    if [ -f "$ctx" ]; then
      CROSSFIRE_JD_CONTEXT=$(cat "$ctx")
      export CROSSFIRE_JD_CONTEXT
    fi
  fi
}

crossfire_practice_interviewer_preamble() {
  cat <<EOF
You are the Crossfire interviewer for a practice session.
Practice session JD (employer facts only):
${CROSSFIRE_JD_CONTEXT}

Source: ${CROSSFIRE_JD_SOURCE_LABEL} (${CROSSFIRE_JD_SOURCE_ID})
Temperature: ${CROSSFIRE_TEMPERATURE:-2} (1=stay on story/core; 2=typical core; 3-5=rarer in-role, still in this JD).
Interviewer persona (optional, lens on this JD): ${CROSSFIRE_PERSONA:-}
Persona flavors voice and question window. Same JD competencies; that interviewer's stance. Domain knowledge implied by the persona is allowed. Do not invent this employer's tools, metrics, products, or systems.
Follow the Practice interviewer (session JD) section of the crossfire-interviewer skill.
The first spoken question is a normal in-role JD competency question. MEMORY.md may season follow-ups only; do not speak weakness_id.
Do not invent this employer's tools, metrics, products, or systems.
Do not write MEMORY.md.
EOF
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
CROSSFIRE_INFERENCE=${CROSSFIRE_INFERENCE:-nous}
CROSSFIRE_JD_KIND=${CROSSFIRE_JD_KIND:-}
CROSSFIRE_JD_SOURCE_ID=${CROSSFIRE_JD_SOURCE_ID:-}
CROSSFIRE_JD_SOURCE_LABEL=$(printf '%q' "${CROSSFIRE_JD_SOURCE_LABEL:-}")
CROSSFIRE_TEMPERATURE=${CROSSFIRE_TEMPERATURE:-2}
CROSSFIRE_PERSONA=$(printf '%q' "${CROSSFIRE_PERSONA:-}")
EOF
  if [ -n "${CROSSFIRE_JD_CONTEXT:-}" ]; then
    printf '%s\n' "$CROSSFIRE_JD_CONTEXT" >"${dir}/jd-context.md"
  fi
  if [ -n "${CROSSFIRE_OPENING_TARGET_SOURCE:-}" ]; then
    cat >>"$f" <<EOF
CROSSFIRE_OPENING_TARGET_SOURCE=${CROSSFIRE_OPENING_TARGET_SOURCE}
CROSSFIRE_OPENER_FAMILY=${CROSSFIRE_OPENER_FAMILY:-}
CROSSFIRE_OPENER_MISSING_CSV=${CROSSFIRE_OPENER_MISSING_CSV:-}
CROSSFIRE_OPENER_WEAKNESS_ID=${CROSSFIRE_OPENER_WEAKNESS_ID:-}
CROSSFIRE_MEMORY_PROBE_USED=${CROSSFIRE_MEMORY_PROBE_USED:-0}
EOF
  fi
}

crossfire_practice_ensure_skill() {
  local dest="${HERMES_SKILLS_DIR}/crossfire-interviewer"
  mkdir -p "$dest" "${HERMES_HOME}/memories"
  cp "${CROSSFIRE_SKILL_PATH}/SKILL.md" "${dest}/SKILL.md"
  if [ -f "${CROSSFIRE_SKILL_PATH}/questions.md" ]; then
    cp "${CROSSFIRE_SKILL_PATH}/questions.md" "${dest}/questions.md"
  fi
  if [ -d "${CROSSFIRE_SKILL_PATH}/sources" ]; then
    mkdir -p "${dest}/sources"
    cp "${CROSSFIRE_SKILL_PATH}/sources/"*.md "${dest}/sources/" 2>/dev/null || true
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
  if [ -z "${CROSSFIRE_JD_KIND:-}" ] || [ -z "${CROSSFIRE_JD_CONTEXT:-}" ]; then
    fail_closed "practice start requires a session JD (pack or paste)"
  fi
  CROSSFIRE_TEMPERATURE="${CROSSFIRE_TEMPERATURE:-2}"
  CROSSFIRE_PERSONA="${CROSSFIRE_PERSONA:-}"
  export CROSSFIRE_JD_KIND CROSSFIRE_JD_CONTEXT CROSSFIRE_JD_SOURCE_ID CROSSFIRE_JD_SOURCE_LABEL
  export CROSSFIRE_TEMPERATURE CROSSFIRE_PERSONA
  CROSSFIRE_INFERENCE=$(crossfire_practice_resolve_inference)
  export CROSSFIRE_INFERENCE
  CROSSFIRE_RUN_ID=$(crossfire_allocate_run_id)
  CROSSFIRE_TURN=0
  CROSSFIRE_SESSION_ID=""
  export CROSSFIRE_RUN_ID
  mkdir -p "${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/spool"
  crossfire_practice_ensure_skill

  if [ -f "$HERMES_MEMORY_MD" ] && grep -q 'CROSSFIRE-WEAKNESSES:START' "$HERMES_MEMORY_MD" \
    && grep -q 'weakness_id:' "$HERMES_MEMORY_MD"; then
    attribution=$(crossfire_print_opener_attribution)
    # $(...) is a subshell — re-select so opener fields persist for follow-up bias
    crossfire_select_newest_weakness "$HERMES_MEMORY_MD" >/dev/null
    target_source="${CROSSFIRE_OPENER_TARGET_SOURCE:-MEMORY.md}"
    CROSSFIRE_OPENING_TARGET_SOURCE="$target_source"
    CROSSFIRE_MEMORY_PROBE_USED=0
    export CROSSFIRE_OPENING_TARGET_SOURCE CROSSFIRE_MEMORY_PROBE_USED
  fi

  if [ "${CROSSFIRE_PRACTICE_STUB:-0}" = "1" ]; then
    CROSSFIRE_SESSION_ID="sess_stub_practice"
    question="Walk through how Praetor decides not to contain. What is the advisory boundary, and how would you know the decision was wrong?"
  else
    stdout=$(mktemp)
    stderr=$(mktemp)
    prompt="$(crossfire_practice_interviewer_preamble)
Ask ONE interview question from this JD only. Reply with the question only."
    cmdline="hermes chat -Q --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "${HERMES_SKILLS_DIR}/crossfire-interviewer") --source tool -q $(printf '%q' "$prompt")"
    cmdline=$(crossfire_practice_inject_inference "$cmdline")
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
  crossfire_practice_kv inference "$CROSSFIRE_INFERENCE"
  crossfire_practice_kv source_id "${CROSSFIRE_JD_SOURCE_ID:-}"
  crossfire_practice_kv source_label "${CROSSFIRE_JD_SOURCE_LABEL:-}"
  crossfire_practice_kv jd_kind "${CROSSFIRE_JD_KIND:-}"
  crossfire_practice_kv temperature "${CROSSFIRE_TEMPERATURE:-2}"
  printf '%s\n' "$attribution" | sed 's/^/attribution_line=/'
  crossfire_practice_kv question "$question"
  crossfire_practice_kv tts_text "$question"
}

crossfire_practice_answer() {
  local answer="${1:-}"
  local stdout stderr proposal qid status="ok" persist="false" question=""
  local spool_file skip_file cmdline skill
  local inbound_temp_set=0 inbound_temp=""

  [ -n "$answer" ] || fail_closed "empty answer"
  : "${CROSSFIRE_RUN_ID:?}"
  if [ -n "${CROSSFIRE_TEMPERATURE+set}" ]; then
    inbound_temp_set=1
    inbound_temp="$CROSSFIRE_TEMPERATURE"
  fi
  crossfire_practice_load_state
  CROSSFIRE_INFERENCE=$(crossfire_practice_resolve_inference)
  export CROSSFIRE_INFERENCE
  if [ "$inbound_temp_set" = "1" ]; then
    CROSSFIRE_TEMPERATURE="$inbound_temp"
  else
    CROSSFIRE_TEMPERATURE="${CROSSFIRE_TEMPERATURE:-2}"
  fi
  export CROSSFIRE_TEMPERATURE
  crossfire_require_monday_home
  [ -n "${CROSSFIRE_JD_CONTEXT:-}" ] || fail_closed "answer requires a session JD"
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
    local memory_bias=""
    if [ "${CROSSFIRE_OPENING_TARGET_SOURCE:-}" = "MEMORY.md" ] \
      && [ "${CROSSFIRE_MEMORY_PROBE_USED:-0}" != "1" ]; then
      memory_bias="
Known weakness from MEMORY.md (season follow-ups only, not the session subject): family=${CROSSFIRE_OPENER_FAMILY} missing_elements=[${CROSSFIRE_OPENER_MISSING_CSV}]. You may ask at most ONE follow-up that listens for a missing element inside the current story, then move on. Do not restart the same drill. Do not speak weakness_id. Do not ask the operator to name the weakness."
      CROSSFIRE_MEMORY_PROBE_USED=1
      export CROSSFIRE_MEMORY_PROBE_USED
    fi
    prompt="$(crossfire_practice_interviewer_preamble)
Operator answer: ${answer}
${memory_bias}

Assess against exactly one family checklist. missing_elements = what was actually absent, not the full checklist. Emit propose-only YAML (family, missing_elements, evidence, persist_recommended) then ask ONE follow-up interview question per temperature. One model pass. Do not ask the operator to confirm persistence. Do not write MEMORY.md."
    cmdline="hermes chat -Q --resume $(printf '%q' "$CROSSFIRE_SESSION_ID") --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "$skill") --source tool -q $(printf '%q' "$prompt")"
    cmdline=$(crossfire_practice_inject_inference "$cmdline")
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

crossfire_practice_skip() {
  local stdout stderr question
  local inbound_temp_set=0 inbound_temp=""
  : "${CROSSFIRE_RUN_ID:?}"
  if [ -n "${CROSSFIRE_TEMPERATURE+set}" ]; then
    inbound_temp_set=1
    inbound_temp="$CROSSFIRE_TEMPERATURE"
  fi
  crossfire_practice_load_state
  CROSSFIRE_INFERENCE=$(crossfire_practice_resolve_inference)
  export CROSSFIRE_INFERENCE
  if [ "$inbound_temp_set" = "1" ]; then
    CROSSFIRE_TEMPERATURE="$inbound_temp"
  else
    CROSSFIRE_TEMPERATURE="${CROSSFIRE_TEMPERATURE:-2}"
  fi
  export CROSSFIRE_TEMPERATURE
  crossfire_require_monday_home
  [ -n "${CROSSFIRE_JD_CONTEXT:-}" ] || fail_closed "skip requires a session JD"

  if [ "${CROSSFIRE_PRACTICE_STUB:-0}" = "1" ]; then
    question="Different question from the same JD — what tradeoff did you accept?"
  else
    stdout=$(mktemp)
    stderr=$(mktemp)
    prompt="$(crossfire_practice_interviewer_preamble)
The operator skipped the last question (it may have sounded invented). Do not emit assessment YAML. Ask ONE different interview question from the same JD only — a new JD question, not hesitation about the same MEMORY.md gap. Reply with the question only."
    cmdline="hermes chat -Q --resume $(printf '%q' "$CROSSFIRE_SESSION_ID") --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "${HERMES_SKILLS_DIR}/crossfire-interviewer") --source tool -q $(printf '%q' "$prompt")"
    cmdline=$(crossfire_practice_inject_inference "$cmdline")
    if ! crossfire_hermes_invoke "$cmdline" "$stdout" "$stderr"; then
      question="I will stay inside this job description. What problem were you solving, and how did you verify it?"
    else
      question=$(crossfire_extract_spoken_question "$(cat "$stdout")")
      [ -n "$question" ] || question="Same JD, different angle: what would make this decision wrong?"
    fi
    rm -f "$stdout" "$stderr"
  fi
  crossfire_practice_save_state
  crossfire_practice_append_transcript "interviewer" "(skipped previous) $question"
  crossfire_practice_kv event skip
  crossfire_practice_kv skipped true
  crossfire_practice_kv assessment_status skipped
  crossfire_practice_kv persist_recommended false
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
    topic="${CROSSFIRE_JD_SOURCE_LABEL:-practice} · ${family}"
    missing=$(crossfire_spool_field "$f" missing_elements)
    missing=${missing//[\[\]]/}
    missing=${missing// /}
    last_seen=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    source_sid=$(crossfire_spool_field "$f" source_session_id)
    answer_ref=$(crossfire_spool_field "$f" answer_ref)
    ev_kind=$(awk '/^evidence:/{getline; if ($0 ~ /kind:/) {sub(/^  kind: /,""); print; exit}}' "$f")
    ev_val=$(awk '/^evidence:/{getline; getline; if ($0 ~ /value:/) {sub(/^  value: /,""); gsub(/^"/,""); gsub(/"$/,""); print; exit}}' "$f")
    if [ ${#ev_val} -gt 180 ]; then
      ev_val="${ev_val:0:180}"
    fi
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

  weak=""
  strong=""
  for f in "${spool_dir}"/*.yaml; do
    [ -f "$f" ] || continue
    fam=$(crossfire_spool_field "$f" family)
    miss=$(crossfire_spool_field "$f" missing_elements)
    if crossfire_spool_should_persist "$f"; then
      weak="${weak};${fam}:${miss}"
    else
      strong="${strong};${fam}"
    fi
  done
  weak="${weak#;}"
  strong="${strong#;}"
  report_text="Weak: ${weak:-none}
Strong: ${strong:-none}"
  crossfire_practice_kv report_weak "$weak"
  crossfire_practice_kv report_strong "$strong"
  printf '%s\n' "$report_text" | sed 's/^/report_line=/'

  crossfire_practice_kv event end
  crossfire_practice_kv persisted_count "$persisted"
  crossfire_practice_kv ack ok
}

usage() {
  echo "usage: $0 start | answer <text> | skip | end" >&2
  echo "  Requires CROSSFIRE_RUN_ID for answer/skip/end (printed by start)." >&2
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
  skip)
    CROSSFIRE_RUN_ID="${CROSSFIRE_RUN_ID:?set CROSSFIRE_RUN_ID from start}"
    crossfire_practice_skip
    ;;
  end)
    CROSSFIRE_RUN_ID="${CROSSFIRE_RUN_ID:?set CROSSFIRE_RUN_ID from start}"
    crossfire_practice_end
    ;;
  *) usage ;;
esac
