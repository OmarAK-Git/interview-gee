#!/usr/bin/env bash
# S2-T6 bash-equivalent assertions (mirrors tests/candidate_skill.bats)
set -u
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
cd "$REPO_ROOT"
passed=0
failed=0

ok() { passed=$((passed + 1)); echo "PASS: $1"; }
fail() { failed=$((failed + 1)); echo "FAIL: $1"; }

TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/crossfire-cs.XXXXXX")
export HERMES_HOME="${TEST_ROOT}/.crossfire/profiles/test"
export CROSSFIRE_RUNS_DIR="${TEST_ROOT}/runs"
export CROSSFIRE_CANDIDATE_SKILLS_ROOT="${TEST_ROOT}/.crossfire/candidate-skills"
export CROSSFIRE_HERMES_DISCOVERY=0
mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills" "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}"
MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"
DEMO_SCRIPT="$REPO_ROOT/scripts/demo_session_1.sh"

# shellcheck disable=SC1091
source "$REPO_ROOT/scripts/stage_candidate_skill.sh"
crossfire_require_isolated_hermes_home

cs_write_behavioral_spool() {
  local run_id="$1" qid="$2"
  local spool_dir="${CROSSFIRE_RUNS_DIR}/${run_id}/spool"
  mkdir -p "$spool_dir"
  cat >"${spool_dir}/${qid}.yaml" <<EOF
family: behavioral
missing_elements: [action, result]
evidence:
  kind: quote
  value: "I just kind of watched the dashboard."
persist_recommended: true
question_id: ${qid}
answer_ref: ${run_id}/${qid}/0
source_session_id: sess_stub
submitted_answer: |
  I just kind of watched the dashboard.
EOF
}

cs_persist_from_spool() {
  local run_id="$1"
  env HERMES_HOME="$HERMES_HOME" \
    CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
    CROSSFIRE_ASSESSOR=stub CROSSFIRE_HERMES_DISCOVERY=0 \
    CROSSFIRE_FINALIZE_RUN_ID="$run_id" \
    bash "$DEMO_SCRIPT" >/dev/null
}

[ -f "$REPO_ROOT/.crossfire/candidate-skills/.gitkeep" ] && ok gitkeep || fail gitkeep

mkdir -p "${HERMES_HOME}/skills/unverified-behavioral-followup"
cat >"${HERMES_HOME}/skills/unverified-behavioral-followup/SKILL.md" <<'EOF'
---
id: crossfire.candidate.behavioral
name: unverified-behavioral-followup
status: unverified
---
EOF
if ( crossfire_assert_candidates_excluded_from_live >/dev/null 2>&1 ); then
  fail assert_live_candidate
else
  ok assert_live_candidate
fi
rm -rf "${HERMES_HOME}/skills/unverified-behavioral-followup"

crossfire_ensure_isolated_skill >/dev/null
if crossfire_assert_candidates_excluded_from_live >/dev/null 2>&1; then
  ok assert_allows_interviewer
else
  fail assert_allows_interviewer
fi

run_id="run_stage_bash"
staged=$(crossfire_stage_candidate_skill \
  "$run_id" behavioral w-deadbeeffeed sess_stub \
  "${run_id}/q_behavioral_01/0" 1 "action,result")
if [[ "$staged" == *"/unverified-behavioral-followup/SKILL.md" ]] && \
   [ ! -e "${HERMES_HOME}/skills/unverified-behavioral-followup/SKILL.md" ] && \
   grep -q '^id: crossfire.candidate.behavioral' "$staged" && \
   grep -q '^status: unverified' "$staged" && \
   grep -q '^source_session_id: sess_stub' "$staged" && \
   grep -q "^answer_ref: ${run_id}/q_behavioral_01/0" "$staged" && \
   grep -q 'missing_elements: \[action,result\]' "$staged"; then
  ok stage_under_candidate_root
else
  fail stage_under_candidate_root
fi

run_id="run_body_bash"
cs_write_behavioral_spool "$run_id" "q_behavioral_01"
cs_persist_from_spool "$run_id"
crossfire_stage_candidates_for_run "$run_id" "$MEMORY_MD" >/dev/null
skill="${CROSSFIRE_CANDIDATE_SKILLS_ROOT}/unverified-behavioral-followup/SKILL.md"
if [ -f "$skill" ] && grep -q 'Do not praise or imitate' "$skill" && \
   grep -q '^source_session_id: sess_stub' "$skill" && \
   grep -q "^answer_ref: ${run_id}/q_behavioral_01/0" "$skill" && \
   ! grep -q 'I just kind of watched the dashboard' "$skill"; then
  ok body_no_bad_answer
else
  fail body_no_bad_answer
fi

run_id="run_flag_bash"
cs_write_behavioral_spool "$run_id" "q_behavioral_01"
cs_persist_from_spool "$run_id"
crossfire_stage_candidates_for_run "$run_id" "$MEMORY_MD" >/dev/null
if [ -f "${CROSSFIRE_RUNS_DIR}/${run_id}/candidate-excluded.flag" ] && \
   grep -q 'unverified-behavioral-followup/SKILL.md' \
     "${CROSSFIRE_RUNS_DIR}/${run_id}/candidate-excluded.flag"; then
  ok barrier_flag
else
  fail barrier_flag
fi

run_id="run_dup_bash"
cs_write_behavioral_spool "$run_id" "q_behavioral_01"
cs_write_behavioral_spool "$run_id" "q_behavioral_02"
if ( crossfire_stage_candidates_for_run "$run_id" "$MEMORY_MD" >/dev/null 2>&1 ); then
  fail one_per_family
