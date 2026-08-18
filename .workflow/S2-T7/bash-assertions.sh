#!/usr/bin/env bash
# S2-T7 bash-equivalent assertions (mirrors tests/demo_session_2.bats)
set -u
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
cd "$REPO_ROOT"
passed=0
failed=0

ok() { passed=$((passed + 1)); echo "PASS: $1"; }
fail() { failed=$((failed + 1)); echo "FAIL: $1"; }

TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/crossfire-s2.XXXXXX")
export HERMES_HOME="${TEST_ROOT}/.crossfire/profiles/test"
export CROSSFIRE_RUNS_DIR="${TEST_ROOT}/runs"
export CROSSFIRE_CANDIDATE_SKILLS_ROOT="${TEST_ROOT}/.crossfire/candidate-skills"
export CROSSFIRE_HERMES_DISCOVERY=0
export CROSSFIRE_OPENER=stub
export CROSSFIRE_STUB_SESSION_ID=sess_stub_s2
mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills"
MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"
DEMO_SCRIPT="$REPO_ROOT/scripts/demo_session_2.sh"
DEMO_ONE="$REPO_ROOT/scripts/demo_session_1.sh"
FIXTURE_THREE="$REPO_ROOT/tests/fixtures/memory-three-weaknesses.md"

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/demo_common.sh"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/weakness_memory.sh"
# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/stage_candidate_skill.sh"
crossfire_require_isolated_hermes_home

if env HERMES_HOME='/home/fish/.hermes' REAL_HERMES_WSL='/home/fish/.hermes' REAL_HERMES_WIN='' \
  bash -c "source '$REPO_ROOT/scripts/demo_common.sh'; crossfire_require_isolated_hermes_home" \
  >/dev/null 2>&1; then
  fail isolation_real_home
else
  ok isolation_real_home
fi

cp "$FIXTURE_THREE" "$MEMORY_MD"
sel=$(crossfire_select_newest_weakness "$MEMORY_MD" 2>/dev/null) || sel=""
if [[ "$sel" == *"weakness_id=w-b2f32d5ee0be"* ]] && \
   [[ "$sel" == *"family=product"* ]] && \
   [[ "$sel" == *"source_session_id=sess_c"* ]]; then
  ok select_newest_three_fixture
else
  fail select_newest_three_fixture
fi

out=$(env HERMES_HOME="$HERMES_HOME" CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  CROSSFIRE_CANDIDATE_SKILLS_ROOT="$CROSSFIRE_CANDIDATE_SKILLS_ROOT" \
  CROSSFIRE_OPENER=stub CROSSFIRE_HERMES_DISCOVERY=0 \
  CROSSFIRE_STUB_SESSION_ID=sess_stub_s2 \
  CROSSFIRE_SESSION_ONE_ID=sess_one_distinct \
  bash "$DEMO_SCRIPT" 2>&1) || out=""
pos_src=$(grep -n 'opening_target_source=MEMORY.md' <<<"$out" | head -1 | cut -d: -f1)
pos_q=$(grep -n '^Question:' <<<"$out" | head -1 | cut -d: -f1)
if [ -n "$pos_src" ] && [ -n "$pos_q" ] && [ "$pos_src" -lt "$pos_q" ] && \
   [[ "$out" == *"target selected by prompt memory"* ]] && \
   [[ "$out" == *"session_identifiability: distinct"* ]]; then
  ok print_before_question
else
  fail print_before_question
fi

mkdir -p "${HERMES_HOME}/skills/unverified-behavioral-followup"
cat >"${HERMES_HOME}/skills/unverified-behavioral-followup/SKILL.md" <<'EOF'
---
id: crossfire.candidate.behavioral
name: unverified-behavioral-followup
status: unverified
---
EOF
if ( env HERMES_HOME="$HERMES_HOME" CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  CROSSFIRE_OPENER=stub CROSSFIRE_HERMES_DISCOVERY=0 \
  bash "$DEMO_SCRIPT" >/dev/null 2>&1 ); then
  fail candidate_in_live_dir
else
  ok candidate_in_live_dir
fi
rm -rf "${HERMES_HOME}/skills/unverified-behavioral-followup"

