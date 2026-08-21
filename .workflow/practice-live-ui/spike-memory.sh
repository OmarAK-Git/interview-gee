#!/usr/bin/env bash
# Spike: does a CROSSFIRE delimited MEMORY.md block survive a Hermes chat that can see memory?
set -euo pipefail
cd "$(dirname "$0")/../.."
# shellcheck disable=SC1091
source .workflow/practice-live-ui/spike-env.sh

OUT="${SPIKE_DIR}/results/spike-memory"
mkdir -p "$OUT"
MEMORY_MD="${HERMES_HOME}/memories/MEMORY.md"
mkdir -p "$(dirname "$MEMORY_MD")"

MARKER_START='<!-- CROSSFIRE-WEAKNESSES:START -->'
MARKER_END='<!-- CROSSFIRE-WEAKNESSES:END -->'

cat >"$MEMORY_MD" <<'EOF'
# Operator memory

Unrelated prose that must be preserved.

<!-- CROSSFIRE-WEAKNESSES:START -->
```yaml
version: 1
weaknesses:
  - weakness_id: w-spikeprobe01
    family: behavioral
    topic: "alter-ego validation evidence"
    topic_key: alter-ego-validation-evidence
    missing_elements: [action, result]
    first_seen: 2026-08-21T19:00:00Z
    last_seen: 2026-08-21T19:00:00Z
    observation_count: 1
    source_session_id: sess_spike
    answer_ref: spike/q_behavioral_01/0
    evidence:
      kind: quote
      value: "I just kind of watched the dashboard."
```
<!-- CROSSFIRE-WEAKNESSES:END -->

Trailing prose that must be preserved.
EOF

cp "$MEMORY_MD" "${OUT}/before.md"
sha_before=$(sha256sum "$MEMORY_MD" | awk '{print $1}')

SKILL="${HERMES_HOME}/skills/crossfire-interviewer"

echo "spike-memory: HERMES_HOME=${HERMES_HOME}"
echo "spike-memory: sha_before=${sha_before}"

# 1) skills-only (production interviewer toolset) — should not rewrite MEMORY.md
hermes chat -Q \
  -q "Read nothing from disk. Reply with exactly the word pong." \
  --max-turns 1 \
  --toolsets skills \
  --skills "$SKILL" \
  --source tool \
  >"${OUT}/skills-only.stdout" 2>"${OUT}/skills-only.stderr" || true

cp "$MEMORY_MD" "${OUT}/after-skills-only.md"
sha_skills=$(sha256sum "$MEMORY_MD" | awk '{print $1}')

# Restore known-good block before memory-tool probe
cp "${OUT}/before.md" "$MEMORY_MD"

# 2) skills,memory — the round-trip risk (Curator / memory tool rewrite)
hermes chat -Q \
  -q "You have in-context memory. Reply with exactly the word pong. Do not edit MEMORY.md." \
  --max-turns 1 \
  --toolsets skills,memory \
  --skills "$SKILL" \
  --source tool \
  >"${OUT}/skills-memory.stdout" 2>"${OUT}/skills-memory.stderr" || true

cp "$MEMORY_MD" "${OUT}/after-skills-memory.md"
sha_mem=$(sha256sum "$MEMORY_MD" | awk '{print $1}')

has_markers() {
  grep -Fq "$MARKER_START" "$1" && grep -Fq "$MARKER_END" "$1" && grep -Fq "w-spikeprobe01" "$1"
}

{
  echo "sha_before=${sha_before}"
  echo "sha_after_skills_only=${sha_skills}"
  echo "sha_after_skills_memory=${sha_mem}"
  if [ "$sha_before" = "$sha_skills" ]; then echo "skills_only_unchanged=yes"; else echo "skills_only_unchanged=no"; fi
  if [ "$sha_before" = "$sha_mem" ]; then echo "skills_memory_unchanged=yes"; else echo "skills_memory_unchanged=no"; fi
  if has_markers "${OUT}/after-skills-only.md"; then echo "skills_only_markers=yes"; else echo "skills_only_markers=no"; fi
  if has_markers "${OUT}/after-skills-memory.md"; then echo "skills_memory_markers=yes"; else echo "skills_memory_markers=no"; fi
} | tee "${OUT}/summary.txt"

echo "spike-memory: wrote ${OUT}/summary.txt"
