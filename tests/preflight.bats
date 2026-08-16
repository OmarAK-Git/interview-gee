#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/demo_common.sh"
}

@test "preflight fails closed when Hermes is missing" {
  run env CROSSFIRE_HERMES_DISCOVERY=0 bash "$REPO_ROOT/scripts/preflight.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Hermes binary not discoverable"* ]]
}

@test "HERMES_HOME defaults to isolated repo profile not real ~/.hermes" {
  unset HERMES_HOME
  # shellcheck disable=SC1091
  source "$REPO_ROOT/scripts/demo_common.sh"
  [[ "$HERMES_HOME" == *".crossfire/profiles/test" ]]
  [ "$HERMES_HOME" != "$REAL_HERMES_WSL" ]
  if [ -n "$REAL_HERMES_WIN" ]; then
    [ "$HERMES_HOME" != "$REAL_HERMES_WIN" ]
  fi
}

@test "MEMORY.md and skill-dir paths are set under isolated HERMES_HOME" {
  [ -n "$HERMES_MEMORY_MD" ]
  [ -n "$HERMES_SKILLS_DIR" ]
  [[ "$HERMES_MEMORY_MD" == "$HERMES_HOME/memories/MEMORY.md" ]]
  [[ "$HERMES_SKILLS_DIR" == "$HERMES_HOME/skills" ]]
  [[ "$HERMES_STATE_DB" == "$HERMES_HOME/state.db" ]]
  [[ "$HERMES_CONFIG" == "$HERMES_HOME/config.yaml" ]]
}

@test "HERMES paths do not point at real home profile" {
  run bash -c "source '$REPO_ROOT/scripts/demo_common.sh' && preflight_check_paths"
  [ "$status" -eq 0 ]
}

@test "preflight_check_paths rejects throwaway HERMES_HOME ending in /.hermes" {
  run bash -c "export HERMES_HOME='/tmp/crossfire-fake/.hermes'; source '$REPO_ROOT/scripts/demo_common.sh'; preflight_check_paths"
  [ "$status" -ne 0 ]
  [[ "$output" == *"HERMES_HOME points at real profile"* ]]
}

@test "distinct session ID check fails closed when Hermes binary is missing" {
  HERMES_BIN=""
  run bash -c "source '$REPO_ROOT/scripts/demo_common.sh' && preflight_check_session_identifiability"
  [ "$status" -ne 0 ]
  [[ "$output" == *"fail-closed"* ]] || [[ "$output" == *"no Hermes binary"* ]]
}

@test "skill loading timing recorded as startup-only until proven otherwise" {
  run bash -c "source '$REPO_ROOT/scripts/demo_common.sh' && preflight_skill_loading_timing_note"
  [ "$status" -eq 0 ]
  [[ "$output" == *"startup-only"* ]]
}

@test "learning-loop latency recorded as documented-fallback placeholder" {
  run bash -c "source '$REPO_ROOT/scripts/demo_common.sh' && preflight_learning_loop_note"
  [ "$status" -eq 0 ]
  [[ "$output" == *"documented-fallback"* ]]
}

@test "Curator strategy is isolated via HERMES_HOME" {
  [ "$CURATOR_STRATEGY" = "isolated" ]
  [[ "$HERMES_HOME" == *".crossfire/profiles/"* ]]
}

@test "session_search observability documented in compatibility note" {
  [ -f "$REPO_ROOT/docs/hermes-compatibility.md" ]
  grep -q "session_search" "$REPO_ROOT/docs/hermes-compatibility.md"
  grep -qE "unsupported|documented-fallback|verified" "$REPO_ROOT/docs/hermes-compatibility.md"
}

@test "compatibility note covers MEMORY.md writer and YAML round-trip status" {
  grep -q "agent-direct" "$REPO_ROOT/docs/hermes-compatibility.md"
  grep -q "CROSSFIRE-WEAKNESSES" "$REPO_ROOT/docs/hermes-compatibility.md"
  grep -q "not proven to survive" "$REPO_ROOT/docs/hermes-compatibility.md"
  grep -q "documented-fallback" "$REPO_ROOT/docs/hermes-compatibility.md"
}

@test "compatibility note labels spec section 15 capabilities with evidence status" {
  grep -q "HERMES_HOME" "$REPO_ROOT/docs/hermes-compatibility.md"
  grep -qE "verified|unsupported|documented-fallback" "$REPO_ROOT/docs/hermes-compatibility.md"
  grep -q "Curator" "$REPO_ROOT/docs/hermes-compatibility.md"
}

@test "preflight prints capability summary before failing closed" {
  run env CROSSFIRE_HERMES_DISCOVERY=0 bash "$REPO_ROOT/scripts/preflight.sh"
  [ "$status" -ne 0 ]
  [[ "$output" == *"Hermes binary not discoverable"* ]]
  [[ "$output" == *"capability summary"* ]]
  [[ "$output" == *"memory_md:"* ]]
  [[ "$output" == *"skills_dir:"* ]]
  [[ "$output" == *"curator_strategy: isolated"* ]]
}
