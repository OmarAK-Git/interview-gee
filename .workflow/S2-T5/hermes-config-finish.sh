#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/fish
export PATH="/home/fish/.local/bin:/home/fish/.hermes/hermes-agent/venv/bin:${PATH}"
export HERMES_HOME="/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test"
hermes config set model.provider nous
hermes config set model.default openai/gpt-5.6-luna
hermes config set model.base_url https://inference-api.nousresearch.com/v1
echo "provider=$(hermes config get model.provider)"
echo "default=$(hermes config get model.default)"
echo "base_url=$(hermes config get model.base_url)"
echo "--- chat help ---"
hermes chat --help 2>&1 | head -50
