# Packet 02-implementation: S5-T4 Preamble, temperature, Skip

Researcher skipped: plan Task 4 is fully specified.

## Files allowed

- `scripts/practice_session.sh`
- `app/server.py`
- `tests/practice_jd.sh`
- `memory-bank/`

Plus `.workflow/S5-T4/results/implementer-result.md`.

Do not commit. Do not mark the queue done. Do not dispatch subagents. Do not touch real `~/.hermes`. Do not build UI chrome. Keep `crossfire_practice_inject_inference` (max-turns 1, reasoning low).

## Do

TDD. Implement plan Task 4 only, plus the jd-context load ruling.

Read first: `docs/superpowers/plans/2026-08-23-practice-interviewer.md` section **Task 4: Prompt injection, temperature on later turns, Skip** through the line before **Task 5**.

1. Append the Skip/preamble checks to `tests/practice_jd.sh` after a successful start.
2. See them fail.
3. Add `crossfire_practice_interviewer_preamble`, rewrite start/answer `-q` as specified, add `crossfire_practice_skip` and `skip)` case, add `POST /api/session/skip`, pass temperature on answer/skip.
4. Re-run Git Bash `tests/practice_jd.sh` (and stub start/skip path if needed).

## Ruling (required)

`practice.state` does not store `CROSSFIRE_JD_CONTEXT`. After `crossfire_practice_load_state`, if context is empty, load it from `jd-context.md`. Otherwise skip fail-closes even after a valid start.

## Acceptance criteria

- crossfire_practice_interviewer_preamble exists and start/answer prompts name the session JD.
- practice_session.sh skip emits skipped=true persist_recommended=false and writes no spool yaml.
- POST /api/session/skip exists and requires an active session.

## Report

Write `.workflow/S5-T4/results/implementer-result.md`. Return status, files, test summary, concerns.
