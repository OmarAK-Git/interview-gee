# S2-T7 implementer result

**Task:** Fresh-process memory-only opener (Task 7)  
**Status:** done (pending code-review + skeptic-verify)  
**Date:** 2026-08-18

## Summary

Implemented session-two harness with deterministic newest-weakness selection from `MEMORY.md`, attribution print-before-question, candidate live-dir barrier, distinct process/session ID checks, and stub/live opener paths (`--toolsets skills` only, no `--resume`).

## Files touched

| File | Rationale |
| --- | --- |
| `scripts/demo_session_2.sh` | Session-two main harness: preflight, selection, attribution, opener ask |
| `scripts/demo_common.sh` | §9 selection helpers, opener cmdline/stub, distinct ID assert; restored S2-T5 live-proposal helpers |
| `skills/crossfire-interviewer/SKILL.md` | Session-two opener contract: directive fields, wording rules, toolset constraints |
| `tests/demo_session_2.bats` | TDD: selection order, print-before-question, barriers, distinct IDs, integration |
| `.workflow/S2-T7/bash-assertions.sh` | Bash-equivalent mirror when bats unavailable |
| `.workflow/S2-T7/results/implementer-result.md` | This report |

## Verification

```text
$ wsl bash .workflow/S2-T7/bash-assertions.sh
PASS: isolation_real_home
PASS: select_newest_three_fixture
PASS: print_before_question
PASS: candidate_in_live_dir
PASS: distinct_session_id
PASS: distinct_process_id
PASS: opener_cmdline_toolsets
PASS: integration_s1_s2
PASS: live_fail_closed
PASS: demo_session_2_exists
PASS: skill_session_two
passed=11 failed=0
```

Manual stub run (three-weakness fixture):

```text
opening_target_source=MEMORY.md
weakness_id=w-b2f32d5ee0be
family=product
source_session_id=sess_c
target selected by prompt memory; wording generated under stable interviewer procedure
Question: For the product decision gap (metric,decision), ...
session_identifiability: distinct process=... session=sess_stub_s2
```

Session-one smoke after `demo_common.sh` restore: persist still writes weakness block (behavioral / `sess_stub`).

`bats tests/demo_session_2.bats`: **BATS_MISSING** (not installed per task constraint).

## JSON summary

```json
{
  "task": "S2-T7",
  "status": "done",
  "selection": "MEMORY.md newest weakness (last_seen desc, observation_count desc, weakness_id asc)",
  "opener_modes": ["stub", "live"],
  "session_search": "documented-fallback (omit from --toolsets skills; no pre-opener detection)",
  "verification": {
    "command": "bash .workflow/S2-T7/bash-assertions.sh",
    "passed": 11,
    "failed": 0
  },
  "not_done": ["Task 9 activation", "queue marked done", "commit"]
}
```

## Concerns

1. **Accidental `git checkout` on `demo_common.sh` during CRLF recovery** — S2-T5 tail functions (`crossfire_normalize_live_proposal` etc.) were restored from conversation context; session-one smoke passed, but reviewer should confirm parity with pre-checkout content.
2. **`session_search` detection dropped** per spec documented-fallback; proof is disk artifact + candidate exclusion + distinct process/session ID only.
3. **Live opener path** is implemented but not exercised in CI here (`CROSSFIRE_HERMES_DISCOVERY=0`); live `-Q` wording quality unverified on this machine.
4. **Windows CRLF**: shell files normalized to LF before WSL execution; editors on Windows may reintroduce CRLF.

---

## Retry (code-review Important 1)

**Trigger:** `blocking_retry` from `.workflow/S2-T7/results/code-reviewer-result.md` — S2-T5 `CROSSFIRE_RUNS_DIR` override lost after checkout mishap.

**Fix:** Restored `CROSSFIRE_RUNS_DIR="${CROSSFIRE_RUNS_DIR:-${REPO_ROOT}/.crossfire/runs}"` in `scripts/demo_common.sh:232`.

**Tests added:** `tests/demo_session_2.bats` — override preserved when exported before source; default when unset. `.workflow/S2-T7/bash-assertions.sh` — `runs_dir_override_preserved`, `runs_dir_default_repo`.

**Minor (cheap):** Removed no-op `trap - RETURN` from `scripts/demo_session_2.sh` main exit.

**Verification (retry):**

```text
$ wsl bash .workflow/S2-T7/bash-assertions.sh
PASS: runs_dir_override_preserved
PASS: runs_dir_default_repo
passed=13 failed=0
```

**Important 1:** fixed.
