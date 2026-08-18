#!/usr/bin/env bash
# S2-T5 bash-equivalent assertions (mirrors tests/demo_session_1.bats)
set -u
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
cd "$REPO_ROOT"
passed=0
failed=0

ok() { passed=$((passed + 1)); echo "PASS: $1"; }
fail() { failed=$((failed + 1)); echo "FAIL: $1"; }

TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/crossfire-s1.XXXXXX")
export HERMES_HOME="${TEST_ROOT}/.crossfire/profiles/test"
export CROSSFIRE_RUNS_DIR="${TEST_ROOT}/runs"
mkdir -p "${HERMES_HOME}/memories"
export CROSSFIRE_ASSESSOR=stub
export CROSSFIRE_HERMES_DISCOVERY=0

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/demo_common.sh"
crossfire_require_isolated_hermes_home

# isolation fail-closed
if env HERMES_HOME='/home/fish/.hermes' REAL_HERMES_WSL='/home/fish/.hermes' REAL_HERMES_WIN='' \
  bash -c "source '$REPO_ROOT/scripts/demo_common.sh'; crossfire_require_isolated_hermes_home" \
  >/dev/null 2>&1; then
  fail isolation_real_home
else
  ok isolation_real_home
fi

fp_before=$(crossfire_memory_md_fingerprint "$HERMES_MEMORY_MD")

export CROSSFIRE_DEFER_FINALIZE=1
if bash "$REPO_ROOT/scripts/demo_session_1.sh" >/tmp/s1d.out 2>/tmp/s1d.err; then
  ok defer_finalize_exit
else
  fail defer_finalize_exit
fi

run_id=$(grep '^CROSSFIRE_RUN_ID=' /tmp/s1d.out | tail -1 | cut -d= -f2)
spool_dir="${CROSSFIRE_RUNS_DIR}/${run_id}/spool"
if [ -f "${spool_dir}/q_technical_01.yaml" ] && \
   [ -f "${spool_dir}/q_behavioral_01.yaml" ] && \
   [ -f "${spool_dir}/q_product_01.yaml" ]; then
  ok spool_before_finalize
else
  fail spool_before_finalize
fi

fp_mid=$(crossfire_memory_md_fingerprint "$HERMES_MEMORY_MD")
if [ "$fp_before" = "$fp_mid" ]; then
  ok fp_unchanged_before_finalize
else
  fail fp_unchanged_before_finalize
fi

export CROSSFIRE_FINALIZE_RUN_ID="$run_id"
unset CROSSFIRE_DEFER_FINALIZE
if bash "$REPO_ROOT/scripts/demo_session_1.sh" >/tmp/s1f.out 2>/tmp/s1f.err; then
  ok manual_finalize_exit
else
  fail manual_finalize_exit
fi
grep -q 'session one finalized' /tmp/s1f.out && ok manual_finalize_ack || fail manual_finalize_ack

fp_after=$(crossfire_memory_md_fingerprint "$HERMES_MEMORY_MD")
if [ "$fp_before" != "$fp_after" ] && [ -f "$HERMES_MEMORY_MD" ]; then
  ok fp_changed_after_finalize
else
  fail fp_changed_after_finalize
fi

unset CROSSFIRE_FINALIZE_RUN_ID
if bash "$REPO_ROOT/scripts/demo_session_1.sh" >/tmp/s1.out 2>/tmp/s1.err; then
  ok harness_exit_0
else
  fail harness_exit_0
fi

if grep -q q_technical_01 /tmp/s1.out && grep -q q_behavioral_01 /tmp/s1.out && grep -q q_product_01 /tmp/s1.out; then
  pos1=$(grep -n 'q_technical_01' /tmp/s1.out | head -1 | cut -d: -f1)
  pos2=$(grep -n 'q_behavioral_01' /tmp/s1.out | head -1 | cut -d: -f1)
  pos3=$(grep -n 'q_product_01' /tmp/s1.out | head -1 | cut -d: -f1)
  if [ "$pos1" -lt "$pos2" ] && [ "$pos2" -lt "$pos3" ]; then
    ok three_questions_order
  else
    fail three_questions_order
  fi
else
  fail three_questions_order
fi

grep -q 'never-contain\|hash-chained' /tmp/s1.out && \
grep -q 'I just kind of watched the dashboard' /tmp/s1.out && \
grep -q 'false-freeze rate' /tmp/s1.out && ok fixture_answers || fail fixture_answers

grep -q 'session one finalized' /tmp/s1.out && ok auto_finalize_ack || fail auto_finalize_ack

run_id=$(grep '^CROSSFIRE_RUN_ID=' /tmp/s1.out | tail -1 | cut -d= -f2)
if [ -n "$run_id" ] && [ -d "${CROSSFIRE_RUNS_DIR}/${run_id}/spool" ]; then
  ok spool_under_test_root
