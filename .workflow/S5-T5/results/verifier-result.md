# S5-T5 verifier result

Verdict: **survives**

Claim checked: S5-T5 is done — operator can pick or paste one JD, set optional persona and temperature, see context, and Skip.

Implementer report was not read. Implementation claims were treated as unevidenced until reproduced from source, the specified unittest, and an isolated HTTP probe.

## Strongest reason

Independent isolated `POST /api/session/start` bodies matching the UI start payload returned **HTTP 400** with JD errors (`paste text required`, `pack_id required`, `jd kind must be pack or paste`). `api()` throws `data.error` on non-OK (`app.js:50`) and the start `catch` bubbles `err.message` (`app.js:251-253`), so that 400 is the interviewer chat text, not a silent reject. Isolation used a tempfile `HERMES_HOME` (`USING_REAL False`) — not real `~/.hermes`.

## Acceptance criteria independently confirmed

| AC | Result | Evidence |
| --- | --- | --- |
| 1. HTML has jd-kind, pack-id, jd-paste, persona, temperature, jd-context, skip | **confirmed** | `app/static/index.html` ids at `:16`, `:22`, `:25`, `:28`, `:31`, `:35`, `:43`. Served `/` in the HTTP probe contained `id="jd-kind"` and `id="skip"`. `UiContractTest` asserts the same strings. |
| 2. app.js fetches /api/packs and posts jd_kind on start | **confirmed** | `loadPacks()` `api("/api/packs")` at `app.js:141-154`, invoked at `:326`. Start body includes `jd_kind: jdKind.value` at `:232` plus pack_id, paste, persona, temperature. Independent `GET /api/packs` → **200** with shipped ids (`alter-ego`, `mastercard-r-281517`, `mccain-cyber-defense`, `praetor`). |
| 3. Start without a JD is rejected in the UI (400 surfaced) | **confirmed** | Server 400 JSON `error` on UI-shaped empty JD (probe below). `api()` `:50` throws that string. Start `catch` `:251-253` `bubble("interviewer", err.message \|\| "Need a job description")`. `withWait` has no catch (only `finally`), so the 400 reaches the bubble. |

Also independently confirmed (goal, not extra ACs): `#jd-context` is filled from `data.context_text` via `textContent` after start (`app.js:241-246`); Skip posts `/api/session/skip` with live temperature and does not send the answer textarea (`app.js:304-317`); `setBusy` disables `#skip` (`:202`); CSS `.setup` / `.context` present (`app.css:81-89`).

## Commands run (this verifier)

```
py -3 -m unittest tests.test_memory_view.UiContractTest
  → Ran 1 test in 0.001s  OK

py -3 -m unittest tests.test_memory_view -v
  → Ran 6 tests in 0.624s  OK
  → UiContractTest.test_enter_sends_and_mic_exists ok

py -3 in-process HTTP (HERMES_HOME=tempfile, USING_REAL False)
  → GET /api/packs 200 four shipped packs
  → GET /  contains id="jd-kind" and id="skip"
  → GET /static/app.js  contains /api/packs, jd_kind, Need a job description
  → POST /api/session/start {}
      400 {"error": "jd kind must be pack or paste"}
  → POST /api/session/start {"inference":"nous"}
      400 {"error": "jd kind must be pack or paste"}
  → POST UI paste-empty (jd_kind=paste, empty paste)
      400 {"error": "paste text required"}
  → POST UI paste-whitespace
      400 {"error": "paste text required"}
  → POST UI pack-empty (jd_kind=pack, empty pack_id)
      400 {"error": "pack_id required"}
  → POST old-UI-shaped (inference only + empty pack/paste, no jd_kind)
      400 {"error": "jd kind must be pack or paste"}
  → POST /api/session/skip {temperature:2} no session
      409 {"error": "no active session"}
```

## file:line reads

- `app/static/index.html:14-35` — `#session-setup` with jd-kind (pack/paste), pack-id, jd-paste, persona, temperature default 2, `#jd-context` hidden.
- `app/static/index.html:43` — `#skip` after Send.
- `app/static/app.js:47-51` — `api()` throws `data.error || res.statusText` when `!res.ok`.
- `app/static/app.js:128-135` — pack vs paste wrap toggle from `#jd-kind`.
- `app/static/app.js:141-154` — `loadPacks()` fills `#pack-id` from `/api/packs`.
- `app/static/app.js:200-206` — `setBusy` disables skip.
- `app/static/app.js:117-126` — `showMeta` chips for `source_label` and `temperature`.
- `app/static/app.js:223-254` — start POST body includes `jd_kind`; success shows context; catch bubbles server error.
- `app/static/app.js:304-317` — Skip POST `{temperature}` only; bubble class `skipped`.
- `app/static/app.js:326` — `loadPacks()` on load.
- `app/static/app.css:81-89` — setup chrome and scrollable context.
- `app/server.py:108-118` — `GET /api/packs`.
- `app/server.py:143-147` — start `ValueError` → HTTP 400 `{error}`.
- `app/packs.py:106-142` — empty pack_id / empty paste / missing kind raise the 400 strings above.
- `tests/test_memory_view.py:93-102` — contract asserts IDs plus `/api/packs`, `jd_kind`, `/api/session/skip`.

## Isolation

No command used real `~/.hermes`. HTTP probe set `HERMES_HOME` to `C:\Users\oalan\AppData\Local\Temp\tmpu0nj5fb_` (`USING_REAL False` vs `C:\Users\oalan\.hermes`). Start-without-JD hits `start_session_args` before `run_practice`, so Hermes was not invoked.

## What would have refuted (not found)

- Start `catch` missing or `api()` swallowing `!res.ok` — would leave 400 unsurfaced. Both present.
- Start body omitting `jd_kind` — old UI shape independently 400s; current body includes it.
- HTML missing any required id — present in file and in served `/`.
- `/api/packs` missing or empty — 200 with four shipped packs.
- Unittest fail — `UiContractTest` and full `tests.test_memory_view` both OK after the reads.

## Residual (does not refute done)

- `UiContractTest` is substring-only. Deleting the start `catch` would still pass. AC3 is locked by source + HTTP, not by the test.
- Default chrome is `jd_kind=pack` plus the first loaded pack, so the first New session click is not “without a JD” if packs loaded. The without-JD path is paste-empty or an empty pack select — both 400 and wired to the bubble.
- Browser click-through was not run here (packet asked for unittest + file read). Controller still owns live UI verification.
