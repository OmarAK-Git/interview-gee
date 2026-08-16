# Workflow Plan — S1-T1

## Goal

Replace every provisional Hermes path and capability assumption with verified, fallback, or unsupported evidence.

## Success Criteria

- [ ] Every required capability is reported verified, unsupported, or documented-fallback in `docs/hermes-compatibility.md`.
- [ ] The MEMORY.md write mechanism is characterized (agent-direct vs Hermes-mediated) including whether a delimited YAML section survives a write round-trip.
- [ ] One Curator strategy is recorded.
- [ ] No public-doc assumption remains implicit.
- [ ] `tests/preflight.bats` exists and encodes the required capability checks.
- [ ] Shared path/command variables live in `scripts/demo_common.sh`.
- [ ] `scripts/preflight.sh` exists.

## Constraints

- Stay within S1-T1 scope and `files_allowed`: `scripts/preflight.sh`, `scripts/demo_common.sh`, `docs/hermes-compatibility.md`, `tests/preflight.bats`, `memory-bank/`.
- Spec `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` (`sparring-1.0.0`) wins over the plan.
- Do not implement weakness merge, demo sessions, or isolation enforcement beyond recording the chosen Curator strategy.
- Ask before dependency installs, harness edits, clones, or writes outside the workspace.
- Tests must never mutate real `~/.hermes`. Discovery is read-only against the real profile. Any write experiment uses a disposable copy inside the workspace.
- Verification is task-scoped. Later sprint gaps are out of scope.

## Risks

| Risk | Approval required | Mitigation |
| --- | --- | --- |
| Mutating real `~/.hermes` during discovery | no | Read-only against the live profile; disposable copies only inside the workspace |
| Hermes not installed / not on PATH | no | Record unsupported/fallback; preflight must fail closed |
| Public docs disagree with installed binary | no | Installed binary and local files win; mark public-doc claims as unverified until checked |
| Write round-trip cannot be proven without Hermes write | no | Prefer source/config evidence; if a probe is needed, use a workspace throwaway profile only |

## Agent Plan

- Researcher: **run** — `needs_research: true`; ≥2 viable paths for MEMORY.md writer, persistence-layer branch, Curator strategy, isolation env var, skill-load timing, session_search observability.
- Implementer: required (`composer-2.5`).
- Code reviewer: required after code-changing implementation (`frequent_after_implement`).
- Skeptic verifier: required (`cursor-grok-4.5-high`).
- Test runner: skipped for this task — not a phase gate; verification.scope is `task`. Queue `test_runner_policy` is `gates_and_major_sections`.

## Work Packets

| ID | Objective | Ownership | Status |
| --- | --- | --- | --- |
| 01-research | Resolve Hermes contract paths and choose Curator / MEMORY.md / persistence branches | researcher | done |
| 02-implementation | Write compatibility note, demo_common vars, preflight script, failing-then-passing bats | implementer | done |
| 03-review | Review code-changing diff | code-reviewer | pending |
| 04-verify | Task-scoped verification of ACs and commands | skeptic-verifier | pending |

## Verification

| Check | Command | Required | Status |
| --- | --- | --- | --- |
| Compatibility note exists | `Test-Path -LiteralPath docs\hermes-compatibility.md -PathType Leaf` | yes | pending |
| Preflight script exists | `Test-Path -LiteralPath scripts\preflight.sh -PathType Leaf` | yes | pending |
| Preflight tests exist | `Test-Path -LiteralPath tests\preflight.bats -PathType Leaf` | yes | pending |
| Required terms present | `Select-String -Path docs\hermes-compatibility.md -Pattern 'MEMORY.md\|Curator\|session_search\|verified\|unsupported\|fallback' \| Measure-Object \| Select-Object -ExpandProperty Count` | yes | pending |
