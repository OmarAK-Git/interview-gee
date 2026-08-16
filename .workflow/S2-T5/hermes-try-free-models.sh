#!/usr/bin/env bash
set -u
export HOME=/home/fish
export PATH="/home/fish/.local/bin:/home/fish/.hermes/hermes-agent/venv/bin:${PATH}"
export HERMES_HOME="/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test"
models=(
  "tencent/hy3"
  "stepfun/step-3.7-flash"
  "stepfun/step-3.7-flash:free"
  "poolside/laguna-s"
  "openai/gpt-5.6-luna"
)
for m in "${models[@]}"; do
  echo "TRY $m"
  out=$(hermes chat -Q --max-turns 1 --safe-mode -m "$m" -q "Reply with exactly the word pong and nothing else." 2>&1) || true
  echo "$out" | tail -8
  if echo "$out" | grep -qiE '^pong$| pong'; then
    echo "SUCCESS_MODEL=$m"
    hermes config set model.default "$m"
    exit 0
  fi
  if echo "$out" | grep -q "credits exhausted\|too low\|free model"; then
    echo "PAID_OR_BLOCKED=$m"
  fi
  echo "----"
done
echo "NO_FREE_MODEL_WORKED"
exit 1
