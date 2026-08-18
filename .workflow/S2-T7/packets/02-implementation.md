# Packet 02-implementation: Memory-only session-two opener

## Objective

Session two targets the persisted weakness with no naming prompt, no loaded candidate, no pre-opener search. This is the demo's minimum success bar.

## Researcher

Skipped: spec §9/§13 lock selection and opener source. session_search is documented-fallback (drop detection assertion; prove MEMORY.md + candidate absent from live dir + distinct process/session ID).

## Files allowed

- `scripts/demo_session_2.sh`
- `scripts/demo_common.sh`
- `skills/crossfire-interviewer/SKILL.md`
- `tests/demo_session_2.bats`

Plus `.workflow/S2-T7/results/implementer-result.md` and optional `.workflow/S2-T7/bash-assertions.sh`. **Do not commit.** Do not edit `demo_session_1.sh` or `stage_candidate_skill.sh` (you may **source** the stage script). Do not implement Task 9 activation.

## Do (TDD)

1. Deterministic newest-weakness selection (spec §9): `last_seen` desc, then `observation_count` desc, then `weakness_id` asc. Parse only the weakness block in MEMORY.md.
2. Print **before the question**: `opening_target_source=MEMORY.md`, `weakness_id`, `family`, `source_session_id`. Also print attribution: `target selected by prompt memory; wording generated under stable interviewer procedure`.
3. Ask a matching opener from the stable skill / harness (family + missing_elements). No operator prompt that names the weakness.
4. Fail if any candidate skill is in the live dir (`crossfire_assert_candidates_excluded_from_live`). Check `.crossfire/runs/<run_id>/candidate-excluded.flag` if present.
5. Distinct process and session IDs vs session one: capture/compare; fail if equal. Session two is a new process (do not `--resume` session one).
6. No pre-opener `session_search`: opener invoke uses `--toolsets skills` (omit session_search). Do not treat skip as pass.
7. Isolation fail-closed. Source `demo_common.sh`. Never real `~/.hermes`.

Tests: fixture MEMORY.md with a known newest weakness; assert print-before-question; assert candidate-in-live-dir fails launch; assert distinct IDs when two session IDs provided/captured; no naming prompt.

If `bats` missing, bash-equivalent `passed=N failed=0`. Do not install bats.

Hermes: WSL `fish`, isolated `HERMES_HOME=<repo>/.crossfire/profiles/test`. Optional live `-Q` opener is not required if stub/deterministic path proves selection+print+barrier; if `CROSSFIRE_LIVE=1` without Hermes, fail closed.

## Expected Output

`.workflow/S2-T7/results/implementer-result.md` with files, actual command results, JSON summary.
