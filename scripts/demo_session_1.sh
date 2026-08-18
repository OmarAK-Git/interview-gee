#!/usr/bin/env bash
# Session-one hybrid harness: three section 11 questions, spool buffer, deferred persist.
set -euo pipefail

_session_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
# shellcheck source=scripts/demo_common.sh
source "${_session_dir}/demo_common.sh"
# shellcheck source=scripts/weakness_memory.sh
source "${_session_dir}/weakness_memory.sh"

crossfire_stub_assess() {
  local qid="${1:-}" family="${2:-}" answer="${3:-}" run_id="${4:-}"
  local session_id="${CROSSFIRE_STUB_SESSION_ID:-sess_stub}"
  local evidence_value answer_ref
  answer_ref="${run_id}/${qid}/0"

  case "$qid" in
    q_technical_01)
      evidence_value="hash-chained audit ledger"
      cat <<EOF
family: technical
missing_elements: []
evidence:
  kind: quote
  value: "${evidence_value}"
persist_recommended: false
question_id: ${qid}
answer_ref: ${answer_ref}
source_session_id: ${session_id}
submitted_answer: |
$(printf '%s' "$answer" | sed 's/^/  /')
EOF
      ;;
    q_behavioral_01)
      evidence_value="I just kind of watched the dashboard."
      cat <<EOF
family: behavioral
missing_elements: [action, result]
evidence:
  kind: quote
  value: "${evidence_value}"
persist_recommended: true
question_id: ${qid}
answer_ref: ${answer_ref}
source_session_id: ${session_id}
submitted_answer: |
$(printf '%s' "$answer" | sed 's/^/  /')
EOF
      ;;
    q_product_01)
      evidence_value="false-freeze rate per thousand sessions"
      cat <<EOF
family: product
missing_elements: []
evidence:
  kind: quote
  value: "${evidence_value}"
persist_recommended: false
question_id: ${qid}
answer_ref: ${answer_ref}
source_session_id: ${session_id}
submitted_answer: |
$(printf '%s' "$answer" | sed 's/^/  /')
EOF
      ;;
    *)
      fail_closed "unknown demo question id: $qid"
      ;;
  esac
}

crossfire_live_assess_once() {
  local qid="${1:-}" family="${2:-}" question="${3:-}" answer="${4:-}" run_id="${5:-}"
  local skill_ref stdout stderr session_id cmdline proposal
  local -a skill_candidates=()

  skill_candidates+=("$CROSSFIRE_SKILL_PATH")
  skill_candidates+=("$(crossfire_ensure_isolated_skill)")

  stdout=$(mktemp)
  stderr=$(mktemp)

  for skill_ref in "${skill_candidates[@]}"; do
    cmdline=$(crossfire_build_assessor_cmdline "$qid" "$family" "$question" "$answer" "$skill_ref")
    if crossfire_hermes_invoke "$cmdline" "$stdout" "$stderr"; then
      session_id=$(crossfire_parse_session_id_from_stderr "$stderr")
      if proposal=$(crossfire_normalize_live_proposal "$(cat "$stdout")" "$qid" "$answer" "$run_id" "$session_id"); then
        rm -f "$stdout" "$stderr"
        printf '%s' "$proposal"
        return 0
      fi
    fi
  done

  cat "$stderr" >&2 || true
  rm -f "$stdout" "$stderr"
  return 1
}

crossfire_live_assess() {
  local qid="${1:-}" family="${2:-}" question="${3:-}" answer="${4:-}" run_id="${5:-}"
  local attempt=0 max_attempts="${CROSSFIRE_LIVE_ASSESSOR_RETRIES}"
  local proposal="" tmp_check=""

  crossfire_discover_hermes_or_fail_closed || fail_closed "live assessor requires Hermes binary"

  while [ "$attempt" -lt "$max_attempts" ]; do
    attempt=$((attempt + 1))
    if proposal=$(crossfire_live_assess_once "$qid" "$family" "$question" "$answer" "$run_id"); then
      if [ "$qid" != "q_behavioral_01" ]; then
        printf '%s' "$proposal"
        return 0
      fi
      tmp_check=$(mktemp)
      printf '%s\n' "$proposal" >"$tmp_check"
      if crossfire_spool_should_persist "$tmp_check"; then
        rm -f "$tmp_check"
        printf '%s' "$proposal"
        return 0
      fi
      rm -f "$tmp_check"
    fi
  done

  if [ "$qid" = "q_behavioral_01" ]; then
    fail_closed "live assessor: bad-answer assessment did not qualify for persist after ${max_attempts} attempts"
  fi
  fail_closed "live assessor failed for ${qid}"
}

crossfire_write_spool() {
  local spool_dir="${1:-}" qid="${2:-}" proposal="${3:-}"
  mkdir -p "$spool_dir"
  printf '%s\n' "$proposal" >"${spool_dir}/${qid}.yaml"
}

crossfire_assess_answer() {
  local qid="${1:-}" family="${2:-}" question="${3:-}" answer="${4:-}" run_id="${5:-}" spool_dir="${6:-}"
  local proposal=""
  local assessor="${CROSSFIRE_ASSESSOR:-stub}"

  if [ "$assessor" = "stub" ]; then
    proposal=$(crossfire_stub_assess "$qid" "$family" "$answer" "$run_id")
  else
    proposal=$(crossfire_live_assess "$qid" "$family" "$question" "$answer" "$run_id")
  fi

  crossfire_write_spool "$spool_dir" "$qid" "$proposal"
  printf '%s' "$proposal"
}

