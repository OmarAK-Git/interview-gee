# Packet 04-verify: S5-T1

Claim: S5-T1 is done. Treat that claim as unevidenced until you check it yourself.

## Goal

Ship four spec-section-4 JD packs and a stdlib parser used by practice start.

## Acceptance criteria

1. Four packs exist and parse (id, facts, 4-6 competencies, core and edge, one family each).
2. Cross-pack leak check passes.
3. require_session_jd rejects missing JD; pack and paste paths return source_id, source_label, context_text.
4. normalize_temperature defaults to 2 and rejects 0 and 6.

## Scope

Sprint 5 task 1 only. Ignore later sprint work (practice UI, Skip, End report). Do not fail this task because S5-T2+ is incomplete.

## Changed files (implementation)

- `skills/crossfire-interviewer/sources/mccain-cyber-defense.md`
- `skills/crossfire-interviewer/sources/mastercard-r-281517.md`
- `skills/crossfire-interviewer/sources/praetor.md`
- `skills/crossfire-interviewer/sources/alter-ego.md`
- `app/packs.py`
- `tests/test_packs.py`
- `tests/source_packs.sh`

## Commands you must run yourself

```
Test-Path -LiteralPath skills\crossfire-interviewer\sources\praetor.md -PathType Leaf
Test-Path -LiteralPath app\packs.py -PathType Leaf
py -3 -m unittest tests.test_packs
```

Also run the leak check if possible:

```
& "C:\Program Files\Git\bin\bash.exe" tests/source_packs.sh
```

## Manual checks

None.

## Result path

Write `.workflow/S5-T1/results/verifier-result.md` with verdict `survives` or `refuted`, commands run, file:line reads, and the single strongest reason.

Do not modify implementation files, git state, or the queue.
