#!/usr/bin/env bash
# Prove persist topic when a real python3 is on PATH. Isolated only.
set -euo pipefail
REPO="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/../../.." && pwd)"
cd "$REPO"

home=$(mktemp -d /tmp/s5t6-persist.XXXXXX)
shim=$(mktemp -d /tmp/s5t6-py3shim.XXXXXX)
# Git Bash: point python3 at Windows py launcher
cat >"$shim/python3" <<'EOF'
#!/usr/bin/env bash
exec py -3 "$@"
EOF
chmod +x "$shim/python3"
export PATH="$shim:$PATH"

export HOME="$home"
mkdir -p "$HOME/.hermes"
export HERMES_HOME="$HOME/.hermes"
export CROSSFIRE_PRACTICE_STUB=1
export CROSSFIRE_RUNS_DIR="$home/runs"

echo "python3=$(command -v python3)"
python3 --version
echo "HERMES_HOME=$HERMES_HOME"

start_out=$(CROSSFIRE_JD_KIND=pack \
  CROSSFIRE_JD_SOURCE_ID=praetor \
  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only' \
  CROSSFIRE_TEMPERATURE=2 \
  bash "$REPO/scripts/practice_session.sh" start)
run_id=$(echo "$start_out" | awk -F= '/^run_id=/{print $2; exit}')
CROSSFIRE_RUN_ID="$run_id" bash "$REPO/scripts/practice_session.sh" answer "I just kind of watched the dashboard." >/dev/null
end_out=$(CROSSFIRE_RUN_ID="$run_id" bash "$REPO/scripts/practice_session.sh" end 2>"$home/end.err")
echo "=== END ==="
echo "$end_out"
echo "=== STDERR ==="
cat "$home/end.err"
echo "=== MEMORY ==="
if [ -f "$HERMES_HOME/memories/MEMORY.md" ]; then
  echo "MEMORY EXISTS"
  cat "$HERMES_HOME/memories/MEMORY.md"
  if grep -q 'q_live_01 practice gap' "$HERMES_HOME/memories/MEMORY.md"; then
    echo "HAS_OLD_TOPIC=yes"
  else
    echo "HAS_OLD_TOPIC=no"
  fi
  if grep -E -q 'Project Praetor|praetor' "$HERMES_HOME/memories/MEMORY.md"; then
    echo "HAS_SOURCE_LABEL=yes"
  else
    echo "HAS_SOURCE_LABEL=no"
  fi
  if grep -q ' · ' "$HERMES_HOME/memories/MEMORY.md"; then
    echo "HAS_DOT_FAMILY=yes"
    grep -E 'topic:' "$HERMES_HOME/memories/MEMORY.md" || true
  else
    echo "HAS_DOT_FAMILY=no"
  fi
else
  echo "MEMORY MISSING"
fi
