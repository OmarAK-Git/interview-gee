# Packet 02-implementation: S5-T7 Docs close-out

Researcher skipped: docs-only; live pass is operator manual.

## Files allowed

- `docs/sparring-1.1.0-practice.md`
- `README.md`
- `tests/interactive_smoke.md`
- `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md`
- `memory-bank/`

Plus `.workflow/S5-T7/results/implementer-result.md`.

Do not commit. Do not mark the queue done. Do not point automated tests at real `~/.hermes`. Do not change 1.0.0 demo scripts.

## Do

Implement plan Task 7 **docs half** only.

Read first: `docs/superpowers/plans/2026-08-23-practice-interviewer.md` section **Task 7: Docs and live demo pass**.

1. Add **Session JD (required)** to `docs/sparring-1.1.0-practice.md` as specified. Remove any implication that start can run with no JD.
2. Update README practice UI bullets: required JD (pack or paste), optional persona, temperature, Skip, End report.
3. Run `py -3 -m unittest tests.test_packs tests.test_memory_view` and Git Bash `tests/source_packs.sh` + `tests/practice_jd.sh` if possible.
4. Live Codex/Luna demo is **not** available in this session. Do **not** set the design spec status to `implemented`. Append a dated pending/human_needed note to `tests/interactive_smoke.md` listing the live checklist (pack, paste, temperature, Skip, End Weak/Strong, panel `{source} · {family}`).

## Acceptance criteria

- Practice addendum states JD is required (pack or paste), persona optional, temperature 1-5 default 2, Skip, End report.
- README practice UI bullets match.
- No new automated test writes real `~/.hermes`.

## Report

Write `.workflow/S5-T7/results/implementer-result.md`. Call out `human_needed: live Luna pass`.
