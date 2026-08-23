# S6-T1 skeptic-verifier result

Verdict: **survives**

Claim tested: S6-T1 is done — practice New session first spoken question is a JD competency question (not a restatement of the newest MEMORY.md gap); follow-ups may season a fitting weakness at most once; Skip yields a different JD question; demo.sh / demo_session_2.sh untouched; design §5 and plan Task 4 no longer require a practice opener that targets missing_elements; persist rule remains ≥ 2.

Implementer report was not used as evidence. Evidence below is first-party. Never used real `~/.hermes` (`C:\Users\oalan\.hermes` absent before and after).

## Strongest reason

An isolated stub start against `tests/fixtures/memory-three-weaknesses.md` (newest gap: product `metric,decision`) still printed `opening_target_source=MEMORY.md` and spoke the Praetor JD stub — not `crossfire_stub_opener_question`’s product-decision drill. Live start `-q` is only “Ask ONE interview question from this JD only.” Design §5 and plan Task 4 no longer require targeting missing_elements. Persist is still `count >= 2`. Demo scripts have no working-tree diff.

## ACs independently confirmed

| AC | Result | Evidence |
| --- | --- | --- |
| 1. New session first spoken question is a JD competency question, not a restatement of the newest MEMORY.md gap | **confirmed** | Fixture start (isolated `/tmp/s6t1-verify.6Bk55g/.hermes`, not real home): `opening_target_source=MEMORY.md`, newest weakness `w-b2f32d5ee0be` product `[metric,decision]`, spoken `question=` / `tts_text=` = Praetor advisory/containment line. Not “product decision gap”. Live `-q` at `scripts/practice_session.sh:143-144` has no missing-elements payload. `practice_session.sh` does not call `crossfire_stub_opener_question` or `crossfire_build_opener_cmdline`. Packet count of `targets those missing elements` in `practice_session.sh` = **0**. SKILL practice first-question rule at `skills/crossfire-interviewer/SKILL.md:198-200`. |
| 2. Follow-ups may probe a fitting weakness at most once inside the current story, then move on | **confirmed** | After fixture start, `practice.state` stored `CROSSFIRE_OPENER_FAMILY=product`, `CROSSFIRE_OPENER_MISSING_CSV=metric,decision`, `CROSSFIRE_MEMORY_PROBE_USED=0`. Live answer injects that bias once then sets the flag (`practice_session.sh:236-242`). Subsequent answers see `!= "1"` fail. SKILL `:200` and `:219` say at most one in-story probe then move on. |
| 3. Skip yields a different JD question, not another turn on the same gap | **confirmed** | Same fixture session: skip `question=` = “Different question from the same JD — what tradeoff did you accept?”; `skipped=true`; `persist_recommended=false`. Live skip `-q` at `:328-329` forbids hesitation about the same MEMORY.md gap. SKILL `### Skip` at `:251-253`. |
| 4. Do not rewrite demo.sh or demo_session_2.sh | **confirmed** | `git diff --stat -- scripts/demo.sh scripts/demo_session_2.sh` empty. `git status --short` empty for both. Last touch `f6a2112 Ship the Crossfire demo through final acceptance.` Packet `MEMORY.md` count in `demo_session_2.sh` = **1** (>0). |
| 5. Design §5 and plan Task 4 no longer require a practice opener that targets missing_elements | **confirmed** | Design §5 (`docs/superpowers/specs/2026-08-23-practice-interviewer-design.md:95`) says first spoken question is a normal in-role JD question; weaknesses season follow-ups only. Packet count of `opener may target` in that file = **0**. Plan Task 4 (`docs/superpowers/plans/2026-08-23-practice-interviewer.md:852`) says do not use a Session-two memory-opener `-q`; start always uses the fresh JD prompt. |
| 6. Persist rule remains ≥ 2 | **confirmed** | `scripts/crossfire_lib.sh:408-423` still persists on `persist_recommended: true` or `count >= 2`. SKILL `:68` and practice `:246`: `persist_recommended: true` only when `count(missing_elements) >= 2`. No `>= 1` persist threshold in `scripts/`. |

## Commands run

