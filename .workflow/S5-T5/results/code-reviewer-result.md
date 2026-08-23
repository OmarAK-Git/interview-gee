# S5-T5 code review — Practice UI chrome

**Packet:** `.workflow/S5-T5/packets/03-review.md`
**Reviewer:** code-reviewer (did not author this code)
**Date:** 2026-08-23
**Kind:** scoped review of Task 5 practice UI chrome
**Scope:** `app/static/index.html`, `app/static/app.js`, `app/static/app.css`, `tests/test_memory_view.py` (`UiContractTest` / `HttpSmokeTest`)
**Spec:** plan Task 5 only (`docs/superpowers/plans/2026-08-23-practice-interviewer.md` through the line before Task 6)

Implementer report treated as unevidenced.

**Verdict:** `approve`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 0 |
| Minor | 3 |
| Blocking | 0 |

**Retry:** no

**Strongest issue:** `UiContractTest` is substring-only. Deleting the start `catch` would still pass, so the packet AC “400 surfaced” is not locked by tests. Independent HTTP + JS wiring this review still confirms the operator sees the server `error` string.

---

## Spec compliance

| Requirement | Result | Evidence |
| --- | --- | --- |
| HTML has `jd-kind`, `pack-id`, `jd-paste`, `persona`, `temperature`, `jd-context`, `skip` | **Met** | `index.html:16-35`, `:43`. IDs match the plan snippet. Skip is immediately after Send. |
| `app.js` fetches `/api/packs` and posts `jd_kind` on start | **Met** | `app.js:141-154` `loadPacks()` + `loadPacks()` at `:326`. Start body `app.js:230-237` includes `jd_kind`, `pack_id`, `paste`, `persona`, `temperature`. |
| Start without a JD is rejected in the UI (400 surfaced) | **Met** | Server 400 JSON `error` (independent HTTP this review). `api()` throws `data.error` (`app.js:50`). Start `catch` bubbles `err.message` (`app.js:251-252`). Operator sees the server string, not a silent reject. |
| Pack / paste toggle; temperature 1–5 default 2; live label | **Met** | `syncJdKind` `app.js:128-135`. Range `min=1 max=5 value=2` (`index.html:32`). `#temperature-val` updated on input (`app.js:137-139`). |
| Context after start via `textContent`; `source_label` + temperature in meta | **Met** | `app.js:241-246` uses `textContent` (not `innerHTML`). `showMeta` `:121-122`. Interface line “before/after start” is implemented as Step 4: show after start. `GET /api/packs` (Task 3) omits `context_text`, so pack preview before start is out of this task’s API. Paste textarea is the pre-start JD view. |
| `setBusy` disables Skip; Skip POSTs live temperature only; does not send textarea | **Met** | `app.js:202`. Skip body `{ temperature: tempInput.value }` (`:308-312`). Answer POST includes live temperature (`:277`). |
| Minimal CSS for `.setup` / `.context` | **Met** | `app.css:81-89` matches the plan block. |
| Plan Step 1 contract assertions | **Met** | `tests/test_memory_view.py:93-102` are the specified `assertIn` lines. |

Nothing extra in the product surface: no End-report rewrite (Task 6), no packs-API expansion, no demo-path chrome.

---

## Start 400 surfaced — independent confirmation

`POST /api/session/start` this review (live `Handler`, not implementer claim):

| Payload | HTTP | `error` |
| --- | --- | --- |
| `{}` | 400 | `jd kind must be pack or paste` |
| UI paste-empty body (`jd_kind=paste`, empty paste) | 400 | `paste text required` |
| Same with whitespace paste | 400 | `paste text required` |
| UI pack-empty body (`jd_kind=pack`, empty `pack_id`) | 400 | `pack_id required` |

Wiring (current `app.js`, read this review):

1. `api()` (`:47-51`): `if (!res.ok) throw new Error(data.error || res.statusText)`
2. `withWait` rethrows after removing the wait bubble (`:215-220`)
3. Start `catch` (`:251-252`): `bubble("interviewer", err.message || "Need a job description")`

`bubble` writes via `textContent` (`:42`), so the operator sees `paste text required` / `pack_id required` in chat. Fallback copy is only if `err.message` is empty. This matches the plan’s `data.error || "Need a job description"` (error string travels on `Error.message`).

