#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

home=$(mktemp -d /tmp/crossfire-practice-jd.XXXXXX)
trap 'rm -rf "$home"' EXIT
export HOME="$home"
mkdir -p "$HOME/.hermes"
export HERMES_HOME="$HOME/.hermes"
export CROSSFIRE_PRACTICE_STUB=1
export CROSSFIRE_RUNS_DIR="$home/runs"

if HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  bash "$REPO_ROOT/scripts/practice_session.sh" start >/tmp/jd-start.out 2>/tmp/jd-start.err; then
  bad "start without JD should fail"
else
  ok "start without JD fail-closed"
fi

start_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  CROSSFIRE_JD_KIND=pack \
  CROSSFIRE_JD_SOURCE_ID=praetor \
  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only' \
  CROSSFIRE_TEMPERATURE=2 \
  bash "$REPO_ROOT/scripts/practice_session.sh" start) || {
  bad "start with pack failed"
  echo "$start_out"
  echo "practice_jd: passed=$pass failed=$fail"
  exit 1
}
echo "$start_out" | grep -q 'source_id=praetor' && ok "source_id printed" || bad "source_id printed"
echo "$start_out" | grep -q 'temperature=2' && ok "temperature printed" || bad "temperature printed"

run_id=$(echo "$start_out" | awk -F= '/^run_id=/{print $2; exit}')

grep -q 'crossfire_practice_interviewer_preamble' "$REPO_ROOT/scripts/practice_session.sh" \
  && ok "preamble helper exists" || bad "preamble helper exists"
grep -q 'Practice session JD' "$REPO_ROOT/scripts/practice_session.sh" \
  && ok "prompt names session JD" || bad "prompt names session JD"

skip_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run_id" \
  CROSSFIRE_TEMPERATURE=4 \
  bash "$REPO_ROOT/scripts/practice_session.sh" skip) || {
  bad "skip command failed: $skip_out"
}
echo "$skip_out" | grep -q 'skipped=true' && ok "skip kv" || bad "skip kv: $skip_out"
echo "$skip_out" | grep -q 'persist_recommended=false' && ok "skip no persist" || bad "skip persist"
spool_count=$(find "$CROSSFIRE_RUNS_DIR/$run_id/spool" -name '*.yaml' 2>/dev/null | wc -l | tr -d ' ')
[ "$spool_count" = "0" ] && ok "skip wrote no spool" || bad "skip wrote spool ($spool_count)"
grep -q 'CROSSFIRE_TEMPERATURE=4' "$CROSSFIRE_RUNS_DIR/$run_id/practice.state" \
  && ok "skip saved temperature 4" || bad "skip saved temperature 4"

echo "practice_jd: passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
