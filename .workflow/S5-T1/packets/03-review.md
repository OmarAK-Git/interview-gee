# Packet 03-review: S5-T1

Code-changing implementation. Reviewer reads the diff package and the task spec; does not modify files.

## Task

Ship four spec-section-4 JD packs and a stdlib parser used by practice start.

## Acceptance criteria

- Four packs exist and parse (id, facts, 4-6 competencies, core and edge, one family each).
- Cross-pack leak check passes.
- require_session_jd rejects missing JD; pack and paste paths return source_id, source_label, context_text.
- normalize_temperature defaults to 2 and rejects 0 and 6.

## Scope / files allowed

- `skills/crossfire-interviewer/sources/`
- `app/packs.py`
- `tests/test_packs.py`
- `tests/source_packs.sh`
- `memory-bank/`

## Review inputs

- Brief: `.workflow/S5-T1/packets/02-implementation.md`
- Implementer report: `.workflow/S5-T1/results/implementer-result.md` (treat claims as unevidenced)
- Diff package: `.workflow/S5-T1/packets/03-review-diff.md`
- Plan Task 1: `docs/superpowers/plans/2026-08-23-practice-interviewer.md` (Task 1 only)
- Design: `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md` §4

## Global constraints

- Stdlib only. No new dependencies.
- No pre-written tail question lists.
- Do not change SKILL.md demo questions, practice UI, or persist topics.
- Tests never mutate real `~/.hermes`.
- Cross-pack leaks forbidden (Praetor advisory-only must not appear on Mastercard).
- Demo 1.0.0 untouched.

## Do not

- Do not modify files, git state, or the environment except read-only checks.
- Do not re-run tests the implementer already ran unless you need independent evidence; you may run them to gather your own evidence.
- Write findings to `.workflow/S5-T1/results/code-reviewer-result.md`.
