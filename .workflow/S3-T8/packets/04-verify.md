# Packet 04-verify: S3-T8

Goal: A reviewer sees durable artifacts without filesystem navigation, with bounded timeouts.

ACs: Success and timeout paths pass. A reviewer sees the durable artifacts without filesystem navigation.

Product: `scripts/demo_common.sh`, `tests/artifact_evidence.bats`

Command: `Test-Path -LiteralPath tests\artifact_evidence.bats -PathType Leaf`

Treat implementation claims as unevidenced. Re-run bash-equivalent including sourced set -e print. Isolation fail-closed. Never real ~/.hermes.

Write `.workflow/S3-T8/results/verifier-result.md`.
