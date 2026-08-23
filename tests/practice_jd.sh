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
if grep -q 'flavor only' "$REPO_ROOT/scripts/practice_session.sh"; then
  bad "preamble still flavor only"
else
  ok "preamble not flavor only"
fi
if grep -q 'only allowed facts' "$REPO_ROOT/scripts/practice_session.sh"; then
  bad "preamble still only-allowed-facts"
else
  ok "preamble not only-allowed-facts"
fi
if grep -q 'that are not in the session JD' "$REPO_ROOT/scripts/practice_session.sh"; then
  bad "preamble still JD-only invent lock"
else
  ok "preamble invent lock is employer-scoped"
fi
grep -q 'lens on this JD' "$REPO_ROOT/scripts/practice_session.sh" \
  && ok "preamble persona is lens" || bad "preamble persona is lens"
grep -q 'Domain knowledge implied by the persona is allowed' "$REPO_ROOT/scripts/practice_session.sh" \
  && ok "preamble allows persona domain" || bad "preamble allows persona domain"

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

dash_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run_id" \
  bash "$REPO_ROOT/scripts/practice_session.sh" answer "I just kind of watched the dashboard.")
echo "$dash_out" | grep -q 'persist_recommended=true' && ok "dash persist rec" || bad "dash persist rec"

end_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run_id" \
  bash "$REPO_ROOT/scripts/practice_session.sh" end) || {
  bad "end failed: $end_out"
}
echo "$end_out" | grep -q 'report_weak=' && ok "report_weak kv" || bad "report_weak kv: $end_out"
echo "$end_out" | grep -q 'report_strong=' && ok "report_strong kv" || bad "report_strong"
echo "$end_out" | grep -q 'Weak:' && ok "report_text Weak" || bad "report_text Weak: $end_out"
echo "$end_out" | grep -q 'Strong:' && ok "report_text Strong" || bad "report_text Strong"
if grep -q 'q_live_01 practice gap' "$HERMES_HOME/memories/MEMORY.md"; then
  bad "old practice-gap topic"
else
  ok "no q_live practice-gap topic"
fi
if grep -q 'Project Praetor' "$HERMES_HOME/memories/MEMORY.md" || grep -q 'praetor' "$HERMES_HOME/memories/MEMORY.md"; then
  ok "topic uses source label"
else
  bad "topic missing source label"
fi

# S6-T1: with MEMORY.md present, Q1 is JD competency — not the memory-opener drill
if grep -q 'targets those missing elements' "$REPO_ROOT/scripts/practice_session.sh"; then
  bad "start still targets missing elements in -q"
else
  ok "start -q no memory drill wording"
fi

start2=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  CROSSFIRE_JD_KIND=pack \
  CROSSFIRE_JD_SOURCE_ID=praetor \
  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only never-contain' \
  bash "$REPO_ROOT/scripts/practice_session.sh" start) || {
  bad "session two start failed: $start2"
}
echo "$start2" | grep -q 'opening_target_source=MEMORY.md' \
  && ok "session two attribution MEMORY.md" || bad "session two attribution: $start2"
q2=$(printf '%s\n' "$start2" | awk -F= '/^question=/{sub(/^question=/,""); print; exit}')
if printf '%s' "$q2" | grep -qi 'what action did you take and what measurable result'; then
  bad "session two spoken Q is behavioral drill"
else
  ok "session two not behavioral drill"
fi
if printf '%s' "$q2" | grep -qi 'technical gap around'; then
  bad "session two spoken Q is technical drill"
else
  ok "session two not technical drill"
fi
if printf '%s' "$q2" | grep -qi 'product decision gap'; then
  bad "session two spoken Q is product drill"
else
  ok "session two not product drill"
fi
if printf '%s' "$q2" | grep -qi 'Praetor.*advisory\|advisory boundary\|decides not to contain'; then
  ok "session two spoken Q is JD stub"
else
  bad "session two spoken Q not JD stub: $q2"
fi

grep -q 'season follow-ups' "$REPO_ROOT/scripts/practice_session.sh" \
  && ok "answer seasons MEMORY follow-ups" || bad "answer memory follow-up bias missing"
grep -q 'not hesitation about the same' "$REPO_ROOT/scripts/practice_session.sh" \
  && ok "skip new JD not same gap" || bad "skip same-gap guard missing"

echo "practice_jd: passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
