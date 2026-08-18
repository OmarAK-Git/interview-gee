#!/usr/bin/env bash
# S3-T10 bash-equivalent assertions (mirrors tests/demo_e2e.bats)
set -u
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
cd "$REPO_ROOT"
passed=0
failed=0

ok() { passed=$((passed + 1)); echo "PASS: $1"; }
fail() { failed=$((failed + 1)); echo "FAIL: $1"; }

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/crossfire-e2e-bash.XXXXXX")"
export HERMES_HOME="${TEST_ROOT}/.crossfire/profiles/test"
export CROSSFIRE_RUNS_DIR="${TEST_ROOT}/runs"
export CROSSFIRE_CANDIDATE_SKILLS_ROOT="${TEST_ROOT}/.crossfire/candidate-skills"
export CROSSFIRE_ASSESSOR=stub CROSSFIRE_OPENER=stub CROSSFIRE_RISK_BEAT=stub
export CROSSFIRE_HERMES_DISCOVERY=0 CROSSFIRE_STUB_SESSION_ID=sess_e2e_bash
DEMO_SCRIPT="$REPO_ROOT/scripts/demo.sh"
DEMO_COMMON="$REPO_ROOT/scripts/demo_common.sh"
MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"

cleanup() { rm -rf "$TEST_ROOT"; }
trap cleanup EXIT

mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills" "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}"

e2e_env() {
  env HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
    CROSSFIRE_CANDIDATE_SKILLS_ROOT="$CROSSFIRE_CANDIDATE_SKILLS_ROOT" \
    CROSSFIRE_ASSESSOR=stub CROSSFIRE_OPENER=stub CROSSFIRE_RISK_BEAT=stub \
    CROSSFIRE_HERMES_DISCOVERY=0 CROSSFIRE_STUB_SESSION_ID=sess_e2e_bash \
    "$@"
}

# demo.sh exists and composes session scripts
if [ -f "$DEMO_SCRIPT" ] && grep -q 'demo_session_1.sh' "$DEMO_SCRIPT" && \
   grep -q 'demo_session_2.sh' "$DEMO_SCRIPT" && grep -q 'demo_risk_beat.sh' "$DEMO_SCRIPT"; then
  ok demo_script_exists
else
  fail demo_script_exists
fi

# isolation fail-closed + recovery
iso_out=$(bash -c "
  export HERMES_HOME='/home/fish/.hermes'
  export REAL_HERMES_WSL='/home/fish/.hermes'
  export REAL_HERMES_WIN=''
  bash '$DEMO_SCRIPT'
" 2>&1) || true
if grep -qE 'HERMES_HOME points at real profile|DEMO FAIL' <<<"$iso_out" && grep -q 'Recovery:' <<<"$iso_out"; then
  ok isolation_recovery
else
  fail isolation_recovery
fi

# demo_prepare resets disposable profile
mkdir -p "${HERMES_HOME}/skills/stray" "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}/unverified-behavioral-followup"
echo stray >"${HERMES_HOME}/skills/stray/SKILL.md"
echo old >"$MEMORY_MD"
echo staged >"${CROSSFIRE_CANDIDATE_SKILLS_ROOT}/unverified-behavioral-followup/SKILL.md"
prep_out=$(e2e_env bash "$DEMO_SCRIPT" --prepare 2>&1) || true
prep_ok=1
grep -q 'demo_prepare' <<<"$prep_out" || prep_ok=0
grep -q 'Personal Memory' "$MEMORY_MD" || prep_ok=0
grep -q 'old' "$MEMORY_MD" && prep_ok=0
[ ! -f "${HERMES_HOME}/skills/stray/SKILL.md" ] || prep_ok=0
[ ! -f "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}/unverified-behavioral-followup/SKILL.md" ] || prep_ok=0
[ "$prep_ok" -eq 1 ] && ok demo_prepare_reset || fail demo_prepare_reset

# full stub smoke
full_out=$(e2e_env bash "$DEMO_SCRIPT" 2>&1) || true
full_ok=1
for needle in 'preflight:' 'CROSSFIRE q_technical_01' 'session one finalized' \
  'artifact_evidence:' 'opening_target_source=MEMORY.md' 'Question:' \
  'UNVERIFIED LEARNING RISK DEMO' 'Follow-up:' 'demo: complete'; do
  grep -q "$needle" <<<"$full_out" || full_ok=0
done
[ "$full_ok" -eq 1 ] && ok full_sequence_smoke || fail full_sequence_smoke

# distinct IDs
s1_pid=$(grep '^CROSSFIRE_SESSION_ONE_PID=' <<<"$full_out" | head -1 | cut -d= -f2)
s2_pid=$(grep '^CROSSFIRE_SESSION_TWO_PID=' <<<"$full_out" | head -1 | cut -d= -f2)
if [ -n "$s1_pid" ] && [ -n "$s2_pid" ] && [ "$s1_pid" != "$s2_pid" ] && \
   grep -q 'session_identifiability: distinct' <<<"$full_out"; then
  ok distinct_ids
else
  fail distinct_ids
fi

# layer labels
if grep -q 'layer_attribution:' <<<"$full_out" && \
   grep -q 'opening_target=MEMORY.md' <<<"$full_out" && \
   grep -q 'opener_wording=stable_interviewer_skill' <<<"$full_out" && \
   grep -q 'candidate_excluded_from_opener' <<<"$full_out"; then
  ok layer_labels
else
  fail layer_labels
fi

# bad answer >=2 missing
run_id=$(grep '^CROSSFIRE_RUN_ID=' <<<"$full_out" | tail -1 | cut -d= -f2)
spool="${CROSSFIRE_RUNS_DIR}/${run_id}/spool/q_behavioral_01.yaml"
if grep -q 'I just kind of watched the dashboard' <<<"$full_out" && \
   [ -f "$spool" ] && grep -qE 'missing_elements: \[(action, result|action,result)\]' "$spool"; then
  ok bad_answer_gaps
else
  fail bad_answer_gaps
fi

# early failure recovery (invalid disposable path)
fail_out=$(env HERMES_HOME="${TEST_ROOT}/not-crossfire/profile" \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" bash "$DEMO_SCRIPT" 2>&1) || true
if grep -q 'Recovery:' <<<"$fail_out" && grep -q 'DEMO FAIL' <<<"$fail_out"; then
  ok failure_recovery
else
  fail failure_recovery
fi

# skip risk beat
skip_out=$(e2e_env env CROSSFIRE_SKIP_RISK_BEAT=1 bash "$DEMO_SCRIPT" 2>&1) || true
if grep -q 'demo: complete' <<<"$skip_out" && grep -q 'Question:' <<<"$skip_out" && \
   ! grep -q 'UNVERIFIED LEARNING RISK DEMO' <<<"$skip_out"; then
  ok skip_risk_beat
else
  fail skip_risk_beat
fi

echo "passed=$passed failed=$failed"
[ "$failed" -eq 0 ]
