#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/fish
export PATH="/home/fish/.local/bin:/home/fish/.hermes/hermes-agent/venv/bin:${PATH}"
export HERMES_HOME="/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test"
echo "=== config.yaml (no secrets expected) ==="
sed -n '1,80p' "$HERMES_HOME/config.yaml" 2>/dev/null || echo NO_CONFIG
echo "=== .env keys only ==="
if [ -f "$HERMES_HOME/.env" ]; then
  awk -F= '/./ && $1 !~ /^#/ {print $1}' "$HERMES_HOME/.env"
else
  echo NO_ENV
fi
echo "=== portal info ==="
hermes portal info 2>&1 | head -80
echo "=== hermes config get model ==="
hermes config get model 2>&1 || true
hermes config get model.default 2>&1 || true
