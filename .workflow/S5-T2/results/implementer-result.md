# S5-T2 Implementer Result: Practice interviewer procedure in the skill

## Status

**DONE** — Task 2 implemented per plan; all required verification passed.

## Task transcribed (plan Task 2 only)

**Goal:** Append practice interviewer procedure to the skill and copy `sources/` when installing the skill for practice sessions.

**Files:**
- Modify: `skills/crossfire-interviewer/SKILL.md` (append after Free-form Monday mode; do not edit demo question table)
- Modify: `scripts/practice_session.sh` `crossfire_practice_ensure_skill` (copy `sources/`)
- Test: add assertions to `tests/source_packs.sh` for skill headings

**Steps executed:**
1. Appended skill-heading checks to `tests/source_packs.sh` before final echo.
2. Ran checks — exists/leak PASS; new checks FAIL (`skill procedure heading`, `skill mentions temperature`).
3. Appended `## Practice interviewer (session JD)` block at end of `SKILL.md`.
4. Replaced `crossfire_practice_ensure_skill` body to copy `sources/*.md`.
5. Re-ran verification suite.

## Files changed

| File | Rationale |
| --- | --- |
| `tests/source_packs.sh` | Added 5 skill-heading checks (procedure, demo IDs, temperature, Skip). |
| `skills/crossfire-interviewer/SKILL.md` | Appended Practice interviewer (session JD) procedure block at end. |
| `scripts/practice_session.sh` | `crossfire_practice_ensure_skill` now copies `sources/*.md` into live skill dir. |

## Verification

### TDD — failing first

```
& "C:\Program Files\Git\bin\bash.exe" tests/source_packs.sh
```

Result: `passed=11 failed=2` (exit 1). Exists/leak 8/8 PASS. FAIL: `skill procedure heading`, `skill mentions temperature`. `skill mentions Skip` PASS (pre-existing "Skip is not proof" text).

### After implementation

```
& "C:\Program Files\Git\bin\bash.exe" tests/source_packs.sh
```

Result: `source_packs: passed=13 failed=0` (exit 0).

```
py -3 -m unittest tests.test_packs -v
```

Result: 6 tests OK.

```
bats tests/question_bank.bats
```

Skipped — `bats` not installed on this host.

## Acceptance criteria

- [x] SKILL.md contains `## Practice interviewer (session JD)` heading plus temperature and Skip sections.
- [x] Three demo question strings remain verbatim (grep + `demo question verbatim` check PASS).
- [x] `crossfire_practice_ensure_skill` copies `sources/*.md` into live skill dir.

## Concerns

- **Skip check false-positive before implementation:** `grep -q 'Skip'` matched existing "Skip is not proof" lines; only `skill procedure heading` and `temperature` were reliable pre-implementation failure signals.
- **`bats` unavailable:** `tests/question_bank.bats` not run; demo ID assertions covered indirectly by `source_packs.sh` demo checks.
- **No runtime test for sources copy:** Task 2 spec verifies via code inspection only; copy behavior will be exercised in later tasks.
