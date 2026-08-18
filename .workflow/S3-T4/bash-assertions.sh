#!/usr/bin/env bash
# S3-T4 bash-equivalent assertions (mirrors tests/question_bank.bats)
set -u
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
cd "$REPO_ROOT"
passed=0
failed=0

ok() { passed=$((passed + 1)); echo "PASS: $1"; }
fail() { failed=$((failed + 1)); echo "FAIL: $1"; }

QUESTIONS_MD="$REPO_ROOT/skills/crossfire-interviewer/questions.md"
SKILL_MD="$REPO_ROOT/skills/crossfire-interviewer/SKILL.md"
DEMO_COMMON="$REPO_ROOT/scripts/demo_common.sh"
DEMO_ANSWERS="$REPO_ROOT/tests/fixtures/demo-answers.txt"

# shellcheck disable=SC1091
source "$DEMO_COMMON"
set +e

question_bank_rows() {
  awk '
    /^\| `q_/ {
      gsub(/^[\| ]+/, "")
      gsub(/[\| ]+$/, "")
      n = split($0, cols, "|")
      for (i = 1; i <= n; i++) {
        gsub(/\r/, "", cols[i])
        gsub(/^ +| +$/, "", cols[i])
        gsub(/^`|`$/, "", cols[i])
      }
      if (cols[1] ~ /^q_[a-z0-9_]+$/) print cols[1] "\t" cols[2] "\t" cols[3] "\t" cols[4]
    }
  ' "$QUESTIONS_MD"
}

question_bank_source_binding_ok() {
  local q_source="$1" q_text="$2"

  case "$q_source" in
    "McCain Foods")
      grep -qiE 'McCain Foods|Cyber Defense Engineer|late-stage rounds' <<<"$q_text" || return 1
      if grep -qiE 'plant ops|plant operations|ALTER_EGO|Praetor|advisory-only|never-contain|Agent Suite|R-281517|UEBA|KL-divergence|shadow profile' <<<"$q_text"; then
        return 1
      fi
      ;;
    "Mastercard R-281517"|"Mastercard Agent Suite")
      grep -qiE 'Mastercard|Agent Suite|R-281517' <<<"$q_text" || return 1
      if grep -qiE 'advisory-only|never-contain|hash-chained|LangGraph|Praetor|ALTER_EGO|McCain|UEBA|KL-divergence|plant ops|plant operations' <<<"$q_text"; then
        return 1
      fi
      ;;
    "Project Praetor")
      grep -qiE 'Praetor|LangGraph|SOAR|advisory-only|never-contain|hash-chained' <<<"$q_text" || return 1
      if grep -qiE 'McCain|ALTER_EGO|Agent Suite|R-281517|plant ops|plant operations|UEBA|KL-divergence|shadow profile|freeze-under-suspicion' <<<"$q_text"; then
        return 1
      fi
      ;;
    "Project ALTER_EGO")
      grep -qiE 'ALTER_EGO|UEBA|KL-divergence|shadow profile|shadow-profile|freeze-under-suspicion|behavioral drift' <<<"$q_text" || return 1
      if grep -qiE 'McCain|McCain Foods|Praetor|advisory-only|never-contain|Agent Suite|R-281517|plant ops|plant operations|LangGraph|SOAR' <<<"$q_text"; then
        return 1
      fi
      ;;
    *)
      return 1
      ;;
  esac
  return 0
}

# questions.md exists
[ -f "$QUESTIONS_MD" ] && ok questions_md_exists || fail questions_md_exists

# cuttable bank + allowlist mentions
if grep -qi 'cut' "$QUESTIONS_MD" && \
   grep -q 'McCain Foods' "$QUESTIONS_MD" && \
   grep -q 'Mastercard' "$QUESTIONS_MD" && \
   grep -q 'Praetor' "$QUESTIONS_MD" && \
   grep -q 'ALTER_EGO' "$QUESTIONS_MD"; then
  ok bank_header_allowlist
else
  fail bank_header_allowlist
fi

rows=$(question_bank_rows)
if [ -n "$rows" ]; then ok has_rows; else fail has_rows; fi

# stable id + family + unique ids
ids=""
id_family_ok=1
while IFS=$'\t' read -r id family _source _question; do
  [[ "$id" =~ ^q_[a-z0-9_]+$ ]] || id_family_ok=0
  [[ "$family" =~ ^(behavioral|technical|product)$ ]] || id_family_ok=0
  [[ "$ids" != *"|${id}|"* ]] || id_family_ok=0
  ids="${ids}|${id}|"
done <<<"$rows"
[ "$id_family_ok" -eq 1 ] && ok id_family_unique || fail id_family_unique

# three families
families=""
while IFS=$'\t' read -r _id family _source _question; do
  families="${families}|${family}|"
done <<<"$rows"
if [[ "$families" == *"|behavioral|"* && "$families" == *"|technical|"* && "$families" == *"|product|"* ]]; then
  ok three_families
else
  fail three_families
fi

# four sources
combined=$(echo "$rows" | cut -f3,4 | tr '\n' ' ')
if [[ "$combined" == *"McCain"* && ( "$combined" == *"Mastercard"* || "$combined" == *"R-281517"* || "$combined" == *"Agent Suite"* ) && \
     "$combined" == *"Praetor"* && "$combined" == *"ALTER_EGO"* ]]; then
  ok four_sources
else
  fail four_sources
fi

# source column allowlist
source_ok=1
allowed_re='^(McCain Foods|McCain|Mastercard R-281517|Mastercard Agent Suite|Mastercard|Project Praetor|Praetor|Project ALTER_EGO|ALTER_EGO)$'
while IFS=$'\t' read -r _id _family q_source _question; do
  [[ "$q_source" =~ $allowed_re ]] || source_ok=0
done <<<"$rows"
[ "$source_ok" -eq 1 ] && ok source_allowlist || fail source_allowlist

# question text binds to spec §4 source bullet
binding_ok=1
while IFS=$'\t' read -r _id _family q_source q_text; do
  question_bank_source_binding_ok "$q_source" "$q_text" || binding_ok=0
done <<<"$rows"
[ "$binding_ok" -eq 1 ] && ok source_binding || fail source_binding

# negative control: known §4 inventions must fail binding
neg_ok=1
bad_mccain='Tell me about coordinating with plant operations at McCain Foods.'
bad_alterego='Describe ALTER_EGO shadow-profile drift at McCain Foods forcing freeze-under-suspicion.'
bad_mastercard='For Agent Suite, how do advisory-only automations avoid false-freeze?'
question_bank_source_binding_ok 'McCain Foods' "$bad_mccain" && neg_ok=0
question_bank_source_binding_ok 'Project ALTER_EGO' "$bad_alterego" && neg_ok=0
question_bank_source_binding_ok 'Mastercard R-281517' "$bad_mastercard" && neg_ok=0
[ "$neg_ok" -eq 1 ] && ok source_binding_negative || fail source_binding_negative

# demo ids verbatim if present
spec_technical='Walk through how Praetor decides not to contain. What is the advisory boundary, and how would you know the decision was wrong?'
spec_behavioral='Tell me about a time a detection you owned was wrong. What did you do, and what changed afterward?'
spec_product='For Mastercard Agent Suite (R-281517), how would you sequence rollout when a false positive could freeze a merchant?'
demo_ok=1
if grep -q '`q_technical_01`' "$QUESTIONS_MD"; then
  grep -Fq "$spec_technical" "$QUESTIONS_MD" || demo_ok=0
fi
if grep -q '`q_behavioral_01`' "$QUESTIONS_MD"; then
  grep -Fq "$spec_behavioral" "$QUESTIONS_MD" || demo_ok=0
fi
if grep -q '`q_product_01`' "$QUESTIONS_MD"; then
  grep -Fq "$spec_product" "$QUESTIONS_MD" || demo_ok=0
fi
[ "$demo_ok" -eq 1 ] && ok demo_ids_verbatim || fail demo_ids_verbatim

# crossfire_demo_question_entry matches spec §11
entry_ok=1
[[ "$(crossfire_demo_question_entry 0)" == "q_technical_01|technical|Walk through how Praetor decides not to contain. What is the advisory boundary, and how would you know the decision was wrong?" ]] || entry_ok=0
[[ "$(crossfire_demo_question_entry 1)" == "q_behavioral_01|behavioral|Tell me about a time a detection you owned was wrong. What did you do, and what changed afterward?" ]] || entry_ok=0
[[ "$(crossfire_demo_question_entry 2)" == "q_product_01|product|For Mastercard Agent Suite (R-281517), how would you sequence rollout when a false positive could freeze a merchant?" ]] || entry_ok=0
[ "$entry_ok" -eq 1 ] && ok demo_question_entry || fail demo_question_entry

# demo-answers fixture ids + demo_common strings
fixture_ok=1
grep -q '# q_technical_01' "$DEMO_ANSWERS" || fixture_ok=0
grep -q '# q_behavioral_01' "$DEMO_ANSWERS" || fixture_ok=0
grep -q '# q_product_01' "$DEMO_ANSWERS" || fixture_ok=0
grep -Fq 'Walk through how Praetor decides not to contain' "$DEMO_COMMON" || fixture_ok=0
grep -Fq 'Tell me about a time a detection you owned was wrong' "$DEMO_COMMON" || fixture_ok=0
grep -Fq 'For Mastercard Agent Suite (R-281517), how would you sequence rollout when a false positive could freeze a merchant?' "$DEMO_COMMON" || fixture_ok=0
[ "$fixture_ok" -eq 1 ] && ok demo_answers_fixture || fail demo_answers_fixture

# SKILL.md still authoritative for demo questions
if grep -q 'q_technical_01' "$SKILL_MD" && \
   grep -q 'q_behavioral_01' "$SKILL_MD" && \
   grep -q 'q_product_01' "$SKILL_MD" && \
   grep -q 'Praetor decides not to contain' "$SKILL_MD" && \
   grep -q 'I just kind of watched the dashboard' "$SKILL_MD"; then
  ok skill_demo_authoritative
else
  fail skill_demo_authoritative
fi

echo "passed=$passed failed=$failed"
[ "$failed" -eq 0 ]
