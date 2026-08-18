# S2-T5 implementer result — session-one hybrid harness

**Packet:** `02-implementation` · **Status:** done_with_concerns · **Date:** 2026-08-18

## Files changed

| File | Rationale |
| --- | --- |
| `scripts/demo_session_1.sh` | Fixed truncated locals (`answer`, `submitted_answer`); `CROSSFIRE_LIVE=1` forces live assessor + fail-closed discovery; removed sticky `RETURN` trap in live assess; clear persist `RETURN` trap before finalize return; propagate exit code |
| `scripts/demo_common.sh` | Allow `CROSSFIRE_RUNS_DIR` override (default `${REPO_ROOT}/.crossfire/runs`) |
| `tests/demo_session_1.bats` | Point runs/spool at `$TEST_ROOT/runs`; pass `CROSSFIRE_RUNS_DIR` through helpers; real discover-helper assertion; live fail-closed expects `PREFLIGHT FAIL` |
| `tests/fixtures/demo-answers.txt` | Unchanged — already matches spec §11 three answers |
| `skills/crossfire-interviewer/SKILL.md` | Unchanged — session-one harness notes intact |
| `.workflow/S2-T5/bash-assertions.sh` | Throwaway bash-equivalent runner (mirrors bats cases) |

## Defect fixes verified

1. **Truncated locals** — `submitted_answer` and `answer` declared and used correctly.
2. **`CROSSFIRE_LIVE=1` fail-closed** — main sets `CROSSFIRE_ASSESSOR=live` and calls `crossfire_discover_hermes_or_fail_closed`; discovery disabled exits nonzero with `PREFLIGHT FAIL`.
3. **`CROSSFIRE_RUNS_DIR` override** — bats setup exports `$TEST_ROOT/runs`; spool assertions use override path.
4. **Discover-helper assertion** — tests grep product scripts for `discover_hermes_bin` / `crossfire_discover_hermes_or_fail_closed`; tests do not exec `hermes` directly.
5. **Persist RETURN trap** — `trap - RETURN` after persist loop prevents sticky trap from `crossfire_persist_weakness` clobbering finalize exit status; live assess uses explicit `rm -f` instead of `RETURN` trap.
6. **Persist exit status** — finalize `if ! crossfire_persist_weakness …; then fail_closed`.
7. **SKILL.md** — not modified; harness notes preserved.

## Commands run (actual results)

### PowerShell existence checks

```
Test-Path -LiteralPath scripts\demo_session_1.sh -PathType Leaf
True
Test-Path -LiteralPath tests\demo_session_1.bats -PathType Leaf
True
Test-Path -LiteralPath tests\fixtures\demo-answers.txt -PathType Leaf
True
```

### bats

```
command -v bats → BATS_MISSING
```

(bats not installed; did not install per approval-first policy)

### Bash-equivalent assertions (WSL)

```
bash .workflow/S2-T5/bash-assertions.sh
PASS: isolation_real_home
PASS: defer_finalize_exit
PASS: spool_before_finalize
PASS: fp_unchanged_before_finalize
PASS: manual_finalize_exit
PASS: manual_finalize_ack
PASS: fp_changed_after_finalize
PASS: harness_exit_0
PASS: three_questions_order
PASS: fixture_answers
PASS: auto_finalize_ack
PASS: spool_under_test_root
PASS: source_session_id
PASS: one_behavioral_weakness
PASS: strong_technical_not_persisted
PASS: strong_product_not_persisted
PASS: no_confirm_prompt
PASS: done_same_finalize_fn
PASS: toolsets_skills
PASS: toolsets_no_memory
PASS: product_uses_discover
PASS: live_fail_closed
PASS: skill_live_notes
passed=23 failed=0
exit 0
```

### Harness exit code (post trap fix)

```
bash scripts/demo_session_1.sh (isolated temp profile)
run1=0
```

### Isolated live `-Q` attempt

Command (via `crossfire_build_assessor_cmdline` + `crossfire_hermes_invoke`, skill copied to isolated profile with `crossfire_ensure_isolated_skill`):

