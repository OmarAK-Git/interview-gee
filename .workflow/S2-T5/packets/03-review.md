# Packet 03-review: S2-T5 session-one harness

## Objective

Review the code-changing S2-T5 implementation for spec/packet compliance and blocking defects. Do not mark the queue item done.

## Reviewer inputs

- Spec: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` §8, §10 live demo gate, §11, §12 (spec wins)
- Plan Task 5: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-plan.md` lines 65–75
- Research locked paths: `.workflow/S2-T5/results/researcher-result.md`
- Implementation packet: `.workflow/S2-T5/packets/02-implementation.md`
- Working-tree delta vs HEAD: `.workflow/S2-T5/packets/03-review-diff.patch`
- Product files (review **full current contents**, not only the small delta — this is the first review of the task):
  - `scripts/demo_session_1.sh`
  - `scripts/demo_common.sh`
  - `tests/demo_session_1.bats`
  - `tests/fixtures/demo-answers.txt`
  - `skills/crossfire-interviewer/SKILL.md`

Implementer result exists at `.workflow/S2-T5/results/implementer-result.md` for command evidence only. Treat implementation claims as unevidenced until you check the files.

## Locked paths (do not reopen as defects)

harness-spool; hybrid driver; deterministic-plus-live tests; harness `/done` finalize (not a Hermes slash command); `--toolsets skills` memory guard; spec `.crossfire/runs/<run_id>/`.

BATS_MISSING with bash-equivalent `passed=23 failed=0` is an environment constraint, not a product defect by itself. Isolation: tests must never mutate real `~/.hermes`.

Out of scope: Task 6 candidate staging, Task 7 session-two opener, installing bats.

## Acceptance criteria (task-scoped)

- E2E shows deferred automatic persistence
- Session one runs against installed Hermes in the isolated profile (live `-Q` attempt recorded; skip is not E2E pass)
- Exactly three questions; MEMORY.md unchanged until finalize after the third answer
- No persist confirmation prompt
- Product files exist

## Verdict contract

Write `.workflow/S2-T5/results/code-reviewer-result.md` with:

- Verdict: `approve` or `blocking_retry`
- Critical / Important / Minor findings with file:line, what’s wrong, and fix
- Mapping to ACs
- Isolation check (no real `~/.hermes`)

Blocking = any Critical or Important. Do not approve if persist can ignore failures, if LIVE=1 can silently stub, if MEMORY.md is written before finalize, if isolation fail-closed is missing, or if the three demo questions/answers diverge from spec §11.