Default chrome is `jd_kind=pack` plus the first loaded pack, so a first click on New session is **not** “without a JD” if `/api/packs` succeeded. The without-JD path is paste-empty or an empty pack select.

---

## Findings

### Critical

None.

### Important (fix before proceeding)

None.

### Minor (track)

#### Minor 1 — `tests/test_memory_view.py:93-102` does not lock 400 surfacing

`UiContractTest` asserts IDs and the substrings `/api/packs`, `jd_kind`, `/api/session/skip`. It does not assert `catch (err)`, `Need a job description`, or `data.error`. Removing the start `catch` still passes.

`HttpSmokeTest` (`:105-145`) was not extended (plan Step 1 only lists `UiContractTest` assertions). It still does not GET `/api/packs` or POST start-without-JD.

**Fix (optional, later):** assert the catch / fallback string in `UiContractTest`, or add one `HttpSmokeTest` POST paste-empty → 400 `paste text required`.

#### Minor 2 — `app/static/app.js:121-125` interpolates `source_label` into `innerHTML`

Paste `source_label` is the first line of operator-controlled JD text (`packs.py:135-139`). `showMeta` builds chips with string HTML. A first line like `<img onerror=…>` would render as markup. `context_text` is correctly assigned with `textContent`. Localhost, single operator, self-XSS only.

**Fix:** build chips with `createElement` / `textContent` (same as `bubble`).

#### Minor 3 — `app/static/app.js:151-153` pack load failure is silent; Skip/answer still uncaught

`loadPacks` swallows `/api/packs` errors and leaves `#pack-id` empty. Start then 400s `pack_id required` (surfaced). Operator is not told packs failed to load.

New Skip handler (`:304-317`) has no `catch`. Sessionless Skip is HTTP 409 (`server.py:207-208`) and becomes an unhandled rejection — wait bubble is removed, chat gets nothing. Answer/End already had this shape; only Start was wrapped, as the plan required.

**Fix (optional):** surface pack-load failure in `#jd-context` or a hint; wrap Skip like Start if silent 409 bothers operators.

---

## Correctness

- Pack vs paste is exclusive via `jd_kind` on the server (`require_session_jd`). Extra `pack_id` in paste mode / leftover paste in pack mode cannot start the wrong JD.
- Temperature from the range is the string `"1"`–`"5"`; `normalize_temperature` accepts that (Task 3, out of edit scope, already present).
- Skip does not read `#answer`. Mid-session temperature is on the next Send/Skip only.
- Failed start does not clear chat (success path does). Stale `#jd-context` from a prior successful start can remain visible after a later 400 — cosmetic.
- `if (data.temperature)` is safe because the server sends `"1"`–`"5"` strings, not `0`.

## Security

- Context body uses `textContent`. Error bubbles use `textContent`.
- New innerHTML sink is `source_label` (Minor 2). Temperature chip is server-normalized 1–5.
- No new secrets, no bind-address change, no pack_id path traversal from this UI (invalid ids 400 via existing sanitize).
- Paste/persona go to JSON then existing env export (Task 3). This task does not widen that.

## Simplicity

- Diff matches the plan snippets. Cached DOM refs instead of repeated `getElementById` are equivalent, not extra abstraction.
- No dead helpers. CSS is the specified block only.

## Tests

Command this review:

```
py -3 -m unittest tests.test_memory_view.UiContractTest -v
```

Result: `test_enter_sends_and_mic_exists ... ok` — Ran 1 test — **OK** (0.001s).

The new asserts would fail if the IDs or hook strings were missing. They would **pass** without 400-to-bubble, pack fill, toggle, or Skip POST body actually working (Minor 1). That matches how this file’s UI contract tests are written; it is not a Task 5 miss versus the specified Step 1 block.

---

## Verdict rationale

Task 5 chrome, start payload, Skip, live temperature, and 400-to-operator-bubble are present and independently confirmed. No spec miss that contradicts Step 4. No correctness or security issue that should block S5-T5. Track the untested 400 path, `source_label` innerHTML, and silent pack-load / Skip 409.
