# Workflow Plan — S2-T7

## Goal

Session two targets the persisted weakness with no naming prompt, no loaded candidate (or disclosed degraded path), and no pre-opener search.

## Success Criteria

- [ ] Automated and manual runs both show session two targeting the persisted weakness.
- [ ] No naming prompt, no loaded candidate (or disclosed degraded path), no pre-opener search.
- [ ] Distinct process and session IDs versus session one.
- [ ] Opener prints opening_target_source, weakness_id, and source_session_id before the question.
- [ ] `scripts/demo_session_2.sh` and `tests/demo_session_2.bats` exist.

## Constraints

- files_allowed: `scripts/demo_session_2.sh`, `scripts/demo_common.sh`, `skills/crossfire-interviewer/SKILL.md`, `tests/demo_session_2.bats`.
- Spec §9 selection order and §13 opener win.
- Do not implement the risk beat (Task 9).
- Tests never mutate real `~/.hermes`.
- Task-scoped verification.

## Risks

| Risk | Approval required | Mitigation |
| --- | --- | --- |
| Candidate still in live skill dir at opener | no | Fail unless `crossfire_assert_candidates_excluded_from_live` passes |
| session_search before opener | no | `--toolsets skills` (omit session_search); drop search-detection if unverified; prove disk artifact + distinct IDs |
| Session IDs collide | no | Capture session one ID from T5 stderr; new process for session two |

## Agent Plan

- Researcher: **skipped** — `needs_research: false`; spec §9/§13 lock selection, MEMORY.md as sole target source, and session_search documented-fallback. No remaining close opportunity cost.
- Implementer: required (`composer-2.5-fast`).
- Code reviewer: required after code-changing implementation.
- Skeptic verifier: required (`cursor-grok-4.6-high-fast`).
- Test runner: skipped — not a phase gate.

## Work Packets

| ID | Objective | Ownership | Status |
| --- | --- | --- | --- |
| 01-research | Path choices | researcher | skipped (spec-locked) |
| 02-implementation | Session-two opener harness + tests | implementer | pending |
| 03-review | Review code-changing diff | code-reviewer | pending |
| 04-verify | Task-scoped verification | skeptic-verifier | pending |

## Verification

| Check | Command | Required | Status |
| --- | --- | --- | --- |
| Session two script | `Test-Path -LiteralPath scripts\demo_session_2.sh -PathType Leaf` | yes | pending |
| Session two tests | `Test-Path -LiteralPath tests\demo_session_2.bats -PathType Leaf` | yes | pending |
