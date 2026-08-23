# S6-T1 implementer result

**Task:** Practice weave — JD owns the first question  
**Branch:** `practice-live-ui`  
**Status:** done (awaiting code-review + skeptic-verify)  
**Date:** 2026-08-23

## Summary

Implemented path 2 (harness + skill): practice start always uses the fresh JD `-q` and JD stub question; MEMORY.md selection remains for attribution kv only. Answer turn injects at-most-one in-story follow-up bias when a gap was selected at start. Skip live `-q` explicitly rejects same-gap hesitation. Practice section of `SKILL.md` overrides Session-two / return-session opener rules.

## Files changed

| File | Rationale |
| --- | --- |
| `scripts/practice_session.sh` | Remove memory-opener Q1 branch; persist opener fields in `practice.state`; answer/skip prompt weave |
| `skills/crossfire-interviewer/SKILL.md` | Practice section: JD owns Q1; MEMORY seasons follow-ups; section wins over demo openers |
| `tests/practice_jd.sh` | TDD: S6 session-two JD stub checks, static no-drill `-q`, follow-up/skip guards |
| `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md` | §5: opener no longer may target gap |
| `docs/superpowers/plans/2026-08-23-practice-interviewer.md` | Task 4: document S6 fresh-JD start + follow-up bias |
| `docs/superpowers/specs/2026-08-23-practice-weave-addendum.md` | Mark S6-T1 implemented |
| `docs/sparring-1.1.0-practice.md` | Session JD section: S6 weave bullet |
| `memory-bank/activeContext.md` | Note implementer pass awaiting verifier |

**Not changed (in scope but unnecessary):** `app/server.py`, `tests/test_memory_view.py` — no server/UI contract change required.

**Not touched (explicit):** `scripts/demo.sh`, `scripts/demo_session_2.sh`, `tests/practice_session_stub.sh`, real `~/.hermes`.

## Verification

```text
bash tests/practice_jd.sh          → passed=24 failed=0
bash tests/practice_session_stub.sh → passed=10 failed=0
python3 -m unittest tests/test_memory_view.py → 6 OK

grep -c 'targets those missing elements' scripts/practice_session.sh → 0
grep -c 'opener may target' docs/superpowers/specs/2026-08-23-practice-interviewer-design.md → 0
grep -c 'MEMORY.md' scripts/demo_session_2.sh → 1
```

TDD order: added failing `practice_jd.sh` checks first; confirmed 5 failures before harness edits; all green after implementation.

## Acceptance mapping

- ✅ First spoken question is JD competency (stub + live `-q`), not memory drill
- ✅ `opening_target_source=MEMORY.md` still prints when weakness block exists
- ✅ Follow-up bias: at most one in-story probe wording on answer turn; `CROSSFIRE_MEMORY_PROBE_USED` in state
- ✅ Skip: new JD question, not same-gap hesitation
- ✅ Design §5 and plan Task 4 amended; demo scripts untouched
- ✅ Persist rule unchanged (>= 2 missing of one family)

## Concerns / open items

1. **Live Luna (`human_needed`):** stub/static checks only; spoken Q1 on real Hermes not verified in this pass.
2. **Family-fit filter:** start still selects newest weakness without JD-family fit check (researcher: non-blocking).
3. **`practice_session_stub.sh:75`** test name still says "session two memory opener" but only asserts attribution kv — behavior is now JD Q1 + honest attribution; rename is out of scope (file not in files_allowed).
4. **Windows CRLF:** WSL test run required `sed -i 's/\r$//'` on shell scripts; pre-existing line-ending issue, not introduced by logic changes.

## Queue / commit

Per packet: **no commit**, **queue not marked done**.
