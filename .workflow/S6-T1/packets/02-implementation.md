# Packet 02-implementation: S6-T1 Practice weave

Research chose **harness + skill (path 2)**. Read `.workflow/S6-T1/results/researcher-result.md`.

## Files allowed

- `skills/crossfire-interviewer/SKILL.md`
- `scripts/practice_session.sh`
- `app/server.py`
- `tests/practice_jd.sh`
- `tests/test_memory_view.py`
- `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md`
- `docs/superpowers/specs/2026-08-23-practice-weave-addendum.md`
- `docs/superpowers/plans/2026-08-23-practice-interviewer.md`
- `docs/sparring-1.1.0-practice.md`
- `memory-bank/`

Plus `.workflow/S6-T1/results/implementer-result.md`.

Do not commit. Do not mark the queue done. Do not rewrite `scripts/demo.sh` or `demo_session_2.sh`. Do not change isolation or persist >=2. Do not add a second memory store.

## Ruling

`tests/practice_session_stub.sh` is **not** in files_allowed. Put Q1-is-JD assertions in `tests/practice_jd.sh` only.

## Do

TDD in `tests/practice_jd.sh`: after start (even when MEMORY.md would exist), spoken question must not be the stub memory-opener drill; `opening_target_source=MEMORY.md` may still print. Remove `targets those missing elements` from practice start `-q`.

Implement path 2:
1. Start always uses the fresh JD `-q` (Ask ONE interview question from this JD only). Keep attribution kv if a weakness exists. Do not call `crossfire_stub_opener_question` / memory-opener `-q` for Q1.
2. Answer `-q`: MEMORY.md seasons at most one in-story follow-up, then move on.
3. Skip `-q`: different JD question, not the same gap.
4. Practice section of SKILL.md: this section wins; Q1 is in-role JD; do not apply Session-two / return-session opener to practice.
5. Amend design §5 so it no longer says the opener may target the gap. Amend plan Task 4 memory-opener wording. Addendum may note S6 implemented.

Verification later expects:
- `targets those missing elements` gone from `practice_session.sh`
- `opener may target` gone from the design spec
- `demo_session_2.sh` still mentions MEMORY.md

## Acceptance criteria

- Practice New session first spoken question is a JD competency question, not a restatement of the newest MEMORY.md gap.
- Follow-ups may probe a fitting weakness at most once inside the current story, then move on.
- Skip / I don't want this topic yields a different JD question, not another turn on the same gap.
- Do not rewrite demo.sh or demo_session_2.sh.
- Design §5 and plan Task 4 no longer require or prefer a practice opener that targets missing_elements.
- Persist rule remains >= 2 missing of one family.

## Report

Write `.workflow/S6-T1/results/implementer-result.md`.
