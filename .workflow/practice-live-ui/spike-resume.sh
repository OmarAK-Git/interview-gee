#!/usr/bin/env bash
# Spike: does hermes chat -Q --resume keep one session_id and interviewer follow-ups?
set -euo pipefail
cd "$(dirname "$0")/../.."
# shellcheck disable=SC1091
source .workflow/practice-live-ui/spike-env.sh

OUT="${SPIKE_DIR}/results/spike-resume"
mkdir -p "$OUT"
rm -f "$OUT"/turn*.stdout "$OUT"/turn*.stderr "$OUT"/summary.txt

SKILL="${HERMES_HOME}/skills/crossfire-interviewer"

echo "spike-resume: HERMES_HOME=${HERMES_HOME}"
echo "spike-resume: hermes=$(command -v hermes)"

# Turn 1: opener, no resume
hermes chat -Q \
  -q "You are the Crossfire interviewer skill. Ask ONE technical interview question about Project Praetor (advisory-only SOAR, never-contain list, hash-chained ledger). Reply with the question only. Do not mention session IDs." \
  --max-turns 1 \
  --toolsets skills \
  --skills "$SKILL" \
  --source tool \
  >"${OUT}/turn1.stdout" 2>"${OUT}/turn1.stderr" || {
  echo "turn1 failed rc=$?" | tee "${OUT}/summary.txt"
  cat "${OUT}/turn1.stderr" >>"${OUT}/summary.txt" || true
  exit 1
}

sid1=$(grep -E '^session_id:' "${OUT}/turn1.stderr" | head -1 | sed -E 's/^session_id:[[:space:]]*//' || true)
if [ -z "$sid1" ]; then
  sid1=$(grep -Eo 'sess[_-]?[A-Za-z0-9-]+' "${OUT}/turn1.stderr" | head -1 || true)
fi

{
  echo "turn1_session_id=${sid1:-MISSING}"
  echo "turn1_stdout_bytes=$(wc -c < "${OUT}/turn1.stdout")"
} | tee "${OUT}/summary.txt"
echo "----- turn1 stdout -----"
cat "${OUT}/turn1.stdout"
echo "----- turn1 stderr (tail) -----"
tail -40 "${OUT}/turn1.stderr"

if [ -z "$sid1" ]; then
  echo "FAIL: no session_id parsed from turn1 stderr" | tee -a "${OUT}/summary.txt"
  exit 1
fi

# Turn 2: resume with a short (strong-ish) answer
hermes chat -Q \
  --resume "$sid1" \
  -q "Answer: Praetor never auto-contains. The never-contain list is the advisory boundary. We would know a miss by checking the hash-chained audit ledger against the disposition. Ask a follow-up that probes verification, not a new topic." \
  --max-turns 1 \
  --toolsets skills \
  --skills "$SKILL" \
  --source tool \
  >"${OUT}/turn2.stdout" 2>"${OUT}/turn2.stderr" || {
  echo "turn2 failed rc=$?" | tee -a "${OUT}/summary.txt"
  cat "${OUT}/turn2.stderr" >>"${OUT}/summary.txt" || true
  exit 1
}

sid2=$(grep -E '^session_id:' "${OUT}/turn2.stderr" | head -1 | sed -E 's/^session_id:[[:space:]]*//' || true)
if [ -z "$sid2" ]; then
  sid2=$(grep -Eo 'sess[_-]?[A-Za-z0-9-]+' "${OUT}/turn2.stderr" | head -1 || true)
fi

{
  echo "turn2_session_id=${sid2:-MISSING}"
  echo "turn2_stdout_bytes=$(wc -c < "${OUT}/turn2.stdout")"
  if [ "$sid1" = "$sid2" ]; then
    echo "session_id_match=yes"
  else
    echo "session_id_match=no"
  fi
} | tee -a "${OUT}/summary.txt"

echo "----- turn2 stdout -----"
cat "${OUT}/turn2.stdout"
echo "----- turn2 stderr (tail) -----"
tail -40 "${OUT}/turn2.stderr"

echo "spike-resume: wrote ${OUT}/summary.txt"
