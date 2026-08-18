# Packet: S3-GE phase exit (verify-only)

Goal: Confirm the audience sees what was learned, which layer caused each behavior, and why ungated learning is dangerous.

ACs:
- Evidence display and risk beat artifacts exist.
- Demo script documents layer labels and the unverified-learning warning.

Commands:
```
Test-Path -LiteralPath tests\artifact_evidence.bats -PathType Leaf
Test-Path -LiteralPath tests\risk_beat.bats -PathType Leaf
Test-Path -LiteralPath tests\demo_e2e.bats -PathType Leaf
```

Sibling evidence: S3-T8, S3-T9, S3-T10 verifier results. Task 4 is not required to pass this gate.

Gate model: cursor-grok-4.6-high-fast. Never Opus. Do not implement. Do not mutate ~/.hermes.
