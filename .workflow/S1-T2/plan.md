# Workflow Plan — S1-T2

## Goal

Ship a deterministic MEMORY.md weakness-block merge with schema, dedup, cap, and failure-safety tests passing.

## Agent Plan

- Researcher: **skipped** — `needs_research: false`; spec §9 is a single deterministic contract (no fork).
- Implementer: required (`composer-2.5`).
- Code reviewer: required after code-changing implementation.
- Skeptic verifier: required.
- Test runner: skipped — not a phase gate.

## Constraints

- files_allowed: `scripts/weakness_memory.sh`, `tests/weakness_memory.bats`, `tests/fixtures/memory-empty.md`, `tests/fixtures/memory-three-weaknesses.md`, `scripts/demo_common.sh`
- Source isolation env from demo_common.sh. Never write real ~/.hermes.
- No fuzzy semantic merge. No demo sessions.
