# Agent Autopilot

This repository uses `ultimate-agentic-workflow` for non-trivial coding work.

## Project and sources of truth

- Product: **Hermes Interview Sparring Partner** (Crossfire), spec `sparring-1.0.0`.
- Spec: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md`.
- Plan and verification: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-plan.md`.
- Durable context: `memory-bank/`.
- Queue and run evidence: `.workflow/autopilot-queue.json` and `.workflow/`.
- Planned source: Hermes Agent CLI harness under `scripts/`, stable skill under `skills/crossfire-interviewer/`, isolated profiles under `.crossfire/`.

The docs are authoritative. Project status into the memory bank; do not silently change locked decisions. If the plan disagrees with the spec, the spec wins.

## Commands

- Build: not configured until scaffold.
- Run: not configured until scaffold (`scripts/demo.sh` and session scripts are plan targets).
- Test: not configured until scaffold (plan uses `bats` under `tests/`).
- Lint: not configured yet.
- Typecheck: not configured yet.

## Delivery constraints

- Platform is Hermes Agent. Do not swap frameworks.
- Build window is about four hours; spoken demo is about 90 seconds after pre-warm.
- No web UI. No multi-user. No scoring-model training. No promotion gate in MVP.
- Tests never mutate real `~/.hermes`. Isolation is build-blocking.
- Never cut isolation, distinct processes, the three demo questions, automatic persist of the scripted bad answer, or the memory-only opener.

## Workflow

- T0: answer or tiny safe edit directly.
- T1: write a durable one-line goal, execute, and verify.
- T2: spec/plan-driven implementation with task-scoped verification.
- T3: full `.workflow/` traceability, explicit risk gates, review, reflection, and archive.

Autopilot task order: research when triggered → implement → code-review after code changes → fresh skeptic verification. Normal tasks use task-scoped verification; only explicit `phase_exit` items run gate checks. Never mark done without verifier evidence.

Defaults:

- `implementation_model`: `composer-2.5`
- `verification_model`: `cursor-grok-4.5-high`
- `gate_model`: `cursor-grok-4.5-high`
- `gate_run_mode`: `in_session_grok`
- `researcher_policy`: `multi_path_opportunity_cost`
- `code_review_policy`: `frequent_after_implement`
- `test_runner_policy`: `gates_and_major_sections`

Gate model standing order (set 2026-07-30, active until the user says otherwise): **all** gates — phase exits, sprint exits, milestone exits, and final plan gates — run on Grok (`cursor-grok-4.5-high`), never Opus.

Without `--stop-before-gate`, gates continue in-session: run `test-runner` on gate commands, then the gate verdict via Task with `cursor-grok-4.5-high`. Do not rely on the chat UI model. `--stop-before-gate` still pauses before gates when requested.

## Permissioned setup

Ask before dependency installs, edits to `.codex`/`.claude` or global harness config, clones, or writes outside the workspace. Include exact commands, targets, network/data risks, and rollback.

Keep live state in durable files. Do not claim completion without fresh verification evidence. Operational details belong in `OPS.md`.
