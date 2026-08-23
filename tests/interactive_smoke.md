# Interactive smoke — free-form Monday usability (S4-T11)

Manual smoke record for non-demo Hermes use. Spec: plan Task 11 — agent continues beyond three questions; sensible no-weakness behavior; targets an existing weakness without demo chatter; optional `session_search` after opener; exit flushes qualifying observations.

## Environment (this record)

| Check | Result |
| --- | --- |
| Date | 2026-08-18 |
| Host | Windows 10 (`win32 10.0.26200`), implementer subagent session |
| WSL | `wsl.exe` present; invocation failed (`Wsl/Service/E_UNEXPECTED`) |
| Hermes on Windows PATH | **Not found** |
| Real `%USERPROFILE%\.hermes` | **Absent** (expected; demo/test never create it) |
| Hermes in WSL (`/home/fish/.local/bin/hermes`) | **Not probed** — WSL unavailable in this session |
| **Live free-form transcript** | **Not recorded** — Hermes not discoverable here |

Prior machine evidence (Task 1 / S2-T5): Hermes Agent **v0.20.2** at `/home/fish/.local/bin/hermes` with isolated `hermes chat -Q -q pong` → `pong`. See `docs/hermes-compatibility.md`.

## Isolation guard (executed)

Verified on Windows without touching real `~/.hermes`:

```powershell
Test-Path -LiteralPath "$env:USERPROFILE\.hermes"   # False
where.exe hermes                                     # not found
```

Demo/stage weaknesses remain under `<repo>/.crossfire/profiles/` only. **No copy** into real `~/.hermes` was attempted or performed.

## Procedure — isolated free-form rehearsal

Run from WSL when Hermes is available. Uses disposable profile + fixture memory (not Monday, not stage demo).

```bash
export REPO_ROOT="/mnt/c/Users/oalan/interview-gee"
export HERMES_HOME="${REPO_ROOT}/.crossfire/profiles/test"

# 1. Disposable profile with pre-existing weaknesses (newest: product w-b2f32d5ee0be)
mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills"
cp tests/fixtures/memory-three-weaknesses.md "${HERMES_HOME}/memories/MEMORY.md"
cp -r skills/crossfire-interviewer "${HERMES_HOME}/skills/"

# 2. Opener turn — session_search OFF
hermes chat \
  --skills crossfire-interviewer \
  --toolsets skills,memory \
  --source cli \
  -q "Start a return-session opener. Target the newest weakness in MEMORY.md. Ask one question for the missing elements. Do not name weakness_id."

# 3. Continue free-form (beyond three questions) — type answers at the REPL
hermes chat \
  --skills crossfire-interviewer \
  --toolsets skills,memory \
  --source cli

# 4. After first question answered, optional session_search (degrade if unsupported)
hermes chat \
  --skills crossfire-interviewer \
  --toolsets skills,memory,session_search \
  --source cli \
  --resume latest

# 5. End with normal Hermes exit; capture stdout for propose-only YAML
```

### Expected behaviors (pass criteria)

1. **Opener targets existing weakness** — question probes product `metric` / `decision` gaps (newest weakness `w-b2f32d5ee0be`) without demo fixture IDs or “scripted bad answer” language.
2. **Beyond three questions** — agent accepts additional Q&A from `questions.md` or natural follow-ups.
3. **No-weakness on strong answer** — after a complete STAR / technical / product answer, assessment YAML shows `missing_elements: []` or one gap only → `persist_recommended: false`.
4. **session_search** — only after opener; if tool missing, session continues without error spam.
5. **Exit flush** — on normal exit, qualifying proposals (`persist_recommended: true`) appear in transcript; harness-owned `MEMORY.md` merge is out of scope for raw interactive chat (documented in `README.md`).

## Stub run log (this session)

**What ran:** isolation checks above; file authoring for S4-T11 (`README.md`, `SKILL.md`, this record).

**What did not run:** steps 2–5 (no Hermes binary reachable from this Windows session).

**Placeholder for live transcript** — paste below when an operator completes the procedure on WSL:

```text
# LIVE RUN (pending)
# date:
# hermes --version:
# HERMES_HOME:
# opener question:
# answers (count > 3):
# sample assessment YAML:
# session_search used: yes/no/degraded
# exit path:
# qualifying proposals at exit:
```

## Monday profile note

For real Monday use, point `HERMES_HOME` at `$HOME/.hermes` and install the skill once (see `README.md`). Do **not** copy `stage` demo `MEMORY.md` or staged candidate skills into Monday. Build weakness history only from your own free-form sessions.

---

## Practice JD — live Luna close-out (S5-T7)

**Date:** 2026-08-23  
**Status:** **human_needed** — live Codex/Luna pass not run in implementer session. Design spec remains `approved design (awaiting implementation plan)` until this checklist is recorded.

Run on Monday WSL `HERMES_HOME` with Codex / `gpt-5.6-luna` (`bash scripts/practice_ui.sh`, open http://127.0.0.1:8787). Do not raise `--max-turns`; each turn is one `hermes chat -Q`.

### Live checklist

| # | Step | Pass? | Notes |
| --- | --- | --- | --- |
| 1 | New session: pack `praetor`, empty persona, temperature 2. Context visible. First question stays in Praetor facts. | pending | |
| 2 | Answer thinly. Next question probes or stays in-role. | pending | |
| 3 | Move temperature to 4. Next question is a rarer Praetor angle, not Mastercard/ALTER_EGO. | pending | |
| 4 | Skip once. No new weakness from the skipped question. | pending | |
| 5 | Answer well on one family (strong) and poorly on another (weak). | pending | |
| 6 | End. Report lists Weak and Strong. Panel title is `Project Praetor · …`, tags are only missing elements, quote is short. | pending | |
| 7 | New session, **paste** a different JD. Questions do not leak Praetor tokens. Optional persona fill once to confirm voice flavor. | pending | |

### Placeholder for live transcript

```text
# LIVE PRACTICE JD RUN (pending)
# date:
# hermes --version:
# HERMES_HOME:
# inference: Codex / gpt-5.6-luna
# pack session opener:
# temperature-4 question:
# skip observed (no persist):
# end report weak/strong:
# panel bucket titles ({source} · {family}):
# paste-JD session (no Praetor leak):
# persona flavor (optional):
```
