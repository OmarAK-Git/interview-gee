# Active Context

## Current state

Hermes Agent **v0.20.2** is installed on WSL Ubuntu (user `fish`). Isolation probe passed for **profile data** under `HERMES_HOME=.crossfire/profiles/test`. `S2-T5` is **pending** again (no longer blocked).

Nous Portal is logged in on the isolated test profile. Free-tier chat works with `stepfun/step-3.7-flash:free` (paid catalog IDs 404 without credits).

## Immediate next step

Drain `S2-T5` (three-question demo with deferred persistence).

## Isolation facts

- Real WSL `~/.hermes` is the **install** (`bin`, `hermes-agent`, `node`).
- Disposable profile: `<repo>/.crossfire/profiles/test`.
- Windows `%USERPROFILE%\.hermes` is absent.
