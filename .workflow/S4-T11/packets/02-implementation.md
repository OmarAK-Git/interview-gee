# Packet 02-implementation: Free-form Monday usability

Researcher skipped: spec-locked non-demo behavior.

## Files allowed

- `tests/interactive_smoke.md`
- `skills/crossfire-interviewer/SKILL.md`
- `README.md`

Plus `.workflow/S4-T11/results/implementer-result.md`. Do not commit. Do not auto-copy demo weaknesses into real ~/.hermes.

## Do

Record a free-form (non-demo) run in `tests/interactive_smoke.md`: agent continues beyond three questions; sensible no-weakness behavior; targets an existing weakness without demo-only chatter; optional session_search only after opener, degrades gracefully; exit still flushes buffered qualifying observations. README: how to run without editing prompts. SKILL.md: free-form notes without breaking demo contract.

If a live free-form Hermes session cannot be run, record an honest isolated/stub procedure plus what was actually executed — do not fake a live transcript. Isolation: never write real ~/.hermes.

ACs: A manual free-form run is recorded. The tool is useful without editing prompts or files. Demo weaknesses do not auto-copy into the Monday profile.
