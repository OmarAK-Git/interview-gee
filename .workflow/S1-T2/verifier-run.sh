#!/usr/bin/env bash
# Skeptic-verifier independent checks for S1-T2 (do not use as product code).
set -euo pipefail
REPO="$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd)"
TMPROOT="$REPO/.workflow/S1-T2/verifier-tmp-$$"
mkdir -p "$TMPROOT"
export HERMES_HOME="$TMPROOT/.crossfire/profiles/verify"
mkdir -p "$HERMES_HOME/memories"
MEMORY_MD="$HERMES_HOME/memories/MEMORY.md"
# shellcheck disable=SC1091
source "$REPO/scripts/weakness_memory.sh"

PASS=0
FAIL=0
ok() { echo "PASS: $*"; PASS=$((PASS + 1)); }
bad() { echo "FAIL: $*"; FAIL=$((FAIL + 1)); }

echo "REPO=$REPO"
echo "HERMES_HOME=$HERMES_HOME"
echo "MEMORY_MD=$MEMORY_MD"

# 1 INSERT
cp "$REPO/tests/fixtures/memory-empty.md" "$MEMORY_MD"
if crossfire_persist_weakness \
  "$MEMORY_MD" behavioral "alter-ego validation evidence" "action,result" \
  "2026-08-16T18:01:02Z" "sess_01" "run_7f3a/q_behavioral_01/0" \
  quote "I just kind of watched the dashboard." \
  "I just kind of watched the dashboard."; then
  if grep -q "CROSSFIRE-WEAKNESSES:START" "$MEMORY_MD" \
    && grep -q "observation_count: 1" "$MEMORY_MD" \
    && grep -q "favorite prompt" "$MEMORY_MD"; then
    ok "insert"
  else
    bad "insert missing expected content"
    cat "$MEMORY_MD"
  fi
else
  bad "insert returned non-zero"
fi

# 2 REJECT
cp "$REPO/tests/fixtures/memory-three-weaknesses.md" "$MEMORY_MD"
BEFORE=$(cat "$MEMORY_MD")
set +e
crossfire_persist_weakness \
  "$MEMORY_MD" behavioral "new topic" "" \
  "2026-08-16T18:01:02Z" "sess_x" "run_x/q_behavioral_01/0" \
  quote "evidence" "evidence text"
rc=$?
set -e
AFTER=$(cat "$MEMORY_MD")
if [ "$rc" -ne 0 ] && [ "$BEFORE" = "$AFTER" ]; then
  ok "reject intact"
else
  bad "reject rc=$rc or mutated"
fi

# 3 MERGE
cp "$REPO/tests/fixtures/memory-empty.md" "$MEMORY_MD"
crossfire_persist_weakness \
  "$MEMORY_MD" behavioral "Alpha Story" "action,result" \
  "2026-08-10T10:00:00Z" "sess_a" "run_a/q_behavioral_01/0" \
  quote "watched the dashboard" "I watched the dashboard quietly"
crossfire_persist_weakness \
  "$MEMORY_MD" behavioral "alpha story" "result,situation" \
  "2026-08-16T18:00:00Z" "sess_b" "run_b/q_behavioral_01/0" \
  quote "dashboard quietly" "I watched the dashboard quietly"
YAML=$(crossfire_weakness_extract_yaml "$MEMORY_MD")
if echo "$YAML" | grep -q "first_seen: 2026-08-10T10:00:00Z" \
  && echo "$YAML" | grep -q "last_seen: 2026-08-16T18:00:00Z" \
  && echo "$YAML" | grep -q "source_session_id: sess_b" \
  && echo "$YAML" | grep -q "observation_count: 2" \
  && (echo "$YAML" | grep -q 'missing_elements: \[action,result,situation\]' \
    || echo "$YAML" | grep -q 'missing_elements: \[action, result, situation\]'); then
  ok "merge"
else
  bad "merge fields wrong"
  echo "$YAML"
fi

# 4 DEDUP
cp "$REPO/tests/fixtures/memory-three-weaknesses.md" "$MEMORY_MD"
BEFORE=$(cat "$MEMORY_MD")
crossfire_persist_weakness \
  "$MEMORY_MD" behavioral "alpha story" "action,result" \
  "2026-08-20T20:00:00Z" "sess_a" "run_a/q_behavioral_01/0" \
  quote "watched the dashboard" "I watched the dashboard"
AFTER=$(cat "$MEMORY_MD")
if [ "$BEFORE" = "$AFTER" ]; then ok "dedup"; else bad "dedup mutated"; fi

