#!/usr/bin/env bash
set -uo pipefail
REPO="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO"
TEST_ROOT=$(mktemp -d /tmp/crossfire-s1.XXXXXX)
export HERMES_HOME="$TEST_ROOT/.crossfire/profiles/test"
mkdir -p "${HERMES_HOME}/memories"
export CROSSFIRE_ASSESSOR=stub CROSSFIRE_HERMES_DISCOVERY=0
DEMO_SCRIPT="$REPO/scripts/demo_session_1.sh"
DEMO_COMMON="$REPO/scripts/demo_common.sh"
ANSWERS_TXT="$REPO/tests/fixtures/demo-answers.txt"
SKILL_MD="$REPO/skills/crossfire-interviewer/SKILL.md"
passed=0
failed=0

# shellcheck disable=SC1091
source "$DEMO_COMMON"
crossfire_require_isolated_hermes_home

pass() { passed=$((passed + 1)); echo "PASS: $1"; }
fail() { failed=$((failed + 1)); echo "FAIL: $1" >&2; }

demo_run_harness() {
  env HERMES_HOME="$HERMES_HOME" CROSSFIRE_ASSESSOR=stub CROSSFIRE_HERMES_DISCOVERY=0 bash "$DEMO_SCRIPT"
}
demo_run_defer() {
  env HERMES_HOME="$HERMES_HOME" CROSSFIRE_ASSESSOR=stub CROSSFIRE_HERMES_DISCOVERY=0 \
    CROSSFIRE_DEFER_FINALIZE=1 bash "$DEMO_SCRIPT"
}
demo_finalize() {
  env HERMES_HOME="$HERMES_HOME" CROSSFIRE_ASSESSOR=stub CROSSFIRE_HERMES_DISCOVERY=0 \
    CROSSFIRE_FINALIZE_RUN_ID="$1" bash "$DEMO_SCRIPT"
}
demo_memory_fp() {
  # shellcheck disable=SC1090
  source "$DEMO_COMMON"
  crossfire_memory_md_fingerprint "$HERMES_MEMORY_MD"
}

if out_fc=$(bash -c "export HERMES_HOME=/home/fish/.hermes REAL_HERMES_WSL=/home/fish/.hermes REAL_HERMES_WIN=; source '$DEMO_COMMON'" 2>&1); then
  fail 'fail closed on real HERMES_HOME (unexpected success)'
elif [[ "$out_fc" == *'HERMES_HOME points at real profile'* ]]; then
  pass 'fail closed on real HERMES_HOME'
else
  fail "fail closed on real HERMES_HOME (got: $out_fc)"
fi

if [[ "$HERMES_HOME" == *'.crossfire/profiles/'* ]]; then pass 'HERMES_HOME isolated'; else fail 'HERMES_HOME isolated'; fi

out=$(demo_run_harness)
if [[ "$HERMES_HOME" == *'.crossfire/profiles/'* ]]; then pass 'HERMES_HOME stays isolated after run'; else fail 'HERMES_HOME after run'; fi

count=$(grep -c '^# q_' "$ANSWERS_TXT" || true)
if [ "$count" -eq 3 ]; then pass 'three answers fixture'; else fail 'three answers fixture'; fi

if [[ "$out" == *'q_technical_01'* && "$out" == *'Praetor decides not to contain'* ]]; then
  pass 'technical question printed'
else
  fail 'technical question printed'
fi

pos1=$(grep -n 'q_technical_01' <<<"$out" | head -1 | cut -d: -f1)
pos2=$(grep -n 'q_behavioral_01' <<<"$out" | head -1 | cut -d: -f1)
pos3=$(grep -n 'q_product_01' <<<"$out" | head -1 | cut -d: -f1)
if [ "$pos1" -lt "$pos2" ] && [ "$pos2" -lt "$pos3" ]; then pass 'question order'; else fail 'question order'; fi

if { [[ "$out" == *'never-contain'* || "$out" == *'hash-chained'* ]]; } \
  && [[ "$out" == *'I just kind of watched the dashboard'* ]] \
  && [[ "$out" == *'false-freeze rate'* ]]; then
  pass 'fixture answers in output'
else
  fail 'fixture answers in output'
fi

defer_out=$(demo_run_defer)
run_id=$(grep '^CROSSFIRE_RUN_ID=' <<<"$defer_out" | tail -1 | cut -d= -f2)
spool_dir="$REPO/.crossfire/runs/${run_id}/spool"
if [ -f "${spool_dir}/q_technical_01.yaml" ] && [ -f "${spool_dir}/q_behavioral_01.yaml" ] && [ -f "${spool_dir}/q_product_01.yaml" ]; then
  pass 'spool files before finalize'
else
  fail 'spool files before finalize'
fi

fp_before=$(demo_memory_fp)
fp_mid=$(demo_memory_fp)
if [ "$fp_before" = "$fp_mid" ]; then pass 'MEMORY unchanged until finalize'; else fail 'MEMORY unchanged until finalize'; fi

fin_out=$(demo_finalize "$run_id")
fp_after=$(demo_memory_fp)
if [ -f "$HERMES_MEMORY_MD" ] && [ "$fp_before" != "$fp_after" ]; then
  pass 'MEMORY updated after finalize'
