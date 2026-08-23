# S5-T6 Implementer Result: End report and family buckets

## Task 6 transcription (plan)

**Goal:** Close-out report and family buckets — persist topic uses `{source_label} · {family}`, evidence truncated to 180 chars, End kv emits `report_weak`/`report_strong`/`report_text`, UI shows report on End.

**Files:** `scripts/practice_session.sh`, `app/server.py`, `app/static/app.js`, `tests/practice_jd.sh`, `tests/test_memory_view.py`

**Produces:**
- Persist `topic` = `${CROSSFIRE_JD_SOURCE_LABEL} · ${family}` (never `q_live_01 practice gap`)
- `topic_key` via existing `crossfire_normalize_topic_key`
- Evidence value truncated to 180 characters
- End kv: `report_weak=` and `report_strong=` as semicolon-separated items, plus `report_text=` via `report_line=` lines
- UI shows `report_text` instead of only `Persisted N`

## Status

**Implemented.** Report kv and UI contract pass. One `practice_jd.sh` assertion (`topic uses source label`) fails on this Windows host because `crossfire_persist_weakness` cannot write `MEMORY.md` — Git Bash resolves `python3` to the Microsoft Store stub, which exits with "Python was not found" during `crossfire_weakness_fsync_file`. Report kv is proven independently of persist.

## Files changed

| File | Rationale |
| --- | --- |
| `scripts/practice_session.sh` | `crossfire_practice_end`: topic `${CROSSFIRE_JD_SOURCE_LABEL} · ${family}`, evidence truncate 180, scan spool for weak/strong report kv |
| `app/server.py` | `kv_parse` joins `report_line=` into `report_text` |
| `app/static/app.js` | End handler bubbles `data.report_text` instead of persisted count |
| `tests/practice_jd.sh` | TDD close-out checks: dashboard answer + end report kv + MEMORY topic |
| `tests/test_memory_view.py` | UiContractTest asserts `report_text` in js, no `Persisted ${data.persisted_count` |

## Verification

### TDD — saw failures first

```
UiContractTest: FAIL — 'report_text' not found in app.js
practice_jd.sh: FAIL report_weak kv, report_strong, report_text Weak/Strong (before impl)
```

### After implementation

```
& "C:\Program Files\Git\bin\bash.exe" tests/practice_jd.sh
  PASS: 15  FAIL: 1 (topic missing source label — MEMORY.md not created, see host gap)
  PASS: report_weak kv, report_strong kv, report_text Weak, report_text Strong
  PASS: dash persist rec, no q_live practice-gap topic

py -3 -m unittest tests.test_memory_view -v
  Ran 6 tests — OK (UiContractTest passes report_text assertions)

py -3 -m unittest tests.test_packs -v
  Ran 8 tests — OK
```

### Stub regression

```
bash tests/practice_session_stub.sh
  PASS: end ack
  FAIL: MEMORY.md missing weakness block (same python3/fsync host gap, pre-existing)
```

## Host gap (Windows)

`weakness_memory.sh` `crossfire_weakness_fsync_file` uses `command -v python3` which succeeds in Git Bash (Store alias) but execution fails. `persisted_count=0` and `MEMORY.md` is never created. Topic/report code is correct; persist proof requires a host with working `python3` or `sync -f`. Not in write scope to fix fsync fallback.

## Concerns

- **MEMORY persist blocked on Windows Git Bash** — `topic uses source label` and stub MEMORY checks fail until python3 fsync works or `sync -f` is available.
- **Report scan uses glob after `shopt -u nullglob`** — safe when spool has files (test case); empty spool would iterate literal `*.yaml` once and skip via `[ -f ]`.
- **No commit / queue** — per packet instructions.

---

## Code review fix: evidence truncation (2026-08-23)

**Finding:** Truncation appended `...` (177 chars + ellipsis), which broke `crossfire_weakness_evidence_valid` quote-substring check — quotes longer than 180 chars never persisted.

**Ruling:** Spec persist validation wins. Truncate to at most 180 characters of the original quote; no ellipsis. Stored `evidence.value` must remain a substring of the source quote.

**Change:** `scripts/practice_session.sh` — `${ev_val:0:177}...` → `${ev_val:0:180}`.

**Re-verification:**

```
& "C:\Program Files\Git\bin\bash.exe" tests/practice_jd.sh
  PASS: 15  FAIL: 1 (topic missing source label — MEMORY.md host gap unchanged)

py -3 -m unittest tests.test_memory_view -v
  Ran 6 tests — OK
```

**Status:** Truncation fix applied. Substring invariant restored for long quotes when persist succeeds.
