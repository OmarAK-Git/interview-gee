#!/usr/bin/env bash
# Isolation + Monday allowlist for practice_common.sh (bats-equivalent).
set -euo pipefail
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

tmpdir=$(mktemp -d /tmp/crossfire-practice-home.XXXXXX)
trap 'rm -rf "$tmpdir"' EXIT

# 1) demo_common still fail-closes on real-looking home (safety property)
if HERMES_HOME=/tmp/evil/.hermes bash -c "source '$REPO_ROOT/scripts/demo_common.sh'" >/tmp/dc.out 2>/tmp/dc.err; then
  bad "demo_common should fail-close on /tmp/evil/.hermes"
else
  if grep -q "HERMES_HOME points at real profile" /tmp/dc.err /tmp/dc.out; then
    ok "demo_common landmine still fires"
  else
    bad "demo_common fail-closed without expected message"
  fi
fi

# 2) practice allowlist: HOME + \$HOME/.hermes only
export HOME="$tmpdir/wsl-home"
mkdir -p "$HOME/.hermes"
allowed="$HOME/.hermes"

if HERMES_HOME="$allowed" bash -c "source '$REPO_ROOT/scripts/practice_common.sh'; crossfire_require_monday_home; printf '%s' \"\$HERMES_HOME\"" >"$tmpdir/ok.out" 2>"$tmpdir/ok.err"; then
  got=$(cat "$tmpdir/ok.out")
  if [ "$got" = "$allowed" ] || [ "$(realpath "$got")" = "$(realpath "$allowed")" ]; then
    ok "practice accepts WSL \$HOME/.hermes"
  else
    bad "practice accepted but HERMES_HOME=$got"
  fi
else
  bad "practice rejected valid Monday path: $(cat "$tmpdir/ok.err")"
fi

# 3) refuse other .hermes
if HERMES_HOME=/tmp/evil/.hermes HOME="$HOME" bash -c "source '$REPO_ROOT/scripts/practice_common.sh'; crossfire_require_monday_home" >/dev/null 2>"$tmpdir/evil.err"; then
  bad "practice accepted /tmp/evil/.hermes"
else
  ok "practice rejects non-Monday .hermes"
fi

# 4) refuse Windows-style path even if exported
if HERMES_HOME='/mnt/c/Users/oalan/.hermes' HOME="$HOME" bash -c "source '$REPO_ROOT/scripts/practice_common.sh'; crossfire_require_monday_home" >/dev/null 2>"$tmpdir/win.err"; then
  bad "practice accepted Windows-mounted .hermes"
else
  if grep -qi "Windows\|must be WSL" "$tmpdir/win.err"; then
    ok "practice rejects Windows .hermes"
  else
    ok "practice rejects Windows .hermes (message: $(head -1 "$tmpdir/win.err"))"
  fi
fi

# 5) refuse isolated test profile
if HERMES_HOME="$REPO_ROOT/.crossfire/profiles/test" HOME="$HOME" bash -c "source '$REPO_ROOT/scripts/practice_common.sh'; crossfire_require_monday_home" >/dev/null 2>"$tmpdir/test.err"; then
  bad "practice accepted disposable test profile"
else
  ok "practice rejects test profile"
fi

# 6) no ALLOW_MONDAY flag in practice_common
if grep -q "CROSSFIRE_ALLOW_MONDAY" "$REPO_ROOT/scripts/practice_common.sh"; then
  bad "CROSSFIRE_ALLOW_MONDAY must not exist"
else
  ok "no CROSSFIRE_ALLOW_MONDAY hole"
fi

echo "practice_home: passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
