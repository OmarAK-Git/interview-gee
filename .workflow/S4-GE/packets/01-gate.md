# Packet: S4-GE final plan gate (verify-only)

Goal: Confirm demo-blocking acceptance criteria have recorded evidence and the demo is operable from a clean terminal.

ACs:
- docs/acceptance-checklist.md exists and covers demo-blocking criteria.
- Isolation and two-process opener evidence still exist.

Commands:
```
Test-Path -LiteralPath docs\acceptance-checklist.md -PathType Leaf
Test-Path -LiteralPath tests\demo_session_2.bats -PathType Leaf
Test-Path -LiteralPath tests\isolation.bats -PathType Leaf
```

Sibling: S4-T12, S2-GE, S1-T1b verifier results. Cuttable polish logged as known limitations is not a fail.

Gate model: cursor-grok-4.6-high-fast. Never Opus. Do not implement. Do not mutate ~/.hermes.
