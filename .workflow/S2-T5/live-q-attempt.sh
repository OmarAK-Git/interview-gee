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
skill_ref=$(crossfire_ensure_isolated_skill)
cmd=$(crossfire_build_assessor_cmdline \
  'q_behavioral_01' behavioral \
  'Tell me about a time a detection you owned was wrong.' \
  'I just kind of watched the dashboard.' \
  "$skill_ref")
stdout=$(mktemp)
stderr=$(mktemp)
echo "CMD: $cmd"
echo "SKILL: $skill_ref"
if crossfire_hermes_invoke "$cmd" "$stdout" "$stderr"; then
  echo "LIVE_OK"
  echo "--- STDOUT ---"
  cat "$stdout"
  echo "--- STDERR ---"
  cat "$stderr"
else
  echo "LIVE_FAILED exit=$?"
  echo "--- STDOUT ---"
  cat "$stdout"
  echo "--- STDERR ---"
  cat "$stderr"
fi
rm -f "$stdout" "$stderr"
