# Active Context

## Current state

Repo bootstrap is in progress. Memory-bank now projects `sparring-1.0.0`. The implementation plan is loaded into `.workflow/autopilot-queue.json`. **No implementation tasks have started.**

## Immediate next step

First runnable queue item: **S1-T1** — verify the installed Hermes contract (read-only discovery, compatibility note, preflight).

Do not drain the loop until the operator asks.

## Constraints in force

- Spec `sparring-1.0.0` wins over the plan.
- Tests never mutate real `~/.hermes`.
- Never cut isolation, distinct processes, three demo questions, automatic persist, or the memory-only opener.
- All gates use `cursor-grok-4.5-high` (`in_session_grok`), never Opus.

## Profiles (from spec)

| Profile | Path | Used by |
| --- | --- | --- |
| Test | `.crossfire/profiles/test` via `HERMES_HOME` (or verified equivalent) | Automated tests |
| Stage | `.crossfire/profiles/stage` | Live 90s demo |
| Monday | Real `~/.hermes` | Free-form use after the event; not written by tests |