else
  ok one_per_family
fi

run_id="run_stage_stray_bash"
mkdir -p "${HERMES_HOME}/skills/unverified-behavioral-followup"
cat >"${HERMES_HOME}/skills/unverified-behavioral-followup/SKILL.md" <<'EOF'
---
id: crossfire.candidate.behavioral
name: unverified-behavioral-followup
status: unverified
---
EOF
cs_write_behavioral_spool "$run_id" "q_behavioral_01"
cs_persist_from_spool "$run_id"
crossfire_stage_candidates_for_run "$run_id" "$MEMORY_MD" >/dev/null
skill="${CROSSFIRE_CANDIDATE_SKILLS_ROOT}/unverified-behavioral-followup/SKILL.md"
if [ ! -e "${HERMES_HOME}/skills/unverified-behavioral-followup/SKILL.md" ] && \
   [ -f "${CROSSFIRE_RUNS_DIR}/${run_id}/live-skill-snapshot/unverified-behavioral-followup/SKILL.md" ] && \
   [ -f "$skill" ] && \
   grep -q '^source_session_id: sess_stub' "$skill" && \
   grep -q "^answer_ref: ${run_id}/q_behavioral_01/0" "$skill"; then
  ok stage_snapshots_stray_then_stages
else
  fail stage_snapshots_stray_then_stages
fi

run_id="run_snapshot_bash"
mkdir -p "${HERMES_HOME}/skills/unverified-behavioral-followup"
cat >"${HERMES_HOME}/skills/unverified-behavioral-followup/SKILL.md" <<'EOF'
---
id: crossfire.candidate.behavioral
name: unverified-behavioral-followup
status: unverified
---
EOF
crossfire_snapshot_live_candidates_if_any "$run_id"
if [ ! -e "${HERMES_HOME}/skills/unverified-behavioral-followup/SKILL.md" ] && \
   [ -f "${CROSSFIRE_RUNS_DIR}/${run_id}/live-skill-snapshot/unverified-behavioral-followup/SKILL.md" ] && \
   crossfire_assert_candidates_excluded_from_live >/dev/null 2>&1; then
  ok snapshot_fallback
else
  fail snapshot_fallback
fi

if env HERMES_HOME='/home/fish/.hermes' REAL_HERMES_WSL='/home/fish/.hermes' REAL_HERMES_WIN='' \
  bash -c "source '$REPO_ROOT/scripts/stage_candidate_skill.sh'; crossfire_require_isolated_hermes_home" \
  >/dev/null 2>&1; then
  fail isolation_real_home
else
  ok isolation_real_home
fi

run_id="run_wid_bash"
cs_write_behavioral_spool "$run_id" "q_behavioral_01"
expected=$(crossfire_candidate_weakness_id_from_spool \
  "${CROSSFIRE_RUNS_DIR}/${run_id}/spool/q_behavioral_01.yaml")
cs_persist_from_spool "$run_id"
crossfire_stage_candidates_for_run "$run_id" "$MEMORY_MD" >/dev/null
if grep -q "weakness_id: ${expected}" \
  "${CROSSFIRE_CANDIDATE_SKILLS_ROOT}/unverified-behavioral-followup/SKILL.md"; then
  ok weakness_id_matches_persist
else
  fail weakness_id_matches_persist
fi

grep -q 'S2-T6 researcher probe' "$REPO_ROOT/docs/hermes-compatibility.md" && \
grep -q 'stage_candidate_skill' "$REPO_ROOT/docs/hermes-compatibility.md" && \
grep -q 'stage candidate skills' "$REPO_ROOT/skills/crossfire-interviewer/SKILL.md" && \
ok docs_and_skill || fail docs_and_skill

if [ "${CROSSFIRE_LIVE:-0}" = "1" ]; then
  if ( crossfire_discover_hermes_or_fail_closed ); then
    run_id="run_live_bash"
    cs_write_behavioral_spool "$run_id" "q_behavioral_01"
    cs_persist_from_spool "$run_id"
    crossfire_stage_candidates_for_run "$run_id" "$MEMORY_MD" >/dev/null
    staged_dir=$(dirname "$(crossfire_candidate_skill_path behavioral)")
    list_out=$(mktemp)
    err_out=$(mktemp)
    crossfire_hermes_invoke "hermes skills list --source local" "$list_out" /dev/null
    ! grep -q 'unverified-' "$list_out" && ok live_list_excludes || fail live_list_excludes
    if ( crossfire_hermes_invoke \
      "hermes chat -Q -q ping --max-turns 0 --toolsets skills --skills ${staged_dir} --source tool" \
      /dev/null "$err_out" ); then
      fail live_unknown_skill
    elif grep -q 'Unknown skill' "$err_out"; then
      ok live_unknown_skill
    else
      fail live_unknown_skill
    fi
    rm -f "$list_out" "$err_out"
  else
    fail live_hermes_required
  fi
else
  echo "SKIP: live (set CROSSFIRE_LIVE=1 to run Hermes exclusion probes)"
fi

if ( env CROSSFIRE_LIVE=1 CROSSFIRE_HERMES_DISCOVERY=0 HERMES_HOME="$HERMES_HOME" \
  bash -c "source '$REPO_ROOT/scripts/stage_candidate_skill.sh'; crossfire_discover_hermes_or_fail_closed" \
  >/dev/null 2>&1 ); then
  fail live_fail_closed_no_hermes
else
  ok live_fail_closed_no_hermes
fi

echo "passed=$passed failed=$failed"
rm -rf "$TEST_ROOT"
exit "$failed"
