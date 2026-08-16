#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(dirname "$0")/demo_common.sh"

preflight_print_capability_summary() {
  echo "=== Hermes preflight capability summary ==="
  echo "repo_root: ${REPO_ROOT}"
  echo "hermes_home: ${HERMES_HOME}"
  echo "memory_md: ${HERMES_MEMORY_MD}"
  echo "skills_dir: ${HERMES_SKILLS_DIR}"
  echo "state_db: ${HERMES_STATE_DB}"
  echo "config: ${HERMES_CONFIG}"
  echo "real_hermes_win: ${REAL_HERMES_WIN:-absent}"
  echo "real_hermes_wsl: ${REAL_HERMES_WSL}"
  echo "wsl_distro: ${WSL_DISTRO}"
  echo "wsl_user: ${WSL_USER}"
  echo "curator_strategy: ${CURATOR_STRATEGY}"
  echo "memory_writer: ${MEMORY_WRITER}"
  echo "persistence_branch: ${PERSISTENCE_BRANCH} (first post-install attempt: ${PERSISTENCE_BRANCH_FIRST_ATTEMPT})"
  echo "session_search: ${SESSION_SEARCH_OBSERVABILITY}"
  preflight_skill_loading_timing_note
  preflight_learning_loop_note
}

main() {
  preflight_check_paths

  if HERMES_BIN=$(discover_hermes_bin); then
    HERMES_BIN=${HERMES_BIN//$'\r'/}
    if HERMES_VERSION=$(discover_hermes_version "$HERMES_BIN"); then
      echo "hermes_executable: verified bin=${HERMES_BIN} version=${HERMES_VERSION}"
    else
      HERMES_BIN=""
      HERMES_VERSION=""
      echo "hermes_executable: unsupported (binary discovery ambiguous for user ${WSL_USER})"
    fi
  else
    HERMES_BIN=""
    HERMES_VERSION=""
    echo "hermes_executable: unsupported (not on Windows PATH or WSL non-interactive PATH for user ${WSL_USER})"
  fi

  preflight_print_capability_summary

  if [ -z "$HERMES_BIN" ]; then
    preflight_check_session_identifiability || true
    fail_closed "Hermes binary not discoverable; install required before demo automation"
  fi

  preflight_check_session_identifiability

  echo "preflight: pass (Hermes discoverable; paths isolated; see docs/hermes-compatibility.md for fallback paths)"
}

main "$@"
