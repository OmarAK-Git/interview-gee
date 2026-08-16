#!/usr/bin/env bash
set -euo pipefail
export HOME=/home/fish
export USER=fish
export PATH="/home/fish/.local/bin:/home/fish/.hermes/bin:/home/fish/.hermes/hermes-agent/venv/bin:${PATH}"
mkdir -p /home/fish/.local/bin
ln -sfn /home/fish/.hermes/hermes-agent/venv/bin/hermes /home/fish/.local/bin/hermes
if ! grep -q '.local/bin' /home/fish/.bashrc; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> /home/fish/.bashrc
fi
echo "which=$(command -v hermes)"
hermes --version
echo "---PROBE_START---"
REPO=/mnt/c/Users/oalan/interview-gee
THROW="$REPO/.crossfire/profiles/test"
mkdir -p "$THROW"
REAL=/home/fish/.hermes
# Snapshot real home (paths + sizes only; do not write a marker into it)
SNAP_BEFORE=$(find "$REAL" -printf '%P\t%s\n' | sort)
echo "real_file_count_before=$(printf '%s\n' "$SNAP_BEFORE" | wc -l)"
export HERMES_HOME="$THROW"
echo "HERMES_HOME=$HERMES_HOME"
hermes --version
hermes doctor || true
# A write that should land in HERMES_HOME if isolation works
hermes config get 2>/dev/null || true
echo "throw_listing:"
find "$THROW" -printf '%P\n' | sort | head -50
SNAP_AFTER=$(find "$REAL" -printf '%P\t%s\n' | sort)
echo "real_file_count_after=$(printf '%s\n' "$SNAP_AFTER" | wc -l)"
if [ "$SNAP_BEFORE" = "$SNAP_AFTER" ]; then
  echo "ISOLATION_PROBE=UNCHANGED"
else
  echo "ISOLATION_PROBE=CHANGED"
  echo "=== diff ==="
  comm -3 <(printf '%s\n' "$SNAP_BEFORE") <(printf '%s\n' "$SNAP_AFTER") | head -40
fi
# Windows real home must stay absent
if [ -e /mnt/c/Users/oalan/.hermes ]; then
  echo "WIN_HERMES=PRESENT"
else
  echo "WIN_HERMES=ABSENT"
fi