if ( env HERMES_HOME="$HERMES_HOME" CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  CROSSFIRE_OPENER=stub CROSSFIRE_HERMES_DISCOVERY=0 \
  CROSSFIRE_STUB_SESSION_ID=sess_stub_s2 CROSSFIRE_SESSION_ONE_ID=sess_stub_s2 \
  bash "$DEMO_SCRIPT" >/dev/null 2>&1 ); then
  fail distinct_session_id
else
  ok distinct_session_id
fi

if ( bash -c "
  export HERMES_HOME='$HERMES_HOME'
  export CROSSFIRE_RUNS_DIR='$CROSSFIRE_RUNS_DIR'
  export CROSSFIRE_OPENER=stub CROSSFIRE_HERMES_DISCOVERY=0
  export CROSSFIRE_STUB_SESSION_ID=sess_stub_s2
  export CROSSFIRE_SESSION_ONE_PID=\$\$
  bash '$DEMO_SCRIPT'
" >/dev/null 2>&1 ); then
  fail distinct_process_id
else
  ok distinct_process_id
fi

cmd=$(env HERMES_HOME="$HERMES_HOME" CROSSFIRE_LOG_CMDLINE_ONLY=1 \
  bash -c "source '$REPO_ROOT/scripts/demo_common.sh'; crossfire_build_opener_cmdline w-test behavioral 'action,result' MEMORY.md")
if [[ "$cmd" == *"--toolsets skills"* ]] && [[ "$cmd" != *"session_search"* ]] && \
   [[ "$cmd" != *"--resume"* ]]; then
  ok opener_cmdline_toolsets
else
  fail opener_cmdline_toolsets
fi

rm -f "$MEMORY_MD"
env HERMES_HOME="$HERMES_HOME" CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  CROSSFIRE_ASSESSOR=stub CROSSFIRE_HERMES_DISCOVERY=0 \
  bash "$DEMO_ONE" >/dev/null
int_out=$(env HERMES_HOME="$HERMES_HOME" CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  CROSSFIRE_OPENER=stub CROSSFIRE_HERMES_DISCOVERY=0 \
  CROSSFIRE_STUB_SESSION_ID=sess_stub_s2 CROSSFIRE_SESSION_ONE_ID=sess_stub \
  bash "$DEMO_SCRIPT" 2>&1) || int_out=""
if [[ "$int_out" == *"family=behavioral"* ]] && [[ "$int_out" == *"source_session_id=sess_stub"* ]]; then
  ok integration_s1_s2
else
  fail integration_s1_s2
fi

if ( env CROSSFIRE_LIVE=1 CROSSFIRE_HERMES_DISCOVERY=0 CROSSFIRE_OPENER=live \
  HERMES_HOME="$HERMES_HOME" CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  bash "$DEMO_SCRIPT" >/dev/null 2>&1 ); then
  fail live_fail_closed
else
  ok live_fail_closed
fi

[ -f "$DEMO_SCRIPT" ] && ok demo_session_2_exists || fail demo_session_2_exists
grep -q 'Session-two opener' "$REPO_ROOT/skills/crossfire-interviewer/SKILL.md" && \
grep -q 'opening_target_source=MEMORY.md' "$REPO_ROOT/skills/crossfire-interviewer/SKILL.md" && \
ok skill_session_two || fail skill_session_two

custom_runs="${TEST_ROOT}/custom-runs-override"
if [ "$(env CROSSFIRE_RUNS_DIR="$custom_runs" HERMES_HOME="$HERMES_HOME" \
  bash -c "source '$REPO_ROOT/scripts/demo_common.sh'; printf '%s' \"\$CROSSFIRE_RUNS_DIR\"")" = "$custom_runs" ]; then
  ok runs_dir_override_preserved
else
  fail runs_dir_override_preserved
fi

if [ "$(env HERMES_HOME="$HERMES_HOME" bash -c "unset CROSSFIRE_RUNS_DIR; source '$REPO_ROOT/scripts/demo_common.sh'; printf '%s' \"\$CROSSFIRE_RUNS_DIR\"")" = "${REPO_ROOT}/.crossfire/runs" ]; then
  ok runs_dir_default_repo
else
  fail runs_dir_default_repo
fi

echo "passed=$passed failed=$failed"
rm -rf "$TEST_ROOT"
exit "$failed"
