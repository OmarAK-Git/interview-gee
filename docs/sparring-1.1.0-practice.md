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

## Voice

Web Speech TTS in `app/static/tts.js`. Web Speech STT in `app/static/stt.js` (Chrome/Edge on localhost). Speak toggles listening; click **Done** or press Enter to send. Starting STT cancels TTS (barge-in). ElevenLabs remains `app/static/elevenlabs.js` (stub). Default Chrome/Windows voices will undersell; that is a one-file swap, not architecture.

## Composer and weaknesses panel

Enter sends the answer; Shift+Enter inserts a newline. `/api/memory` still returns raw `MEMORY.md` `text` (on-disk YAML unchanged) plus a parsed `weaknesses` array. The aside renders cards (family, topic, missing elements, last seen, quote), not YAML.

## Inference (Nous / Codex)

The interviewer is still Hermes (`hermes chat --resume`). The UI **Inference** control chooses the model provider for the next **New session** only:

| Choice | Hermes flags | Pays |
| --- | --- | --- |
| Nous (default) | `--provider nous --model stepfun/step-3.7-flash:free` | Nous Portal |
| Codex | `--provider openai-codex --model gpt-5.4` | ChatGPT / Codex subscription |

Override models with `CROSSFIRE_NOUS_MODEL` / `CROSSFIRE_CODEX_MODEL`. Does **not** rewrite `config.yaml`. Codex needs `hermes auth add openai-codex` (or imported `~/.codex/auth.json`) on the Monday `HERMES_HOME`.

## Named cuts

- Session history / reread past sessions
- Candidate-skill promotion gate
- Dual-maintaining the 90s demo theater
