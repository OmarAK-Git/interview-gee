# Hermes install + isolation probe (2026-08-16)

Operator approved WSL install.

## Install

- Official: `curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-browser --skip-computer-use --skip-setup --non-interactive`
- Version: Hermes Agent v0.20.2 (2026.8.16)
- Binary: `/home/fish/.local/bin/hermes` → `/home/fish/.hermes/hermes-agent/venv/bin/hermes`
- Skipped: ripgrep, ffmpeg (no passwordless sudo); Playwright; interactive setup
- `npm install` for Node browser tools failed; CLI still runs

## Isolation probe

`HERMES_HOME=/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test hermes doctor`

Throwaway received: `memories/`, `sessions/`, `logs/`, `skills/`, `SOUL.md`, `state.db`, caches.

Real `/home/fish/.hermes` top-level after probe: `bin`, `hermes-agent`, `node` only. No operator `memories/`, `sessions/`, `state.db`, `config.yaml`, `SOUL.md`.

Windows `%USERPROFILE%\.hermes`: absent.

Install-tree `__pycache__` under `hermes-agent/` changed (Python import of the checkout). Treated as code-install side effect, not profile-data leak.

## Portal (2026-08-16)

- OAuth login succeeded; `auth.json` is under `.crossfire/profiles/test` (gitignored).
- Free tier: paid model IDs (including `openai/gpt-5.6-luna`, `tencent/hy3`) return credits-exhausted.
- Working default: `model.provider=nous`, `model.default=stepfun/step-3.7-flash:free`.
- Isolated `hermes chat -Q -q pong` returned `pong`.

## Still open

- YAML CROSSFIRE round-trip not probed
- Two-process session IDs not measured
