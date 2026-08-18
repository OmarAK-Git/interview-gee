#!/usr/bin/env bats

# Static validation for skills/crossfire-interviewer/questions.md (spec §11 bank).
# Demo questions live in session-one fixtures; this bank is cuttable extra coverage.

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  QUESTIONS_MD="$REPO_ROOT/skills/crossfire-interviewer/questions.md"
  SKILL_MD="$REPO_ROOT/skills/crossfire-interviewer/SKILL.md"
  DEMO_COMMON="$REPO_ROOT/scripts/demo_common.sh"
  DEMO_ANSWERS="$REPO_ROOT/tests/fixtures/demo-answers.txt"
  # shellcheck disable=SC1091
  source "$DEMO_COMMON"
}

# Parse table rows: | `id` | `family` | source | question |
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

# Bind question text to the spec §4 bullet named in Source (exit 0 = pass).
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

@test "questions.md exists" {
  [ -f "$QUESTIONS_MD" ]
}

@test "questions.md declares cuttable bank and source-material allowlist" {
  grep -qi 'cut' "$QUESTIONS_MD"
  grep -q 'McCain Foods' "$QUESTIONS_MD"
  grep -q 'Mastercard' "$QUESTIONS_MD"
  grep -q 'Praetor' "$QUESTIONS_MD"
  grep -q 'ALTER_EGO' "$QUESTIONS_MD"
}

@test "every bank question has stable id and declared family" {
  local rows ids="" row id family
  rows=$(question_bank_rows)
  [ -n "$rows" ]
  while IFS=$'\t' read -r id family _source _question; do
    [[ "$id" =~ ^q_[a-z0-9_]+$ ]]
    [[ "$family" =~ ^(behavioral|technical|product)$ ]]
    [[ "$ids" != *"|${id}|"* ]]
    ids="${ids}|${id}|"
  done <<<"$rows"
}

@test "question bank covers all three families" {
  local rows families=""
  rows=$(question_bank_rows)
  while IFS=$'\t' read -r _id family _source _question; do
    families="${families}|${family}|"
  done <<<"$rows"
  [[ "$families" == *"|behavioral|"* ]]
  [[ "$families" == *"|technical|"* ]]
  [[ "$families" == *"|product|"* ]]
}

@test "question bank covers McCain Mastercard Praetor and ALTER_EGO sources" {
  local combined=""
  combined=$(question_bank_rows | cut -f3,4 | tr '\n' ' ')
  [[ "$combined" == *"McCain"* ]]
  [[ "$combined" == *"Mastercard"* || "$combined" == *"R-281517"* || "$combined" == *"Agent Suite"* ]]
  [[ "$combined" == *"Praetor"* ]]
  [[ "$combined" == *"ALTER_EGO"* ]]
}

@test "source column uses only allowed employer material" {
  local allowed_re='^(McCain Foods|McCain|Mastercard R-281517|Mastercard Agent Suite|Mastercard|Project Praetor|Praetor|Project ALTER_EGO|ALTER_EGO)$'
  while IFS=$'\t' read -r _id _family q_source _question; do
    [[ "$q_source" =~ $allowed_re ]]
  done <<<"$(question_bank_rows)"
}

@test "question text binds to spec section 4 source bullet without cross-bullet inventions" {
  local id q_source q_text
  while IFS=$'\t' read -r id _family q_source q_text; do
    question_bank_source_binding_ok "$q_source" "$q_text"
  done <<<"$(question_bank_rows)"
}

@test "question text rejects known section 4 inventions" {
  local bad_mccain='Tell me about coordinating with plant operations at McCain Foods.'
  local bad_alterego='Describe ALTER_EGO shadow-profile drift at McCain Foods forcing freeze-under-suspicion.'
  local bad_mastercard='For Agent Suite, how do advisory-only automations avoid false-freeze?'
  ! question_bank_source_binding_ok 'McCain Foods' "$bad_mccain"
  ! question_bank_source_binding_ok 'Project ALTER_EGO' "$bad_alterego"
  ! question_bank_source_binding_ok 'Mastercard R-281517' "$bad_mastercard"
}

@test "demo question ids in bank match spec section 11 verbatim if present" {
  local spec_technical='Walk through how Praetor decides not to contain. What is the advisory boundary, and how would you know the decision was wrong?'
  local spec_behavioral='Tell me about a time a detection you owned was wrong. What did you do, and what changed afterward?'
  local spec_product='For Mastercard Agent Suite (R-281517), how would you sequence rollout when a false positive could freeze a merchant?'

  if grep -q '`q_technical_01`' "$QUESTIONS_MD"; then
    grep -Fq "$spec_technical" "$QUESTIONS_MD"
  fi
  if grep -q '`q_behavioral_01`' "$QUESTIONS_MD"; then
    grep -Fq "$spec_behavioral" "$QUESTIONS_MD"
  fi
  if grep -q '`q_product_01`' "$QUESTIONS_MD"; then
    grep -Fq "$spec_product" "$QUESTIONS_MD"
  fi
}

@test "session-one demo questions in crossfire_demo_question_entry match spec section 11" {
  [[ "$(crossfire_demo_question_entry 0)" == "q_technical_01|technical|Walk through how Praetor decides not to contain. What is the advisory boundary, and how would you know the decision was wrong?" ]]
  [[ "$(crossfire_demo_question_entry 1)" == "q_behavioral_01|behavioral|Tell me about a time a detection you owned was wrong. What did you do, and what changed afterward?" ]]
  [[ "$(crossfire_demo_question_entry 2)" == "q_product_01|product|For Mastercard Agent Suite (R-281517), how would you sequence rollout when a false positive could freeze a merchant?" ]]
}

@test "session-one demo question ids remain in demo-answers fixture" {
  grep -q '# q_technical_01' "$DEMO_ANSWERS"
  grep -q '# q_behavioral_01' "$DEMO_ANSWERS"
  grep -q '# q_product_01' "$DEMO_ANSWERS"
  grep -Fq 'Walk through how Praetor decides not to contain' "$DEMO_COMMON"
  grep -Fq 'Tell me about a time a detection you owned was wrong' "$DEMO_COMMON"
  grep -Fq 'For Mastercard Agent Suite (R-281517), how would you sequence rollout when a false positive could freeze a merchant?' "$DEMO_COMMON"
}

@test "session-one demo fixtures remain authoritative in SKILL.md" {
  grep -q 'q_technical_01' "$SKILL_MD"
  grep -q 'q_behavioral_01' "$SKILL_MD"
  grep -q 'q_product_01' "$SKILL_MD"
  grep -q 'Praetor decides not to contain' "$SKILL_MD"
  grep -q 'I just kind of watched the dashboard' "$SKILL_MD"
}
