# Packet 03-review: S5-T5

## Task

Operator can pick or paste one JD, set optional persona and temperature, see context, and Skip.

## Acceptance criteria

- HTML has jd-kind, pack-id, jd-paste, persona, temperature, jd-context, skip.
- app.js fetches /api/packs and posts jd_kind on start.
- Start without a JD is rejected in the UI (400 surfaced).

## Review inputs

- Diff: `.workflow/S5-T5/packets/03-review-diff.md`
- Plan Task 5 only

Write `.workflow/S5-T5/results/code-reviewer-result.md`. Do not modify implementation files.
