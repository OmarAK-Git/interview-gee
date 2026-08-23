# S5-T2 code review — Practice interviewer procedure

**Packet:** `.workflow/S5-T2/packets/03-review.md`
**Reviewer:** code-reviewer (did not author this code)
**Date:** 2026-08-23
**Kind:** scoped review of Task 2 skill procedure + `ensure_skill` sources copy
**Scope:** `skills/crossfire-interviewer/SKILL.md`, `scripts/practice_session.sh`, `tests/source_packs.sh`
**BASE:** `44c8221`

Implementer report treated as unevidenced. Plan Task 2 only (`docs/superpowers/plans/2026-08-23-practice-interviewer.md` through the line before Task 3) and design §6 are the spec.

**Verdict:** `approve`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 0 |
| Minor | 3 |
| Blocking | 0 |

**Retry:** no

**Strongest issue:** `tests/source_packs.sh:35` `grep -q 'Skip'` is already green on unchanged BASE `SKILL.md` because of pre-existing “Skip is not proof” (three hits). The new Skip section is present (`SKILL.md:219`); the assertion does not prove it.

---

## Spec compliance

| Requirement | Result | Evidence |
| --- | --- | --- |
| Append `## Practice interviewer (session JD)` after Free-form Monday mode | **Met** | `SKILL.md:188`. `git diff --numstat 44c8221` is `39 0` (append-only). First hunk is a blank line after the Monday assessment bullets. No edits above Free-form Monday mode. |
| Plan Task 2 procedure block (temperature, probes, Skip, propose-only, no MEMORY write) | **Met** | `SKILL.md:188-225` matches the plan Step 3 markdown (en-dash U+2013 on `1–5` / `3–5`; em-dash U+2014 on “absent — not”). Packet `03-review-diff.md` mojibake (`ΓÇö`) is not on disk. |
| Three demo question strings remain verbatim | **Met** | BASE vs live `SKILL.md:86-88` unchanged. Full strings still: Praetor advisory boundary; detection you owned; Mastercard Agent Suite (R-281517) rollout. |
| `ensure_skill` copies `sources/*.md` into the live skill dir | **Met** | `practice_session.sh:46-49` matches plan Step 4. Independent isolated invoke of the product function copied all four packs (below). |
| Propose-only YAML unchanged | **Met** | No edit to session-one YAML shape. New text says “same propose-only YAML as session one” and `persist_recommended: true` only when `count(missing_elements) >= 2` (`SKILL.md:214`). |
| Demo 1.0.0 / demo harness untouched | **Met** | Diff files are only SKILL.md, `practice_session.sh`, `source_packs.sh` (plus orchestrator queue, out of scope). |
| Tests never mutate real `~/.hermes` | **Met** | `source_packs.sh` only `cat`/`grep`s repo files. |
| Files allowed | **Met** | Product files are exactly the Task 2 set. |
| Design §6 (one JD, temp 1–5 default 2, probe/thin, Skip = no YAML, skill does not write MEMORY or render the report) | **Met** | Covered in the appended section. Mid-session “slider does not rewrite the on-screen question” is a Task 4/5 wrapper rule; not in the plan Step 3 block. |

---

## Independent verification (not implementer output)

`git diff 44c8221 --stat` (product only): `practice_session.sh` +4, `SKILL.md` +39, `source_packs.sh` +7.

```
"C:\Program Files\Git\bin\bash.exe" tests/source_packs.sh
source_packs: passed=13 failed=0
```

```
py -3 -m unittest tests.test_packs -v
Ran 6 tests in 0.002s
OK
```

`bats` is not installed; `tests/question_bank.bats` not re-run. Static read: that file still asserts `q_technical_01` / `q_behavioral_01` / `q_product_01` in `SKILL.md` (`question_bank.bats:167-172`).

BASE (`44c8221`) vs new heading checks:

| Check | BASE `SKILL.md` | Live |
| --- | --- | --- |
| `## Practice interviewer (session JD)` | fail | pass |
| `temperature` | fail | pass |
| `grep -q 'Skip'` | **pass** (vacuous) | pass |
| `### Skip` | fail | pass (`SKILL.md:219`) |

Isolated invoke of **product** `crossfire_practice_ensure_skill` (extracted via `sed`, not retyped). `HOME`/`HERMES_HOME` under `/tmp/s5t2-enskill.*`. Never real `~/.hermes`.

```
DEST=/tmp/s5t2-enskill.YIZdZQ/hermes/skills/crossfire-interviewer
COPIED mccain-cyber-defense
COPIED mastercard-r-281517
COPIED praetor
COPIED alter-ego
PRAETOR_IDENTICAL
SKILL_COPIED
PROBE_OK
```

