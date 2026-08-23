# Packet 03-review: S5-T3

## Task

New session cannot start without exactly one JD (pack or paste).

## Acceptance criteria

- start_session_args raises without jd_kind/pack/paste.
- GET /api/packs lists the four shipped packs.
- Wrapper start without JD fail-closes; start with pack prints source_id and temperature.
- Existing stub session and inference starts still pass when given pack env.

## Ruling in scope

Sanitize pack_id before path join (basename + containment). Unit test that `../SKILL` raises.

## Review inputs

- Brief: `.workflow/S5-T3/packets/02-implementation.md`
- Diff: `.workflow/S5-T3/packets/03-review-diff.md` (BASE HEAD = S5-T2)
- Plan Task 3 only

## Global constraints

- Do not add Skip UI or change persist topic.
- Tests never mutate real `~/.hermes`.
- Demo 1.0.0 untouched.

Write `.workflow/S5-T3/results/code-reviewer-result.md`. Do not modify implementation files or git state.
