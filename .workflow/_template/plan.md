# Workflow Plan

## Goal

TODO: one sentence describing what this run must achieve (copy the queue item goal verbatim).

## Success Criteria

- [ ] TODO

## Constraints

- Stay within the queue item's scope and `files_allowed`.
- Treat `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` and `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-plan.md` as the source of truth. Spec wins if they disagree.
- Do not claim completion without fresh verifier evidence.
- Verification is task-scoped unless this run is an explicit sprint/phase gate.
- Ask before dependency installs, harness edits, clones, or writes outside the workspace.
- Tests must never mutate real `~/.hermes`.

## Risks

| Risk | Approval required | Mitigation |
| --- | --- | --- |
| TODO | no | TODO |

## Agent Plan

- Researcher: TODO — run for multi-path opportunity cost, or record why skipped.
- Implementer: required for non-gate tasks.
- Code reviewer: TODO — required after code-changing implementation, or record why skipped.
- Skeptic verifier: required for normal tasks.
- Test runner: required for gates and major-section boundaries.

## Work Packets

| ID | Objective | Ownership | Status |
| --- | --- | --- | --- |
| 01-research | Resolve meaningful path choices when triggered | researcher | pending/skipped |
| 02-implementation | Implement the scoped queue item | implementer | pending |
| 03-review | Review code-changing diff | code-reviewer | pending/skipped |
| 04-verify | Run task-scoped or explicit gate verification | verifier | pending |

## Verification

| Check | Command | Required | Status |
| --- | --- | --- | --- |
| TODO | `not configured` | yes | pending |