---

## Findings

### Critical

None.

### Important

None.

### Minor (track)

#### Minor 1 — `tests/source_packs.sh:35` Skip check is already true on BASE

`grep -q 'Skip'` matches pre-existing “Skip is not proof” at `SKILL.md:102`, `:130`, `:160`. A file that added only the heading plus the word `temperature` would pass every new assertion without `### Skip` or “do not emit assessment YAML”.

**Fix:** assert a phrase that did not exist before Task 2:

```bash
grep -Fq '### Skip' "$SKILL" && ok "skill mentions Skip" || bad "skill mentions Skip"
grep -Fq 'do not emit assessment YAML' "$SKILL" && ok "skip omits YAML" || bad "skip omits YAML"
```

#### Minor 2 — no test invokes `crossfire_practice_ensure_skill`

Acceptance requires the sources copy. `source_packs.sh` never calls the function; `source_packs: passed=13` would still pass if lines `46-49` were deleted. Plan Step 1 did not add this check. Reviewer probe (above) shows the live function copies all four `.md` files.

**Fix:** in an isolated `$HERMES_HOME` (never `~/.hermes`), source/eval the function and `test -f "$HERMES_SKILLS_DIR/crossfire-interviewer/sources/praetor.md"`.

#### Minor 3 — `scripts/practice_session.sh:48` copy errors are swallowed

```bash
cp "${CROSSFIRE_SKILL_PATH}/sources/"*.md "${dest}/sources/" 2>/dev/null || true
```

Plan Step 4 specifies this. If the glob matches nothing or `cp` fails, start still succeeds with an empty `dest/sources/`. Runtime JD is injected later (Task 4) and practice already strips `--toolsets` (`practice_common.sh:122`), so an empty copy is not a live-interview break today.

**Fix (later, if copy becomes load-bearing):** drop `|| true` after the directory exists, or fail closed when `sources/*.md` count is not 4.

---

## Correctness / security / simplicity / tests (audit)

**Correctness**

- Procedure is one-question, one-JD, fact-bound, temperature bands, probe-when-thin, Skip = no assessment YAML, End closer is wrapper-owned, no `MEMORY.md` write.
- `ensure_skill` still copies `SKILL.md` and optional `questions.md`; only addition is `sources/*.md` into `dest/sources/` (does not wipe unrelated dest files).
- Practice already strips `--toolsets` in `crossfire_practice_inject_inference`; skill text that packs are not read at runtime is already true.

**Security**

- No user-controlled path in the new copy (`CROSSFIRE_SKILL_PATH` is repo `skills/crossfire-interviewer`).
- No secrets, no new deps, no deserialization.
- Tests and the reviewer probe do not touch real `~/.hermes`.

**Simplicity**

- Implementation is the plan’s exact SKILL block and exact `ensure_skill` body. No extra APIs, no Task 3+ start/skip/UI work.

**Tests**

- New checks match plan Step 1 verbatim.
- Heading and `temperature` cannot pass on BASE. Demo `q_technical_01` + Praetor fragment are regression guards (already true on BASE; correct for “do not edit demo strings”).
- Could they pass without the new behavior? Heading/temperature: no. Skip: yes (Minor 1). Sources copy: yes (Minor 2). Full procedure prose (persist rule, probes, one-JD): yes, if heading + “temperature” were stubbed.

**Out of scope / not findings**

- `.workflow/autopilot-queue.json` dirty — orchestrator, not Task 2 product.
- Untracked `.workflow/S5-T2/` and `.workflow/practice-live-ui/debug-persist.sh` — not in the review diff.
- Design §6 “slider does not rewrite the question already on screen” / Skip “no report line” — wrapper Tasks 4–6.

---

## What was checked so approve is auditable

1. Read packets `03-review.md`, `03-review-diff.md`, `02-implementation.md`; implementer result (unevidenced); plan Task 2 only; design §6.
2. Read live `SKILL.md` (append + demo table), `practice_session.sh` (`ensure_skill` only), `tests/source_packs.sh`.
3. `git diff 44c8221` / `--numstat` / `--name-only`: SKILL append-only; `ensure_skill` +4 lines; no demo harness edits.
4. Re-ran Git Bash `tests/source_packs.sh` and `py -3 -m unittest tests.test_packs -v`.
5. Proved BASE already satisfies `grep -q Skip`; BASE fails heading, `temperature`, and `### Skip`.
6. Invoked product `crossfire_practice_ensure_skill` under `/tmp` `HERMES_HOME`; all four packs copied; `praetor.md` `cmp` identical.
7. Grepped live demo IDs/strings; confirmed `--toolsets` strip is pre-existing in `practice_common.sh`.
