# Packet 04-verify: S5-T3

Claim: S5-T3 is done. Treat that claim as unevidenced until you check it yourself.

## Goal

New session cannot start without exactly one JD (pack or paste).

## Acceptance criteria

1. start_session_args raises without jd_kind/pack/paste.
2. GET /api/packs lists the four shipped packs.
3. Wrapper start without JD fail-closes; start with pack prints source_id and temperature.
4. Existing stub session and inference starts still pass when given pack env.

## Scope

Sprint 5 task 3 only. Ignore Skip UI and End report. Do not fail this task because later tasks are incomplete.

If `practice_session_stub.sh` has persist failures, determine whether they are start/JD regressions or pre-existing persist/host issues. Only start/JD regressions refute this task.

## Commands you must run yourself

```
py -3 -m unittest tests.test_packs
Test-Path -LiteralPath tests\practice_jd.sh -PathType Leaf
```

Also independently:
- Call GET /api/packs (in-process server is fine) and confirm four pack ids.
- Run Git Bash `tests/practice_jd.sh`.
- Confirm pack_id `../SKILL` is rejected.

## Result path

Write `.workflow/S5-T3/results/verifier-result.md` with verdict `survives` or `refuted`.

Do not modify implementation files, git state, or the queue.
