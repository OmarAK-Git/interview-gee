# Packet 02-implementation: S5-T3 Require one JD on session start

Researcher skipped: plan Task 3 is fully specified.

## Files allowed

- `app/packs.py`
- `app/server.py`
- `scripts/practice_session.sh`
- `tests/test_packs.py`
- `tests/practice_jd.sh`
- `tests/practice_session_stub.sh`
- `tests/practice_inference.sh`
- `memory-bank/`

Plus `.workflow/S5-T3/results/implementer-result.md`.

Do not commit. Do not mark the queue done. Do not dispatch subagents. Do not touch real `~/.hermes`. Do not add Skip UI or change persist topic.

## Do

TDD. Implement plan Task 3 only, plus the pack_id sanitize ruling below.

Read first: `docs/superpowers/plans/2026-08-23-practice-interviewer.md` section **Task 3: Require one JD on session start** through the line before **Task 4**.

1. Add `test_start_session_args_requires_jd` to `tests/test_packs.py` as specified.
2. See it fail (`start_session_args` missing).
3. Implement `start_session_args` in `app/packs.py`; wire `GET /api/packs` and start-time JD in `app/server.py`; fail-closed + state + kv in `crossfire_practice_start`; update every `practice_session.sh start` in the two stub tests with pack env.
4. Add `tests/practice_jd.sh` as specified.
5. Run: `py -3 -m unittest tests.test_packs tests.test_memory_view -v` and Git Bash for `tests/practice_jd.sh`, `tests/practice_session_stub.sh`, `tests/practice_inference.sh`.

Existing interfaces to keep:
- `app/server.py` `/api/session/start` currently only passes `CROSSFIRE_INFERENCE`. After Task 3 it must call `start_session_args`, HTTP 400 on ValueError, pass the extra_env block from the plan, and merge `source_id`, `source_label`, `jd_kind`, `temperature`, `persona`, `context_text` into the JSON (not only kv). Do not put the full paste through `kv_parse`.
- `crossfire_practice_save_state` currently writes run_id, session_id, turn, HERMES_HOME, inference. Extend with the plan's JD fields. Write `jd-context.md` from `CROSSFIRE_JD_CONTEXT`.
- Fail-closed check goes immediately after `crossfire_require_monday_home`.

## Ruling (required)

In `require_session_jd`, reject `pack_id` that is not a single safe slug or that resolves outside `sources_dir` (e.g. `../SKILL`). Add a unit test that `../SKILL` raises. This is load-bearing because T3 wires pack_id to HTTP.

## Acceptance criteria

- start_session_args raises without jd_kind/pack/paste.
- GET /api/packs lists the four shipped packs.
- Wrapper start without JD fail-closes; start with pack prints source_id and temperature.
- Existing stub session and inference starts still pass when given pack env.

## Report

Write `.workflow/S5-T3/results/implementer-result.md`. Return status, files, one-line test summary, concerns.
