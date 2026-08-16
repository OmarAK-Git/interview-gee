#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  TEST_ROOT="$(mktemp -d "${BATS_TMPDIR:-/tmp}/crossfire-wm.XXXXXX")"
  export HERMES_HOME="${TEST_ROOT}/.crossfire/profiles/test"
  mkdir -p "${HERMES_HOME}/memories"
  MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/weakness_memory.sh"
}

teardown() {
  rm -rf "$TEST_ROOT"
}

wm_copy_fixture() {
  local fixture="$1"
  cp "$REPO_ROOT/tests/fixtures/$fixture" "$MEMORY_MD"
}

wm_snapshot() {
  cat "$MEMORY_MD" 2>/dev/null || true
}

@test "topic_key normalization lowercases and hyphenates" {
  run crossfire_normalize_topic_key "Alter-Ego  Validation!!! Evidence"
  [ "$status" -eq 0 ]
  [ "$output" = "alter-ego-validation-evidence" ]
}

@test "weakness_id is w- plus first 12 hex of SHA-256 family newline topic_key" {
  run crossfire_compute_weakness_id "behavioral" "alter-ego-validation-evidence"
  [ "$status" -eq 0 ]
  expected=$(printf '%s\n%s' "behavioral" "alter-ego-validation-evidence" | sha256sum | awk '{print $1}')
  expected="w-${expected:0:12}"
  [ "$output" = "$expected" ]
}

@test "insert complete record into empty MEMORY.md" {
  wm_copy_fixture "memory-empty.md"
  before=$(wm_snapshot)
  run crossfire_persist_weakness \
    "$MEMORY_MD" \
    behavioral \
    "alter-ego validation evidence" \
    "action,result" \
    "2026-08-16T18:01:02Z" \
    "sess_01" \
    "run_7f3a/q_behavioral_01/0" \
    quote \
    "I just kind of watched the dashboard." \
    "I just kind of watched the dashboard."
  [ "$status" -eq 0 ]
  grep -q "$CROSSFIRE_WEAKNESS_START" "$MEMORY_MD"
  grep -q "$CROSSFIRE_WEAKNESS_END" "$MEMORY_MD"
  grep -q "version: 1" "$MEMORY_MD"
  grep -q "observation_count: 1" "$MEMORY_MD"
  grep -q "first_seen: 2026-08-16T18:01:02Z" "$MEMORY_MD"
  grep -q "last_seen: 2026-08-16T18:01:02Z" "$MEMORY_MD"
  grep -q "favorite prompt" "$MEMORY_MD"
  [ "$(crossfire_weakness_block_count "$MEMORY_MD")" -eq 1 ]
}

@test "reject missing fields leaves original block intact" {
  wm_copy_fixture "memory-three-weaknesses.md"
  before=$(wm_snapshot)
  run crossfire_persist_weakness \
    "$MEMORY_MD" \
    behavioral \
    "new topic" \
    "" \
    "2026-08-16T18:01:02Z" \
    "sess_x" \
    "run_x/q_behavioral_01/0" \
    quote \
    "evidence" \
    "evidence text"
  [ "$status" -ne 0 ]
  [ "$(wm_snapshot)" = "$before" ]
}

@test "merge same topic family keeps first_seen and unions missing_elements" {
  wm_copy_fixture "memory-empty.md"
  crossfire_persist_weakness \
    "$MEMORY_MD" behavioral "Alpha Story" "action,result" \
    "2026-08-10T10:00:00Z" "sess_a" "run_a/q_behavioral_01/0" \
    quote "watched the dashboard" "I watched the dashboard quietly"
  crossfire_persist_weakness \
    "$MEMORY_MD" behavioral "alpha story" "result,situation" \
    "2026-08-16T18:00:00Z" "sess_b" "run_b/q_behavioral_01/0" \
    quote "dashboard quietly" "I watched the dashboard quietly"
  yaml=$(crossfire_weakness_extract_yaml "$MEMORY_MD")
  [[ "$yaml" == *"first_seen: 2026-08-10T10:00:00Z"* ]]
  [[ "$yaml" == *"last_seen: 2026-08-16T18:00:00Z"* ]]
  [[ "$yaml" == *"source_session_id: sess_b"* ]]
  [[ "$yaml" == *"answer_ref: run_b/q_behavioral_01/0"* ]]
  [[ "$yaml" == *"missing_elements: [action,result,situation]"* ]] || [[ "$yaml" == *"missing_elements: [action, result, situation]"* ]]
  grep -q "observation_count: 2" "$MEMORY_MD"
}

@test "dedup identical source_session_id and answer_ref is no-op" {
  wm_copy_fixture "memory-three-weaknesses.md"
  before=$(wm_snapshot)
  run crossfire_persist_weakness \
    "$MEMORY_MD" behavioral "alpha story" "action,result" \
    "2026-08-20T20:00:00Z" "sess_a" "run_a/q_behavioral_01/0" \
    quote "watched the dashboard" "I watched the dashboard"
  [ "$status" -eq 0 ]
  [ "$(wm_snapshot)" = "$before" ]
}

