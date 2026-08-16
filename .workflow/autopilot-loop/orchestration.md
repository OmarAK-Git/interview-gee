# Orchestration — Hermes Interview Sparring Partner Autopilot

The controller is `.cursor/commands/gsd-autopilot-loop.md`; the queue is `.workflow/autopilot-queue.json`.

## Dispatch policy

For each runnable **task** item:

1. Create the scoped `run_dir` and record an agent plan.
2. If the task has multiple viable paths, a fork, ambiguity, or close opportunity cost, run `researcher` and save `results/researcher-result.md`.
3. Run `implementer` and save `results/implementer-result.md`.
4. After every code-changing implementation, run `code-reviewer`; blocking findings force retry.
5. Run `skeptic-verifier` from fresh context using the goal, acceptance criteria, diff, and commands, without the implementer's reasoning dump.
6. Update queue status only after verifier evidence exists.

For each runnable **gate** when `--stop-before-gate` is absent:

1. Create the gate run and verification packet.
2. Run `test-runner` on `verification.commands`.
3. Request the gate verdict through Task using `cursor-grok-4.5-high` (Opus unavailable; gates use Grok), not the chat UI model unless the controller is already Grok-class.
4. Update the queue from that verdict only.

## Agent roles and defaults

| Agent | Policy / model | Required behavior |
| --- | --- | --- |
| `researcher` | `multi_path_opportunity_cost` | Run for ≥2 viable paths, forks, ambiguity, or close trade-offs |
| `implementer` | `composer-2.5` | Always for non-gate tasks |
| `code-reviewer` | `frequent_after_implement` | Run after every code-changing implementation |
| `skeptic-verifier` | `cursor-grok-4.5-high` | Always verify normal tasks from fresh context |
| `test-runner` | `gates_and_major_sections` | Run at phase gates and other major-section boundaries |
| Gate verdict | `cursor-grok-4.5-high` | Run in-session via Task when a gate is entered (Opus unavailable; gates use Grok) |

Any skipped opportunistic agent needs a one-line reason in the run plan.

## Loop bounds

- Drain runnable `pending` or `retry` items in stable queue order.
- Default `max_retries_per_task` is 1; parallel implementation is disabled.
- `--stop-before-gate` leaves the next explicit gate untouched.
- Stop on `blocked`, `human_needed`, repeated verifier gaps, irrelevant/empty code diffs, approval gates, dependency waiting, or user interruption.

## Approval gates

Stop and ask before dependency installs, `.codex`/`.claude` edits, clones, writes outside the workspace, deploys/publishes, destructive git actions, or widening beyond `files_allowed`.

## Status transitions

`pending` → `in_progress` → `verifying` → `done`; gaps move to `retry` or `blocked`, and required human checks move to `human_needed`.

Never mark `done` from implementer or code-reviewer output. A task needs a verifier result and evidence path. A phase gate additionally needs test-runner evidence and the Grok gate verdict.

## Verification scope

- Default: `verification.scope: task`.
- Sprint/phase checks run only in explicit `phase_exit` queue items.
- Routine tasks must not fail because later sprint work is incomplete.

## Isolation

Automated runs must use the disposable test/stage profile. Never point tests at real `~/.hermes`.

## Projection

After an item passes, update `memory-bank/tasks.md`, `memory-bank/progress.md`, and `memory-bank/activeContext.md` when their status changed.
