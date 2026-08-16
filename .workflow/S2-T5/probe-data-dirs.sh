#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/fish
REAL=/home/fish/.hermes
echo "=== real data files (exclude hermes-agent code tree) ==="
find "$REAL" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort
echo "=== operator data dirs ==="
for d in memories sessions logs skills cron; do
  if [ -e "$REAL/$d" ]; then
    echo "REAL_HAS_$d"
    find "$REAL/$d" -printf '%P\n' | head
  else
    echo "REAL_NO_$d"
  fi
done
for f in MEMORY.md config.yaml state.db SOUL.md USER.md .env; do
  if [ -e "$REAL/$f" ] || [ -e "$REAL/memories/$f" ]; then
    echo "REAL_HAS_$f"
  else
    echo "REAL_NO_$f"
  fi
done
if [ -e /mnt/c/Users/oalan/.hermes ]; then echo WIN_HERMES=PRESENT; else echo WIN_HERMES=ABSENT; fi
echo "=== throw memories ==="
ls -la /mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test/memories
echo "=== throw top ==="
ls /mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test
