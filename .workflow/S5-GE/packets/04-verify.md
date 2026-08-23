# Packet 04-verify: S5-GE practice interviewer close-out

Verify-only gate. Model: cursor-grok-4.6-high-fast. Never Opus.

## Goal

Confirm Sprint 5 tasks meet the 2026-08-23 design: one JD, skill-steered questions, Skip, strong/weak report, family buckets. 1.0.0 demo untouched.

## Acceptance criteria

1. S5-T1 through S5-T7 are done with verifier evidence.
2. Four packs and skill procedure exist; demo three questions still verbatim.
3. Start requires a JD; Skip and End report exist in code.
4. Automated tests do not target real ~/.hermes.

## Commands (test-runner)

```
py -3 -m unittest tests.test_packs tests.test_memory_view
Test-Path -LiteralPath skills\crossfire-interviewer\sources\mastercard-r-281517.md -PathType Leaf
Select-String -Path skills\crossfire-interviewer\SKILL.md -Pattern 'q_technical_01' | Measure-Object | Select-Object -ExpandProperty Count
```

## Manual

Operator live pass recorded or explicitly left human_needed.

Isolation fail-closed still required. Do not infer 90s demo theater work. Do not treat stub as proof of the live bar.

## Evidence to consult (do not trust without checking)

- `.workflow/S5-T1/results/verifier-result.md` through `.workflow/S5-T7/results/verifier-result.md`
- Queue statuses for S5-T1..S5-T7
- `tests/interactive_smoke.md` live Luna human_needed

Write `.workflow/S5-GE/results/verifier-result.md` with pass/fail. Test-runner writes `.workflow/S5-GE/results/test-runner-result.md` first.