@test "increment observation_count only on new observation" {
  wm_copy_fixture "memory-empty.md"
  crossfire_persist_weakness \
    "$MEMORY_MD" technical "Beta Tradeoff" "tradeoff,verification" \
    "2026-08-11T11:00:00Z" "sess_b" "run_b/q_technical_01/0" \
    quote "skipped verification" "We skipped verification entirely"
  crossfire_persist_weakness \
    "$MEMORY_MD" technical "beta tradeoff" "tradeoff,verification" \
    "2026-08-11T11:00:00Z" "sess_b" "run_b/q_technical_01/0" \
    quote "skipped verification" "We skipped verification entirely"
  grep -q "observation_count: 1" "$MEMORY_MD"
  crossfire_persist_weakness \
    "$MEMORY_MD" technical "beta tradeoff" "tradeoff,verification" \
    "2026-08-12T12:00:00Z" "sess_b2" "run_b2/q_technical_01/0" \
    quote "skipped verification" "We skipped verification entirely"
  grep -q "observation_count: 2" "$MEMORY_MD"
}

@test "evict by last_seen not first_seen when timestamps disagree" {
  wm_copy_fixture "memory-empty.md"
  crossfire_persist_weakness \
    "$MEMORY_MD" behavioral "alpha story" "action,result" \
    "2026-08-01T00:00:00Z" "sess_a" "run_a/q_behavioral_01/0" \
    quote "watched the dashboard" "I watched the dashboard"
  crossfire_persist_weakness \
    "$MEMORY_MD" technical "beta tradeoff" "tradeoff,verification" \
    "2026-08-10T10:00:00Z" "sess_b" "run_b/q_technical_01/0" \
    quote "skipped verification" "We skipped verification entirely"
  crossfire_persist_weakness \
    "$MEMORY_MD" product "gamma metric" "metric,decision" \
    "2026-08-15T12:00:00Z" "sess_c" "run_c/q_product_01/0" \
    byte_offset "0:6" "metric"
  crossfire_persist_weakness \
    "$MEMORY_MD" behavioral "alpha story" "action,result" \
    "2026-08-20T20:00:00Z" "sess_a2" "run_a2/q_behavioral_01/0" \
    quote "watched the dashboard" "I watched the dashboard again"
  crossfire_persist_weakness \
    "$MEMORY_MD" behavioral "delta gap" "action,result" \
    "2026-08-21T21:00:00Z" "sess_d" "run_d/q_behavioral_02/0" \
    quote "new gap" "There was a new gap in the story"
  yaml=$(crossfire_weakness_extract_yaml "$MEMORY_MD")
  grep -q "w-e00e42cd5216" "$MEMORY_MD"
  [[ "$yaml" != *"w-1ee6d6febe17"* ]]
  grep -q "w-b2f32d5ee0be" "$MEMORY_MD"
  [[ "$yaml" == *"topic_key: delta-gap"* ]]
  count=$(grep -c '  - weakness_id:' <<<"$yaml")
  [ "$count" -eq 3 ]
}

@test "evict oldest on fourth topic preserving cap three" {
  wm_copy_fixture "memory-three-weaknesses.md"
  crossfire_persist_weakness \
    "$MEMORY_MD" behavioral "delta gap" "action,result" \
    "2026-08-20T20:00:00Z" "sess_d" "run_d/q_behavioral_02/0" \
    quote "new gap" "There was a new gap in the story"
  yaml=$(crossfire_weakness_extract_yaml "$MEMORY_MD")
  [[ "$yaml" != *"w-e00e42cd5216"* ]]
  grep -q "w-1ee6d6febe17" "$MEMORY_MD"
  grep -q "w-b2f32d5ee0be" "$MEMORY_MD"
  [[ "$yaml" == *"topic_key: delta-gap"* ]]
  count=$(grep -c '  - weakness_id:' <<<"$yaml")
  [ "$count" -eq 3 ]
}

@test "preserve unrelated MEMORY.md content outside delimited block" {
  wm_copy_fixture "memory-three-weaknesses.md"
  crossfire_persist_weakness \
    "$MEMORY_MD" product "new rollout" "metric,decision" \
    "2026-08-20T20:00:00Z" "sess_d" "run_d/q_product_02/0" \
    quote "rollout plan" "Here is the rollout plan"
  grep -q "Session notes preserved outside the weakness block." "$MEMORY_MD"
  grep -q "Footer content must survive updates." "$MEMORY_MD"
}

@test "validation failure leaves original intact for bad family" {
  wm_copy_fixture "memory-three-weaknesses.md"
  before=$(wm_snapshot)
  run crossfire_persist_weakness \
    "$MEMORY_MD" unknown "topic" "action,result" \
    "2026-08-16T18:01:02Z" "sess_x" "run_x/q_behavioral_01/0" \
    quote "x" "x"
  [ "$status" -ne 0 ]
  [ "$(wm_snapshot)" = "$before" ]
}

