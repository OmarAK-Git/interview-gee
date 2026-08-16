#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/fish
export PATH="/home/fish/.local/bin:/home/fish/.hermes/hermes-agent/venv/bin:${PATH}"
export HERMES_HOME="/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test"
hermes chat -Q --max-turns 1 --safe-mode -q "Reply with exactly the word pong and nothing else."
echo "CHAT_EXIT=$?"
