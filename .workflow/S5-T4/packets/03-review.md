# Packet 03-review: S5-T4

## Task

Every Hermes turn sees the session JD; Skip asks again without persist.

## Acceptance criteria

- crossfire_practice_interviewer_preamble exists and start/answer prompts name the session JD.
- practice_session.sh skip emits skipped=true persist_recommended=false and writes no spool yaml.
- POST /api/session/skip exists and requires an active session.

## Review inputs

- Brief: `.workflow/S5-T4/packets/02-implementation.md`
- Diff: `.workflow/S5-T4/packets/03-review-diff.md`
- Plan Task 4 only

## Global constraints

- Keep inject_inference (max-turns 1, reasoning low).
- Skip writes no spool YAML.
- Tests never mutate real `~/.hermes`.
- No UI chrome.

Write `.workflow/S5-T4/results/code-reviewer-result.md`. Do not modify implementation files.
