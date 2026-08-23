# S5-T3 Implementer Result: Require one JD on session start

## Status

**Done** — Task 3 implemented per plan; task-scoped verification green except two pre-existing Windows stub persist checks (see concerns).

## Task 3 transcription (plan)

Require exactly one JD (pack or paste) before a practice session starts.

**Produces:**
- `GET /api/packs` → `{"packs": [{id, employer, role, requisition, families}]}`
- `POST /api/session/start` accepts `inference`, `jd_kind`, `pack_id`, `paste`, `persona`, `temperature`
- Env into wrapper: `CROSSFIRE_JD_KIND`, `CROSSFIRE_JD_SOURCE_ID`, `CROSSFIRE_JD_SOURCE_LABEL`, `CROSSFIRE_JD_CONTEXT`, `CROSSFIRE_PERSONA`, `CROSSFIRE_TEMPERATURE`
- Wrapper start kv: `source_id`, `source_label`, `jd_kind`, `temperature`
- Server start JSON merges `source_id`, `source_label`, `jd_kind`, `temperature`, `persona`, `context_text` (full paste not via `kv_parse`)
- Missing JD → HTTP 400; wrapper `fail_closed` if env missing
- `crossfire_practice_save_state` persists JD fields + writes `jd-context.md`

**Ruling applied:** `require_session_jd` rejects unsafe `pack_id` (slug regex + resolved path must stay under `sources_dir`); unit test for `../SKILL`.

## Files changed

| File | Rationale |
| --- | --- |
| `app/packs.py` | Added `_resolve_pack_path`, `start_session_args`; pack_id slug/path sanitize |
| `app/server.py` | `GET /api/packs`; `/api/session/start` calls `start_session_args`, passes JD env, merges response fields |
| `scripts/practice_session.sh` | Fail-closed JD check after Monday home; JD kv on start; extended `save_state` + `jd-context.md`; `%q` quoting for label/persona in state |
| `tests/test_packs.py` | TDD: `test_start_session_args_requires_jd`, `test_require_pack_rejects_path_traversal` |
| `tests/practice_jd.sh` | New: no-JD fail-closed; pack start prints `source_id` and `temperature` |
| `tests/practice_session_stub.sh` | Pack JD env on every `start` invocation |
| `tests/practice_inference.sh` | Pack JD env on codex stub start |

## Verification

### TDD (fail first)

```
py -3 -m unittest tests.test_packs.TemperatureAndJdTest.test_start_session_args_requires_jd -v
# ImportError: cannot import name 'start_session_args'  (expected)
```

### Final runs

```
py -3 -m unittest tests.test_packs tests.test_memory_view -v
# Ran 14 tests — OK

"C:\Program Files\Git\bin\bash.exe" tests/practice_jd.sh
# practice_jd: passed=3 failed=0

"C:\Program Files\Git\bin\bash.exe" tests/practice_inference.sh
# practice_inference: passed=12 failed=0

"C:\Program Files\Git\bin\bash.exe" tests/practice_session_stub.sh
# practice_session: passed=8 failed=2 (MEMORY.md persist + session-two opener — see concerns)
```

## Concerns

1. **`practice_session_stub.sh` persist on Windows:** `crossfire_persist_weakness` fsync uses `python3`; Git Bash resolves `python3` to the Windows Store stub (`Python was not found`), so `MEMORY.md` is not written and session-two opener checks fail downstream. Task 3 JD/start paths in that script all pass. Likely pre-existing on this host; Linux CI should be unaffected.

2. **`practice.state` quoting:** Added `printf '%q'` for `CROSSFIRE_JD_SOURCE_LABEL` and `CROSSFIRE_PERSONA` so `source` does not break on labels with spaces (e.g. `Project Praetor`). Not explicitly in plan but required for stub stability.

3. **UI unchanged (Task 5):** `/api/session/start` now requires JD in payload; current UI will get HTTP 400 until Task 5 wires pick-or-paste.

4. **`CROSSFIRE_JD_CONTEXT` not in `practice.state`:** Only written to `jd-context.md` per plan; Task 4 must load it for answer/skip prompts.

## Acceptance criteria

- [x] `start_session_args` raises without jd_kind/pack/paste
- [x] `GET /api/packs` lists four shipped packs (verified via `list_source_packs`)
- [x] Wrapper start without JD fail-closes
- [x] Wrapper start with pack prints `source_id` and `temperature`
- [x] Stub session and inference starts pass with pack env (`practice_inference` full pass; stub JD/start paths pass)

---

## Code review fix: inference-before-JD validation order

**Issue:** `start_session_args` called `require_session_jd` before `normalize_inference`, so `POST {"inference":"cursor"}` returned `"jd kind must be pack or paste"` instead of an inference error.

**Fix:** In `app/packs.py`, call `normalize_inference` first, then `require_session_jd`.

### Re-run (post-fix)

```
py -3 -m unittest tests.test_packs tests.test_inference tests.test_memory_view -v
# Ran 19 tests in 1.102s — OK
# test_unknown_inference_is_400 ... ok

"C:\Program Files\Git\bin\bash.exe" tests/practice_jd.sh
# PASS: start without JD fail-closed
# PASS: source_id printed
# PASS: temperature printed
# practice_jd: passed=3 failed=0
```
