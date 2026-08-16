#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "HERMES_HOME defaults to repo isolated profile not real homes" {
  run bash -c "unset HERMES_HOME; source '$REPO_ROOT/scripts/demo_common.sh'; printf '%s' \"\$HERMES_HOME\""
  [ "$status" -eq 0 ]
  [[ "$output" == *".crossfire/profiles/test" ]]
  [[ "$output" != *"/.hermes" ]]
}

@test "preflight_check_paths rejects HERMES_HOME under /.hermes outside crossfire profiles" {
  run bash -c "export HERMES_HOME='/tmp/crossfire-fake/.hermes'; source '$REPO_ROOT/scripts/demo_common.sh'; preflight_check_paths"
  [ "$status" -ne 0 ]
  [[ "$output" == *"HERMES_HOME points at real profile"* ]]
}

@test "preflight_check_paths rejects operator WSL real home when overridden" {
  run bash -c "
    export HERMES_HOME='/home/fish/.hermes'
    export REAL_HERMES_WSL='/home/fish/.hermes'
    export REAL_HERMES_WIN=''
    source '$REPO_ROOT/scripts/demo_common.sh'
    preflight_check_paths
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"HERMES_HOME points at real profile"* ]]
}

@test "sourcing demo_common does not create real Win or WSL hermes directories" {
  run bash -c "
    CROSSFIRE_PATHS_ONLY=1 source '$REPO_ROOT/scripts/demo_common.sh'
    win_was_absent=0
    wsl_was_absent=0
    if [ -n \"\${REAL_HERMES_WIN:-}\" ] && [ ! -e \"\$REAL_HERMES_WIN\" ]; then win_was_absent=1; fi
    if [ ! -e \"\$REAL_HERMES_WSL\" ]; then wsl_was_absent=1; fi

    source '$REPO_ROOT/scripts/demo_common.sh'

    if [ \"\$win_was_absent\" -eq 1 ] && [ -n \"\${REAL_HERMES_WIN:-}\" ] && [ -e \"\$REAL_HERMES_WIN\" ]; then
      echo \"created REAL_HERMES_WIN: \$REAL_HERMES_WIN\" >&2
      exit 1
    fi
    if [ \"\$wsl_was_absent\" -eq 1 ] && [ -e \"\$REAL_HERMES_WSL\" ]; then
      echo \"created REAL_HERMES_WSL: \$REAL_HERMES_WSL\" >&2
      exit 1
    fi
  "
  [ "$status" -eq 0 ]
}

@test "start-wsl-isolated does not create real Win or WSL hermes directories" {
  run bash -c "
    CROSSFIRE_PATHS_ONLY=1 source '$REPO_ROOT/scripts/demo_common.sh'
    win_was_absent=0
    wsl_was_absent=0
    if [ -n \"\${REAL_HERMES_WIN:-}\" ] && [ ! -e \"\$REAL_HERMES_WIN\" ]; then win_was_absent=1; fi
    if [ ! -e \"\$REAL_HERMES_WSL\" ]; then wsl_was_absent=1; fi

    CROSSFIRE_HERMES_DISCOVERY=0 bash '$REPO_ROOT/scripts/start-wsl-isolated.sh'

    CROSSFIRE_PATHS_ONLY=1 source '$REPO_ROOT/scripts/demo_common.sh'
    if [ \"\$win_was_absent\" -eq 1 ] && [ -n \"\${REAL_HERMES_WIN:-}\" ] && [ -e \"\$REAL_HERMES_WIN\" ]; then
      echo \"created REAL_HERMES_WIN: \$REAL_HERMES_WIN\" >&2
      exit 1
    fi
    if [ \"\$wsl_was_absent\" -eq 1 ] && [ -e \"\$REAL_HERMES_WSL\" ]; then
      echo \"created REAL_HERMES_WSL: \$REAL_HERMES_WSL\" >&2
      exit 1
    fi
  "
  [ "$status" -eq 0 ]
}

@test "harness write under HERMES_HOME does not touch fake real-home marker" {
  fake_root="$(mktemp -d "${BATS_TMPDIR}/crossfire-fake-home.XXXXXX")"
  fake_hermes="${fake_root}/.hermes"
  marker="${fake_hermes}/isolation-marker"
  mkdir -p "$fake_hermes"
  printf 'UNTOUCHED\n' >"$marker"

  run bash -c "
    export REAL_HERMES_WSL='$fake_hermes'
    export REAL_HERMES_WIN=''
    export HERMES_HOME='$REPO_ROOT/.crossfire/profiles/test'
    source '$REPO_ROOT/scripts/demo_common.sh'
    crossfire_harness_write_probe
  "
  [ "$status" -eq 0 ]
  [ "$(cat "$marker")" = "UNTOUCHED" ]

  rm -rf "$fake_root"
}

@test "start-wsl-isolated refuses real profile HERMES_HOME" {
  run bash -c "export HERMES_HOME='/tmp/evil-operator/.hermes'; bash '$REPO_ROOT/scripts/start-wsl-isolated.sh'"
  [ "$status" -ne 0 ]
  [[ "$output" == *"HERMES_HOME points at real profile"* ]]
}

@test "start-wsl-isolated exports isolated env without invoking hermes" {
  run env CROSSFIRE_HERMES_DISCOVERY=0 bash "$REPO_ROOT/scripts/start-wsl-isolated.sh"
  [ "$status" -eq 0 ]
  [[ "$output" == *"isolation env ready"* ]]
  [[ "$output" != *"hermes "* ]]
}

@test "crossfire_require_isolated_hermes_home enforces disposable profile" {
  run bash -c "source '$REPO_ROOT/scripts/demo_common.sh'; crossfire_require_isolated_hermes_home; printf '%s' \"\$HERMES_HOME\""
  [ "$status" -eq 0 ]
  [[ "$output" == *".crossfire/profiles/test"* ]]
}

@test "sourcing demo_common fail-closed on pre-exported real HERMES_HOME" {
  run bash -c "export HERMES_HOME='/tmp/evil/.hermes'; source '$REPO_ROOT/scripts/demo_common.sh'"
  [ "$status" -ne 0 ]
  [[ "$output" == *"HERMES_HOME points at real profile"* ]]
}

@test "isolation contract documented in demo_common and compatibility doc" {
  grep -q "must source" "$REPO_ROOT/scripts/demo_common.sh"
  grep -q "crossfire_require_isolated_hermes_home" "$REPO_ROOT/scripts/demo_common.sh"
  grep -q "Task 1b" "$REPO_ROOT/docs/hermes-compatibility.md"
  grep -q "Hermes-invoking automation" "$REPO_ROOT/docs/hermes-compatibility.md"
}
