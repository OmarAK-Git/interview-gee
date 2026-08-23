# S5-T3 code review — Require one JD on session start

**Packet:** `.workflow/S5-T3/packets/03-review.md`
**Reviewer:** code-reviewer (did not author this code)
**Date:** 2026-08-23
**Kind:** scoped review of Task 3 JD-required start + pack_id sanitize
**Scope:** `app/packs.py`, `app/server.py`, `scripts/practice_session.sh`, `tests/test_packs.py`, `tests/practice_jd.sh`, `tests/practice_session_stub.sh`, `tests/practice_inference.sh`
**BASE:** S5-T2 (packet `03-review-diff.md`)

Implementer report treated as unevidenced. Plan Task 3 only (`docs/superpowers/plans/2026-08-23-practice-interviewer.md` through the line before Task 4) plus the pack_id sanitize ruling are the spec.

**Verdict:** `block`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 1 |
| Minor | 3 |
| Blocking | 1 |

**Retry:** yes — fix Important 1 (inference-before-JD, or update `StartInferenceHttpTest`), then re-run `py -3 -m unittest tests.test_inference -v`.

**Strongest issue:** `app/packs.py:148` validates JD before inference, so existing `tests/test_inference.py:69` `StartInferenceHttpTest` fails: `{"inference":"cursor"}` now returns HTTP 400 `"jd kind must be pack or paste"` instead of `"nous or codex"`. Reproduced this review.

---

## Spec compliance

| Requirement | Result | Evidence |
| --- | --- | --- |
| `start_session_args` raises without jd_kind/pack/paste | **Met** | `app/packs.py:145-159`. Independent: `start_session_args({"inference":"nous"})` → `ValueError: jd kind must be pack or paste`. Unit test `test_start_session_args_requires_jd` passes. |
| `GET /api/packs` lists the four shipped packs | **Met** | Independent HTTP GET on live `Handler` (not implementer claim): exactly `{alter-ego, mastercard-r-281517, mccain-cyber-defense, praetor}`; each object has only `id, employer, role, requisition, families`. |
| Wrapper start without JD fail-closes | **Met** | `practice_session.sh:78-80` immediately after `crossfire_require_monday_home`. Independent Git Bash: `practice_jd.sh` `PASS: start without JD fail-closed`. |
| Wrapper start with pack prints `source_id` and `temperature` | **Met** | `practice_session.sh:141-144`. Independent: `practice_jd.sh` passed=3 failed=0. |
| Stub session + inference starts still pass with pack env | **Met (start path)** | All `practice_session.sh start` invocations in the two stub tests carry pack env. Inference script passed=12 failed=0. Stub start prints `source_id=praetor` / `jd_kind=pack` / `temperature=2`. Two stub failures are persist/opener, not start (see bash classification). |
| Sanitize pack_id (safe slug + containment); `../SKILL` raises | **Met** | `app/packs.py:96-103` regex `^[a-z0-9]+(?:-[a-z0-9]+)*$` then `resolve()` + `is_relative_to(base)`. Independent: `../SKILL`, `..\\SKILL`, `praetor/../SKILL` all `ValueError invalid pack_id`; HTTP POST same payloads → 400. Four real pack ids resolve. |
| Server start calls `start_session_args`, 400 on `ValueError`, extra_env block, merge JSON fields (do not put paste through `kv_parse`) | **Met** | `app/server.py:143-175`. `context_text` / `persona` copied from `args`, not `kv_parse`. extra_env keys match plan. Independent: start without JD → 400 JSON error. |
| `save_state` JD fields + `jd-context.md` | **Met** | `practice_session.sh:36-44`. Label/persona use `printf %q` (stricter than plan; needed because `source` of unquoted `Project Praetor` would break). |
| No Skip UI / persist topic unchanged / demo 1.0.0 untouched / no real `~/.hermes` | **Met** | Diff does not touch `app/static/*`, demo scripts, or persist topic (`practice_session.sh:271` still `{topic} practice gap`). Bash tests use `mktemp` HOME. |

---

## Findings

### Critical

None.

### Important (fix before proceeding)

#### Important 1 — `app/packs.py:148` / `tests/test_inference.py:69` JD-first validation breaks existing start HTTP test

`start_session_args` calls `require_session_jd` before `normalize_inference`. `StartInferenceHttpTest.test_unknown_inference_is_400` POSTs only `{"inference":"cursor"}` and asserts the error contains `"nous or codex"`.

Independent run (`py -3 -m unittest tests.test_inference -v`):

```
AssertionError: 'nous or codex' not found in 'jd kind must be pack or paste'
```

HTTP 400 still occurs. With a valid JD, unknown inference still 400s with the old message (`START_CURSOR_WITH_PACK` this review). The regression is the dual-invalid payload + the existing test.

**Fix (pick one, in allowed files):**

1. Validate inference (and temperature) before JD so the existing test stays green:

```python
def start_session_args(payload: dict, *, sources_dir: Path) -> dict:
    from inference import normalize_inference

    inference = normalize_inference(payload.get("inference"))
    temperature = normalize_temperature(payload.get("temperature"))
    persona = (payload.get("persona") or "").strip()
    jd = require_session_jd(
        payload.get("jd_kind"),
        payload.get("pack_id"),
        payload.get("paste"),
        sources_dir=sources_dir,
    )
    return {"inference": inference, "temperature": temperature, "persona": persona, **jd}
```

2. Or extend `StartInferenceHttpTest` to send `jd_kind=pack` + `pack_id=praetor` with `inference=cursor` so it still asserts `"nous or codex"` under the new start contract.

