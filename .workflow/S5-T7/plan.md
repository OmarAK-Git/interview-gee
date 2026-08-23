# Workflow Plan — S5-T7

## Goal

Document one-JD practice sessions. Live Luna pass is recorded as a manual check, not an automated Monday-home test.

## Agent Plan

- Researcher: **skipped** — docs-only plus static suite; live pass is operator manual.
- Implementer: required (`composer-2.5-fast`).
- Code reviewer: required (docs + any interactive_smoke edit).
- Skeptic verifier: required.
- Test runner: **skipped** — not a phase gate (S5-GE is the gate).

## Ruling

Do not change `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md` status to `implemented`. Live Codex/Luna pass is not recorded in this session; leave it `human_needed` and append a pending checklist row to `tests/interactive_smoke.md` if useful.

## Work Packets

| ID | Objective | Ownership | Status |
| --- | --- | --- | --- |
| 01-research | Path choices | researcher | skipped |
| 02-implementation | Docs | implementer | pending |
| 03-review | Review | code-reviewer | pending |
| 04-verify | Verify | skeptic-verifier | pending |
