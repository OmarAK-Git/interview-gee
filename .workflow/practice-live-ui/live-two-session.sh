#!/usr/bin/env bash
# Live two-session smoke against WSL Monday. Not CI.
set -euo pipefail
export HOME=/home/fish USER=fish
export PATH="/home/fish/.local/bin:/usr/bin:/bin:${PATH:-}"
unset CROSSFIRE_PRACTICE_STUB || true
REPO=/mnt/c/Users/oalan/interview-gee
cd "$REPO"

echo "=== live session 1 start ==="
start1=$(bash scripts/practice_session.sh start)
printf '%s\n' "$start1"
run1=$(printf '%s\n' "$start1" | awk -F= '/^run_id=/{print $2; exit}')
sid1=$(printf '%s\n' "$start1" | awk -F= '/^session_id=/{print $2; exit}')
export CROSSFIRE_RUN_ID="$run1"

echo "=== live session 1 weak answer ==="
ans1=$(bash scripts/practice_session.sh answer "I just kind of watched the dashboard.")
printf '%s\n' "$ans1"

echo "=== live session 1 end ==="
end1=$(bash scripts/practice_session.sh end)
printf '%s\n' "$end1"

echo "=== live session 2 start (must not resume $sid1) ==="
unset CROSSFIRE_RUN_ID
start2=$(bash scripts/practice_session.sh start)
printf '%s\n' "$start2"
sid2=$(printf '%s\n' "$start2" | awk -F= '/^session_id=/{print $2; exit}')

printf 'sid1=%s\nsid2=%s\n' "$sid1" "$sid2"
if [ "$sid1" = "$sid2" ]; then
  echo "FAIL: session ids not distinct" >&2
  exit 1
fi
if ! printf '%s\n' "$start2" | grep -q 'opening_target_source=MEMORY.md'; then
  echo "WARN: opener source not MEMORY.md (check MEMORY.md on Monday)" >&2
fi
echo "LIVE_SMOKE_OK"
