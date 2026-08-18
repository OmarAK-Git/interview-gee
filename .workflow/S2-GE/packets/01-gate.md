# Packet: S2-GE phase exit (verify-only)

## Goal

Confirm the deliverable demo: memory-only opener works across separate processes with candidate exclusion (or recorded degraded path).

## ACs

- Session two targets the weak area with no operator prompt that names it.
- Candidate skill is not in the live dir at opener (or degraded path is recorded).
- Session one and two are different processes and session IDs.
- Tests never mutate real ~/.hermes.

## Commands (test-runner)

```
Test-Path -LiteralPath tests\demo_session_1.bats -PathType Leaf
Test-Path -LiteralPath tests\demo_session_2.bats -PathType Leaf
Test-Path -LiteralPath tests\candidate_skill.bats -PathType Leaf
Test-Path -LiteralPath tests\isolation.bats -PathType Leaf
```

Do not implement features. Do not mutate ~/.hermes. Do not install packages.
Gate model: cursor-grok-4.6-high-fast. Never Opus.

Task-scoped sibling evidence (do not re-implement):
- `.workflow/S2-T5/results/verifier-result.md`
- `.workflow/S2-T6/results/verifier-result.md`
- `.workflow/S2-T7/results/verifier-result.md`
- `.workflow/S1-T1b/results/verifier-result.md` (isolation)
