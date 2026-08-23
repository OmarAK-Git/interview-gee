# Workflow Plan — S5-T1

## Goal

Ship four spec-section-4 JD packs and a stdlib parser used by practice start.

## Success Criteria

- [x] Four packs exist and parse (id, facts, 4-6 competencies, core and edge, one family each).
- [x] Cross-pack leak check passes.
- [x] require_session_jd rejects missing JD; pack and paste paths return source_id, source_label, context_text.
- [x] normalize_temperature defaults to 2 and rejects 0 and 6.

## Constraints

- Stay within the queue item's scope and `files_allowed`.
- Practice design (`docs/superpowers/specs/2026-08-23-practice-interviewer-design.md`) and plan Task 1 are the source of truth for this increment. `sparring-1.0.0` demo contract is unchanged.
- Do not change SKILL.md demo questions, practice UI, or persist topics.
- Do not claim completion without fresh verifier evidence.
- Verification is task-scoped.
- Ask before dependency installs, harness edits, clones, or writes outside the workspace.
- Tests must never mutate real `~/.hermes`.
- Stdlib only for `app/packs.py`. No new dependencies.

## Risks

| Risk | Approval required | Mitigation |
| --- | --- | --- |
| Pack facts leak across employers | no | `tests/source_packs.sh` leak regexes; Mastercard must not contain Praetor tokens |
| Parser invents extra API | no | Transcribe plan Task 1 interfaces only |
| Isolation landmine | no | Packs/parser are static; no Hermes invocation |

## Agent Plan

- Researcher: **skipped** — plan Task 1 specifies exact pack contents, APIs, tests, and leak-check script. No ≥2 viable paths or opportunity-cost fork.
- Implementer: required. Harness has `composer-2.5-fast` only (queue default `composer-2.5` slug unavailable). Ruling: dispatch `composer-2.5-fast`.
- Code reviewer: required after code-changing implementation (`frequent_after_implement`).
- Skeptic verifier: required (`cursor-grok-4.6-high-fast`).
- Test runner: **skipped** — not a phase gate; task-scoped verification only (`test_runner_policy: gates_and_major_sections`).

## Work Packets

| ID | Objective | Ownership | Status |
| --- | --- | --- | --- |
| 01-research | Resolve meaningful path choices when triggered | researcher | skipped |
| 02-implementation | Implement S5-T1 packs + parser | implementer | done |
| 03-review | Review code-changing diff | code-reviewer | done (approve, 3 minor) |
| 04-verify | Task-scoped verification | skeptic-verifier | done (survives) |

## Verification

| Check | Command | Required | Status |
| --- | --- | --- | --- |
| Praetor pack exists | `Test-Path -LiteralPath skills\crossfire-interviewer\sources\praetor.md -PathType Leaf` | yes | pending |
| Parser module exists | `Test-Path -LiteralPath app\packs.py -PathType Leaf` | yes | pending |
| Unit tests | `py -3 -m unittest tests.test_packs` | yes | pending |
| Leak check | `bash tests/source_packs.sh` (or documented bash-equivalent if bash unavailable) | yes | pending |
