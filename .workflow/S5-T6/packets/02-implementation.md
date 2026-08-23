# Packet 02-implementation: S5-T6 End report and family buckets

Researcher skipped: plan Task 6 is fully specified.

## Files allowed

- `scripts/practice_session.sh`
- `app/server.py`
- `app/static/app.js`
- `tests/practice_jd.sh`
- `tests/test_memory_view.py`
- `memory-bank/`

Plus `.workflow/S5-T6/results/implementer-result.md`.

Do not commit. Do not mark the queue done. Do not change the persist rule (>=2 missing). Do not write a second memory store.

## Do

TDD. Implement plan Task 6 only.

Read first: `docs/superpowers/plans/2026-08-23-practice-interviewer.md` section **Task 6: Close-out report and family buckets** through the line before **Task 7**.

1. Append failing close-out checks to `practice_jd.sh` and `UiContractTest`.
2. See them fail.
3. Change persist topic to `${CROSSFIRE_JD_SOURCE_LABEL} · ${family}`; truncate evidence to 180; emit report_weak/report_strong/report_line; join report_line in kv_parse; UI End shows report_text.
4. Re-run Git Bash `tests/practice_jd.sh` and `py -3 -m unittest tests.test_memory_view`.

If persist cannot write MEMORY.md on this Windows host (python3 Store stub), still implement the topic/report code. Do not weaken the assertions. Document the host gap; report kv can still be proven.

## Acceptance criteria

- End kv includes report_weak, report_strong, and report_text with Weak: and Strong:.
- MEMORY.md topic is not q_live_01 practice gap.
- UI shows report_text on End.

## Report

Write `.workflow/S5-T6/results/implementer-result.md`.
