# Packet 02-implementation: S5-T2 Practice interviewer procedure

Researcher skipped: plan Task 2 is fully specified (exact SKILL.md block, exact `crossfire_practice_ensure_skill` body, exact heading checks).

## Files allowed

- `skills/crossfire-interviewer/SKILL.md`
- `scripts/practice_session.sh`
- `tests/source_packs.sh`
- `memory-bank/`

Plus write `.workflow/S5-T2/results/implementer-result.md`.

Do not commit. Do not mark the queue done. Do not dispatch subagents. Do not point checks at real `~/.hermes`. Do not edit the three demo question strings (`q_technical_01` / `q_behavioral_01` / `q_product_01`) or any demo harness script.

## Do

TDD. Implement plan Task 2 only.

Read first: `docs/superpowers/plans/2026-08-23-practice-interviewer.md` section **Task 2: Practice interviewer procedure in the skill** through the line before **Task 3**.

1. Append the plan's heading checks to `tests/source_packs.sh` before the final echo.
2. Run `tests/source_packs.sh` via Git Bash (`"C:\Program Files\Git\bin\bash.exe"`) and confirm the new skill-heading checks fail while exists/leak still pass.
3. Append the plan's `## Practice interviewer (session JD)` block at the **end** of `SKILL.md`. Do not edit lines above Free-form Monday mode.
4. Replace the body of `crossfire_practice_ensure_skill` in `scripts/practice_session.sh` with the plan's version that copies `sources/*.md`.
5. Re-run `bash tests/source_packs.sh` and `py -3 -m unittest tests.test_packs -v`. If `bats` exists, run `bats tests/question_bank.bats`.

## Acceptance criteria

- SKILL.md contains the Practice interviewer (session JD) heading plus temperature and Skip.
- Three demo question strings remain verbatim.
- ensure_skill copies sources/*.md into the live skill dir.

## Report

Write `.workflow/S5-T2/results/implementer-result.md`. Return only status, files, one-line test summary, and concerns.