```
hermes chat -Q -q Assess this interview Q+A; emit propose-only YAML per crossfire-interviewer skill. question_id=q_behavioral_01 family=behavioral question=Tell me about a time a detection you owned was wrong. answer=I just kind of watched the dashboard. --max-turns 1 --toolsets skills --skills /mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test/skills/crossfire-interviewer --source tool
```

**Outcome:** `LIVE_OK` (exit 0). Stdout contained propose-only YAML with `persist_recommended: true`, `missing_elements: [situation, task, action, result]`. Stderr: `session_id: 20260818_093114_eb1ecd` plus deprecated `.env` warning in isolated profile.

**Note:** Direct `--skills <repo>/skills/crossfire-interviewer` fails with `Error: Unknown skill(s): /mnt/c/.../skills/crossfire-interviewer`. Product loop tries repo path first, then runtime copy via `crossfire_ensure_isolated_skill` (locked researcher resolution #1).

## Unresolved / concerns

- Hermes v0.20.2 rejects filesystem repo skill path; live assessor relies on runtime copy into `$HERMES_SKILLS_DIR/crossfire-interviewer/`. Fallback is implemented in `crossfire_live_assess_once`.
- Live stdout includes reasoning preamble before YAML; parser/spool writer uses full stdout today — may need YAML extraction hardening in a follow-up if live driver is enabled by default.
- Isolated profile emits deprecated `.env` `TERMINAL_CWD` warning (non-blocking).
- `bats` not installed on this machine; bash-equivalent runner used instead.

## JSON summary

```json
{
  "packet_id": "02-implementation",
  "status": "done_with_concerns",
  "files_touched": [
    "scripts/demo_session_1.sh",
    "scripts/demo_common.sh",
    "tests/demo_session_1.bats",
    "tests/fixtures/demo-answers.txt",
    "skills/crossfire-interviewer/SKILL.md",
    ".workflow/S2-T5/bash-assertions.sh",
    ".workflow/S2-T5/results/implementer-result.md"
  ],
  "checks_run": {
    "powershell_existence": "3/3 True",
    "bats": "BATS_MISSING",
    "bash_equivalent": "passed=23 failed=0",
    "live_q_attempt": "LIVE_OK session_id=20260818_093114_eb1ecd"
  }
}
```

---

## Fix round (code review Critical 1)

**Review verdict addressed:** `blocking_retry` → Critical 1 fixed.

### Changes

| File | Rationale |
| --- | --- |
| `scripts/demo_common.sh` | Added `crossfire_extract_yaml_from_live_stdout` (strip preamble / fenced blocks; exact `family:` match only), `crossfire_strip_spool_harness_fields`, `crossfire_overlay_spool_harness_fields`, `crossfire_normalize_live_proposal`; made `crossfire_spool_field` grep-safe with `\|\| true` |
| `scripts/demo_session_1.sh` | Live assess path uses `crossfire_normalize_live_proposal`; removed `evidence_value` fallback for `submitted_answer`; fail-closed when spool lacks `submitted_answer` |
| `tests/demo_session_1.bats` | Added live-shaped YAML finalize test (preamble + no `submitted_answer`); `/done` test now asserts shared persist side effects via `CROSSFIRE_FINALIZE_RUN_ID` hook |
| `skills/crossfire-interviewer/SKILL.md` | Document harness injection of `submitted_answer` and YAML extraction |
| `.workflow/S2-T5/bash-assertions.sh` | Added `live_yaml_extract_overlay` and `live_shaped_finalize_persist` cases |

### Verification (fix round)

```
bash .workflow/S2-T5/bash-assertions.sh
passed=25 failed=0
exit 0
```

Critical 1 probe cases now covered deterministically:
- Preamble line `family: this is a behavioral question...` ignored (exact family match only)
- Skill-shaped YAML without `submitted_answer` → harness overlay → finalize rc=0, MEMORY.md written, ack printed

```json
{
  "fix_round": "critical_1",
  "status": "done",
  "bash_equivalent": "passed=25 failed=0",
  "critical_1_fixed": true
}
```
