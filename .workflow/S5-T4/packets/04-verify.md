# Packet 04-verify: S5-T4

Claim: S5-T4 is done. Treat that claim as unevidenced.

## Goal

Every Hermes turn sees the session JD; Skip asks again without persist.

## Acceptance criteria

1. crossfire_practice_interviewer_preamble exists and start/answer prompts name the session JD.
2. practice_session.sh skip emits skipped=true persist_recommended=false and writes no spool yaml.
3. POST /api/session/skip exists and requires an active session.

## Commands

```
Select-String -Path scripts\practice_session.sh -Pattern 'crossfire_practice_interviewer_preamble' | Measure-Object | Select-Object -ExpandProperty Count
Select-String -Path app\server.py -Pattern '/api/session/skip' | Measure-Object | Select-Object -ExpandProperty Count
```

Also run Git Bash `tests/practice_jd.sh`. Prove skip writes no spool. Prove skip HTTP requires an active session. Never use real `~/.hermes`.

Write `.workflow/S5-T4/results/verifier-result.md`. Do not modify implementation files.