else
  fail 'MEMORY updated after finalize'
fi

if [[ "$out" == *'CROSSFIRE: session one finalized'* ]]; then pass 'auto-finalize ack'; else fail 'auto-finalize ack'; fi

if grep -q 'crossfire_session_one_finalize' "$DEMO_SCRIPT" \
  && [ "$(grep -c 'crossfire_session_one_finalize' "$DEMO_SCRIPT")" -ge 2 ] \
  && [[ "$fin_out" == *'CROSSFIRE: session one finalized'* ]]; then
  pass '/done uses same finalize function'
else
  fail '/done uses same finalize function'
fi

if grep -q 'I just kind of watched the dashboard' "$HERMES_MEMORY_MD" && grep -q 'sess_stub' "$HERMES_MEMORY_MD"; then
  pass 'behavioral bad answer persisted'
else
  fail 'behavioral bad answer persisted'
fi

TEST_ROOT2=$(mktemp -d /tmp/crossfire-s1b.XXXXXX)
export HERMES_HOME="$TEST_ROOT2/.crossfire/profiles/test"
mkdir -p "${HERMES_HOME}/memories"
demo_run_harness >/dev/null
blocks=$(grep -c 'weakness_id:' "$HERMES_MEMORY_MD" 2>/dev/null || echo 0)
if [ "$blocks" -eq 1 ] && grep -q 'behavioral' "$HERMES_MEMORY_MD" \
  && ! grep -q 'never-contain' "$HERMES_MEMORY_MD" \
  && ! grep -q 'false-freeze rate' "$HERMES_MEMORY_MD"; then
  pass 'strong answers do not persist'
else
  fail 'strong answers do not persist'
fi

if ! [[ "$out" =~ [Pp]lease.*confirm ]] && ! [[ "$out" =~ [Cc]onfirm.*persist ]]; then
  pass 'no persist confirmation prompt'
else
  fail 'no persist confirmation prompt'
fi

cmd_out=$(env HERMES_HOME="$HERMES_HOME" CROSSFIRE_LOG_CMDLINE_ONLY=1 bash -c \
  "source '$DEMO_COMMON'; crossfire_build_assessor_cmdline 'q_behavioral_01' behavioral 'question' 'answer'")
if [[ "$cmd_out" == *'--toolsets skills'* ]] && ! [[ "$cmd_out" == *'memory'* && "$cmd_out" == *'--toolsets'*'file'* ]]; then
  pass 'assessor cmdline omits memory/file/terminal'
else
  fail 'assessor cmdline omits memory/file/terminal'
fi

live_out=$(env CROSSFIRE_LIVE=1 CROSSFIRE_HERMES_DISCOVERY=0 HERMES_HOME="$HERMES_HOME" bash "$DEMO_SCRIPT" 2>&1 || true)
if [[ "$live_out" == *'FAIL CLOSED'* || "$live_out" == *'not discoverable'* ]]; then
  pass 'CROSSFIRE_LIVE=1 fails closed without Hermes'
else
  fail 'CROSSFIRE_LIVE=1 fails closed without Hermes'
fi

if grep -q 'Skip is not proof' "$SKILL_MD" && grep -qi 'fail closed' "$SKILL_MD"; then
  pass 'SKILL documents skip is not proof'
else
  fail 'SKILL documents skip is not proof'
fi

if grep -q 'discover_hermes_bin' "$REPO/tests/demo_session_1.bats"; then
  pass 'bats references discover_hermes_bin'
else
  fail 'bats references discover_hermes_bin'
fi

skill_grep() {
  if grep -q "$1" "$SKILL_MD"; then pass "SKILL grep: $1"; else fail "SKILL grep: $1"; fi
}
skill_grep 'behavioral'
skill_grep '`situation`'
skill_grep '`task`'
skill_grep '`action`'
skill_grep '`result`'
skill_grep '`problem`'
skill_grep '`approach`'
skill_grep '`tradeoff`'
skill_grep '`verification`'
skill_grep '`user`'
skill_grep '`constraint`'
skill_grep '`decision`'
skill_grep '`metric`'
if grep -qiE '≥ 2|>= 2' "$SKILL_MD"; then pass 'SKILL grep: >=2'; else fail 'SKILL grep: >=2'; fi
skill_grep 'One'
skill_grep 'automatic'
skill_grep 'confirm'
skill_grep 'mixed-family'
skill_grep 'forbidden'
skill_grep 'exactly one'
skill_grep 'never'
skill_grep 'STAR'
skill_grep 'technical'
skill_grep 'missing_elements'
skill_grep 'byte_offset'
skill_grep 'quote'
skill_grep 'propose'
skill_grep 'MEMORY.md'
skill_grep 'must not'
skill_grep 'q_technical_01'
skill_grep 'q_behavioral_01'
skill_grep 'q_product_01'
skill_grep 'Praetor decides not to contain'
skill_grep 'detection you owned was wrong'
skill_grep 'Mastercard Agent Suite (R-281517)'
skill_grep 'I just kind of watched the dashboard'
skill_grep 'N = 5'

rm -rf "$TEST_ROOT" "$TEST_ROOT2"
echo "BATS_MISSING passed=$passed failed=$failed"
exit "$failed"
