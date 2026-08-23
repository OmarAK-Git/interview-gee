# Packet 04-verify: S6-T1

Claim: S6-T1 is done. Treat as unevidenced.

## ACs

1. Practice New session first spoken question is a JD competency question, not a restatement of the newest MEMORY.md gap.
2. Follow-ups may probe a fitting weakness at most once inside the current story, then move on.
3. Skip yields a different JD question, not another turn on the same gap.
4. Do not rewrite demo.sh or demo_session_2.sh.
5. Design §5 and plan Task 4 no longer require a practice opener that targets missing_elements.
6. Persist rule remains >= 2.

## Commands

```
Select-String -Path scripts\practice_session.sh -Pattern 'targets those missing elements' | Measure-Object | Select-Object -ExpandProperty Count
Select-String -Path docs\superpowers\specs\2026-08-23-practice-interviewer-design.md -Pattern 'opener may target' | Measure-Object | Select-Object -ExpandProperty Count
Select-String -Path scripts\demo_session_2.sh -Pattern 'MEMORY.md' | Measure-Object | Select-Object -ExpandProperty Count
```

First two counts should be 0. Third should be >0. Also run Git Bash `tests/practice_jd.sh`. Never use real ~/.hermes.

Write `.workflow/S6-T1/results/verifier-result.md`.
