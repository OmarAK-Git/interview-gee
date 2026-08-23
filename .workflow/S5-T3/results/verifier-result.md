# S5-T3 verifier result

Verdict: **survives**

Claim checked: S5-T3 is done — a new session cannot start without exactly one JD (pack or paste).

Implementer report was not read. Implementation claims were treated as unevidenced until reproduced.

## Strongest reason

Independent HTTP and wrapper runs show the gate is real, not a test-only assertion: in-process `GET /api/packs` returned HTTP 200 with exactly the four shipped ids; `start_session_args` and `POST /api/session/start` raise/400 without JD; isolated wrapper `start` exits 1 with `PREFLIGHT FAIL: practice start requires a session JD (pack or paste)` (not a Monday-home miss); wrapper `start` with pack env prints `source_id=praetor` and `temperature=2`. Isolation used `/tmp/crossfire-*` homes only — not real `~/.hermes`.

## Acceptance criteria independently confirmed

| AC | Result | Evidence |
| --- | --- | --- |
| 1. `start_session_args` raises without jd_kind/pack/paste | **confirmed** | unittest + independent Python raises `ValueError: jd kind must be pack or paste`; HTTP `POST /api/session/start` with `{"inference":"nous"}` returned **400** `{"error": "jd kind must be pack or paste"}` |
| 2. `GET /api/packs` lists the four shipped packs | **confirmed** | In-process `ThreadingHTTPServer` + `GET /api/packs` → HTTP 200, ids `alter-ego`, `mastercard-r-281517`, `mccain-cyber-defense`, `praetor` |
| 3. Wrapper start without JD fail-closes; start with pack prints source_id and temperature | **confirmed** | `tests/practice_jd.sh` 3/3; independent probe: no-JD / kind-only / context-only all RC=1 with JD fail-closed message; pack start RC=0 with `source_id=praetor` and `temperature=2` |
| 4. Existing stub session and inference starts still pass when given pack env | **confirmed (starts)** | `practice_inference.sh` 12/12 including `inference=codex` start; stub **start** passed (`event=start`, `run_id` printed). Persist/MEMORY.md failures are host/persist, not start/JD (see below) |

Also independently confirmed: `pack_id` `../SKILL` is rejected (`invalid pack_id '../SKILL'`). Same for `..\\SKILL`, `../SKILL.md`, `SKILL`, `../../etc/passwd`.

## Commands run (this verifier)

```
py -3 -m unittest tests.test_packs
  → Ran 8 tests in 0.002s  OK

Test-Path -LiteralPath tests\practice_jd.sh -PathType Leaf
  → True

py -3 in-process GET /api/packs (server.Handler, 127.0.0.1:ephemeral)
  → STATUS 200
  → IDS ['alter-ego', 'mastercard-r-281517', 'mccain-cyber-defense', 'praetor'] COUNT 4

py -3 independent start_session_args / require_session_jd
  → empty / nous-only / empty-strings / Nones: RAISED ValueError 'jd kind must be pack or paste'
  → TRAVERSAL_REJECT ../SKILL "invalid pack_id '../SKILL'"
  → VALID praetor 3 pack

"C:\Program Files\Git\bin\bash.exe" tests/practice_jd.sh
  → PASS: start without JD fail-closed
  → PASS: source_id printed
  → PASS: temperature printed
  → practice_jd: passed=3 failed=0

"C:\Program Files\Git\bin\bash.exe" tests/practice_session_stub.sh
  → PASS: start event, run_id printed, skip/assess/persist-recommended, end ack, strong answer
  → FAIL: MEMORY.md missing weakness block
  → FAIL: session two opener (opening_target_source=none)
  → "Python was not found" on persist path
  → practice_session: passed=8 failed=2

"C:\Program Files\Git\bin\bash.exe" tests/practice_inference.sh
  → practice_inference: passed=12 failed=0
  → start prints inference=codex

Isolated wrapper probe (HOME=/tmp/crossfire-verify-jd.3Oz3fR, not ~/.hermes)
  → NO_JD_RC=1 PREFLIGHT FAIL: practice start requires a session JD (pack or paste)
  → KIND_ONLY_RC=1 same message
  → CTX_ONLY_RC=1 same message
  → PACK_RC=0 source_id=praetor temperature=2 event=start

py -3 in-process POST /api/session/start {"inference":"nous"}
  → START_NO_JD 400 {"error": "jd kind must be pack or paste"}
```

