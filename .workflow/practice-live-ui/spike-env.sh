#!/usr/bin/env bash
# Shared env for practice-live-ui spikes. Isolated profile first; never default to Monday.
set -euo pipefail

export HOME=/home/fish
export USER=fish
export PATH="/home/fish/.local/bin:/usr/bin:/bin:${PATH:-}"

REPO_ROOT="${REPO_ROOT:-/mnt/c/Users/oalan/interview-gee}"
export HERMES_HOME="${HERMES_HOME:-${REPO_ROOT}/.crossfire/profiles/test}"
export SPIKE_DIR="${REPO_ROOT}/.workflow/practice-live-ui"

mkdir -p "${SPIKE_DIR}/results" "${HERMES_HOME}/skills" "${HERMES_HOME}/memories"

if [ ! -d "${HERMES_HOME}/skills/crossfire-interviewer" ]; then
  mkdir -p "${HERMES_HOME}/skills/crossfire-interviewer"
fi
cp "${REPO_ROOT}/skills/crossfire-interviewer/SKILL.md" \
  "${HERMES_HOME}/skills/crossfire-interviewer/SKILL.md"
if [ -f "${REPO_ROOT}/skills/crossfire-interviewer/questions.md" ]; then
  cp "${REPO_ROOT}/skills/crossfire-interviewer/questions.md" \
    "${HERMES_HOME}/skills/crossfire-interviewer/questions.md"
fi