```
Select-String -Path scripts\practice_session.sh -Pattern 'targets those missing elements'
  → Count = 0

Select-String -Path docs\superpowers\specs\2026-08-23-practice-interviewer-design.md -Pattern 'opener may target'
  → Count = 0

Select-String -Path scripts\demo_session_2.sh -Pattern 'MEMORY.md'
  → Count = 1

git diff --stat -- scripts/demo.sh scripts/demo_session_2.sh
  → empty

git status --short -- scripts/demo.sh scripts/demo_session_2.sh
  → empty

git log -3 --oneline -- scripts/demo.sh scripts/demo_session_2.sh
  → f6a2112 Ship the Crossfire demo through final acceptance.

"C:\Program Files\Git\bin\bash.exe" tests/practice_jd.sh
  → practice_jd: passed=22 failed=2
  → FAIL topic missing source label (MEMORY.md never written; “Python was not found”)
  → FAIL session two attribution (opening_target_source=none because no MEMORY.md)
  → PASS start -q no memory drill wording; session two spoken Q is JD stub
  → HOME=/tmp/crossfire-practice-jd.*; not real ~/.hermes

Isolated fixture proof (Git Bash; HOME=/tmp/s6t1-verify.6Bk55g; HERMES_HOME=$HOME/.hermes;
  copied tests/fixtures/memory-three-weaknesses.md; CROSSFIRE_PRACTICE_STUB=1; praetor pack)
  → opening_target_source=MEMORY.md
  → attribution weakness_id=w-b2f32d5ee0be family=product
  → question=Walk through how Praetor decides not to contain...
  → skip question=Different question from the same JD — what tradeoff did you accept?
  → REAL_HERMES_EXISTS_BEFORE=no AFTER=no; FIXTURE_IS_NOT_REAL=yes
```

## file:line reads

- `scripts/practice_session.sh:32-45` — preamble: first spoken question is JD; MEMORY seasons follow-ups only.
- `scripts/practice_session.sh:126-144` — MEMORY present still selects newest weakness for attribution; live `-q` is JD-only (no missing-elements list).
- `scripts/practice_session.sh:137-139` — stub start always Praetor JD line (does not call `crossfire_stub_opener_question`).
- `scripts/practice_session.sh:236-242` — first live answer may inject one MEMORY follow-up bias, then `CROSSFIRE_MEMORY_PROBE_USED=1`.
- `scripts/practice_session.sh:328-329` — skip asks a different JD question, not the same gap.
- `scripts/crossfire_lib.sh:408-423` — persist iff recommended or `count >= 2`.
- `scripts/crossfire_lib.sh:599-613` — leftover demo stub drill wording; practice start does not call it (grep: no matches in `practice_session.sh`).
- `skills/crossfire-interviewer/SKILL.md:68,246` — persist ≥ 2.
- `skills/crossfire-interviewer/SKILL.md:188-200,251-253` — practice section wins; Q1 is JD; Skip is a new JD question.
- `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md:95` — §5 JD-first.
- `docs/superpowers/plans/2026-08-23-practice-interviewer.md:852` — Task 4: no Session-two opener `-q`.

## Letter-not-intent attacks (did not refute)

- `tests/practice_jd.sh` session-two Q checks are weak on this host: persist never wrote MEMORY.md (`Python was not found`), so start2 ran with `opening_target_source=none`. The stub question is always the Praetor line, so “not a drill” would pass even without MEMORY. **Independent fixture start** supplies the missing MEMORY-present proof.
- AC2 is prompt + one-shot env flag, not a model-behavior test. Stub `answer` never injects `memory_bias` (live-only). Enough for this task’s contract; not a live Luna wording gold.
- Attribution still prints `weakness_id=` (`app/static/app.js:247` bubbles it). Addendum allows attribution kv; TTS uses `tts_text` / `question` (`:249`), which is the JD line. “Do not speak weakness_id” holds for the spoken question.
- `SKILL.md:173` Free-form Monday still says return-session opener targets missing elements. Practice section `:190` says that section wins when the practice wrapper drives; preamble `:41` points at it. Residual model-confusion risk, not an AC letter fail.
- Plan Task 2 historical snippet (`:513`) still shows the old “first question may target those missing elements” skill text. AC5 names design §5 and plan Task 4 only; both were updated.
- Weave addendum conflict table still quotes the old S5 rule. That is historical; design §5 itself does not.

## Residuals (not used as fail)

- `practice_jd.sh` exits 2 on this Windows host: persist path needs `python3` to write MEMORY.md. Same host gap noted in S5. Isolated fixture covered the S6-T1 memory-present start/skip ACs. Not a product AC miss.
- Demo `crossfire_stub_opener_question` remains in `crossfire_lib.sh` for the 1.0.0 session-two theater (AC4 requires leaving that path).

## Isolation

`Test-Path C:\Users\oalan\.hermes` was false before and after. All starts used `HOME=/tmp/...` and `HERMES_HOME=$HOME/.hermes` under Git Bash. Fixture dest `/tmp/s6t1-verify.6Bk55g/.hermes` ≠ real profile.
