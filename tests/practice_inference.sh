#!/usr/bin/env bash
# Inference flag helper + stub start prints the chosen provider.
set -euo pipefail
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

# shellcheck source=scripts/practice_common.sh
source "$REPO_ROOT/scripts/practice_common.sh"

CROSSFIRE_INFERENCE=nous
flags=$(crossfire_practice_inference_flags)
printf '%s\n' "$flags" | grep -q -- '--provider nous' && ok "nous provider flag" || bad "nous provider flag: $flags"
printf '%s\n' "$flags" | grep -q -- '--model' && ok "nous model flag" || bad "nous model flag: $flags"

CROSSFIRE_INFERENCE=codex
flags=$(crossfire_practice_inference_flags)
printf '%s\n' "$flags" | grep -q -- '--provider openai-codex' && ok "codex provider flag" || bad "codex provider flag: $flags"
printf '%s\n' "$flags" | grep -q -- 'gpt-5.6-luna' && ok "codex default luna" || bad "codex default model: $flags"

CROSSFIRE_INFERENCE=openai-codex
[ "$(crossfire_practice_resolve_inference)" = "codex" ] && ok "alias openai-codex" || bad "alias openai-codex"

if (CROSSFIRE_INFERENCE=cursor crossfire_practice_resolve_inference) >/dev/null 2>&1; then
  bad "cursor should fail_closed"
else
  ok "unknown inference fail-closed"
fi

cmd="hermes chat -Q --reasoning none --max-turns 3 --toolsets skills -q hi"
injected=$(crossfire_practice_inject_inference "$cmd")
printf '%s\n' "$injected" | grep -q 'hermes chat --provider' && ok "inject after hermes chat" || bad "inject: $injected"
printf '%s\n' "$injected" | grep -q -- '--max-turns 1' && ok "force max-turns 1" || bad "max-turns: $injected"
printf '%s\n' "$injected" | grep -q -- '--reasoning low' && ok "reasoning low" || bad "reasoning: $injected"
if printf '%s\n' "$injected" | grep -q -- '--reasoning none'; then
  bad "should not keep reasoning none: $injected"
else
  ok "drop reasoning none"
fi
if printf '%s\n' "$injected" | grep -q -- '--toolsets'; then
  bad "toolsets should be stripped: $injected"
else
  ok "strip toolsets"
fi

home=$(mktemp -d /tmp/crossfire-practice-inf.XXXXXX)
trap 'rm -rf "$home"' EXIT
export HOME="$home"
mkdir -p "$HOME/.hermes"
export HERMES_HOME="$HOME/.hermes"
export CROSSFIRE_PRACTICE_STUB=1
export CROSSFIRE_RUNS_DIR="$home/runs"

start_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_INFERENCE=codex \
  CROSSFIRE_JD_KIND=pack \
  CROSSFIRE_JD_SOURCE_ID=praetor \
  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only never-contain' \
  bash "$REPO_ROOT/scripts/practice_session.sh" start) || {
  bad "codex stub start failed"
  echo "$start_out"
  echo "practice_inference: passed=$pass failed=$fail"
  exit 1
}
echo "$start_out" | grep -q 'inference=codex' && ok "start prints inference=codex" || bad "start inference: $start_out"

echo "practice_inference: passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
