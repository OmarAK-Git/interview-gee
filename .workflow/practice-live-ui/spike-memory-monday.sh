#!/usr/bin/env bash
# Spike: MEMORY.md round-trip on the one allowed Monday path. Restores prior file.
set -euo pipefail
cd "$(dirname "$0")/../.."

export HOME=/home/fish
export USER=fish
export PATH="/home/fish/.local/bin:/usr/bin:/bin:${PATH:-}"

MONDAY=$(realpath /home/fish/.hermes)
export HERMES_HOME="$MONDAY"
SPIKE_DIR="/mnt/c/Users/oalan/interview-gee/.workflow/practice-live-ui"
OUT="${SPIKE_DIR}/results/spike-memory-monday"
mkdir -p "$OUT" "${HERMES_HOME}/memories"

resolved=$(realpath "$HERMES_HOME")
if [ "$resolved" != "$MONDAY" ]; then
  echo "REFUSE: HERMES_HOME=$resolved is not Monday $MONDAY" >&2
  exit 1
fi

MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"
MARKER_START='<!-- CROSSFIRE-WEAKNESSES:START -->'

if [ -f "$MEMORY_MD" ]; then
  cp -a "$MEMORY_MD" "${OUT}/monday-memory.prev.md"
  HAD_MEMORY=1
else
  HAD_MEMORY=0
fi

cat >"$MEMORY_MD" <<'EOF'
# Operator memory (spike; will be restored)

<!-- CROSSFIRE-WEAKNESSES:START -->
```yaml
version: 1
weaknesses:
  - weakness_id: w-mondayspike01
    family: product
    topic: "mastercard rollout sequencing"
    topic_key: mastercard-rollout-sequencing
    missing_elements: [metric, constraint]
    first_seen: 2026-08-21T19:30:00Z
    last_seen: 2026-08-21T19:30:00Z
    observation_count: 1
    source_session_id: sess_monday_spike
    answer_ref: spike-monday/q_product_01/0
    evidence:
      kind: quote
      value: "we would just ship it"
```
<!-- CROSSFIRE-WEAKNESSES:END -->
EOF

cp "$MEMORY_MD" "${OUT}/before.md"
sha_before=$(sha256sum "$MEMORY_MD" | awk '{print $1}')

restore_monday() {
  if [ "$HAD_MEMORY" = "1" ]; then
    cp -a "${OUT}/monday-memory.prev.md" "$MEMORY_MD"
  else
    rm -f "$MEMORY_MD"
  fi
}
trap restore_monday EXIT

echo "spike-memory-monday: HERMES_HOME=${HERMES_HOME}"
echo "spike-memory-monday: sha_before=${sha_before}"

hermes chat -Q \
  -q "Reply with exactly the word pong. Do not edit MEMORY.md." \
  --max-turns 1 \
  --toolsets skills,memory \
  --source tool \
  >"${OUT}/chat.stdout" 2>"${OUT}/chat.stderr" || true

cp "$MEMORY_MD" "${OUT}/after.md"
sha_after=$(sha256sum "$MEMORY_MD" | awk '{print $1}')

{
  echo "monday_path=${HERMES_HOME}"
  echo "had_prior_memory=${HAD_MEMORY}"
  echo "sha_before=${sha_before}"
  echo "sha_after=${sha_after}"
  if [ "$sha_before" = "$sha_after" ]; then echo "unchanged=yes"; else echo "unchanged=no"; fi
  if grep -Fq "$MARKER_START" "${OUT}/after.md" && grep -Fq "w-mondayspike01" "${OUT}/after.md"; then
    echo "markers=yes"
  else
    echo "markers=no"
  fi
} | tee "${OUT}/summary.txt"

echo "spike-memory-monday: restoring prior Monday MEMORY.md (had_prior=${HAD_MEMORY})"
