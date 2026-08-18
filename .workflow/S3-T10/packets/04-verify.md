# Packet 04-verify: S3-T10

Goal: Compose a full-sequence smoke that completes within 90 seconds after pre-warm.

ACs: Three consecutive rehearsals complete within 90s and produce expected evidence and opener. Failure exits early with recovery. Reset/prep never deletes unrelated Hermes state.

Product: `scripts/demo.sh`, `tests/demo_e2e.bats`, `docs/demo-script.md`

Commands:
```
Test-Path -LiteralPath scripts\demo.sh -PathType Leaf
Test-Path -LiteralPath tests\demo_e2e.bats -PathType Leaf
Test-Path -LiteralPath docs\demo-script.md -PathType Leaf
```

Manual: timed rehearsal evidence if e2e cannot enforce wall-clock 90s.

Treat implementation claims as unevidenced. Re-run bash-equivalent. Isolation fail-closed. Never real ~/.hermes.

Write `.workflow/S3-T10/results/verifier-result.md`.
