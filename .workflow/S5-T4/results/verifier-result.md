# S5-T4 verifier result

Verdict: **survives**

Claim checked: S5-T4 is done — every Hermes turn sees the session JD; Skip asks again without persist.

Implementer report was not read. Implementation claims were treated as unevidenced until reproduced.

## Strongest reason

Independent isolated wrapper `skip` (no `CROSSFIRE_JD_CONTEXT` in the environment after start) emitted `skipped=true` `persist_recommended=false` `assessment_status=skipped` and left `spool/*.yaml` at 0 after two skips; independent in-process `POST /api/session/skip` returned **409** `no active session` for `{}`, `{temperature:9}`, and `{temperature:3}` (session gate first). Isolation used `/tmp/crossfire-verify-s5t4*` and a tempfile Hermes home only — not real `~/.hermes`.

## Acceptance criteria independently confirmed

| AC | Result | Evidence |
| --- | --- | --- |
| 1. `crossfire_practice_interviewer_preamble` exists and start/answer prompts name the session JD | **confirmed** | Helper at `scripts/practice_session.sh:32-45` interpolates `CROSSFIRE_JD_CONTEXT` under `Practice session JD`. Live `-q` sites call it: start memory-opener `:135`, start fresh `:139`, answer `:233` (skip also `:316`). Packet `Select-String` count on the script: **5**. `tests/practice_jd.sh` PASS `preamble helper exists` / `prompt names session JD`. |
| 2. `practice_session.sh skip` emits `skipped=true` `persist_recommended=false` and writes no spool yaml | **confirmed** | Suite + independent probe (below). Skip function has no yaml write; only answer writes `spool/${qid}.yaml` (`:262`). |
| 3. `POST /api/session/skip` exists and requires an active session | **confirmed** | `app/server.py:206-209` returns 409 when `SESSION["run_id"]` is empty. Independent HTTP: empty / bad temp / good temp → **409**; typo `/api/session/ski` → **404**. Packet `Select-String` count on `app/server.py`: **1**. |

Also independently confirmed: after `load_state`, empty context is reloaded from `jd-context.md` (`practice_session.sh:23-29`). `practice.state` stores no `CROSSFIRE_JD_CONTEXT` (probe `STATE_JD_CTX_LINES=0`, `JD_FILE=1`). Skip saved inbound temperature 4.

## Commands run (this verifier)

```
Select-String -Path scripts\practice_session.sh -Pattern 'crossfire_practice_interviewer_preamble'
  → Count 5

Select-String -Path app\server.py -Pattern '/api/session/skip'
  → Count 1

"C:\Program Files\Git\bin\bash.exe" tests/practice_jd.sh
  → PASS: start without JD fail-closed
  → PASS: source_id printed
  → PASS: temperature printed
  → PASS: preamble helper exists
  → PASS: prompt names session JD
  → PASS: skip kv
  → PASS: skip no persist
  → PASS: skip wrote no spool
  → PASS: skip saved temperature 4
  → practice_jd: passed=9 failed=0

Independent wrapper skip (HOME=/tmp/crossfire-verify-s5t4.9S2KN0, not ~/.hermes)
  unset CROSSFIRE_JD_CONTEXT after stub start
  → event=skip skipped=true assessment_status=skipped persist_recommended=false
  → question/tts_text present
  → START_SPOOL=0 SKIP_SPOOL_COUNT=0 SKIP2_SPOOL_COUNT=0
  → STATE_TEMP=CROSSFIRE_TEMPERATURE=4
  → JD_FILE=1 STATE_JD_CTX_LINES=0

py -3 in-process POST /api/session/skip (HERMES_HOME=tempfile, USING_REAL False)
  → EMPTY_BODY 409 {"error": "no active session"}
  → BAD_TEMP_NO_SESSION 409 {"error": "no active session"}
  → OK_TEMP_NO_SESSION 409 {"error": "no active session"}
  → TYPO_PATH 404 {"error": "not found"}
  → HEALTH 200 run_id null
```

## file:line reads

- `scripts/practice_session.sh:17-29` — `load_state` sources `practice.state`; if `CROSSFIRE_JD_CONTEXT` empty, cats `${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/jd-context.md`.
- `scripts/practice_session.sh:32-45` — preamble names `Practice session JD` and interpolates session context, source, temperature, persona.
- `scripts/practice_session.sh:135-143` — start memory-opener and fresh-start `-q` call preamble; then `crossfire_practice_inject_inference`.
- `scripts/practice_session.sh:233-238` — answer `-q` calls preamble; then inject_inference.
- `scripts/practice_session.sh:291-336` — `crossfire_practice_skip`: no spool yaml write; kv `skipped=true` `persist_recommended=false`; live `-q` calls preamble + inject_inference (`:316-319`).
- `scripts/practice_session.sh:262` — only yaml write is answer `spool/${qid}.yaml`.
- `scripts/practice_session.sh:402-405` — `skip)` case.
- `scripts/practice_session.sh:52-66` — `save_state` writes metadata + `jd-context.md`, not `CROSSFIRE_JD_CONTEXT` into `practice.state`.
- `app/server.py:206-228` — `POST /api/session/skip` requires `SESSION["run_id"]` (409), optional temperature, `run_practice(["skip"], ...)`.
- `tests/practice_jd.sh:9-15` — isolated `HOME`/`HERMES_HOME` under `mktemp /tmp/crossfire-practice-jd.*`, `CROSSFIRE_PRACTICE_STUB=1`.
- `tests/practice_jd.sh:43-59` — preamble greps; skip kv / no persist / no spool yaml / saved temperature 4.
- `scripts/practice_common.sh:133-137` — `crossfire_practice_inject_inference` still wraps speed-tune (max-turns 1, reasoning low).

## Isolation

No command used real `~/.hermes`. Wrapper probes set `HOME`/`HERMES_HOME` to `/tmp/crossfire-verify-s5t4*` or `/tmp/crossfire-practice-jd.*`. HTTP probes set `HERMES_HOME` to a tempfile (`USING_REAL False` vs `C:\Users\oalan\.hermes`). Skip HTTP does not invoke Hermes.

## What would have refuted (not found)

- Preamble helper missing, or start/answer live `-q` not calling it / not interpolating `CROSSFIRE_JD_CONTEXT`.
- `skip` succeeding without `skipped=true` or with `persist_recommended=true`.
- `skip` writing `spool/*.yaml`.
- Skip fail-closing after a valid start because context lives only in `jd-context.md`.
- `POST /api/session/skip` missing (404) or succeeding with `SESSION["run_id"]` empty.
- Sessionless skip validating temperature before the session gate (400 instead of 409).
- Packet commands or `tests/practice_jd.sh` failing.

## Scope note

HTTP skip **with** an active session was not proven on this host: `POST /api/session/start` from Windows Python returned 500 `/bin/bash: C:Usersoalaninterview-geescriptspractice_session.sh: No such file or directory` (backslash path eaten). That is host path-to-bash, not a missing skip route. AC3 as written is the session gate; wrapper skip already proves “asks again without persist.” Live Hermes was not invoked (stub + static `-q` reads), which the plan allows.

Sprint 5 task 4 only. UI chrome / Skip button not used as fail criteria.
