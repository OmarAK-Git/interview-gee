#!/usr/bin/env bash
# Harness-owned candidate skill staging (spec §14). Never writes under $HERMES_SKILLS_DIR.
set -euo pipefail

_stage_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
if ! declare -F fail_closed >/dev/null 2>&1; then
  # shellcheck source=scripts/demo_common.sh
  source "${_stage_dir}/demo_common.sh"
fi
# shellcheck source=scripts/weakness_memory.sh
source "${_stage_dir}/weakness_memory.sh"

crossfire_candidate_skills_root() {
  if [ -n "${CROSSFIRE_CANDIDATE_SKILLS_ROOT:-}" ]; then
    printf '%s' "$CROSSFIRE_CANDIDATE_SKILLS_ROOT"
  else
    printf '%s' "${REPO_ROOT}/.crossfire/candidate-skills"
  fi
}

crossfire_candidate_skill_dir_name() {
  local family="${1:-}"
  crossfire_weakness_is_valid_family "$family" || return 1
  printf 'unverified-%s-followup' "$family"
}

crossfire_candidate_skill_path() {
  local family="${1:-}"
  local root dir
  root=$(crossfire_candidate_skills_root)
  dir=$(crossfire_candidate_skill_dir_name "$family") || return 1
  printf '%s/%s/SKILL.md' "$root" "$dir"
}

crossfire_candidate_missing_yaml_list() {
  local csv="${1:-}"
  local -a items=()
  local item
  local IFS=','
  for item in $csv; do
    item=${item// /}
    [ -n "$item" ] && items+=("$item")
  done
  printf '[%s]' "$(IFS=','; printf '%s' "${items[*]}")"
}

crossfire_candidate_checklist_lines() {
  local csv="${1:-}"
  local item
  local IFS=','
  for item in $csv; do
    item=${item// /}
    [ -n "$item" ] && printf -- '- %s\n' "$item"
  done
}

crossfire_candidate_followup_sentence() {
  local family="${1:-}" csv="${2:-}"
  local -a items=()
  local item n
  local IFS=','
  for item in $csv; do
    item=${item// /}
    [ -n "$item" ] && items+=("$item")
  done
  n=${#items[@]}
  [ "$n" -gt 0 ] || return 1

  case "$family" in
    behavioral)
      if [ "$n" -eq 1 ]; then
        case "${items[0]}" in
          action) printf '%s' 'Ask the candidate to describe the specific action they took.' ;;
          result) printf '%s' 'Ask the candidate to describe the measurable result that followed.' ;;
          situation) printf '%s' 'Ask the candidate to set the situation with concrete context.' ;;
          task) printf '%s' 'Ask the candidate to clarify their task or responsibility.' ;;
          *) printf '%s' "Ask the candidate to supply the missing behavioral element: ${items[0]}." ;;
        esac
      else
        printf '%s' 'Ask the candidate to describe the specific action they took and the result that followed.'
      fi
      ;;
    technical)
      printf '%s' "Ask the candidate to cover the missing technical elements (${csv// /}) with problem context, approach, tradeoffs, and verification."
      ;;
    product)
      printf '%s' "Ask the candidate to cover the missing product elements (${csv// /}) with user, constraint, decision, and metric."
      ;;
    *)
      printf '%s' "Ask the candidate to supply the missing elements: ${csv// /}."
      ;;
  esac
}

crossfire_candidate_weakness_id_from_spool() {
  local spool_file="${1:-}"
  local qid family topic topic_key
  qid=$(crossfire_spool_field "$spool_file" question_id)
  family=$(crossfire_spool_field "$spool_file" family)
  topic="${qid} demo gap"
  topic_key=$(crossfire_normalize_topic_key "$topic")
  crossfire_compute_weakness_id "$family" "$topic_key"
}

crossfire_candidate_observation_count_from_memory() {
  local memory_md="${1:-}" weakness_id="${2:-}"
  local block tmp count
  [ -f "$memory_md" ] || {
    printf '1'
    return 0
  }
  block=$(mktemp)
  local before after
  before=$(mktemp)
  after=$(mktemp)
  crossfire_weakness_split_memory_file "$memory_md" "$before" "$block" "$after"
  rm -f "$before" "$after"
  count=$(
    crossfire_weakness_parse_block_records "$block" | while IFS= read -r record || [ -n "$record" ]; do
      [ -n "$record" ] || continue
      if [ "$(crossfire_weakness_record_field "$record" 1)" = "$weakness_id" ]; then
        crossfire_weakness_record_field "$record" 8
        break
      fi
    done
  )
  rm -f "$block"
  if [ -n "$count" ]; then
    printf '%s' "$count"
  else
    printf '1'
  fi
}

