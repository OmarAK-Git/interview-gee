#!/usr/bin/env bash
set -euo pipefail
printf '%s\n%s' behavioral alpha-story | sha256sum
printf '%s\n%s' technical beta-tradeoff | sha256sum
printf '%s\n%s' product gamma-metric | sha256sum
# wrong (no newline) for contrast
printf '%s%s' behavioral alpha-story | sha256sum
