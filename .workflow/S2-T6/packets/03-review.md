# Packet 03-review: S2-T6 candidate staging

## Objective

Review the code-changing S2-T6 implementation. Do not mark the queue done.

## Inputs

- Spec §8, §13, §14; plan Task 6
- Research: `.workflow/S2-T6/results/researcher-result.md` (locked: harness-relocated, never-write-live, `.crossfire/candidate-skills/`)
- Packet: `.workflow/S2-T6/packets/02-implementation.md`
- Tracked delta: `.workflow/S2-T6/packets/03-review-diff.patch` (SKILL.md + hermes-compatibility.md only)
- **New untracked product files (review in full):**
  - `scripts/stage_candidate_skill.sh`
  - `tests/candidate_skill.bats`
  - `.crossfire/candidate-skills/.gitkeep`

**Ruling (not a defect):** `scripts/demo_session_1.sh` is outside `files_allowed`; finalize is not hooked this task. Tests must still prove a poor-answer fixture produces a staged candidate.

BATS_MISSING with bash-equivalent evidence is an environment constraint. Isolation: never real `~/.hermes`. Out of scope: Task 7 opener, Task 9 activation.

## Verdict

Write `.workflow/S2-T6/results/code-reviewer-result.md` with `approve` or `blocking_retry`. Blocking if: candidate can land in `$HERMES_SKILLS_DIR`; missing §14 provenance fields; bad answer treated as model answer; isolation not fail-closed; skip treated as exclusion proof.
