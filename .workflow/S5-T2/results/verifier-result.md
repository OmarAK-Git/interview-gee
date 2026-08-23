# S5-T2 skeptic-verifier result

Verdict: **survives**

Claim tested: S5-T2 is done — Practice interviewer (session JD) section with temperature and Skip; three demo question strings unchanged; `crossfire_practice_ensure_skill` copies `sources/*.md` into the live skill dir.

Implementer report was not read. Evidence below is first-party.

## Strongest reason

All three ACs hold under independent checks: `SKILL.md` gained a new `## Practice interviewer (session JD)` block with temperature rules and a dedicated `### Skip` heading (not only older “Skip is not proof” text); the three demo question strings match `HEAD` exactly and the prefix through Free-form Monday is identical; the real `crossfire_practice_ensure_skill` body, extracted and invoked against an isolated `/tmp/s5t2-ensure-*` dest (never `~/.hermes`), copied all four `sources/*.md` with `cmp` MATCH.

## ACs independently confirmed

| AC | Result | Evidence |
| --- | --- | --- |
| 1. SKILL.md contains Practice interviewer (session JD) heading plus temperature and Skip | **confirmed** | Heading `skills/crossfire-interviewer/SKILL.md:188`. Temperature at `:194`, `:204–206`, `:215`. Dedicated `### Skip` at `:219–221`. `HEAD` had 0 “temperature”, 3 “Skip” (all “Skip is not proof”), and no `### Skip`. |
| 2. Three demo question strings remain verbatim | **confirmed** | Python exact-string compare vs `git show HEAD:skills/crossfire-interviewer/SKILL.md`: all three strings present once in HEAD and once in work. Prefix before `## Free-form Monday mode (non-demo)` identical. `git diff HEAD -- skills/crossfire-interviewer/SKILL.md` is append-only after line 186. |
| 3. ensure_skill copies sources/*.md into the live skill dir | **confirmed** | Function at `scripts/practice_session.sh:39–50`. Isolated proof dest `/tmp/s5t2-ensure-bcalxG` (not `${HOME}/.hermes`). Copied `alter-ego.md`, `mastercard-r-281517.md`, `mccain-cyber-defense.md`, `praetor.md` — all MATCH vs repo sources. Also copied `SKILL.md` and `questions.md`. |

## Commands run

```
Select-String -Path skills\crossfire-interviewer\SKILL.md -Pattern 'Practice interviewer' | Measure-Object
  → Count = 1

Select-String -Path skills\crossfire-interviewer\SKILL.md -Pattern 'Walk through how Praetor decides not to contain' | Measure-Object
  → Count = 1

git diff HEAD -- skills/crossfire-interviewer/SKILL.md
  → append-only Practice interviewer block after Free-form Monday

git diff HEAD -- scripts/practice_session.sh tests/source_packs.sh
  → ensure_skill gained sources/*.md copy; source_packs.sh gained heading checks

py -3 exact-string compare of the three demo questions vs HEAD
  → HEAD=True WORK=True COUNT=1 for each; prefix_identical True

"C:\Program Files\Git\bin\bash.exe" tests/source_packs.sh
  → passed=13 failed=0

Isolated ensure_skill proof (extracted fn from practice_session.sh; dest /tmp/s5t2-ensure-bcalxG; HERMES_HOME/HERMES_SKILLS_DIR under that dest; CROSSFIRE_SKILL_PATH=repo skill)
  → MATCH all four sources/*.md; SKILL.md + questions.md copied; ISOLATED_OK dest_is_not_real_hermes
```

`bats` was not on PATH; demo-string invariance was checked against HEAD instead of `question_bank.bats`.

## file:line reads

- `skills/crossfire-interviewer/SKILL.md:80–88` — demo table (`q_technical_01` / `q_behavioral_01` / `q_product_01`) unchanged vs HEAD.
- `skills/crossfire-interviewer/SKILL.md:102,130,160` — older “Skip is not proof” (letter-only trap).
- `skills/crossfire-interviewer/SKILL.md:188–225` — new Practice interviewer section: session JD, temperature 1–5, probes, `### Skip`, End.
- `scripts/practice_session.sh:39–50` — `crossfire_practice_ensure_skill` copies `SKILL.md`, optional `questions.md`, and `sources/*.md`.
- `tests/source_packs.sh:30–35` — heading / demo / temperature / Skip greps (Skip grep is weak; see residual).
- `docs/superpowers/plans/2026-08-23-practice-interviewer.md:469–562` — Task 2 specified block and ensure_skill body; working copies match.

## Letter-not-intent attacks (did not refute)

- `grep -q 'Skip'` in `tests/source_packs.sh:35` would pass on HEAD’s older “Skip is not proof” lines alone. That test is weak. The AC still holds because work added `### Skip` at `SKILL.md:219` under Practice interviewer; HEAD had no `### Skip`.
- `grep -q 'temperature'` would have been a weak check if HEAD already mentioned temperature. HEAD temperature count = 0; work mentions are only in the new section.
- `cp … 2>/dev/null || true` can hide an empty glob. With the four shipped packs present, the isolated run copied all four files byte-identical. Residual: a missing `sources/*.md` would still look like success. Not enough to refute “copies sources/*.md” given the live files and MATCH proof.

## Residual (non-blocking)

- `source_packs.sh` does not execute `ensure_skill`; copy behavior was proven out-of-band.
- `bats tests/question_bank.bats` not run (bats missing).
- Isolated proof extracted the function rather than sourcing `practice_session.sh` (that file’s `case` dispatcher would run a command). Same function body as `practice_session.sh:39–50`.

## Scope

Sprint 5 Task 2 only. No fail for missing JD start / Skip UI / End report (S5-T3+).
