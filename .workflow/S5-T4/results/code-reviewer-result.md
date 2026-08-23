# S5-T4 code review — Prompt injection, temperature, Skip

**Packet:** `.workflow/S5-T4/packets/03-review.md`
**Reviewer:** code-reviewer (did not author this code)
**Date:** 2026-08-23
**Kind:** scoped review of plan Task 4 + jd-context load ruling
**Scope:** `scripts/practice_session.sh`, `app/server.py`, `tests/practice_jd.sh`
**BASE:** packet `03-review-diff.md` (S5-T3 → T4)

Implementer report treated as unevidenced. Spec is plan Task 4 only (`docs/superpowers/plans/2026-08-23-practice-interviewer.md` through the line before Task 5) plus the packet ruling: after `crossfire_practice_load_state`, empty `CROSSFIRE_JD_CONTEXT` must load `jd-context.md`.

**Verdict:** `block`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 1 |
| Minor | 2 |
| Blocking | 1 |

**Retry:** yes — capture incoming `CROSSFIRE_TEMPERATURE` before `crossfire_practice_load_state` in both `answer` and `skip`, persist it via `save_state`, and assert the saved value (and/or preamble) is the new temperature.

**Strongest issue:** Mid-session temperature is dead. Server/CLI can export `CROSSFIRE_TEMPERATURE=4`, but `load_state` sources `practice.state` (`CROSSFIRE_TEMPERATURE=2`) and overwrites it. Independent start(temp=2) then skip(temp=4) left `practice.state` at `2`.

---

## Spec compliance

| Requirement | Result | Evidence |
| --- | --- | --- |
| `crossfire_practice_interviewer_preamble` exists; start/answer `-q` name the session JD | **Met** | Helper at `practice_session.sh:32-45` includes `Practice session JD`. Used at start memory-opener `:135`, start fresh `:139`, answer `:224`. |
| Skip asks again without persist; `skipped=true` `persist_recommended=false`; no spool YAML | **Met** | `crossfire_practice_skip` (`:282-318`) never calls `crossfire_normalize_live_proposal` and never writes `spool/*.yaml`. Independent stub start+skip: kv as specified; `SPOOL_YAML_COUNT=0`; `ANY_YAML_UNDER_RUN=0`. |
| `POST /api/session/skip` exists and requires an active session | **Met** | `app/server.py:206-209` returns 409 `no active session` when `SESSION["run_id"]` is empty. Independent HTTP: `{}` → 409; `{temperature:9}` with no session → 409 (session gate first); fake `run_id` + temp 9 → 400. |
| Answer/skip POST may include `temperature`; server exports it and updates `practice.state` | **Not met** | Server export is present (`server.py:187-194`, `:211-218`) but wrapper `load_state` clobbers it (Important 1). |
| jd-context ruling: load `jd-context.md` after `load_state` if context empty | **Met** | `practice_session.sh:23-29`. Independent skip with only `CROSSFIRE_RUN_ID` (no `CROSSFIRE_JD_CONTEXT` in env) succeeded; `jd-context.md` existed after start. Missing state fail-closes `no practice session; run start`. |
| Keep `inject_inference` (max-turns 1, reasoning low) | **Met** | Start `:143`, answer `:229`, skip `:301` still call `crossfire_practice_inject_inference`. `practice_common.sh` unchanged. |
| Tests never mutate real `~/.hermes`; no UI chrome | **Met** | `practice_jd.sh` uses `mktemp` HOME. Diff does not touch `app/static/*`. |

---

## Findings

### Critical

None.

### Important (fix before proceeding)

#### Important 1 — `scripts/practice_session.sh:180` / `:285` `load_state` clobbers mid-session temperature

Task 4 interface: “Answer POST may include `temperature`; server exports `CROSSFIRE_TEMPERATURE` and updates `practice.state`.” Plan/spec: mid-session temperature applies to the **next** question only.

`crossfire_practice_save_state` always writes `CROSSFIRE_TEMPERATURE=N` (`:61`). `crossfire_practice_load_state` sources that file (`:22`), which **unconditionally assigns** the saved value.

Answer (`:180-184`) and skip (`:285-289`) then do:

```bash
crossfire_practice_load_state
CROSSFIRE_TEMPERATURE="${CROSSFIRE_TEMPERATURE:-2}"
```

Incoming env from the server (`extra_env["CROSSFIRE_TEMPERATURE"]`) or CLI is overwritten before the preamble runs and before `save_state`. The `${:-2}` default cannot help once state has set the variable.

Independent reproduction (Git Bash, stub, isolated HOME):

```
START_TEMP_STATE=CROSSFIRE_TEMPERATURE=2
# skip invoked with CROSSFIRE_TEMPERATURE=4
AFTER_SKIP_TEMP_STATE=CROSSFIRE_TEMPERATURE=2
```

