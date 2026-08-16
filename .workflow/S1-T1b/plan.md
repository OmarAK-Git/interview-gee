# Workflow Plan — S1-T1b

## Goal

Prove an automated run leaves real Hermes state unchanged.

## Success Criteria

- [ ] An automated run provably leaves real Hermes state unchanged.
- [ ] Subsequent scripts/tests are documented to source the isolation env.
- [ ] If isolation cannot be achieved, a recorded decision stops automation against Hermes (hand-script only).

## Constraints

- Stay within files_allowed: `scripts/start-wsl-isolated.sh`, `scripts/demo_common.sh`, `tests/isolation.bats`, `docs/hermes-compatibility.md`, `memory-bank/`.
- BUILD-BLOCKING. Never point tests at real `~/.hermes`.
- Do not implement weakness merge, demo sessions, or assessment eval.
- Spec wins. Ask before installs.

## Risks

| Risk | Approval required | Mitigation |
| --- | --- | --- |
| Touching real ~/.hermes during tests | no | Marker tests use a fake home or read-only assertions; never write the operator profile |
| No Hermes binary to prove HERMES_HOME | no | Either prove script-level isolation without invoking Hermes, or record STOP/hand-script for Hermes-invoking automation |

## Agent Plan

- Researcher: **run** — `needs_research: true`; paths: HERMES_HOME vs copied throwaway vs STOP/hand-script. `start-wsl-isolated.sh` from /home/fish/crossfire is a dead end (T1).
- Implementer: required (`composer-2.5`).
- Code reviewer: required after code-changing implementation.
- Skeptic verifier: required.
- Test runner: skipped — not a phase gate.

## Work Packets

| ID | Objective | Ownership | Status |
| --- | --- | --- | --- |
| 01-research | Choose isolation mechanism given no Hermes binary | researcher | pending |
| 02-implementation | Isolation env, start-wsl-isolated.sh, isolation.bats | implementer | pending |
| 03-review | Review code-changing diff | code-reviewer | pending |
| 04-verify | Task-scoped verification | skeptic-verifier | pending |

## Verification

| Check | Command | Required | Status |
| --- | --- | --- | --- |
| isolation.bats exists | `Test-Path -LiteralPath tests\isolation.bats -PathType Leaf` | yes | pending |
| demo_common.sh exists | `Test-Path -LiteralPath scripts\demo_common.sh -PathType Leaf` | yes | pending |
| Manual | Confirm isolation.bats would fail if a marker in real ~/.hermes were touched (read the test; do not run against the real profile) | yes | pending |
