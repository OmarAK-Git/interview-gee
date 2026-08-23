# Packet 04-verify: S5-T7

Claim: S5-T7 docs half is done. Live Luna pass is human_needed. Treat the docs claim as unevidenced.

## Acceptance criteria

1. Practice addendum states JD is required (pack or paste), persona optional, temperature 1-5 default 2, Skip, End report.
2. README practice UI bullets match.
3. No new automated test writes real ~/.hermes.

## Commands

```
Select-String -Path docs\sparring-1.1.0-practice.md -Pattern 'Session JD' | Measure-Object | Select-Object -ExpandProperty Count
py -3 -m unittest tests.test_packs tests.test_memory_view
```

Confirm design spec is not `implemented`. Confirm live pass is explicitly human_needed. Do not fail the task because the operator has not run Luna.

Write `.workflow/S5-T7/results/verifier-result.md`.
