# Workflow Plan — S2-T5

## Goal

Run session one end-to-end in the isolated profile with exactly three questions and deferred automatic persistence.

## Success Criteria

- [x] E2E shows deferred automatic persistence.
- [x] Session one runs against installed Hermes in the isolated profile.
- [x] Exactly three questions; MEMORY.md unchanged until finalize after the third answer.
- [x] No persist confirmation prompt.
- [x] `scripts/demo_session_1.sh`, `tests/demo_session_1.bats`, and `tests/fixtures/demo-answers.txt` exist.

## Constraints

- Stay within S2-T5 scope and `files_allowed`: `skills/crossfire-interviewer/SKILL.md`, `scripts/demo_session_1.sh`, `scripts/demo_common.sh`, `tests/demo_session_1.bats`, `tests/fixtures/demo-answers.txt`.
- Spec `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` (`sparring-1.0.0`) wins over the plan. Spec path is `.crossfire/runs/<run_id>/` (plan's `.crossfire/run/` is superseded).
- Do not implement session-two opener or candidate skill staging (Task 6/7).
- Tests must never mutate real `~/.hermes`. Source isolation env. Use disposable `HERMES_HOME=.crossfire/profiles/test`.
- Verification is task-scoped. Later sprint gaps are out of scope.
- Ask before dependency installs, harness edits, clones, or writes outside the workspace.

## Risks

| Risk | Approval required | Mitigation |
| --- | --- | --- |
| Live Hermes chat writes real `~/.hermes` | no | Fail closed unless `HERMES_HOME` is under `.crossfire/profiles/`; never default to operator home |
| Hermes `memory` tool rewrites MEMORY.md before finalize | no | Researcher must choose disable-memory-tool vs harness-only writes; probe on throwaway profile only |
| Free-tier model flakiness for live E2E | no | Buffer + persist are harness-owned; live path retries assessment K=3; bats may split deterministic vs live |
| Native session state unverified | no | Fallback: session-ID-scoped buffer under `.crossfire/runs/<run_id>/` |

## Agent Plan

- Researcher: **run** — `needs_research: true`; ≥2 viable paths for assessment buffer (Hermes-native vs `.crossfire/runs/`), session driver (live chat vs harness-orchestrated), and test strategy (full live E2E vs deterministic + optional live).
- Implementer: required (`composer-2.5-fast` slug; queue name `composer-2.5`). Local drain resume 2026-08-18 (cloud dispatch previously failed: GitHub App missing repo).
- Code reviewer: required after code-changing implementation (`frequent_after_implement`).
- Skeptic verifier: required (`cursor-grok-4.6-high-fast`).
- Test runner: skipped — not a phase gate; `verification.scope` is `task`; policy is `gates_and_major_sections`.

## Work Packets

| ID | Objective | Ownership | Status |
| --- | --- | --- | --- |
| 01-research | Choose buffer, Hermes drive path, and test strategy | researcher | done |
| 02-implementation | Demo session-one harness, fixtures, bats | implementer | done_with_concerns |
| 03-review | Review code-changing diff | code-reviewer | done (approve after retry) |
| 04-verify | Task-scoped verification of ACs and commands | skeptic-verifier | done |

## Verification

| Check | Command | Required | Status |
| --- | --- | --- | --- |
| Session script exists | `Test-Path -LiteralPath scripts\demo_session_1.sh -PathType Leaf` | yes | pending |
| Session tests exist | `Test-Path -LiteralPath tests\demo_session_1.bats -PathType Leaf` | yes | pending |
| Scripted answers exist | `Test-Path -LiteralPath tests\fixtures\demo-answers.txt -PathType Leaf` | yes | pending |
