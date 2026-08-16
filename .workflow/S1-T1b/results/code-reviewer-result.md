# S1-T1b code review (restore retry)

**Packet:** `03-review-restore`  
**Reviewer:** code-reviewer (did not author the diff)  
**Date:** 2026-08-16  
**Scope:** Honest leak/restore recording after operator-approved `rmdir` of empty `/home/fish/.hermes`. Product isolation tests were already approved; this retry is documentation + comment calibration.  
**Files read:** `docs/hermes-compatibility.md`, `scripts/demo_common.sh`, `scripts/start-wsl-isolated.sh`, `tests/isolation.bats`  
**Also consulted:** prior `03-review-retry` result, implementer restore-retry notes, packet `02-implementation`, `scripts/preflight.sh` (mkdir blast radius)  
**Diff source:** all four product files are untracked (`git status` `??`); compared current trees to the prior approved review description and grep of `mkdir` / mutate claims.

**Verdict:** `approve`

No Critical or Important findings. Prior Important (no-create tripwire) remains in place. The first-run leak is no longer papered over.

---

## Check 1 — Docs do not claim the first 1b run never mutated real `~/.hermes`

`docs/hermes-compatibility.md:115-127` records an **Operator-profile incident** for the first S1-T1b run:

- T1 baseline: `/home/fish/.hermes` absent (~14:49); Win `%USERPROFILE%\.hermes` absent
- Leak: empty `/home/fish/.hermes` born **2026-08-16 14:59:15** during S1-T1b
- Creator: **Uncertain** (current product source has no operator-path `mkdir`)
- Explicit: **Do not claim** the first S1-T1b run never mutated real `~/.hermes`

The old overclaim (sourcing isolation “does not create or mutate” real homes, with `REAL_HERMES_WSL` listed as simply “(absent)”) is gone. Shared-var rows `:104-105` now say **absent after restore** and point at the incident.

Preflight `:109` still says that script does not write real `~/.hermes`. That is scoped to `scripts/preflight.sh`, not to the first 1b run as a whole.

Locked-choices `:22` still says “harness boundary proven in Task 1b”. That is going-forward harness language, not a claim that the first run never mutated. See Minor.

---

## Check 2 — Leak + operator-approved rmdir + restored absence are recorded

Incident table `:119-125`:

| Required fact | Present |
| --- | --- |
| Leak (empty WSL dir, birth 14:59:15, mid-1b) | Yes |
| Operator approved removal | Yes (`:124`) |
| Exact restore command | Yes: `wsl.exe -e bash -c "rmdir /home/fish/.hermes"` after confirming empty |
| Post-restore both homes absent | Yes (`:125`, `:104-105`, `:141`) |

Independent read-only check at review time (this reviewer; no writes):

- `Test-Path -LiteralPath $env:USERPROFILE\.hermes` → `False`
- `wsl.exe -e bash -lc '[ ! -e /home/fish/.hermes ] && echo WSL_ABSENT'` → `WSL_ABSENT`
- `wsl.exe -e bash -lc '[ ! -e /mnt/c/Users/oalan/.hermes ] && echo WIN_WSL_ABSENT'` → `WIN_WSL_ABSENT`

Docs match current disk. Attribution remains unproven; that is recorded.

---

## Check 3 — `isolation.bats` tripwire unchanged; tests do not write operator `~/.hermes`

`tests/isolation.bats` is **unchanged** relative to the prior approved `03-review-retry` (same tests, same line ranges, no restore-retry edits). Implementer restore-retry file list omits it.

Same-process snapshot before source/start:

- `:32-52` — `CROSSFIRE_PATHS_ONLY=1 source demo_common.sh` resolves `REAL_HERMES_*` only; records `win_was_absent` / `wsl_was_absent` via `[ ! -e ]`; then full `source demo_common.sh`; fails if a previously absent path now exists.
- `:54-75` — same snapshot in the parent `bash -c`; product is `bash start-wsl-isolated.sh` as a child; after-check stays in the parent (not a second re-source-only bash).

After restore both resolved homes are absent, so **both** halves of the tripwire are live again. If a previously absent path appears, those tests `exit 1`.

Operator-profile writes:

- No-create tests only stat resolved `REAL_HERMES_*`.
- Marker test `:77-95` `mkdir`/`printf`/`rm` only under `mktemp` in `BATS_TMPDIR`; exports fake `REAL_HERMES_WSL` **before** source.
- No test writes `/home/fish/.hermes` or `%USERPROFILE%\.hermes`.

---

## Check 4 — No new mkdir of operator paths

Repo `mkdir` sites in product/test scripts:

