#!/usr/bin/env bash
# Isolation contract (Task 1b): every harness script and test must source this
# file (or scripts/start-wsl-isolated.sh) before writing under HERMES_HOME.
# Call crossfire_require_isolated_hermes_home before any write; sourcing
# fail-closed when HERMES_HOME points at a real profile.
# Product scripts never mkdir REAL_HERMES_WIN or REAL_HERMES_WSL; the only
# mkdir is under disposable HERMES_HOME in crossfire_harness_write_probe.
# tests/isolation.bats snapshots absence of real homes in-process and fails
# if a previously absent REAL_HERMES_* path appears.
set -euo pipefail

demo_common_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
# shellcheck source=scripts/crossfire_lib.sh
source "${demo_common_dir}/crossfire_lib.sh"

if [ "${CROSSFIRE_PATHS_ONLY:-}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi

HERMES_HOME="${HERMES_HOME:-${REPO_ROOT}/.crossfire/profiles/test}"
crossfire_apply_hermes_derived_paths

if is_real_hermes_home "${HERMES_HOME}"; then
  fail_closed "HERMES_HOME points at real profile: $HERMES_HOME"
fi
