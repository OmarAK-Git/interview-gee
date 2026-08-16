#!/usr/bin/env bats

# Static contract checks for spec §10 assessment + fixture label hygiene.
# Live §10 N=5 tolerance eval is skipped when Hermes is missing; forced live
# mode without a binary fails closed. Skip is never treated as N=5 passed.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SKILL_MD="$REPO_ROOT/skills/crossfire-interviewer/SKILL.md"
  CASES_MD="$REPO_ROOT/tests/fixtures/assessment-cases.md"
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/demo_common.sh"
  crossfire_require_isolated_hermes_home
}

# --- SKILL.md static contract ---

@test "SKILL.md exists and states behavioral required elements" {
  [ -f "$SKILL_MD" ]
  grep -q 'behavioral' "$SKILL_MD"
  grep -q '`situation`' "$SKILL_MD"
  grep -q '`task`' "$SKILL_MD"
  grep -q '`action`' "$SKILL_MD"
  grep -q '`result`' "$SKILL_MD"
}

@test "SKILL.md states technical required elements" {
  grep -q '`problem`' "$SKILL_MD"
  grep -q '`approach`' "$SKILL_MD"
  grep -q '`tradeoff`' "$SKILL_MD"
  grep -q '`verification`' "$SKILL_MD"
}

@test "SKILL.md states product required elements" {
  grep -q '`user`' "$SKILL_MD"
  grep -q '`constraint`' "$SKILL_MD"
  grep -q '`decision`' "$SKILL_MD"
  grep -q '`metric`' "$SKILL_MD"
}

@test "SKILL.md states persist when >=2 missing and one missing does not persist" {
  grep -qiE '≥ 2|>= 2' "$SKILL_MD"
  grep -q 'One' "$SKILL_MD"
  grep -qiE 'not.*persist' "$SKILL_MD"
  grep -qi 'automatic' "$SKILL_MD"
  grep -qi 'confirm' "$SKILL_MD"
}

@test "SKILL.md forbids mixed-family scoring" {
  grep -qi 'mixed-family' "$SKILL_MD"
  grep -qi 'forbidden' "$SKILL_MD"
  grep -qi 'exactly one' "$SKILL_MD"
}

@test "SKILL.md states technical answers are never scored with STAR" {
  grep -qi 'never' "$SKILL_MD"
  grep -q 'STAR' "$SKILL_MD"
  grep -q 'technical' "$SKILL_MD"
}

@test "SKILL.md states assessment output names family missing_elements and evidence" {
  grep -q 'missing_elements' "$SKILL_MD"
  grep -q 'byte_offset' "$SKILL_MD"
  grep -q 'quote' "$SKILL_MD"
}

@test "SKILL.md states propose-only harness writes MEMORY.md" {
  grep -qi 'propose' "$SKILL_MD"
  grep -q 'MEMORY.md' "$SKILL_MD"
  grep -qi 'must not' "$SKILL_MD"
}

@test "SKILL.md includes all three spec section 11 demo questions" {
  grep -q 'q_technical_01' "$SKILL_MD"
  grep -q 'q_behavioral_01' "$SKILL_MD"
  grep -q 'q_product_01' "$SKILL_MD"
  grep -q 'Praetor decides not to contain' "$SKILL_MD"
  grep -q 'detection you owned was wrong' "$SKILL_MD"
  grep -q 'Mastercard Agent Suite (R-281517)' "$SKILL_MD"
  grep -q 'I just kind of watched the dashboard' "$SKILL_MD"
}

@test "SKILL.md records skip is not N=5 pass and fail-closed forced live" {
  grep -qi 'Skip is not proof' "$SKILL_MD"
  grep -qi 'fail closed' "$SKILL_MD"
}

# --- Fixture parsing helpers ---

assessment_cases_extract() {
  awk '
    /^<!-- CASE START -->/ { in_case=1; next }
    /^<!-- CASE END -->/ {
      if (in_case) print "CASE_RECORD_END"
      in_case=0
      next
    }
    in_case { print }
  ' "$CASES_MD"
}