else
  fail spool_under_test_root
fi

grep -q 'sess_stub' "$HERMES_MEMORY_MD" && ok source_session_id || fail source_session_id
blocks=$(grep -c 'weakness_id:' "$HERMES_MEMORY_MD" 2>/dev/null || echo 0)
if [ "$blocks" -eq 1 ] && grep -q behavioral "$HERMES_MEMORY_MD"; then
  ok one_behavioral_weakness
else
  fail one_behavioral_weakness
fi

grep -q 'never-contain' "$HERMES_MEMORY_MD" && fail strong_technical_not_persisted || ok strong_technical_not_persisted
grep -q 'false-freeze rate' "$HERMES_MEMORY_MD" && fail strong_product_not_persisted || ok strong_product_not_persisted

if grep -qE '[Pp]lease.*confirm|[Cc]onfirm.*persist' /tmp/s1.out; then
  fail no_confirm_prompt
else
  ok no_confirm_prompt
fi

count=$(grep -c 'crossfire_session_one_finalize' "$REPO_ROOT/scripts/demo_session_1.sh" || echo 0)
[ "$count" -ge 2 ] && ok done_same_finalize_fn || fail done_same_finalize_fn

# live-shaped YAML with preamble, no submitted_answer in raw assessor output
live_run_id="live_shape_bash"
live_spool="${CROSSFIRE_RUNS_DIR}/${live_run_id}/spool"
mkdir -p "$live_spool"
live_raw='The user wants me to assess an interview Q+A pair.
family: this is a behavioral question about STAR elements

family: behavioral
missing_elements: [action, result]
evidence:
  kind: quote
  value: "I just kind of watched the dashboard."
persist_recommended: true
question_id: q_behavioral_01
answer_ref: <run_id>/q_behavioral_01/0'
live_proposal=$(crossfire_normalize_live_proposal "$live_raw" "q_behavioral_01" \
  "I just kind of watched the dashboard." "$live_run_id" "sess_live_bash")
if printf '%s\n' "$live_proposal" | grep -q '^submitted_answer:'; then
  ok live_yaml_extract_overlay
else
  fail live_yaml_extract_overlay
fi
printf '%s\n' "$live_proposal" >"${live_spool}/q_behavioral_01.yaml"
rm -f "$HERMES_MEMORY_MD"
export CROSSFIRE_FINALIZE_RUN_ID="$live_run_id"
unset CROSSFIRE_DEFER_FINALIZE
if bash "$REPO_ROOT/scripts/demo_session_1.sh" >/tmp/s1live.out 2>/tmp/s1live.err; then
  grep -q 'session one finalized' /tmp/s1live.out && \
  grep -q 'I just kind of watched the dashboard' "$HERMES_MEMORY_MD" && \
  ok live_shaped_finalize_persist || fail live_shaped_finalize_persist
else
  fail live_shaped_finalize_persist
fi
unset CROSSFIRE_FINALIZE_RUN_ID

cmd=$(env HERMES_HOME="$HERMES_HOME" CROSSFIRE_LOG_CMDLINE_ONLY=1 bash -c \
  "source '$REPO_ROOT/scripts/demo_common.sh'; crossfire_build_assessor_cmdline q_behavioral_01 behavioral q a")
echo "$cmd" | grep -q -- '--toolsets skills' && ok toolsets_skills || fail toolsets_skills
echo "$cmd" | grep -qE 'toolsets.*memory' && fail toolsets_no_memory || ok toolsets_no_memory

grep -q 'discover_hermes_bin' "$REPO_ROOT/scripts/demo_common.sh" && \
grep -q 'crossfire_discover_hermes_or_fail_closed' "$REPO_ROOT/scripts/demo_session_1.sh" && \
ok product_uses_discover || fail product_uses_discover

if env CROSSFIRE_LIVE=1 CROSSFIRE_HERMES_DISCOVERY=0 HERMES_HOME="$HERMES_HOME" \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  bash "$REPO_ROOT/scripts/demo_session_1.sh" >/dev/null 2>/tmp/livefail.txt; then
  fail live_fail_closed
else
  grep -Eiq 'PREFLIGHT FAIL|not discoverable' /tmp/livefail.txt && ok live_fail_closed || fail live_fail_closed
fi

grep -q 'Skip is not proof' "$REPO_ROOT/skills/crossfire-interviewer/SKILL.md" && \
grep -q 'fail closed' "$REPO_ROOT/skills/crossfire-interviewer/SKILL.md" && \
ok skill_live_notes || fail skill_live_notes

echo "passed=$passed failed=$failed"
rm -rf "$TEST_ROOT"
exit "$failed"
