# S2-T7 code review retry — CROSSFIRE_RUNS_DIR override

**Packet:** `03-review` (scoped retry of Important 1)  
**Reviewer:** code-reviewer (did not author this fix; did not implement, commit, or mark the queue done)  
**Date:** 2026-08-18  
**Scope:** Important 1 plus any new Critical/Important in the override restore (and its tests). Current `scripts/demo_common.sh:232`, `tests/demo_session_2.bats` override tests, `.workflow/S2-T7/bash-assertions.sh` override assertions. YAML helpers still present.

**Verdict:** `approve`

| Item | Result |
| --- | --- |
| Important 1 | **ADDRESSED** |
| New Critical | 0 |
| New Important | 0 |
| New blocking count | **0** |

**Retry:** no

---

## Important 1 — ADDRESSED

**Required:** `CROSSFIRE_RUNS_DIR="${CROSSFIRE_RUNS_DIR:-${REPO_ROOT}/.crossfire/runs}"`

**Current** (`scripts/demo_common.sh:232`):

```bash
CROSSFIRE_RUNS_DIR="${CROSSFIRE_RUNS_DIR:-${REPO_ROOT}/.crossfire/runs}"
```

Git diff vs HEAD for this line is exactly that restore (`"${REPO_ROOT}/.crossfire/runs"` → parameter-expansion default). No other assignment of `CROSSFIRE_RUNS_DIR=` in `scripts/`.

**Test that would fail without the behavior:**

- `tests/demo_session_2.bats` `@test "CROSSFIRE_RUNS_DIR override preserved when exported before source"` — `export CROSSFIRE_RUNS_DIR='$custom'` then `source demo_common.sh`, asserts `[ "$output" = "$custom" ]`. A hard-assign to `${REPO_ROOT}/.crossfire/runs` would make `$output` the repo path, not `$custom`.
- `.workflow/S2-T7/bash-assertions.sh` `runs_dir_override_preserved` — `env CROSSFIRE_RUNS_DIR="$custom_runs"` then source, exact-string compare.

Those are not source greps of the success string.

---

## Independent probe (disposable HERMES_HOME)

WSL bash. `HERMES_HOME=/tmp/crossfire-s2t7-rereview.nHC97J/.crossfire/profiles/test`. Never wrote real `~/.hermes`. Probe tree contained only `PROBE/.../memories` (created for isolation default); deleted after.

| Check | Result |
| --- | --- |
| Export `CROSSFIRE_RUNS_DIR=/tmp/crossfire-s2t7-rereview.nHC97J/runs`, then source | `AFTER_SOURCE_RUNS_DIR=/tmp/crossfire-s2t7-rereview.nHC97J/runs` **OVERRIDE_MATCH=yes** |
| Unset, then source | `DEFAULT_AFTER=/mnt/c/Users/oalan/interview-gee/.crossfire/runs` **DEFAULT_MATCH=yes** |
| `crossfire_extract_yaml_from_live_stdout` / `crossfire_normalize_live_proposal` | **present** |
| Source with `HERMES_HOME=/home/fish/.hermes` | `REAL_HOME_FAIL_RC=1` (`PREFLIGHT FAIL: HERMES_HOME points at real profile`) |
| Real `/home/fish/.hermes` fingerprint | **unchanged** `1786910797:4096` before and after |
| Windows `C:\Users\oalan\.hermes` | **absent** before and after |

---

## S2-T5 helper checklist (retry)

| Helper | Status | Evidence |
| --- | --- | --- |
| `crossfire_extract_yaml_from_live_stdout` | **present** | `scripts/demo_common.sh:439-490`; probe `declare -F` |
| `crossfire_normalize_live_proposal` | **present** | `scripts/demo_common.sh:522-527` |
| `CROSSFIRE_RUNS_DIR` override | **ADDRESSED** | `:232` default expansion; export-before-source probe preserved disposable path |

---

## New Critical / Important

None in the override restore or its tests.

Prior Minors (barrier flag unused unless `CROSSFIRE_RUN_ID` set; distinct-ID skip-if-unset; leftover `trap - RETURN`) are **not** re-raised as blocking. The no-op `trap - RETURN` was removed from `scripts/demo_session_2.sh` (cheap). Remaining prior Minors stay track-only.

**Minor (track, not blocking):** bats default-path test uses `[[ "$output" == *"/.crossfire/runs" ]]` (suffix glob). bash-assertions uses exact `${REPO_ROOT}/.crossfire/runs`. Independent probe used the exact path.

---

## Isolation

No product write under real `~/.hermes`. Probe sourced `demo_common.sh` only; `mkdir` was the reviewer's disposable `HERMES_HOME/.../memories`. Real-home fingerprints unchanged.

---

## Return (for orchestrator)

```text
verdict: approve
Important 1: ADDRESSED
new blocking count: 0
```
