#!/usr/bin/env bash
set -u
cd /mnt/c/Users/oalan/interview-gee
passed=0; failed=0
ok(){ passed=$((passed+1)); echo "PASS: $1"; }
fail(){ failed=$((failed+1)); echo "FAIL: $1"; }
REPO=/mnt/c/Users/oalan/interview-gee
TEST_ROOT=$(mktemp -d)
export HERMES_HOME="$TEST_ROOT/.crossfire/profiles/test"
mkdir -p "$HERMES_HOME/memories"
source scripts/demo_common.sh
crossfire_require_isolated_hermes_home
export CROSSFIRE_ASSESSOR=stub CROSSFIRE_HERMES_DISCOVERY=0
fp_before=$(crossfire_memory_md_fingerprint "$HERMES_MEMORY_MD")
export CROSSFIRE_DEFER_FINALIZE=1
bash scripts/demo_session_1.sh >/tmp/s1d.out 2>/tmp/s1d.err
run_id2=$(grep RUN_ID /tmp/s1d.out | tail -1 | cut -d= -f2)
fp_mid=$(crossfire_memory_md_fingerprint "$HERMES_MEMORY_MD")
test "$fp_before" = "$fp_mid" && ok fp_unchanged_before_finalize || fail fp_unchanged_before_finalize
export CROSSFIRE_FINALIZE_RUN_ID=$run_id2
unset CROSSFIRE_DEFER_FINALIZE
bash scripts/demo_session_1.sh >/tmp/s1f.out 2>/tmp/s1f.err
fp_after=$(crossfire_memory_md_fingerprint "$HERMES_MEMORY_MD")
test "$fp_before" != "$fp_after" && ok fp_changed_after_finalize || fail fp_changed_after_finalize
if bash scripts/demo_session_1.sh >/tmp/s1.out 2>/tmp/s1.err; then ok harness_exit_0; else fail harness_exit_0; fi
grep -q q_technical_01 /tmp/s1.out && grep -q q_behavioral_01 /tmp/s1.out && grep -q q_product_01 /tmp/s1.out && ok three_questions || fail three_questions
grep -q never-contain /tmp/s1.out && ok fixture_answers || fail fixture_answers
grep -q "session one finalized" /tmp/s1.out && ok finalize_ack || fail finalize_ack
run_id=$(grep RUN_ID /tmp/s1.out | tail -1 | cut -d= -f2)
test -f "$REPO/.crossfire/runs/$run_id/spool/q_behavioral_01.yaml" && ok spool_exists || fail spool_exists
grep -q sess_stub "$HERMES_MEMORY_MD" && ok source_session_id || fail source_session_id
grep -q 'crossfire_session_one_finalize' scripts/demo_session_1.sh && ok done_same_finalize_fn || fail done_same_finalize_fn
blocks=$(grep -c weakness_id "$HERMES_MEMORY_MD" || true)
test "$blocks" -eq 1 && ok one_weakness || fail one_weakness
cmd=$(CROSSFIRE_LOG_CMDLINE_ONLY=1 bash -c "source scripts/demo_common.sh; crossfire_build_assessor_cmdline q_behavioral_01 behavioral q a")
echo "$cmd" | grep -q -- "--toolsets skills" && ok toolsets_skills || fail toolsets_skills
echo "$cmd" | grep -q memory && fail toolsets_no_memory || ok toolsets_no_memory
if env CROSSFIRE_LIVE=1 CROSSFIRE_HERMES_DISCOVERY=0 HERMES_HOME="$HERMES_HOME" bash scripts/demo_session_1.sh >/dev/null 2>/tmp/livefail.txt; then fail live_fail_closed; else grep -Eiq "fail closed|not discoverable" /tmp/livefail.txt && ok live_fail_closed || fail live_fail_closed; fi
echo "passed=$passed failed=$failed"
rm -rf "$TEST_ROOT"
test "$failed" -eq 0