@test "validation failure leaves original intact for bad answer_ref" {
  wm_copy_fixture "memory-three-weaknesses.md"
  before=$(wm_snapshot)
  run crossfire_persist_weakness \
    "$MEMORY_MD" behavioral "topic" "action,result" \
    "2026-08-16T18:01:02Z" "sess_x" "bad-ref" \
    quote "x" "x"
  [ "$status" -ne 0 ]
  [ "$(wm_snapshot)" = "$before" ]
}

@test "validation failure leaves original intact for non UTC timestamp" {
  wm_copy_fixture "memory-three-weaknesses.md"
  before=$(wm_snapshot)
  run crossfire_persist_weakness \
    "$MEMORY_MD" behavioral "topic" "action,result" \
    "2026-08-16T18:01:02+00:00" "sess_x" "run_x/q_behavioral_01/0" \
    quote "x" "x"
  [ "$status" -ne 0 ]
  [ "$(wm_snapshot)" = "$before" ]
}

@test "validation failure leaves original intact when quote not in answer" {
  wm_copy_fixture "memory-three-weaknesses.md"
  before=$(wm_snapshot)
  run crossfire_persist_weakness \
    "$MEMORY_MD" behavioral "topic" "action,result" \
    "2026-08-16T18:01:02Z" "sess_x" "run_x/q_behavioral_01/0" \
    quote "missing substring" "totally different answer"
  [ "$status" -ne 0 ]
  [ "$(wm_snapshot)" = "$before" ]
}

@test "byte_offset evidence validates UTF-8 byte range" {
  wm_copy_fixture "memory-empty.md"
  run crossfire_persist_weakness \
    "$MEMORY_MD" product "gamma metric" "metric,decision" \
    "2026-08-16T18:01:02Z" "sess_c" "run_c/q_product_01/0" \
    byte_offset "0:6" "metric"
  [ "$status" -eq 0 ]
  grep -q "kind: byte_offset" "$MEMORY_MD"
  grep -q 'value: "0:6"' "$MEMORY_MD" || grep -q 'value: 0:6' "$MEMORY_MD"
}

@test "exactly one CROSSFIRE-WEAKNESSES delimited block after writes" {
  wm_copy_fixture "memory-empty.md"
  crossfire_persist_weakness \
    "$MEMORY_MD" behavioral "one" "action,result" \
    "2026-08-16T18:01:02Z" "sess_1" "run_1/q_behavioral_01/0" \
    quote "one" "one answer"
  crossfire_persist_weakness \
    "$MEMORY_MD" technical "two" "problem,approach" \
    "2026-08-16T18:02:02Z" "sess_2" "run_2/q_technical_01/0" \
    quote "two" "two answer"
  [ "$(crossfire_weakness_block_count "$MEMORY_MD")" -eq 1 ]
  [ "$(grep -c "$CROSSFIRE_WEAKNESS_START" "$MEMORY_MD")" -eq 1 ]
  [ "$(grep -c "$CROSSFIRE_WEAKNESS_END" "$MEMORY_MD")" -eq 1 ]
}

@test "family must be behavioral technical or product" {
  for bad in foo star mixed; do
    wm_copy_fixture "memory-empty.md"
    run crossfire_persist_weakness \
      "$MEMORY_MD" "$bad" "topic" "action,result" \
      "2026-08-16T18:01:02Z" "sess_x" "run_x/q_behavioral_01/0" \
      quote "x" "x"
    [ "$status" -ne 0 ]
  done
}

@test "writes stay under isolated HERMES_HOME not operator profile" {
  wm_copy_fixture "memory-empty.md"
  crossfire_persist_weakness \
    "$MEMORY_MD" behavioral "isolated" "action,result" \
    "2026-08-16T18:01:02Z" "sess_iso" "run_iso/q_behavioral_01/0" \
    quote "isolated" "isolated answer"
  [[ "$MEMORY_MD" == *"/.crossfire/profiles/"* ]]
  [[ "$MEMORY_MD" != *"/.hermes/memories"* ]] || [[ "$MEMORY_MD" == *"/.crossfire/profiles/"* ]]
}

@test "atomic persist renames temp into MEMORY.md with expected content" {
  wm_copy_fixture "memory-empty.md"
  before=$(wm_snapshot)
  target_dir=$(dirname "$MEMORY_MD")
  crossfire_persist_weakness \
    "$MEMORY_MD" behavioral "atomic check" "action,result" \
    "2026-08-16T18:01:02Z" "sess_atomic" "run_atomic/q_behavioral_01/0" \
    quote "atomic check" "this is an atomic check answer"
  [ -f "$MEMORY_MD" ]
  [[ "$(wm_snapshot)" != "$before" ]]
  grep -q "topic_key: atomic-check" "$MEMORY_MD"
  grep -q "sess_atomic" "$MEMORY_MD"
  grep -q "$CROSSFIRE_WEAKNESS_START" "$MEMORY_MD"
  shopt -s nullglob
  temps=("${target_dir}"/MEMORY.md.*)
  leftovers=()
  for t in "${temps[@]:-}"; do
    [[ "$t" == *.lock ]] && continue
    leftovers+=("$t")
  done
  [ "${#leftovers[@]}" -eq 0 ]
  shopt -u nullglob
}
