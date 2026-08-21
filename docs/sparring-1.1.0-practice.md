# sparring-1.1.0 — live practice (addendum)

**Date:** 2026-08-21  
**Authority:** this addendum wins for the practice app. `sparring-1.0.0` remains the demo CLI contract. Do not silently edit locked 1.0.0 decisions.

Written **after** live spikes (`.workflow/practice-live-ui/results/SPIKE.md`).

## What changed

- Practice is a local single-operator UI + harness. Hermes is the interviewer (`hermes chat -Q --resume` within a session).
- Durable writes for practice go to **exactly** canonical WSL `$HOME/.hermes` (realpath). Windows `%USERPROFILE%\.hermes` is always refused. There is **no** `CROSSFIRE_ALLOW_MONDAY` flag.
- `scripts/demo_common.sh` still fail-closes at source time on any real home. Tests and `demo.sh` keep that landmine. Practice sources `practice_common.sh` → `crossfire_lib.sh` and never punches the demo guard.
- After a proven live practice loop, `scripts/demo.sh` is **legacy**. Isolation fail-closed remains a safety requirement; demo-theater feature work is not.

## Spikes (load-bearing)

- `--resume` keeps one `session_id` and follow-ups (verified live on the isolated test profile).
- Isolated `MEMORY.md` HTML-comment block survived `skills` and `skills,memory` turns. Persistence branch: **memory-md-block**.
- Monday profile had no Nous `auth.json` until copied from the working test profile (gitignored). A no-keys Monday chat is not a round-trip proof.

## Degraded live turns

Parse failure (prose, truncated YAML, wrong family): keep the operator text, log raw stdout under `.crossfire/runs/<run_id>/skipped/`, skip assessment, continue the interview. Never `fail_closed` the session.

Practice does **not** inherit demo K=3 persist retry. One model pass per answer. `persist_recommended: false` / no weakness is success.

## TTS

Web Speech API behind `app/static/tts.js`. ElevenLabs is `app/static/elevenlabs.js` (stub). Default Chrome/Windows voices will undersell; that is a one-file swap, not architecture.

## Named cuts

- Session history / reread past sessions
- Candidate-skill promotion gate
- STT / voice agent / barge-in
- Dual-maintaining the 90s demo theater
