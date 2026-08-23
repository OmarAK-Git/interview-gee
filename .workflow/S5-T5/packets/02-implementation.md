# Packet 02-implementation: S5-T5 Practice UI chrome

Researcher skipped: plan Task 5 is fully specified.

## Files allowed

- `app/static/index.html`
- `app/static/app.js`
- `app/static/app.css`
- `tests/test_memory_view.py`
- `memory-bank/`

Plus `.workflow/S5-T5/results/implementer-result.md`.

Do not commit. Do not mark the queue done. Do not dispatch subagents. Do not change persist topic or End report copy.

## Do

TDD. Implement plan Task 5 only.

Read first: `docs/superpowers/plans/2026-08-23-practice-interviewer.md` section **Task 5: Practice UI chrome** through the line before **Task 6**.

1. Extend `UiContractTest` assertions as specified; see them fail.
2. Add HTML, JS, CSS as specified.
3. Run `py -3 -m unittest tests.test_memory_view.UiContractTest` then full `tests.test_memory_view`.

Inference toggle remains New session only. Live temperature is sent on next Send/Skip.

If `api()` currently swallows HTTP errors, wrap so start 400 surfaces as an interviewer bubble: `Need a job description` or the server error.

## Acceptance criteria

- HTML has jd-kind, pack-id, jd-paste, persona, temperature, jd-context, skip.
- app.js fetches /api/packs and posts jd_kind on start.
- Start without a JD is rejected in the UI (400 surfaced).

## Report

Write `.workflow/S5-T5/results/implementer-result.md`. Return status, files, test summary, concerns.