Option 1 is in `app/packs.py` (allowed) and does not change Task 3 acceptance.

---

### Minor (track)

#### Minor 1 — `tests/test_packs.py:82-84` traversal test would pass without sanitizer

`test_require_pack_rejects_path_traversal` only asserts `ValueError`. Pre-T3, `sources_dir / "../SKILL.md"` resolved to `skills/crossfire-interviewer/SKILL.md`; `parse_pack_file` already raised `ValueError` (`pack missing front matter` / `invalid pack shape`). The new test would have been green on T1 code.

Independent HTTP/unit checks this review show the *new* message is `invalid pack_id '../SKILL'`, so the sanitizer is present — the test just does not uniquely prove it. `is_relative_to` is also unreachable for any id the regex rejects (no slug can contain `..`).

**Fix:** `self.assertIn("invalid pack_id", str(ctx.exception))` (and optionally a symlink-outside-sources case if you want the containment branch live).

#### Minor 2 — `GET /api/packs` has no HTTP test

Acceptance is “GET /api/packs lists the four shipped packs.” `test_four_required_packs_exist` hits `list_source_packs` only. A typo’d route (`/api/pack`) would still leave that unit test green. This review hit the real handler and it is correct.

**Fix:** add one request in `HttpSmokeTest` (Task 5 already extends that class) asserting the four ids and key set.

#### Minor 3 — `tests/practice_jd.sh` is CRLF

New file is CRLF (42/42). Git Bash on this host passed. Linux `bash` can fail on `\r` in `set -euo pipefail` scripts. No `.gitattributes`.

**Fix:** rewrite the file as LF (or add `*.sh text eol=lf`).

---

## Independent checks (not implementer claims)

### GET /api/packs

Spun `ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)` and GET `/api/packs`.

- 200, `packs` length 4
- ids exactly `alter-ego`, `mastercard-r-281517`, `mccain-cyber-defense`, `praetor`
- each item keys = `{id, employer, role, requisition, families}` (no `context_text` leak)
- `server.PACKS` = `skills/crossfire-interviewer/sources` and exists

### pack_id path containment

| pack_id | `require_session_jd` | HTTP POST `/api/session/start` |
| --- | --- | --- |
| `../SKILL` | `invalid pack_id` | 400 same |
| `..\\SKILL` | `invalid pack_id` | 400 same |
| `praetor/../SKILL` | `invalid pack_id` | 400 same |
| `/etc/passwd` | `invalid pack_id` | — |
| `praetor.md` / `SKILL` / `..` / `.` | `invalid pack_id` | 400 |
| `praetor`, `mastercard-r-281517`, `mccain-cyber-defense`, `alter-ego` | OK | — |
| `""` / `None` | `pack_id required` | — |

Regex rejects traversal before join; `is_relative_to` is defense-in-depth for a slug-named symlink out of `sources/`. T1 escape (`../SKILL` → parent `SKILL.md`) is closed.

### Tests this review ran

```
py -3 -m unittest tests.test_packs tests.test_memory_view tests.test_inference -v
# 18 ok, 1 fail: StartInferenceHttpTest.test_unknown_inference_is_400

"C:\Program Files\Git\bin\bash.exe" tests/practice_jd.sh
# practice_jd: passed=3 failed=0

"C:\Program Files\Git\bin\bash.exe" tests/practice_inference.sh
# practice_inference: passed=12 failed=0

"C:\Program Files\Git\bin\bash.exe" tests/practice_session_stub.sh
# practice_session: passed=8 failed=2
```

### Bash failures: this task vs host

**Not introduced by T3.** Stub start with pack env succeeded (`event=start`, `source_id=praetor`, `jd_kind=pack`, `temperature=2`). Failures:

1. `MEMORY.md missing weakness block`
2. `session two opener` (`opening_target_source=none` because persist never wrote MEMORY.md)

During `end`, Git Bash printed:

```
Python was not found; run without arguments to install from the Microsoft Store...
```

Cause: `scripts/weakness_memory.sh:183-184` `crossfire_weakness_fsync_file` prefers `python3`; this host’s `python3` is `C:\Users\oalan\AppData\Local\Microsoft\WindowsApps\python3.exe` (Store stub). Persist then fails; session-two opener has nothing to read. T3 did not edit `weakness_memory.sh` or persist topic. Linux CI with a real `python3` should be unaffected.

---

## Correctness / security / simplicity / tests (summary)

- **Correctness:** Start contract matches Task 3. Fail-closed is kind-or-context empty only (as specified); wrapper does not re-validate `pack|paste`. `CROSSFIRE_JD_CONTEXT` lives in `jd-context.md` not `practice.state` (plan; Task 4 must reload).
- **Security:** pack_id is slug-gated + contained before HTTP start reads a file. Isolation (`mktemp` HOME) intact. No new persist writer. `%q` on label/persona avoids `source` injection/breakage from spaces.
- **Simplicity:** Implementation is the plan plus `_resolve_pack_path` (ruling) and `%q` (necessary for `source`). No Skip UI, no extra APIs.
- **Tests:** New unit + `practice_jd.sh` exercise the Task 3 ACs except HTTP `/api/packs`. Traversal test is not unique proof (Minor 1). Existing inference HTTP test is red (Important 1). Stub persist fails are pre-existing host `python3`.

---

## Out of scope / not defects

- Current UI start body is still `{inference}` only (`app/static/app.js:190`) → HTTP 400 until Task 5. Plan Task 5 wires pick-or-paste. Do not add Skip UI in T3.
- `CROSSFIRE_JD_CONTEXT` not reloaded on answer — Task 4.
- Persist topic still `q_live_N practice gap` — Task 6.
