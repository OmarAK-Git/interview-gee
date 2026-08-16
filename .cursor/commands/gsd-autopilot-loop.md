# GSD Autopilot Loop

Bounded queue controller for **Hermes Interview Sparring Partner**. Drain runnable work from `.workflow/autopilot-queue.json`, dispatch scoped agent passes, and update status only after verifier evidence exists.

## Arguments

- `--max-tasks N` — optional cap; default drains all runnable items.
- `--task-id <id>` — run one runnable queue item.
- `--stop-before-gate` — stop before any explicit `phase_exit` / `milestone_exit` or `in_session_grok` item and report it as `next_runnable`.

## Read first

1. `.workflow/autopilot-queue.json`
2. `.workflow/autopilot-loop/state.json`
3. `.workflow/autopilot-loop/orchestration.md`
4. `AGENTS.md`, `OPS.md`, `memory-bank/activeContext.md`, `memory-bank/tasks.md`
5. `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` and `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-plan.md`

The spec (`sparring-1.0.0`) wins if the plan disagrees.

## Runnable selection and loop

An item is runnable when its status is `pending` or `retry`, every `depends_on` item is `done`, and its retry limit is not exceeded. Select the first runnable item in queue order, execute the protocol, and repeat until a stop condition fires.

Task-scoped verification is the default. Phase/sprint verification occurs only in explicit queue items whose `verification.scope` is `phase_exit` (or `milestone_exit`). Never infer a gate from an ordinary task.

## Models and five kit agents

Read queue `defaults`; item fields may override:

| Role | Default / policy |
| --- | --- |
| `researcher` | `multi_path_opportunity_cost`: run for ≥2 viable paths, forks, ambiguous design, or close opportunity cost |
| `implementer` | always for non-gate tasks with `implementation_model: composer-2.5` |
| `code-reviewer` | `frequent_after_implement`: run after every code-changing implementation |
| `skeptic-verifier` | always for task verification with `verification_model: cursor-grok-4.6-high-fast` and fresh context |
| `test-runner` | `gates_and_major_sections`: run at sprint/phase gates and other major-section boundaries |

Gate verdict model is `cursor-grok-4.6-high-fast`; `gate_run_mode` is `in_session_grok`. Opus unavailable; gates use Grok.

Record which optional agents fired and why in the run plan. If a policy-triggered agent is skipped, record one line explaining why.

## Normal task order

The controller orchestrates; it does not implement or verify inline.

1. **Research?** When `needs_research` or the researcher policy fires, dispatch `researcher`; record the chosen path, alternatives, and evidence.
2. **Implement.** Dispatch `implementer` using `composer-2.5`, limited to `files_allowed`.
3. **Code review?** If code changed, dispatch `code-reviewer`. Blocking findings force `retry` or `blocked`; do not continue as passed.
4. **Skeptic verify.** Set status to `verifying`, then dispatch `skeptic-verifier` using `cursor-grok-4.6-high-fast`.

The verifier packet contains the original goal, acceptance criteria, changed files/diff, task commands, manual checks, and result paths. Do not include the implementer's reasoning dump. Tell the verifier to treat implementation claims as unevidenced until checked and to ignore phase-level gaps for task-scoped work.

Never mark `done` without fresh verifier evidence. Implementer or code-review output alone has no completion authority.

## Gates

With `--stop-before-gate`, stop before selecting the gate and leave it unchanged.

Without `--stop-before-gate`, gates continue in this session:

1. Create the gate run directory and verification packet.
2. Dispatch `test-runner` on `verification.commands`; save `results/test-runner-result.md`.
3. Request the gate verdict via Task with model `cursor-grok-4.6-high-fast` (or Grok-class in-session judgment). Do not use Opus. Save `results/verifier-result.md`.
4. Update the queue only from the Grok gate verdict.

Gates are verify-only; do not dispatch implementer.

## Per-item artifacts and status

- Prepare `item.run_dir/plan.md` from `.workflow/_template/`, including goal, scope, ACs, allowed files, commands, tier, and agent plan.
- Write packets under `packets/` and results under `results/`.
- Before mutation: `pending|retry` → `in_progress`.
- Before verification: `in_progress` → `verifying`.
- Verifier pass: `done` and append verifier path to `evidence`.
- Gaps with retry remaining: `retry`; exhausted: `blocked`.
- Human-only check: `human_needed`.

On `done`, project status into `memory-bank/tasks.md`, `memory-bank/progress.md`, and `memory-bank/activeContext.md`.

## Approval gates

Stop and ask before dependency installs, edits to `.codex`/`.claude` or global harness config, repository clones, writes outside the workspace, deploys/publishes, destructive git operations, or widening beyond `files_allowed`. Provide exact commands, paths, risks, and rollback.

Hard stop: do not point automated tests at real `~/.hermes`. If isolation cannot be proven, stop automating against Hermes.

## Stop conditions

Stop on queue drain, dependency waiting, task cap, `blocked`, `human_needed`, `--stop-before-gate`, approval required, empty/irrelevant code diff, repeated verifier gap, failed agent/model dispatch, or user interruption.

## Final report

Report completed item IDs and evidence, agents used/skipped with reasons, blocked/human-needed items, dependency waiting, next runnable ID, and checks run. For any gate completed in-session, confirm the gate model was `cursor-grok-4.6-high-fast` (Opus unavailable; gates use Grok).
