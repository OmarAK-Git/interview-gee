#!/usr/bin/env bash
# One-time: copy working Nous config onto WSL Monday home. Does not commit secrets.
set -euo pipefail
export HOME=/home/fish
REPO=/mnt/c/Users/oalan/interview-gee
SRC="$REPO/.crossfire/profiles/test"
DST="$HOME/.hermes"
mkdir -p "$DST/skills/crossfire-interviewer" "$DST/memories"
cp "$SRC/config.yaml" "$DST/config.yaml"
if [ -f "$SRC/auth.json" ]; then
  cp "$SRC/auth.json" "$DST/auth.json"
fi
cp "$REPO/skills/crossfire-interviewer/SKILL.md" "$DST/skills/crossfire-interviewer/SKILL.md"
echo "monday_ready HERMES_HOME=$DST"
ls -l "$DST/config.yaml" "$DST/auth.json" "$DST/skills/crossfire-interviewer/SKILL.md"
