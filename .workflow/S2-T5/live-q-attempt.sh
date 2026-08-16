#!/usr/bin/env bash
set -uo pipefail
export HOME=/home/fish
export PATH="/home/fish/.local/bin:$PATH"
export HERMES_HOME=/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test
REPO=/mnt/c/Users/oalan/interview-gee
cd "$REPO"
# shellcheck disable=SC1091
source "$REPO/scripts/demo_common.sh"
crossfire_require_isolated_hermes_home
cmd=$(crossfire_build_assessor_cmdline \
  'q_behavioral_01' behavioral \
  'Tell me about a time a detection you owned was wrong.' \
  'I just kind of watched the dashboard.' \
  "$REPO/skills/crossfire-interviewer")
stdout=$(mktemp)
stderr=$(mktemp)
echo "CMD: $cmd"
if crossfire_hermes_invoke "$cmd" "$stdout" "$stderr"; then
  echo "LIVE_OK"
  echo "--- STDOUT ---"
  cat "$stdout"
  echo "--- STDERR ---"
  cat "$stderr"
else
  echo "LIVE_FAILED exit=$?"
  echo "--- STDERR ---"
  cat "$stderr"
fi
rm -f "$stdout" "$stderr"
