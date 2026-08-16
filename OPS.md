# Operational Guide

Keep this file concise; status belongs in `memory-bank/` and `.workflow/`.

## Sources of truth

- Product/content: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` (`sparring-1.0.0`)
- Implementation/tasks/checks: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-plan.md`
- Queue: `.workflow/autopilot-queue.json`
- Durable state: `memory-bank/`
- Loop contract: `.cursor/commands/gsd-autopilot-loop.md`

## Build and run

- Build: not configured until scaffold.
- Run: not configured until scaffold (plan targets: `scripts/demo_session_1.sh`, `scripts/demo_session_2.sh`, `scripts/demo.sh`).
- Test: not configured until scaffold (plan uses `bats` under `tests/`).
- Lint: not configured yet.
- Typecheck: not configured yet.
- Stop gate: existence checks only until real test/lint commands exist.

Do not install global tools. Do not point automated tests at real `~/.hermes`. `demo_prepare` restores only the disposable test or stage profile after validating the resolved path.

## Autopilot defaults

- Implement: `implementer` / `composer-2.5`
- Verify: `skeptic-verifier` / `cursor-grok-4.5-high`
- Gate: `test-runner`, then Task verdict / `cursor-grok-4.5-high`
- Gate mode: `in_session_grok`
- Research: `multi_path_opportunity_cost`
- Review: `frequent_after_implement`
- Test runner: `gates_and_major_sections`
- Verification: task-scoped except explicit `phase_exit` items

Order is research? → implement → code-review? → skeptic-verify. Never mark done without verifier evidence.

Gate model standing order (set 2026-07-30): all gates run on Grok (`cursor-grok-4.5-high`), never Opus. Without `--stop-before-gate`, gates continue in-session.

The must-ship target is Sprint 2 / Task 7 (fresh-process memory-only opener). Tasks 4 and 8–12 are quality/hardening and cut in plan order if time runs short.

## Operational risks

- Hermes paths under `~/.hermes` are provisional until Task 1 verifies the installed version.
- If tests cannot be isolated from real `~/.hermes`, stop automating against Hermes and hand-script the demo (recorded decision).
- Persistence layer is a Task 1 branch: `MEMORY.md` block, else session archive, else STOP.

## Permissioned setup

Ask before installs, `.codex`/`.claude` or global harness edits, clones, or outside-workspace writes. Give exact commands, targets, risks, and rollback.