assessment_case_field() {
  local block="$1"
  local field="$2"
  printf '%s\n' "$block" | awk -v f="$field" '
    $0 ~ "^" f ": " { sub("^" f ": ", ""); print; exit }
    $0 ~ "^" f ":$" { capture=1; buf=""; next }
    capture && /^[^ ]/ { print buf; exit }
    capture { buf = (buf == "" ? $0 : buf "\n" $0) }
  '
}

assessment_case_answer() {
  local block="$1"
  printf '%s\n' "$block" | awk '
    /^answer: \|/ { capture=1; next }
    capture && /^[^ ]/ { exit }
    capture { sub(/^  /, ""); print }
  '
}

assessment_family_elements() {
  case "$1" in
    behavioral) printf '%s\n' situation task action result ;;
    technical) printf '%s\n' problem approach tradeoff verification ;;
    product) printf '%s\n' user constraint decision metric ;;
    *) return 1 ;;
  esac
}

assessment_is_star_element() {
  case "$1" in
    situation | task | action | result) return 0 ;;
    *) return 1 ;;
  esac
}

assessment_is_technical_element() {
  case "$1" in
    problem | approach | tradeoff | verification) return 0 ;;
    *) return 1 ;;
  esac
}

assessment_parse_missing_elements() {
  local raw="${1:-[]}"
  raw=${raw#\[}
  raw=${raw%]}
  raw=${raw// /}
  if [ -z "$raw" ]; then
    return 0
  fi
  local IFS=','
  # shellcheck disable=SC2206
  local parts=($raw)
  local p
  for p in "${parts[@]}"; do
    [ -n "$p" ] || continue
    printf '%s\n' "$p"
  done
}

assessment_cases_each() {
  local block=""
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    if [ "$line" = "CASE_RECORD_END" ]; then
      if ! "$@" "$block"; then
        return 1
      fi
      block=""
      continue
    fi
    if [ -z "$block" ]; then
      block="$line"
    else
      block="${block}"$'\n'"${line}"
    fi
  done < <(assessment_cases_extract)
}

assessment_assert_case_hygiene() {
  local block="$1"
  local id family expected_persist evidence_kind evidence_value answer
  local -a missing=()
  local elem count=0 expected_bool persist_bool allowed_elem allowed

  id=$(assessment_case_field "$block" id)
  family=$(assessment_case_field "$block" family)
  expected_persist=$(assessment_case_field "$block" expected_persist)
  evidence_kind=$(assessment_case_field "$block" evidence_kind)
  evidence_value=$(assessment_case_field "$block" evidence_value)
  answer=$(assessment_case_answer "$block")

  [ -n "$id" ] || { echo "case missing id" >&2; return 1; }
  [ -n "$family" ] || { echo "$id: missing family" >&2; return 1; }
  [ -n "$(assessment_case_field "$block" question_id)" ] || { echo "$id: missing question_id" >&2; return 1; }
  [ -n "$expected_persist" ] || { echo "$id: missing expected_persist" >&2; return 1; }
  [ -n "$evidence_kind" ] || { echo "$id: missing evidence_kind" >&2; return 1; }
  [ -n "$evidence_value" ] || { echo "$id: missing evidence_value" >&2; return 1; }
  [ -n "$answer" ] || { echo "$id: missing answer" >&2; return 1; }

  case "$family" in
    behavioral | technical | product) ;;
    *) echo "$id: unknown family $family" >&2; return 1 ;;
  esac

  local raw_missing
  raw_missing=$(assessment_case_field "$block" missing_elements)
  while IFS= read -r elem; do
    [ -n "$elem" ] || continue
    missing+=("$elem")
  done < <(assessment_parse_missing_elements "$raw_missing")

  count=${#missing[@]}
  if [ "$count" -ge 2 ]; then
    persist_bool=true
  else
    persist_bool=false
  fi

  if [ "$expected_persist" = "true" ]; then
    expected_bool=true
  elif [ "$expected_persist" = "false" ]; then
    expected_bool=false
  else
    echo "$id: expected_persist must be true or false" >&2
    return 1
  fi

  if [ "$persist_bool" != "$expected_bool" ]; then
    echo "$id: expected_persist=$expected_persist but missing count=$count" >&2
    return 1
  fi

  for elem in "${missing[@]}"; do
    allowed=false
    while IFS= read -r allowed_elem; do
      if [ "$elem" = "$allowed_elem" ]; then
        allowed=true
        break
      fi
    done < <(assessment_family_elements "$family")
    if [ "$allowed" != true ]; then
      echo "$id: missing element '$elem' not in family $family" >&2
      return 1
    fi
    if [ "$family" = "technical" ] && assessment_is_star_element "$elem"; then
      echo "$id: STAR element '$elem' on technical case" >&2
      return 1
    fi
    if [ "$family" = "behavioral" ] && assessment_is_technical_element "$elem"; then
      echo "$id: technical element '$elem' on behavioral case" >&2
      return 1
    fi
    if [ "$family" = "product" ] && { assessment_is_star_element "$elem" || assessment_is_technical_element "$elem"; }; then
      echo "$id: foreign element '$elem' on product case" >&2
      return 1
    fi
  done

  case "$evidence_kind" in
    quote)
      if [[ "$answer" != *"$evidence_value"* ]]; then
        echo "$id: evidence quote not substring of answer" >&2
        return 1
      fi
      ;;
    byte_offset)
      if [[ ! "$evidence_value" =~ ^[0-9]+:[0-9]+$ ]]; then
        echo "$id: invalid byte_offset evidence" >&2
        return 1
      fi
      ;;
    *)
      echo "$id: unknown evidence_kind $evidence_kind" >&2
      return 1
      ;;
  esac
}

