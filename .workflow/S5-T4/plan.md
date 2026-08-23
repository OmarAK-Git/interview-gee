# Workflow Plan — S5-T4

## Goal

Every Hermes turn sees the session JD; Skip asks again without persist.

## Success Criteria

- [ ] crossfire_practice_interviewer_preamble exists and start/answer prompts name the session JD.
- [ ] practice_session.sh skip emits skipped=true persist_recommended=false and writes no spool yaml.
- [ ] POST /api/session/skip exists and requires an active session.

## Agent Plan

- Researcher: **skipped** — plan Task 4 specifies preamble, prompts, skip command, and HTTP route.
- Implementer: required (`composer-2.5-fast`).
- Code reviewer: required.
- Skeptic verifier: required.
- Test runner: **skipped** — not a phase gate.

## Ruling

After `crossfire_practice_load_state`, if `CROSSFIRE_JD_CONTEXT` is empty, read `${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/jd-context.md`. T3 persisted context to that file, not practice.state. Skip/answer must see the JD.

## Work Packets

| ID | Objective | Ownership | Status |
| --- | --- | --- | --- |
| 01-research | Path choices | researcher | skipped |
| 02-implementation | Preamble + Skip | implementer | pending |
| 03-review | Review | code-reviewer | pending |
| 04-verify | Verify | skeptic-verifier | pending |
