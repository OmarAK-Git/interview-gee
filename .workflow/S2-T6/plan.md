# Workflow Plan — S2-T6

## Goal

A poor answer produces a visible provenance-linked candidate SKILL.md that is not loadable before session two.

## Success Criteria

- [ ] A poor answer produces a visible provenance-linked candidate SKILL.md.
- [ ] A pre-session-two assertion proves it is not loadable.
- [ ] If exclusion is impossible, the degraded path is recorded.
- [ ] `scripts/stage_candidate_skill.sh`, `tests/candidate_skill.bats`, and `.crossfire/candidate-skills/.gitkeep` exist.

## Constraints

- Stay within S2-T6 scope and `files_allowed`: `scripts/stage_candidate_skill.sh`, `.crossfire/candidate-skills/.gitkeep`, `tests/candidate_skill.bats`, `skills/crossfire-interviewer/SKILL.md`, `docs/hermes-compatibility.md`.
- Spec `sparring-1.0.0` wins. Candidate lives in `.crossfire/candidate-skills/` until after the opener. Harness owns that dir. Do not load it for the opener (Task 7).
- Do not implement session-two opener or risk-beat activation.
- Tests must never mutate real `~/.hermes`. Source isolation env.
- Verification is task-scoped.
- Ask before dependency installs, harness edits, clones, or writes outside the workspace.

## Risks

| Risk | Approval required | Mitigation |
| --- | --- | --- |
| Hermes learning loop writes candidate into live `$HERMES_SKILLS_DIR` | no | Snapshot immediately then disable/move reversibly; never leave candidate loadable before session two |
| Staging collides with S2-T5 runtime copy of the stable skill | no | Candidate must not use `crossfire-interviewer/` live path |
| Tests write real `~/.hermes` | no | Fail closed unless HERMES_HOME is under `.crossfire/profiles/` |

## Agent Plan

- Researcher: **run** — `needs_research: true`; ≥2 viable paths for authorship (Hermes-authored vs skill-authored vs harness-relocated) and exclusion (never-write-live vs snapshot-then-move).
- Implementer: required (`composer-2.5-fast`).
- Code reviewer: required after code-changing implementation (`frequent_after_implement`).
- Skeptic verifier: required (`cursor-grok-4.6-high-fast`).
- Test runner: skipped — not a phase gate; `verification.scope` is `task`.

## Work Packets

| ID | Objective | Ownership | Status |
| --- | --- | --- | --- |
| 01-research | Choose authorship, staging path, and live-dir exclusion | researcher | done |
| 02-implementation | Stage candidate skill + tests | implementer | in_progress |
| 03-review | Review code-changing diff | code-reviewer | pending |
| 04-verify | Task-scoped verification of ACs and commands | skeptic-verifier | pending |

## Verification

| Check | Command | Required | Status |
| --- | --- | --- | --- |
| Stage script exists | `Test-Path -LiteralPath scripts\stage_candidate_skill.sh -PathType Leaf` | yes | pending |
| Candidate tests exist | `Test-Path -LiteralPath tests\candidate_skill.bats -PathType Leaf` | yes | pending |
| Staging gitkeep exists | `Test-Path -LiteralPath .crossfire\candidate-skills\.gitkeep -PathType Leaf` | yes | pending |
