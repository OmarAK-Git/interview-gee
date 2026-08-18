# Packet 04-verify: S2-T6 task-scoped verification

## Goal

A poor answer produces a visible provenance-linked candidate SKILL.md that is not loadable before session two.

## Acceptance criteria

- A poor answer produces a visible provenance-linked candidate SKILL.md.
- A pre-session-two assertion proves it is not loadable.
- If exclusion is impossible, the degraded path is recorded.

## Product files

- `scripts/stage_candidate_skill.sh`
- `.crossfire/candidate-skills/.gitkeep`
- `tests/candidate_skill.bats`
- `skills/crossfire-interviewer/SKILL.md`
- `docs/hermes-compatibility.md`

Treat implementation claims as unevidenced. Do not use implementer-result.md as evidence. Ignore Task 7/9 gaps and the ruling that `demo_session_1.sh` is not hooked.

## Required commands

```
Test-Path -LiteralPath scripts\stage_candidate_skill.sh -PathType Leaf
Test-Path -LiteralPath tests\candidate_skill.bats -PathType Leaf
Test-Path -LiteralPath .crossfire\candidate-skills\.gitkeep -PathType Leaf
```

If bats missing, run bash-equivalent covering: §14 fields including source_session_id and answer_ref; never-write-live; snapshot-then-assert when a stray live candidate exists; isolation fail-closed; skip is not a pass; CROSSFIRE_LIVE=1 without Hermes fails closed. Record actual passed/failed.

Isolation: never real `~/.hermes`.

Write `.workflow/S2-T6/results/verifier-result.md`. Existence checks alone are not a pass.
