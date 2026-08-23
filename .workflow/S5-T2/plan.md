# Workflow Plan — S5-T2

## Goal

Add a practice interviewer section that uses one session JD, temperature, probes, and Skip.

## Success Criteria

- [ ] SKILL.md contains the Practice interviewer (session JD) heading plus temperature and Skip.
- [ ] Three demo question strings remain verbatim.
- [ ] ensure_skill copies sources/*.md into the live skill dir.

## Constraints

- Stay within `files_allowed`.
- Append after Free-form Monday mode. Do not edit the three demo question strings or demo harness scripts.
- Propose-only YAML unchanged.
- Tests never mutate real `~/.hermes`.
- Verification is task-scoped.

## Risks

| Risk | Approval required | Mitigation |
| --- | --- | --- |
| Accidental edit to demo questions | no | source_packs.sh verbatim grep + question_bank IDs |
| ensure_skill overwrite of unrelated files | no | copy only SKILL.md, questions.md, sources/*.md |

## Agent Plan

- Researcher: **skipped** — plan Task 2 specifies exact SKILL.md block, ensure_skill body, and test assertions. No path fork.
- Implementer: required (`composer-2.5-fast`; queue slug `composer-2.5` unavailable).
- Code reviewer: required after code-changing implementation.
- Skeptic verifier: required (`cursor-grok-4.6-high-fast`).
- Test runner: **skipped** — not a phase gate.

## Work Packets

| ID | Objective | Ownership | Status |
| --- | --- | --- | --- |
| 01-research | Path choices | researcher | skipped |
| 02-implementation | Skill procedure + ensure_skill | implementer | pending |
| 03-review | Review code-changing diff | code-reviewer | pending |
| 04-verify | Task-scoped verification | skeptic-verifier | pending |

## Verification

| Check | Command | Required | Status |
| --- | --- | --- | --- |
| Practice heading | `Select-String -Path skills\crossfire-interviewer\SKILL.md -Pattern 'Practice interviewer'` | yes | pending |
| Demo question verbatim | `Select-String -Path skills\crossfire-interviewer\SKILL.md -Pattern 'Walk through how Praetor decides not to contain'` | yes | pending |
