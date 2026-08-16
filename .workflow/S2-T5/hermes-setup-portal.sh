#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/fish
export PATH="/home/fish/.local/bin:/home/fish/.hermes/hermes-agent/venv/bin:${PATH}"
export HERMES_HOME="/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test"
mkdir -p "$HERMES_HOME"
echo "HERMES_HOME=$HERMES_HOME"
# Allocate a PTY so --portal can run the OAuth wizard.
exec script -q -c 'hermes setup --portal' /tmp/hermes-setup-portal.log