# 5 EVICT by last_seen (not first_seen)
cp "$REPO/tests/fixtures/memory-empty.md" "$MEMORY_MD"
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
YAML=$(crossfire_weakness_extract_yaml "$MEMORY_MD")
COUNT=$(grep -c '  - weakness_id:' <<<"$YAML" || true)
if echo "$YAML" | grep -q "w-e00e42cd5216" \
  && ! echo "$YAML" | grep -q "w-1ee6d6febe17" \
  && echo "$YAML" | grep -q "w-b2f32d5ee0be" \
  && echo "$YAML" | grep -q "topic_key: delta-gap" \
  && [ "$COUNT" -eq 3 ]; then
  ok "evict last_seen"
else
  bad "evict last_seen unexpected count=$COUNT"
  echo "$YAML"
fi

# 6 PRESERVE
cp "$REPO/tests/fixtures/memory-three-weaknesses.md" "$MEMORY_MD"
crossfire_persist_weakness \
  "$MEMORY_MD" product "new rollout" "metric,decision" \
  "2026-08-20T20:00:00Z" "sess_d" "run_d/q_product_02/0" \
  quote "rollout plan" "Here is the rollout plan"
if grep -q "Session notes preserved outside the weakness block." "$MEMORY_MD" \
  && grep -q "Footer content must survive updates." "$MEMORY_MD"; then
  ok "preserve"
else
  bad "preserve lost content"
  cat "$MEMORY_MD"
fi

# Schema helpers
TK=$(crossfire_normalize_topic_key "Alter-Ego  Validation!!! Evidence")
WID=$(crossfire_compute_weakness_id "behavioral" "alter-ego-validation-evidence")
EXP=$(printf '%s\n%s' "behavioral" "alter-ego-validation-evidence" | sha256sum | awk '{print $1}')
EXP="w-${EXP:0:12}"
if [ "$TK" = "alter-ego-validation-evidence" ] && [ "$WID" = "$EXP" ]; then
  ok "schema topic_key+weakness_id"
else
  bad "schema helpers TK=$TK WID=$WID EXP=$EXP"
fi

# Isolation
if [[ "$HERMES_HOME" == *"/.crossfire/profiles/"* ]] && [[ "$MEMORY_MD" != *"/.hermes/memories"* || "$MEMORY_MD" == *"/.crossfire/"* ]]; then
  ok "isolation path"
else
  bad "isolation path suspect"
fi

# Extra validation failures leave intact
cp "$REPO/tests/fixtures/memory-three-weaknesses.md" "$MEMORY_MD"
BEFORE=$(cat "$MEMORY_MD")
for case in family answer_ref ts quote; do
  set +e
  case "$case" in
    family)
      crossfire_persist_weakness "$MEMORY_MD" unknown "topic" "action,result" \
        "2026-08-16T18:01:02Z" "sess_x" "run_x/q_behavioral_01/0" quote "x" "x"
      ;;
    answer_ref)
      crossfire_persist_weakness "$MEMORY_MD" behavioral "topic" "action,result" \
        "2026-08-16T18:01:02Z" "sess_x" "bad-ref" quote "x" "x"
      ;;
    ts)
      crossfire_persist_weakness "$MEMORY_MD" behavioral "topic" "action,result" \
        "2026-08-16T18:01:02+00:00" "sess_x" "run_x/q_behavioral_01/0" quote "x" "x"
      ;;
    quote)
      crossfire_persist_weakness "$MEMORY_MD" behavioral "topic" "action,result" \
        "2026-08-16T18:01:02Z" "sess_x" "run_x/q_behavioral_01/0" \
        quote "missing substring" "totally different answer"
      ;;
  esac
  rc=$?
  set -e
  AFTER=$(cat "$MEMORY_MD")
  if [ "$rc" -ne 0 ] && [ "$BEFORE" = "$AFTER" ]; then
    ok "fail-safe $case"
  else
    bad "fail-safe $case rc=$rc"
  fi
done

# Cap-3 from three-fixture
cp "$REPO/tests/fixtures/memory-three-weaknesses.md" "$MEMORY_MD"
crossfire_persist_weakness \
  "$MEMORY_MD" behavioral "delta gap" "action,result" \
  "2026-08-20T20:00:00Z" "sess_d" "run_d/q_behavioral_02/0" \
  quote "new gap" "There was a new gap in the story"
YAML=$(crossfire_weakness_extract_yaml "$MEMORY_MD")
COUNT=$(grep -c '  - weakness_id:' <<<"$YAML" || true)
if ! echo "$YAML" | grep -q "w-e00e42cd5216" \
  && echo "$YAML" | grep -q "w-1ee6d6febe17" \
  && echo "$YAML" | grep -q "w-b2f32d5ee0be" \
  && echo "$YAML" | grep -q "topic_key: delta-gap" \
  && [ "$COUNT" -eq 3 ]; then
  ok "cap3 evict oldest last_seen from fixture"
else
  bad "cap3 fixture eviction"
  echo "$YAML"
fi

echo "SUMMARY pass=$PASS fail=$FAIL"
rm -rf "$TMPROOT"
exit "$FAIL"
