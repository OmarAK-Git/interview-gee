#!/usr/bin/env bash
# Stub practice session: persist path, degraded parse, no K=3 retry.
set -euo pipefail
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

home=$(mktemp -d /tmp/crossfire-practice-sess.XXXXXX)
trap 'rm -rf "$home"' EXIT
export HOME="$home"
mkdir -p "$HOME/.hermes"
export HERMES_HOME="$HOME/.hermes"
export CROSSFIRE_PRACTICE_STUB=1
export CROSSFIRE_RUNS_DIR="$home/runs"
export PATH="/usr/bin:/bin:${PATH:-}"

start_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  CROSSFIRE_JD_KIND=pack \
  CROSSFIRE_JD_SOURCE_ID=praetor \
  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only never-contain' \
  bash "$REPO_ROOT/scripts/practice_session.sh" start) || {
  echo "$start_out"
  bad "start failed"
  echo "practice_session: passed=$pass failed=$fail"
  exit 1
}
echo "$start_out" | grep -q 'event=start' && ok "start event" || bad "start event"
run_id=$(echo "$start_out" | awk -F= '/^run_id=/{print $2; exit}')
[ -n "$run_id" ] && ok "run_id printed" || bad "run_id printed"

# Degraded turn: prose, no YAML — must keep user text and skip assessment
skip_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run_id" \
  CROSSFIRE_STUB_ASSESS_STDOUT="Thanks that is interesting let me think about Praetor in general." \
  bash "$REPO_ROOT/scripts/practice_session.sh" answer "my unique answer about the dashboard never happened in this skip path XYZ123") || {
  bad "degraded answer aborted session"
}
echo "$skip_out" | grep -q 'assessment_status=skipped' && ok "parse failure skipped" || bad "parse failure skipped: $skip_out"
if grep -q 'XYZ123' "$CROSSFIRE_RUNS_DIR/$run_id/transcript/session.txt"; then
  ok "user text kept on skip"
else
  bad "user text dropped on skip"
fi

# Qualifying weakness from dashboard fixture (second answer)
dash_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run_id" \
  bash "$REPO_ROOT/scripts/practice_session.sh" answer "I just kind of watched the dashboard.") || {
  bad "dashboard answer failed: $dash_out"
}
echo "$dash_out" | grep -q 'assessment_status=ok' && ok "dashboard assess ok" || bad "dashboard assess: $dash_out"
echo "$dash_out" | grep -q 'persist_recommended=true' && ok "persist recommended" || bad "persist recommended"

end_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run_id" \
  bash "$REPO_ROOT/scripts/practice_session.sh" end) || {
  bad "end failed: $end_out"
}
echo "$end_out" | grep -q 'ack=ok' && ok "end ack" || bad "end ack: $end_out"
if grep -q 'CROSSFIRE-WEAKNESSES:START' "$HERMES_HOME/memories/MEMORY.md"; then
  ok "weakness persisted to Monday-shaped home"
else
  bad "MEMORY.md missing weakness block"
fi

start2=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  CROSSFIRE_JD_KIND=pack \
  CROSSFIRE_JD_SOURCE_ID=praetor \
  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only never-contain' \
  bash "$REPO_ROOT/scripts/practice_session.sh" start)
echo "$start2" | grep -q 'opening_target_source=MEMORY.md' && ok "session two memory opener" || bad "session two opener: $start2"

# Strong answer should not require retry / not force persist
start3=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  CROSSFIRE_JD_KIND=pack \
  CROSSFIRE_JD_SOURCE_ID=praetor \
  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only never-contain' \
  bash "$REPO_ROOT/scripts/practice_session.sh" start) || true
run2=$(printf '%s\n' "$start3" | awk -F= '/^run_id=/{print $2; exit}')
strong=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run2" \
  bash "$REPO_ROOT/scripts/practice_session.sh" answer "Praetor never-contain list plus hash-chained ledger verification.")
echo "$strong" | grep -q 'persist_recommended=false' && ok "strong answer no weakness" || bad "strong: $strong"

echo "practice_session: passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
