# Packet 04-verify: S5-T6

Claim: S5-T6 is done. Treat that claim as unevidenced.

## Goal

End session shows Weak and Strong; MEMORY.md topics are {source} · {family}, not q_live practice gap.

## Acceptance criteria

1. End kv includes report_weak, report_strong, and report_text with Weak: and Strong:.
2. MEMORY.md topic is not q_live_01 practice gap.
3. UI shows report_text on End.

## Commands

```
Select-String -Path scripts\practice_session.sh -Pattern 'report_weak' | Measure-Object | Select-Object -ExpandProperty Count
Select-String -Path app\static\app.js -Pattern 'report_text' | Measure-Object | Select-Object -ExpandProperty Count
```

Also run Git Bash `tests/practice_jd.sh`. If MEMORY.md is missing, determine whether topic assignment in end() is correct and persist is a host gap (python3 fsync). Do not fail the task solely for the Windows Store python3 stub if topic code is `{label} · {family}` and report kv is proven. Still refute if the product still writes `q_live_01 practice gap`.

Write `.workflow/S5-T6/results/verifier-result.md`.