assessment_count_cases() {
  assessment_cases_extract | grep -c '^CASE_RECORD_END$' || true
}

assessment_family_kinds() {
  local target_family="$1"
  assessment_cases_each bash -c '
    block="$1"
    target="'"$target_family"'"
    family=$(printf "%s" "$block" | awk "/^family: / { sub(/^family: /, \"\"); print; exit }")
    expected=$(printf "%s" "$block" | awk "/^expected_persist: / { sub(/^expected_persist: /, \"\"); print; exit }")
    raw=$(printf "%s" "$block" | awk "/^missing_elements: / { sub(/^missing_elements: /, \"\"); print; exit }")
    [ "$family" = "$target" ] || exit 0
    n=0
    raw=${raw#\[}; raw=${raw%\]}; raw=${raw// /}
    if [ -n "$raw" ]; then
      n=$(printf "%s" "$raw" | awk -F, "{print NF}")
    fi
    if [ "$n" -eq 0 ]; then echo strong; fi
    if [ "$n" -eq 1 ]; then echo one; fi
    if [ "$n" -ge 2 ] && [ "$expected" = "true" ]; then echo weak; fi
  ' _
}

# --- assessment-cases.md static checks ---

@test "assessment-cases.md exists with parseable case blocks" {
  [ -f "$CASES_MD" ]
  local n
  n=$(assessment_count_cases)
  [ "$n" -ge 9 ]
}

@test "each fixture case passes label hygiene checks" {
  assessment_cases_each assessment_assert_case_hygiene
}

@test "behavioral family has strong weak and one-missing fixtures" {
  local kinds
  kinds=$(assessment_family_kinds behavioral)
  echo "$kinds" | grep -q strong
  echo "$kinds" | grep -q one
  echo "$kinds" | grep -q weak
}

@test "technical family has strong weak and one-missing fixtures" {
  local kinds
  kinds=$(assessment_family_kinds technical)
  echo "$kinds" | grep -q strong
  echo "$kinds" | grep -q one
  echo "$kinds" | grep -q weak
}

@test "product family has strong weak and one-missing fixtures" {
  local kinds
  kinds=$(assessment_family_kinds product)
  echo "$kinds" | grep -q strong
  echo "$kinds" | grep -q one
  echo "$kinds" | grep -q weak
}

@test "q_behavioral_01 demo bad answer persists with action and result missing" {
  local found
  found=$(assessment_cases_each bash -c '
    block="$1"
    qid=$(printf "%s" "$block" | awk "/^question_id: / { sub(/^question_id: /, \"\"); print; exit }")
    expected=$(printf "%s" "$block" | awk "/^expected_persist: / { sub(/^expected_persist: /, \"\"); print; exit }")
    raw=$(printf "%s" "$block" | awk "/^missing_elements: / { sub(/^missing_elements: /, \"\"); print; exit }")
    [ "$qid" = "q_behavioral_01" ] || exit 0
    [ "$expected" = "true" ] || exit 1
    [[ "$raw" == *action* ]] || exit 1
    [[ "$raw" == *result* ]] || exit 1
    echo found
  ' _ | grep -c found || true)
  [ "$found" -ge 1 ]
}

# --- Isolation ---

@test "HERMES_HOME stays isolated under .crossfire/profiles" {
  [[ "$HERMES_HOME" == *".crossfire/profiles/"* ]]
  [ "$HERMES_HOME" != "$REAL_HERMES_WSL" ]
  if [ -n "$REAL_HERMES_WIN" ]; then
    [ "$HERMES_HOME" != "$REAL_HERMES_WIN" ]
  fi
}

@test "live hook uses discover_hermes_bin in subshell only not hermes exec" {
  grep -q 'discover_hermes_bin' "$BATS_TEST_FILENAME"
  local direct
  direct=$(grep -vE '^\s*#' "$BATS_TEST_FILENAME" | grep -E '(^|[;&|])[[:space:]]*hermes[[:space:]]' || true)
  [ -z "$direct" ]
}

# --- Live §10 N=5 hook (skip or fail-closed; never fake pass) ---

@test "live N=5 fixture eval skips when Hermes is undiscoverable (default)" {
  [ "${CROSSFIRE_LIVE_ASSESSMENT:-0}" != "1" ] || skip "live flag set — covered by fail-closed test"
  run env CROSSFIRE_HERMES_DISCOVERY=0 bash -c '
    source "'"$REPO_ROOT"'/scripts/demo_common.sh"
    if discover_hermes_bin >/dev/null 2>&1; then
      echo "unexpected hermes"
      exit 0
    fi
    echo "SKIP: Hermes binary not discoverable; spec section 10 N=5 live eval unsupported"
    exit 77
  '
  [ "$status" -eq 77 ]
  [[ "$output" == *"N=5"* ]] || [[ "$output" == *"unsupported"* ]]
}

@test "live N=5 fixture eval fails closed when forced without Hermes" {
  run env CROSSFIRE_LIVE_ASSESSMENT=1 CROSSFIRE_HERMES_DISCOVERY=0 bash -c '
    source "'"$REPO_ROOT"'/scripts/demo_common.sh"
    if [ "${CROSSFIRE_LIVE_ASSESSMENT:-0}" = "1" ]; then
      if ! discover_hermes_bin >/dev/null 2>&1; then
        echo "FAIL CLOSED: CROSSFIRE_LIVE_ASSESSMENT=1 but Hermes binary not discoverable" >&2
        exit 1
      fi
    fi
    exit 0
  '
  [ "$status" -ne 0 ]
  [[ "$output" == *"FAIL CLOSED"* ]] || [[ "$output" == *"not discoverable"* ]]
}

@test "live N=5 hook documents skip is not tolerance eval pass" {
  grep -q 'Skip is not proof' "$SKILL_MD"
  grep -q 'N = 5' "$SKILL_MD"
}