`tests/practice_jd.sh:48-51` also passes `CROSSFIRE_TEMPERATURE=4` on skip and never checks state or preamble, so the suite stays green.

**Fix:** capture the inbound value before load, then persist it:

```bash
incoming_temp="${CROSSFIRE_TEMPERATURE:-}"
crossfire_practice_load_state
if [ -n "$incoming_temp" ]; then
  CROSSFIRE_TEMPERATURE="$incoming_temp"
fi
CROSSFIRE_TEMPERATURE="${CROSSFIRE_TEMPERATURE:-2}"
export CROSSFIRE_TEMPERATURE
```

Do this in both `crossfire_practice_answer` and `crossfire_practice_skip`. Extend `practice_jd.sh` to `grep CROSSFIRE_TEMPERATURE=4` on `$CROSSFIRE_RUNS_DIR/$run_id/practice.state` after the temp=4 skip.

---

### Minor (track)

#### Minor 1 — `tests/practice_jd.sh:43-46` preamble checks are source greps

`grep -q 'crossfire_practice_interviewer_preamble'` and `grep -q 'Practice session JD'` would pass if the helper existed but start/answer never called it. This review confirmed the three live `-q` sites do call it (`:135`, `:139`, `:224`). No HTTP test asserts `POST /api/session/skip` → 409; packet AC is met by reading `server.py:206-209` and an independent request this review, not by the task suite.

**Fix:** after the existing skip, assert saved temperature (see Important 1). Optional: one `HttpSmokeTest` POST `/api/session/skip` with empty `SESSION["run_id"]` expecting 409.

#### Minor 2 — `scripts/practice_session.sh:300` live skip has no `session_id` guard

Answer live path fail-closes on missing `CROSSFIRE_SESSION_ID` (`:223`). Skip builds `--resume` from the same variable with no check. Empty id would fail Hermes, then fall back to the canned JD-bound question (`:303`). Header comment (`:2`) still says `start | answer | end`.

**Fix:** `[ -n "$CROSSFIRE_SESSION_ID" ] || fail_closed "missing session_id"` before the live skip invoke (same as answer). Update the file header.

---

## Independent checks (not implementer claims)

### Skip writes no spool YAML

Isolated stub start (pack praetor) then `skip`:

- kv: `event=skip`, `skipped=true`, `assessment_status=skipped`, `persist_recommended=false`, `question=` / `tts_text=` set
- `find $run/spool -name '*.yaml'` → 0
- `find $run -name '*.yaml'` → 0
- `skip` with `CROSSFIRE_RUN_ID=does-not-exist` → rc 1, `PREFLIGHT FAIL: no practice session; run start`

`save_state` still `mkdir -p .../spool` (`:50`). Directory only; no YAML. Matches AC.

### `POST /api/session/skip` requires an active session

Spun `ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)` with `SESSION["run_id"]=None`:

| Request | Status | Body |
| --- | --- | --- |
| POST `{}` | 409 | `{"error": "no active session"}` |
| POST `{temperature: 9}` (no session) | 409 | same (session gate before temp) |
| POST `{temperature: 9}` after `run_id="run_fake"` | 400 | `temperature must be 1-5 (got 9)` |

### Temperature clobber

Same isolated start (`CROSSFIRE_TEMPERATURE=2`) then skip (`CROSSFIRE_TEMPERATURE=4`): `practice.state` remained `CROSSFIRE_TEMPERATURE=2`.

### `practice_jd.sh` this review

```
"C:\Program Files\Git\bin\bash.exe" tests/practice_jd.sh
# practice_jd: passed=8 failed=0
```

Passes without proving later-turn temperature (Important 1).

---

## Correctness / security / simplicity / tests (summary)

- **Correctness:** Skip contract and jd-context reload are right. Mid-session temperature is not: inbound env loses to sourced state on every answer/skip.
- **Security:** Skip is session-gated (409). Temperature is int-normalized 1–5 before export. Isolation (`mktemp` HOME) intact. No new persist writer. No real `~/.hermes`.
- **Simplicity:** Preamble + skip match the plan text. No UI chrome. No extra persist engine. `inject_inference` kept.
- **Tests:** Skip kv + no-spool are real behavioral checks. Preamble/JD naming and later-turn temperature are not. HTTP skip 409 is untested in-repo.

---

## Out of scope / not defects

- Task 5 UI chrome (`#skip`, slider → POST body) is not in this diff.
- Task 6 persist topic / end report still `q_live_N practice gap`.
- Stub answer still emits a Mastercard follow-up; pre-existing, not introduced by the T4 prompt rewrite.
- Plan skip snippet has the same load-then-`${:-2}` order; the Task 4 **interface** still requires the inbound temperature to win.
