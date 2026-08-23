# Workflow Plan — S5-T5

## Goal

Operator can pick or paste one JD, set optional persona and temperature, see context, and Skip.

## Success Criteria

- [ ] HTML has jd-kind, pack-id, jd-paste, persona, temperature, jd-context, skip.
- [ ] app.js fetches /api/packs and posts jd_kind on start.
- [ ] Start without a JD is rejected in the UI (400 surfaced).

## Agent Plan

- Researcher: **skipped** — plan Task 5 specifies HTML, JS, CSS, and contract assertions.
- Implementer: required (`composer-2.5-fast`).
- Code reviewer: required.
- Skeptic verifier: required.
- Test runner: **skipped** — not a phase gate.

Controller will verify the UI in the browser after implement+review+verify.

## Work Packets

| ID | Objective | Ownership | Status |
| --- | --- | --- | --- |
| 01-research | Path choices | researcher | skipped |
| 02-implementation | UI chrome | implementer | pending |
| 03-review | Review | code-reviewer | pending |
| 04-verify | Verify | skeptic-verifier | pending |
