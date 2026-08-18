# Packet 04-verify: S2-T7 task-scoped verification

## Goal

Session two targets the persisted weakness with no naming prompt, no loaded candidate (or disclosed degraded path), and no pre-opener search.

## Acceptance criteria

- Automated and manual runs both show session two targeting the persisted weakness.
- No naming prompt, no loaded candidate (or disclosed degraded path), no pre-opener search.
- Distinct process and session IDs versus session one.
- Opener prints opening_target_source, weakness_id, and source_session_id before the question.

## Product files

`scripts/demo_session_2.sh`, `scripts/demo_common.sh`, `skills/crossfire-interviewer/SKILL.md`, `tests/demo_session_2.bats`

Treat implementation claims as unevidenced. Ignore Task 9. session_search detection omitted is documented-fallback if MEMORY.md + candidate exclusion + distinct IDs are proven.

## Commands

```
Test-Path -LiteralPath scripts\demo_session_2.sh -PathType Leaf
Test-Path -LiteralPath tests\demo_session_2.bats -PathType Leaf
```

If bats missing, bash-equivalent covering selection order, print-before-question, live-dir barrier, isolation, CROSSFIRE_RUNS_DIR override, distinct IDs. Record actual passed/failed. Never real `~/.hermes`.

Write `.workflow/S2-T7/results/verifier-result.md`. Existence checks alone are not a pass. Manual check: opener prints opening_target_source before the question.
