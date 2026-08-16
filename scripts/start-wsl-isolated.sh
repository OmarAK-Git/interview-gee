#!/usr/bin/env bash
# Hermes-specific WSL isolation entrypoint (Task 1b).
# Subsequent scripts must source scripts/demo_common.sh or this script
# before any write under HERMES_HOME or Hermes-touching automation.
# This script never mkdirs REAL_HERMES_WIN or REAL_HERMES_WSL; it only
# exports disposable HERMES_HOME and fail-closed checks via demo_common.sh.
set -euo pipefail

_start_wsl_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)
# shellcheck disable=SC1091
source "$_start_wsl_dir/demo_common.sh"

crossfire_apply_isolation_env
crossfire_require_isolated_hermes_home

export HERMES_HOME HERMES_MEMORY_MD HERMES_SKILLS_DIR HERMES_STATE_DB HERMES_CONFIG

if discover_hermes_bin >/dev/null 2>&1; then
  echo "start-wsl-isolated: Hermes binary discoverable; isolation env ready (Hermes invoke not started by this script)"
else
  echo "start-wsl-isolated: Hermes binary not discoverable; isolation env ready; Hermes invoke stopped"
fi

echo "hermes_home=${HERMES_HOME}"
echo "isolation env ready"