| Site | Target |
| --- | --- |
| `scripts/demo_common.sh:225` | `mkdir -p "$(dirname "$probe")"` where `probe=${HERMES_HOME}/.crossfire-harness-probe`, after `crossfire_require_isolated_hermes_home` |
| `tests/isolation.bats:81` | temp fake home only |

`scripts/start-wsl-isolated.sh` has no `mkdir`/`cp`/`rm`/`touch`. Comments at `:5-6` and `demo_common.sh:6-9,:224` are comment-only; they do not add operator-path creation.

`crossfire_resolve_real_hermes_paths` assigns `REAL_HERMES_*` strings only. `CROSSFIRE_PATHS_ONLY=1` returns before helpers/writes.

---

## Check 5 — Going-forward harness claim is not stronger than evidence

Going-forward prose `:129-137` is scoped to **current source + tests**, not to the leaked first run:

- Product scripts **do not mkdir operator paths** — matches grep.
- Sole product `mkdir -p` is under disposable `HERMES_HOME` in the probe — matches `:221-227`.
- No-create tests fail closed if a previously absent path appears — matches bats.
- Hermes process write-scope remains **unsupported**; Hermes-invoking automation remains **stopped**.
- Copied throwaway trees into real `~/.hermes` remain forbidden.

Status split is preserved: harness boundary **verified** (script-level); spec §15 Hermes write-scope **unsupported**. That matches the researcher split and the already-approved isolation tests. It does not relabel Hermes isolation as verified.

`:141` “**verified** (post-restore)” plus evidence “both real homes absent after restore” slightly mixes operator `rmdir` outcome with harness proof. Absence after restore re-arms the tripwire; it does not itself prove isolation. The surrounding prose and incident table keep that from becoming an overclaim of the first run. Tracked as Minor.

---

## `demo_common.sh` / `start-wsl-isolated.sh` — comment-only as expected

Logic matches the prior approved review:

- Isolation contract + `CROSSFIRE_PATHS_ONLY` early return
- `crossfire_apply_isolation_env` / `crossfire_require_isolated_hermes_home` / `crossfire_harness_write_probe`
- Fail-closed at source when `HERMES_HOME` is a real profile (`demo_common.sh:229-231`)
- `start-wsl-isolated.sh` still resolves via `${BASH_SOURCE[0]:-$0}`, sources `demo_common.sh`, applies isolation, does not invoke `hermes`

New material is comments only (never mkdir `REAL_HERMES_*`; bats snapshot tripwire).

---

## Findings

### Critical

None.

### Important

None.

### Minor

1. **Restore absence cited as harness-isolation evidence**  
   - File: `docs/hermes-compatibility.md:141`  
   - What’s wrong: Evidence for “Harness script isolation **verified** (post-restore)” includes “both real homes absent after restore.” Operator-approved `rmdir` proves restored absence, not that the harness never created the dir.  
   - Why it matters: A later reader could treat post-rmdir absence as a new isolation proof.  
   - Fix: Cite `tests/isolation.bats` + no operator `mkdir` in current source; describe restored absence as “tripwire live again,” not as isolation evidence.

2. **Locked-choices row does not point at the incident**  
   - File: `docs/hermes-compatibility.md:22`  
   - What’s wrong: “harness boundary proven in Task 1b” is accurate for going-forward scripts/tests but does not link the incident table.  
   - Why it matters: A table-only reader misses that the first 1b window mutated real state.  
   - Fix: Append “see Task 1b incident + restore.”

Neither blocks. Going-forward claims in `:129-137` stay within evidence.

---

## Spec / packet AC mapping (restore-retry lens)

| AC | Result |
| --- | --- |
| First 1b run not claimed mutation-free | Met (`:127`) |
| Leak + approved rmdir + restored absence recorded | Met; independently confirmed absent now |
| isolation.bats same-process snapshot tripwire | Met; unchanged; live again because both homes absent |
| Tests never write operator `~/.hermes` | Met |
| No new operator-path mkdir | Met |
| Going-forward harness claim ≤ evidence | Met in prose; Minor nit on `:141` evidence column |
| Hermes-invoking automation STOP | Met |
| Do not fail for missing Hermes binary | Honored (out of this retry) |

```json
{
  "packet_id": "03-review-restore",
  "status": "done",
  "verdict": "approve",
  "findings": [
    {
      "severity": "minor",
      "file": "docs/hermes-compatibility.md:141",
      "issue": "Post-rmdir absence listed as evidence of verified harness isolation; it re-arms the tripwire, it does not prove isolation."
    },
    {
      "severity": "minor",
      "file": "docs/hermes-compatibility.md:22",
      "issue": "Locked-choices 'harness boundary proven' does not point at the Task 1b incident table."
    }
  ]
}
```
