# S5-T4 Implementer Result

## Status

**done** — Task 4 (prompt injection, mid-session temperature, Skip) implemented per plan and jd-context load ruling.

## Task 4 transcription (plan excerpt)

**Goal:** Inject session JD/persona/temperature into every Hermes `-q`; add `skip` without persist; pass temperature on answer/skip from server.

**Files:** `scripts/practice_session.sh`, `app/server.py`, `tests/practice_jd.sh`

**Produces:**
- `crossfire_practice_interviewer_preamble` — text block injected into every `-q`
- `practice_session.sh skip` — no spool write, no persist; asks another question
- `POST /api/session/skip` body `{temperature?: int}` → same kv as answer plus `assessment_status=skipped`, `skipped=true`
- Answer POST may include `temperature`; server exports `CROSSFIRE_TEMPERATURE` and updates state via `save_state`

**Ruling applied:** `practice.state` does not store `CROSSFIRE_JD_CONTEXT`. After `crossfire_practice_load_state`, if context is empty, load from `{run_dir}/jd-context.md` (written at start/save).

## Files changed

| File | Rationale |
| --- | --- |
| `scripts/practice_session.sh` | Added `crossfire_practice_interviewer_preamble`; jd-context reload in `load_state`; rewrote start/answer `-q` prompts; added `crossfire_practice_skip` and `skip)` case; temperature export on answer/skip |
| `app/server.py` | `POST /api/session/skip`; temperature on answer/skip via `normalize_temperature` + `CROSSFIRE_TEMPERATURE` env |
| `tests/practice_jd.sh` | TDD: preamble helper, session JD naming, skip kv, no persist, no spool checks after successful start |

## Verification

### TDD — fail first

```
& "C:\Program Files\Git\bin\bash.exe" tests/practice_jd.sh
```

Before implementation: `practice_jd: passed=4 failed=5` (preamble helper, prompt names session JD, skip command/kv/persist failed).

### After implementation

```
& "C:\Program Files\Git\bin\bash.exe" tests/practice_jd.sh
```

```
PASS: start without JD fail-closed
PASS: source_id printed
PASS: temperature printed
PASS: preamble helper exists
PASS: prompt names session JD
PASS: skip kv
PASS: skip no persist
PASS: skip wrote no spool
practice_jd: passed=8 failed=0
```

### Stub regression

```
& "C:\Program Files\Git\bin\bash.exe" tests/practice_session_stub.sh
```

`practice_jd: passed=8 failed=0`. Stub script reported 2 pre-existing failures unrelated to Task 4 (`Python was not found` on persist path; session-two opener / MEMORY.md block on this Windows host). Start/skip path in stub mode unaffected.

## Acceptance criteria

- [x] `crossfire_practice_interviewer_preamble` exists; start/answer prompts name the session JD
- [x] `practice_session.sh skip` emits `skipped=true`, `persist_recommended=false`, writes no spool yaml
- [x] `POST /api/session/skip` exists and requires active session (`409` without `run_id`)
- [x] jd-context load ruling: skip works with only `CROSSFIRE_RUN_ID` (context loaded from `jd-context.md`)

## Concerns

- `practice_session_stub.sh` full suite still fails on this host due to missing `python` on PATH for persist verification and session-two opener fixtures — not introduced by this task.
- Live (non-stub) Hermes turns not exercised here; stub covers skip contract.

## Not done (per scope)

- No commit, no queue update, no UI (Task 5), no subagents.

---

## Code-review fix: mid-session temperature (2026-08-23)

### Finding

`crossfire_practice_load_state` sources `practice.state` and overwrote inbound `CROSSFIRE_TEMPERATURE` on answer/skip. Start at temp=2 then skip at temp=4 left state at 2.

### Fix

In `crossfire_practice_answer` and `crossfire_practice_skip`: before `load_state`, save inbound `CROSSFIRE_TEMPERATURE` when the caller set it (`${CROSSFIRE_TEMPERATURE+set}`). After `load_state` and jd-context reload, restore that value so preamble/skip use it and `save_state` persists it.

### Files changed

| File | Rationale |
| --- | --- |
| `scripts/practice_session.sh` | Preserve/restore inbound temperature across `load_state` on answer and skip |
| `tests/practice_jd.sh` | Assert `practice.state` contains `CROSSFIRE_TEMPERATURE=4` after skip with temp=4 |

### Verification

```
& "C:\Program Files\Git\bin\bash.exe" tests/practice_jd.sh
```

```
PASS: start without JD fail-closed
PASS: source_id printed
PASS: temperature printed
PASS: preamble helper exists
PASS: prompt names session JD
PASS: skip kv
PASS: skip no persist
PASS: skip wrote no spool
PASS: skip saved temperature 4
practice_jd: passed=9 failed=0
```

### Concerns

None for this fix; answer path uses the same preserve/restore pattern as skip.
