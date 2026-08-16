# Packet: S1-GE phase exit (verify-only)

## Goal

Confirm the platform contract is known, isolation is enforced, and core logic is testable.

## ACs

- docs/hermes-compatibility.md records verified/unsupported/documented-fallback for required capabilities.
- Isolation tests exist and claim real ~/.hermes is untouched (from restored baseline; first-run leak was operator-rmdir'd).
- Weakness merge and assessment fixture artifacts exist.

## Commands (test-runner)

```
Test-Path -LiteralPath docs\hermes-compatibility.md -PathType Leaf
Test-Path -LiteralPath tests\isolation.bats -PathType Leaf
Test-Path -LiteralPath tests\weakness_memory.bats -PathType Leaf
Test-Path -LiteralPath tests\assessment_eval.bats -PathType Leaf
```

Do not implement features. Do not mutate ~/.hermes. Do not install packages.
Gate model: cursor-grok-4.5-high. Never Opus.