## file:line reads

- `app/packs.py:96-104` — `_resolve_pack_path` rejects non-`^[a-z0-9]+(?:-[a-z0-9]+)*$` ids before join; resolved path must stay under `sources_dir`.
- `app/packs.py:106-142` — `require_session_jd` requires `pack` or `paste`; missing pack_id / empty paste raise; else `jd kind must be pack or paste`.
- `app/packs.py:145-160` — `start_session_args` always calls `require_session_jd` (no JD-optional path).
- `app/server.py:108-118` — `GET /api/packs` lists `id, employer, role, requisition, families` from `list_source_packs(PACKS)`.
- `app/server.py:143-148` — `POST /api/session/start` maps `ValueError` from `start_session_args` to HTTP 400 before `run_practice`.
- `scripts/practice_session.sh:77-80` — wrapper fail-closes if `CROSSFIRE_JD_KIND` or `CROSSFIRE_JD_CONTEXT` is empty.
- `scripts/practice_session.sh:141-144` — start kv prints `source_id`, `source_label`, `jd_kind`, `temperature`.
- `tests/test_packs.py:86-98` — `start_session_args` without JD raises; pack path returns praetor / temp 3.
- `tests/test_packs.py:82-84` — `../SKILL` rejected.
- `tests/practice_jd.sh:17-39` — no-JD must fail; pack start must print `source_id=praetor` and `temperature=2`. Isolated `HOME`/`HERMES_HOME` under `mktemp /tmp/crossfire-practice-jd.*`.
- `tests/practice_session_stub.sh:19-32` and `:69-74` — stub starts now pass pack env (`CROSSFIRE_JD_KIND=pack` + context).
- `tests/practice_inference.sh:56-68` — inference start given pack env.
- `skills/crossfire-interviewer/sources/*.md` — four files: `alter-ego`, `mastercard-r-281517`, `mccain-cyber-defense`, `praetor`.

## Stub persist failures (does not refute)

Packet: if `practice_session_stub.sh` persist fails, decide start/JD regression vs pre-existing persist/host. Only start/JD regressions refute.

- Start with pack env **passed** (`event=start`, `run_id` printed).
- Failure is after dashboard assess, on `end` persist: `Python was not found` (Windows Store alias from Git Bash). `MEMORY.md` never written → session-two opener stays `none`.
- This is a persist/host Python discovery issue, not a missing-JD or pack-env start break. Per packet, it does not refute S5-T3.

## Isolation

No command used real `~/.hermes`. Wrapper and bats-style scripts set `HOME`/`HERMES_HOME` to `/tmp/crossfire-*`. HTTP probes only hit `/api/packs` and `/api/session/start` validation (400 before shell).

## What would have refuted (not found)

- `GET /api/packs` missing any of the four ids, or not going through the HTTP handler.
- `start_session_args` accepting `{}` / nous-only / empty jd fields.
- Wrapper start without JD succeeding, or failing for a non-JD reason only.
- Wrapper start with pack omitting `source_id` or `temperature`.
- Stub or inference **start** failing when pack env is set.
- `../SKILL` resolving to a file under sources.

## Scope note

Sprint 5 task 3 only. Skip UI / End report not used as fail criteria. Wrapper accepts any non-empty `CROSSFIRE_JD_KIND` plus context (Python/HTTP still require `pack` or `paste`). That is weaker than the goal sentence but matches AC3 as written; not treated as a refute.
