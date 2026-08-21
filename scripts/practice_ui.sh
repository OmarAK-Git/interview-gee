#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export HOME="${HOME:-/home/fish}"
export USER="${USER:-fish}"
export PATH="/home/fish/.local/bin:/usr/bin:/bin:${PATH:-}"
exec python3 app/server.py
