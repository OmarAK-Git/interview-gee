#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# wsl.exe inherits Windows HOME (e.g. C:\Users\...). That fails the Monday allowlist.
case "${HOME:-}" in
  /home/*) ;;
  *) HOME=/home/fish ;;
esac
export HOME
export USER="${USER:-fish}"
export PATH="/home/fish/.local/bin:/usr/bin:/bin:${PATH:-}"
export HERMES_HOME="${HOME}/.hermes"
exec python3 app/server.py
