# Packet 03-review: S5-T2

## Task

Add a practice interviewer section that uses one session JD, temperature, probes, and Skip.

## Acceptance criteria

- SKILL.md contains the Practice interviewer (session JD) heading plus temperature and Skip.
- Three demo question strings remain verbatim.
- ensure_skill copies sources/*.md into the live skill dir.

## Files allowed

- `skills/crossfire-interviewer/SKILL.md`
- `scripts/practice_session.sh`
- `tests/source_packs.sh`
- `memory-bank/`

## Review inputs

- Brief: `.workflow/S5-T2/packets/02-implementation.md`
- Diff: `.workflow/S5-T2/packets/03-review-diff.md` (BASE `44c8221`)
- Plan Task 2 only

## Global constraints

- Append after Free-form Monday mode. Do not edit demo question strings.
- Propose-only YAML unchanged.
- Tests never mutate real `~/.hermes`.
- Demo 1.0.0 untouched.

Write findings to `.workflow/S5-T2/results/code-reviewer-result.md`. Do not modify implementation files or git state.
