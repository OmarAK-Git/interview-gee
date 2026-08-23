# Packet 04-verify: S5-T2

Claim: S5-T2 is done. Treat that claim as unevidenced until you check it yourself.

## Goal

Add a practice interviewer section that uses one session JD, temperature, probes, and Skip.

## Acceptance criteria

1. SKILL.md contains the Practice interviewer (session JD) heading plus temperature and Skip.
2. Three demo question strings remain verbatim.
3. ensure_skill copies sources/*.md into the live skill dir.

## Scope

Sprint 5 task 2 only. Ignore later Sprint 5 work (JD start, Skip UI, End report). Do not fail because S5-T3+ is incomplete.

## Changed files

- `skills/crossfire-interviewer/SKILL.md`
- `scripts/practice_session.sh`
- `tests/source_packs.sh`

## Commands you must run yourself

```
Select-String -Path skills\crossfire-interviewer\SKILL.md -Pattern 'Practice interviewer' | Measure-Object | Select-Object -ExpandProperty Count
Select-String -Path skills\crossfire-interviewer\SKILL.md -Pattern 'Walk through how Praetor decides not to contain' | Measure-Object | Select-Object -ExpandProperty Count
```

Also independently confirm:
- The three demo IDs / question strings are unchanged vs BASE if you can (`git show HEAD:skills/crossfire-interviewer/SKILL.md` vs working copy for those strings). Working tree may have uncommitted Task 2 edits; HEAD is S5-T1.
- `crossfire_practice_ensure_skill` copies `sources/*.md` (read the function). You may prove the copy with an isolated temp dest, never real `~/.hermes`.

## Result path

Write `.workflow/S5-T2/results/verifier-result.md` with verdict `survives` or `refuted`.

Do not modify implementation files, git state, or the queue.
