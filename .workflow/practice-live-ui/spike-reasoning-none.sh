#!/usr/bin/env bash
# Spike: does --reasoning none clean stdout enough to parse a question without a reasoning dump?
set -euo pipefail
cd "$(dirname "$0")/../.."
# shellcheck disable=SC1091
source .workflow/practice-live-ui/spike-env.sh

OUT="${SPIKE_DIR}/results/spike-reasoning-none"
mkdir -p "$OUT"
SKILL="${HERMES_HOME}/skills/crossfire-interviewer"

hermes chat -Q \
  --reasoning none \
  -q "You are the Crossfire interviewer. Ask ONE product interview question about Mastercard Agent Suite R-281517. Reply with the question only." \
  --max-turns 3 \
  --toolsets skills \
  --skills "$SKILL" \
  --source tool \
  >"${OUT}/stdout.txt" 2>"${OUT}/stderr.txt" || true

{
  echo "stdout_bytes=$(wc -c < "${OUT}/stdout.txt")"
  echo "has_reasoning_box=$(grep -c 'Reasoning' "${OUT}/stdout.txt" || true)"
  echo "has_yaml=$(grep -c '^family:' "${OUT}/stdout.txt" || true)"
  echo "session_id=$(grep -E '^session_id:' "${OUT}/stderr.txt" | head -1 | sed -E 's/^session_id:[[:space:]]*//' || true)"
} | tee "${OUT}/summary.txt"
echo "----- stdout -----"
cat "${OUT}/stdout.txt"
