# Packet 02-implementation: S5-T1 Source packs and parser

Researcher skipped: plan Task 1 is fully specified (exact pack files, APIs, tests, leak script). No path fork.

## Files allowed

- `skills/crossfire-interviewer/sources/` (create the four pack markdown files)
- `app/packs.py`
- `tests/test_packs.py`
- `tests/source_packs.sh`
- `memory-bank/`

Plus write `.workflow/S5-T1/results/implementer-result.md`.

Do not commit. Do not mark the queue item done. Do not dispatch subagents. Do not point checks at real `~/.hermes`. Do not edit `SKILL.md`, demo scripts, practice UI, or persist topic logic.

## Do

TDD. Implement plan Task 1 only.

Read first — this is your requirements, transcribe do not invent:

`docs/superpowers/plans/2026-08-23-practice-interviewer.md` section **Task 1: Source packs and parser** through the line before **Task 2**.

1. Write `tests/test_packs.py` exactly as the plan specifies.
2. Run `py -3 -m unittest tests.test_packs -v` (or `python -m unittest tests.test_packs -v`) and confirm it fails for the right reason (missing `packs` or missing pack files).
3. Write the four pack files exactly as the plan specifies:
   - `skills/crossfire-interviewer/sources/mccain-cyber-defense.md`
   - `skills/crossfire-interviewer/sources/mastercard-r-281517.md`
   - `skills/crossfire-interviewer/sources/praetor.md`
   - `skills/crossfire-interviewer/sources/alter-ego.md`
4. Write `app/packs.py` as the plan specifies (stdlib only).
5. Write `tests/source_packs.sh` as the plan specifies.
6. Re-run unit tests and the leak script. Expected: all PASS, `source_packs: passed=8 failed=0`.
7. If `bash` is unavailable on Windows, still ship `tests/source_packs.sh` and run an equivalent leak check; record the commands and output.

Functions required: `parse_pack_file`, `list_source_packs`, `normalize_temperature`, `slug_paste`, `require_session_jd`.

No pre-written tail question lists. No new dependencies.

## Acceptance criteria

- Four packs exist and parse (id, facts, 4-6 competencies, core and edge, one family each).
- Cross-pack leak check passes.
- `require_session_jd` rejects missing JD; pack and paste paths return `source_id`, `source_label`, `context_text`.
- `normalize_temperature` defaults to 2 and rejects 0 and 6.

## Report

Write `.workflow/S5-T1/results/implementer-result.md` with files changed, TDD evidence (fail then pass), commands + actual output, AC table, unresolved items. Return only status, files, one-line test summary, and concerns.
