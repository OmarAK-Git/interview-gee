#!/usr/bin/env bash
set -euo pipefail
export HERMES_HOME=/tmp/cf-id-check2/.crossfire/profiles/verify
mkdir -p "$HERMES_HOME/memories"
cd /mnt/c/Users/oalan/interview-gee
# shellcheck disable=SC1091
source scripts/weakness_memory.sh
echo "alpha: [$(crossfire_compute_weakness_id behavioral alpha-story)]"
echo "beta: [$(crossfire_compute_weakness_id technical beta-tradeoff)]"
echo "gamma: [$(crossfire_compute_weakness_id product gamma-metric)]"
echo "delta: [$(crossfire_compute_weakness_id behavioral delta-gap)]"
raw=$(printf '%s\n%s' behavioral alpha-story | crossfire_sha256_hex)
echo "raw_hash=[$raw]"
echo "fixture_alpha=w-e00e42cd5216"
echo "fixture_beta=w-1ee6d6febe17"
echo "fixture_gamma=w-b2f32d5ee0be"
