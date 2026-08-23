#!/usr/bin/env bash
set -euo pipefail
REPO="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/../../.." && pwd)"
cd "$REPO"

home=$(mktemp -d /tmp/s5t6-verify.XXXXXX)
export HOME="$home"
mkdir -p "$HOME/.hermes"
export HERMES_HOME="$HOME/.hermes"
export CROSSFIRE_PRACTICE_STUB=1
export CROSSFIRE_RUNS_DIR="$home/runs"

real_hermes="$HOME/.hermes"
if [ "$HERMES_HOME" = "/c/Users/oalan/.hermes" ] || [ "$HERMES_HOME" = "$USERPROFILE/.hermes" ]; then
  echo "REFUSE: would use real hermes"
  exit 99
fi

echo "HOME=$HOME"
echo "HERMES_HOME=$HERMES_HOME"
echo "REPO=$REPO"

start_out=$(CROSSFIRE_JD_KIND=pack \
  CROSSFIRE_JD_SOURCE_ID=praetor \
  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only' \
  CROSSFIRE_TEMPERATURE=2 \
  bash "$REPO/scripts/practice_session.sh" start)
run_id=$(echo "$start_out" | awk -F= '/^run_id=/{print $2; exit}')
echo "RUN_ID=$run_id"

dash_out=$(CROSSFIRE_RUN_ID="$run_id" bash "$REPO/scripts/practice_session.sh" answer "I just kind of watched the dashboard.")
echo "=== DASH ==="
echo "$dash_out"

set +e
end_out=$(CROSSFIRE_RUN_ID="$run_id" bash "$REPO/scripts/practice_session.sh" end 2>"$home/end.err")
end_rc=$?
set -e
echo "=== END rc=$end_rc ==="
echo "$end_out"
echo "=== END STDERR ==="
cat "$home/end.err"
echo "=== STATE ==="
cat "$CROSSFIRE_RUNS_DIR/$run_id/practice.state"
echo "=== SPOOL ==="
ls -la "$CROSSFIRE_RUNS_DIR/$run_id/spool" || true
for f in "$CROSSFIRE_RUNS_DIR/$run_id/spool"/*.yaml; do
  [ -f "$f" ] || continue
  echo "--- $f ---"
  cat "$f"
done
echo "=== MEMORY ==="
if [ -f "$HERMES_HOME/memories/MEMORY.md" ]; then
  echo "MEMORY EXISTS"
  cat "$HERMES_HOME/memories/MEMORY.md"
else
  echo "MEMORY MISSING"
  ls -la "$HERMES_HOME" || true
  ls -la "$HERMES_HOME/memories" 2>/dev/null || true
fi
echo "=== GREP KEYS ==="
echo "$end_out" | grep -E '^(report_weak|report_strong|report_line|report_text|event|persisted_count)=' || true
echo "HOME_KEEP=$home"