crossfire_assert_candidates_excluded_from_live() {
  local skills_dir="${HERMES_SKILLS_DIR:-}"
  local skill_file dir base id_line name_line status_line rel
  local -a offenders=()

  crossfire_require_isolated_hermes_home

  case "$HERMES_HOME" in
    */.crossfire/profiles/*) ;;
    *)
      fail_closed "HERMES_HOME must be under .crossfire/profiles/ for candidate exclusion assert"
      ;;
  esac

  [ -d "$skills_dir" ] || return 0

  while IFS= read -r -d '' skill_file; do
    rel=${skill_file#"${skills_dir}/"}
    base=$(dirname "$rel")
    case "$base" in
      crossfire-interviewer | crossfire-interviewer/*) continue ;;
      */crossfire-interviewer | */crossfire-interviewer/*) continue ;;
    esac
    if [[ "$rel" == unverified-* ]] || [[ "$rel" == unverified-*/* ]] \
      || [[ "$rel" == crossfire.candidate.* ]] || [[ "$rel" == crossfire.candidate.*/* ]]; then
      offenders+=("$skill_file")
      continue
    fi
    id_line=$(grep -E '^id:[[:space:]]*crossfire\.candidate\.' "$skill_file" 2>/dev/null | head -1 || true)
    name_line=$(grep -E '^name:[[:space:]]*unverified-' "$skill_file" 2>/dev/null | head -1 || true)
    status_line=$(grep -E '^status:[[:space:]]*unverified' "$skill_file" 2>/dev/null | head -1 || true)
    if [ -n "$id_line" ] || [ -n "$name_line" ] || [ -n "$status_line" ]; then
      offenders+=("$skill_file")
    fi
  done < <(find "$skills_dir" -name 'SKILL.md' -print0 2>/dev/null)

  for dir in "$skills_dir"/unverified-* "$skills_dir"/crossfire.candidate.*; do
    [ -e "$dir" ] || continue
    offenders+=("$dir")
  done

  if [ "${#offenders[@]}" -gt 0 ]; then
    fail_closed "candidate skill material found under live skills dir: ${offenders[*]}"
  fi
  return 0
}

crossfire_write_candidate_barrier_flag() {
  local run_id="${1:-}"
  shift || true
  local -a staged_paths=("$@")
  local flag_dir flag_file path

  [ -n "$run_id" ] || fail_closed "run_id required for candidate barrier flag"
  flag_dir="${CROSSFIRE_RUNS_DIR}/${run_id}"
  mkdir -p "$flag_dir"
  flag_file="${flag_dir}/candidate-excluded.flag"
  : >"$flag_file"
  for path in "${staged_paths[@]:-}"; do
    [ -n "$path" ] || continue
    printf '%s\n' "$path" >>"$flag_file"
  done
  return 0
}

crossfire_snapshot_live_candidates_if_any() {
  local run_id="${1:-}"
  local skills_dir="${HERMES_SKILLS_DIR:-}"
  local snapshot_root skill_file dest_dir base

  [ -n "$run_id" ] || fail_closed "run_id required for live candidate snapshot"
  crossfire_require_isolated_hermes_home
  [ -d "$skills_dir" ] || return 0

  snapshot_root="${CROSSFIRE_RUNS_DIR}/${run_id}/live-skill-snapshot"
  local moved=0

  while IFS= read -r -d '' skill_file; do
    if grep -qE '^id:[[:space:]]*crossfire\.candidate\.' "$skill_file" 2>/dev/null \
      || grep -qE '^name:[[:space:]]*unverified-.*-followup' "$skill_file" 2>/dev/null; then
      base=$(basename "$(dirname "$skill_file")")
      dest_dir="${snapshot_root}/${base}"
      mkdir -p "$dest_dir"
      mv "$skill_file" "${dest_dir}/SKILL.md"
      rmdir "$(dirname "$skill_file")" 2>/dev/null || true
      moved=1
    fi
  done < <(find "$skills_dir" -name 'SKILL.md' -print0 2>/dev/null)

  for dir in "$skills_dir"/unverified-*-followup; do
    [ -d "$dir" ] || continue
    base=$(basename "$dir")
    dest_dir="${snapshot_root}/${base}"
    mkdir -p "$dest_dir"
    if [ -f "${dir}/SKILL.md" ]; then
      mv "${dir}/SKILL.md" "${dest_dir}/SKILL.md"
    fi
    rmdir "$dir" 2>/dev/null || true
    moved=1
  done

  if [ "$moved" -eq 1 ]; then
    crossfire_assert_candidates_excluded_from_live
  fi
  return 0
}

crossfire_render_candidate_skill_md() {
  local family="${1:-}" weakness_id="${2:-}" source_session_id="${3:-}"
  local answer_ref="${4:-}" observation_count="${5:-}" missing_csv="${6:-}"
  local skill_id skill_name missing_yaml checklist followup

  crossfire_weakness_is_valid_family "$family" || return 1
  skill_id="crossfire.candidate.${family}"
  skill_name=$(crossfire_candidate_skill_dir_name "$family")
  missing_yaml=$(crossfire_candidate_missing_yaml_list "$missing_csv")
  checklist=$(crossfire_candidate_checklist_lines "$missing_csv")
  followup=$(crossfire_candidate_followup_sentence "$family" "$missing_csv")

  cat <<EOF
---
id: ${skill_id}
name: ${skill_name}
status: unverified
weakness_id: ${weakness_id}
source_session_id: ${source_session_id}
answer_ref: ${answer_ref}
observation_count: ${observation_count}
target_family: ${family}
missing_elements: ${missing_yaml}
---

# Unverified follow-up

Do not praise or imitate the recorded answer. Ask for the missing elements.

## Corrective checklist
${checklist}
## Follow-up template
${followup}
EOF
}

crossfire_stage_candidate_skill() {
  local run_id="${1:-}" target_family="${2:-}" weakness_id="${3:-}"
  local source_session_id="${4:-}" answer_ref="${5:-}" observation_count="${6:-}"
  local missing_csv="${7:-}"
  local dest root dir tmp staged_path

  [ -n "$run_id" ] || fail_closed "run_id required"
  [ -n "$target_family" ] || fail_closed "target_family required"
  [ -n "$weakness_id" ] || fail_closed "weakness_id required"
  [ -n "$source_session_id" ] || fail_closed "source_session_id required"
  [ -n "$answer_ref" ] || fail_closed "answer_ref required"
  [ -n "$observation_count" ] || observation_count=1
  [ -n "$missing_csv" ] || fail_closed "missing_elements required"

  crossfire_require_isolated_hermes_home
  crossfire_snapshot_live_candidates_if_any "$run_id"
  crossfire_assert_candidates_excluded_from_live

  root=$(crossfire_candidate_skills_root)
  dir=$(crossfire_candidate_skill_dir_name "$target_family") || fail_closed "invalid target_family: ${target_family}"
  staged_path="${root}/${dir}/SKILL.md"

  case "$staged_path" in
    "${HERMES_SKILLS_DIR}"/*) fail_closed "refusing to stage candidate under live skills dir" ;;
  esac

  mkdir -p "${root}/${dir}"
  tmp=$(mktemp "${staged_path}.XXXXXX")
  crossfire_render_candidate_skill_md \
    "$target_family" "$weakness_id" "$source_session_id" "$answer_ref" \
    "$observation_count" "$missing_csv" >"$tmp"
  mv -f "$tmp" "$staged_path"

  crossfire_assert_candidates_excluded_from_live
  printf '%s\n' "$staged_path"
}

crossfire_stage_candidate_from_spool() {
  local run_id="${1:-}" spool_file="${2:-}" memory_md="${3:-$HERMES_MEMORY_MD}"
  local family missing_csv source_session_id answer_ref weakness_id observation_count
  local submitted_answer staged_path

  [ -f "$spool_file" ] || fail_closed "spool file missing: ${spool_file}"
  crossfire_spool_should_persist "$spool_file" || return 0

  family=$(crossfire_spool_field "$spool_file" family)
  missing_csv=$(crossfire_spool_field "$spool_file" missing_elements)
  missing_csv=${missing_csv//[\[\]]/}
  missing_csv=${missing_csv// /}
  source_session_id=$(crossfire_spool_field "$spool_file" source_session_id)
  answer_ref=$(crossfire_spool_field "$spool_file" answer_ref)
  submitted_answer=$(awk '/^submitted_answer:/{capture=1; next} capture && /^[^ ]/{exit} capture {sub(/^  /,""); print}' "$spool_file")
  weakness_id=$(crossfire_candidate_weakness_id_from_spool "$spool_file")
  observation_count=$(crossfire_candidate_observation_count_from_memory "$memory_md" "$weakness_id")

  staged_path=$(crossfire_stage_candidate_skill \
    "$run_id" "$family" "$weakness_id" "$source_session_id" "$answer_ref" \
    "$observation_count" "$missing_csv")

  if [ -n "$submitted_answer" ] && grep -Fq "$submitted_answer" "$staged_path"; then
    fail_closed "candidate body must not contain submitted_answer text"
  fi

  printf '%s\n' "$staged_path"
}

crossfire_stage_candidates_for_run() {
  local run_id="${1:-}" memory_md="${2:-$HERMES_MEMORY_MD}"
  local spool_dir="${CROSSFIRE_RUNS_DIR}/${run_id}/spool"
  local spool_file staged_path
  local -a staged_paths=()
  local -A seen_families=()

  [ -d "$spool_dir" ] || fail_closed "spool missing for run_id=${run_id}"

  crossfire_require_isolated_hermes_home
  crossfire_snapshot_live_candidates_if_any "$run_id"
  crossfire_assert_candidates_excluded_from_live

  for spool_file in "${spool_dir}"/*.yaml; do
    [ -f "$spool_file" ] || continue
    crossfire_spool_should_persist "$spool_file" || continue
    family=$(crossfire_spool_field "$spool_file" family)
    if [ -n "${seen_families[$family]:-}" ]; then
      fail_closed "more than one persist-eligible spool entry for family ${family}"
    fi
    seen_families[$family]=1
    staged_path=$(crossfire_stage_candidate_from_spool "$run_id" "$spool_file" "$memory_md")
    staged_paths+=("$staged_path")
  done

  if [ "${#staged_paths[@]}" -gt 0 ]; then
    crossfire_write_candidate_barrier_flag "$run_id" "${staged_paths[@]}"
  fi

  printf '%s\n' "${staged_paths[@]}"
}