crossfire_session_one_finalize() {
  local run_id="${1:-}"
  local spool_dir="${CROSSFIRE_RUNS_DIR}/${run_id}/spool"
  local family topic missing_csv last_seen source_session_id answer_ref evidence_kind evidence_value submitted_answer
  local spool_file persisted=0 now_iso qid

  [ -d "$spool_dir" ] || fail_closed "spool missing for run_id=${run_id}"

  mkdir -p "$(dirname "$HERMES_MEMORY_MD")"

  now_iso=$(date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)

  for spool_file in "${spool_dir}"/*.yaml; do
    [ -f "$spool_file" ] || continue
    if ! crossfire_spool_should_persist "$spool_file"; then
      continue
    fi
    qid=$(crossfire_spool_field "$spool_file" question_id)
    family=$(crossfire_spool_field "$spool_file" family)
    missing_csv=$(crossfire_spool_field "$spool_file" missing_elements)
    missing_csv=${missing_csv//[\[\]]/}
    missing_csv=${missing_csv// /}
    source_session_id=$(crossfire_spool_field "$spool_file" source_session_id)
    answer_ref=$(crossfire_spool_field "$spool_file" answer_ref)
    evidence_kind=$(awk '/^evidence:/{getline; if ($0 ~ /kind:/) {sub(/^  kind: /,""); print; exit}}' "$spool_file")
    evidence_value=$(awk '/^evidence:/{getline; getline; if ($0 ~ /value:/) {sub(/^  value: /,""); gsub(/^"/,""); gsub(/"$/,""); print; exit}}' "$spool_file")
    submitted_answer=$(awk '/^submitted_answer:/{capture=1; next} capture && /^[^ ]/{exit} capture {sub(/^  /,""); print}' "$spool_file")
    if [ -z "$submitted_answer" ]; then
      fail_closed "spool missing submitted_answer for ${qid}"
    fi
    topic="${qid} demo gap"
    last_seen="$now_iso"

    if ! crossfire_persist_weakness \
      "$HERMES_MEMORY_MD" \
      "$family" \
      "$topic" \
      "$missing_csv" \
      "$last_seen" \
      "$source_session_id" \
      "$answer_ref" \
      "$evidence_kind" \
      "$evidence_value" \
      "$submitted_answer"; then
      fail_closed "persist failed for ${qid}"
    fi
    persisted=$((persisted + 1))
  done

  trap - RETURN 2>/dev/null || true
  printf 'CROSSFIRE: session one finalized; %s weakness(es) persisted.\n' "$persisted"
  return 0
}

crossfire_run_question_loop() {
  local run_id="${1:-}"
  local spool_dir="${CROSSFIRE_RUNS_DIR}/${run_id}/spool"
  local -a answers=()
  local i entry qid family question answer

  crossfire_read_demo_answers "$CROSSFIRE_DEMO_ANSWERS" answers

  for i in 0 1 2; do
    entry=$(crossfire_demo_question_entry "$i")
    IFS='|' read -r qid family question <<<"$entry"
    answer="${answers[$i]}"
    printf 'CROSSFIRE %s (%s)\n' "$qid" "$family"
    printf '%s\n\n' "$question"
    printf 'Answer: %s\n\n' "$answer"
    crossfire_assess_answer "$qid" "$family" "$question" "$answer" "$run_id" "$spool_dir" >/dev/null
    printf 'Assessment buffered for %s\n' "$qid"
  done
}

crossfire_session_one_main() {
  crossfire_require_isolated_hermes_home

  if [ "${CROSSFIRE_LIVE:-0}" = "1" ]; then
    export CROSSFIRE_ASSESSOR=live
    crossfire_discover_hermes_or_fail_closed
  elif [ "${CROSSFIRE_ASSESSOR:-stub}" != "stub" ]; then
    crossfire_discover_hermes_or_fail_closed || \
      fail_closed "live assessor selected but Hermes binary not discoverable"
  fi

  if [ -n "${CROSSFIRE_FINALIZE_RUN_ID:-}" ]; then
    crossfire_session_one_finalize "$CROSSFIRE_FINALIZE_RUN_ID"
    return $?
  fi

  local run_id
  run_id=$(crossfire_allocate_run_id)
  mkdir -p "${CROSSFIRE_RUNS_DIR}/${run_id}/spool"
  printf 'CROSSFIRE_RUN_ID=%s\n' "$run_id"

  crossfire_run_question_loop "$run_id"

  if [ "${CROSSFIRE_DEFER_FINALIZE:-0}" = "1" ]; then
    printf 'CROSSFIRE: session one buffered (finalize deferred).\n'
    return 0
  fi

  crossfire_session_one_finalize "$run_id"
}

if [[ "${BASH_SOURCE[0]:-}" == "${0}" ]]; then
  crossfire_session_one_main "$@"
  rc=$?
  trap - RETURN 2>/dev/null || true
  exit "$rc"
fi
