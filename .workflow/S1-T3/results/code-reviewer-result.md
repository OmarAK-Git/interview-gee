# S1-T3 code review (retry)

**Packet:** `03-review-retry`  
**Reviewer:** code-reviewer (did not author the diff)  
**Date:** 2026-08-16  
**Scope:** Task 3 product files only (`skills/crossfire-interviewer/SKILL.md`, `tests/fixtures/assessment-cases.md`, `tests/assessment_eval.bats`) after Important fixes  
**Spec:** `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` §10 and §11  
**Chosen path:** 3 — encode §10 contract; skip live N=5; fail-closed if live forced without binary. Missing live Hermes eval is **not** a review failure.

**Prior packet:** `03-review` verdict `blocking_retry` (invalid awk `.` concat; `missing_elements` required non-empty).

**Verdict:** `approve`

Independent re-read of the three files plus WSL probes (GNU Awk 5.3.2). Both Important items are fixed. No Critical or Important remain. Isolation snapshot is still uncovered (Minor, not blocking).

---

## Prior Important — disposition

1. **`assessment_case_field` awk `.` concatenation** — **fixed.** Line 109 is awk adjacency `buf = (buf == "" ? $0 : buf "\n" $0)`. Perl-style `.` is absent. WSL awk compiles. Ternary probe: empty buf → `first`; nonempty → `first\nsecond`. Hygiene over all 9 cases: `hygiene_cases=9 errors=0`.
2. **`missing_elements` required non-empty** — **fixed.** SKILL output table (line 47) allows empty `[]` when the answer covers all required elements. Line 68 sets `persist_recommended: false` when empty. `Non-empty` is absent from SKILL.md. Three strong fixtures use `missing_elements: []` / `expected_persist: false`. Spec §9 “Non-empty” applies to the **persisted** MEMORY.md weakness schema (only written when ≥2 missing), not to assessment proposals.

Prior Minors 1 (persist grep vs markdown bold) and 2 (skip test accepting status 0) are also fixed. Prior Minor 3 (isolation snapshot) remains.

---

## Check 1 — Persist ≥2 / one-missing does not persist

SKILL persist bullets match spec §10:

```34:36:skills/crossfire-interviewer/SKILL.md
- Persist a weakness **automatically** when **≥ 2** required elements of that family are missing.
- **One** missing element does **not** persist.
- Do **not** ask the operator to confirm persistence.
```

`persist_recommended: true` only when `count(missing_elements) >= 2`; false for one-missing and empty. WSL parse of all 9 fixture cases: `expected_persist == (n_missing >= 2)` with zero errors. Demo `q_behavioral_01` is `missing_elements: [action, result]`, `expected_persist: true`. Persist grep `not.*persist` now matches the markdown-bold bullet.

## Check 2 — Technical not STAR; mixed-family forbidden

SKILL states exactly one family, mixed-family forbidden, and technical never scored with STAR. Technical fixtures use only `problem` / `approach` / `tradeoff` / `verification`. Probe: `star_on_tech=0`.

## Check 3 — Demo questions (§11)

All three IDs and question strings match spec §11 verbatim, including Mastercard `R-281517`. Scripted bad answer quote `I just kind of watched the dashboard.` is in SKILL and in `behavioral_weak_demo_01`.

## Check 4 — No invented employer facts; propose-only

Forbidden list names McCain Foods, Mastercard R-281517, Project Praetor, Project ALTER_EGO. Fixtures stay inside that set. Skill is propose-only: must not edit `MEMORY.md` or `.crossfire/candidate-skills/`. Tests never call `crossfire_persist_weakness` and never write `MEMORY.md`.

## Check 5 — Isolation; tests do not write `~/.hermes`

`setup()` sources `scripts/demo_common.sh` and calls `crossfire_require_isolated_hermes_home` (path check only; no mkdir). Default `HERMES_HOME` probe: `/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test`. Distinct from `REAL_HERMES_WSL=/home/fish/.hermes` and `REAL_HERMES_WIN=/mnt/c/Users/oalan/.hermes`. No `hermes` exec; live hook uses `discover_hermes_bin` with `CROSSFIRE_HERMES_DISCOVERY=0`. `crossfire_harness_write_probe` is not invoked.

## Check 6 — Skip is not N=5 pass; fail-closed if live forced

SKILL: skip is not proof N=5 passed; forcing live without a binary must fail closed. Inner skip snippet exits 77 with unsupported reason. Forced live snippet exits 1 with `FAIL CLOSED`. Bats skip test now requires status 77 only (no longer accepts 0). This review does **not** treat missing live N=5 as a defect. `BATS_MISSING` on WSL is an environment constraint, not a product defect; hygiene logic was executed independently.

---

## Findings

### Critical

None.

### Important

None.

### Minor

1. **Isolation test does not observe that real `~/.hermes` was untouched**  
   - File: `tests/assessment_eval.bats:361`  
   - What’s wrong: asserts `HERMES_HOME` string contains `.crossfire/profiles/` and is not `REAL_HERMES_*`. No absence snapshot around the test body. Setup does not write, so this is coverage not a live leak.  
   - Fix: snapshot `REAL_HERMES_WIN` / `REAL_HERMES_WSL` existence before/after; assert no new path.

---

## Spec / packet AC mapping

| AC | Result |
| --- | --- |
| Persist automatically when ≥2 family elements missing | Met in SKILL + fixtures; hygiene parser now verifies |
| One missing element does not persist | Met; one-missing fixtures `expected_persist: false`; persist grep matches |
| Technical never STAR; mixed-family forbidden | Met in SKILL + technical fixtures |
| Output names family, missing_elements, quote or byte_offset evidence | Met; empty `missing_elements` allowed on zero-missing path |
| Demo questions §11 (three IDs, verbatim text, bad-answer quote) | Met |
| No invented employer facts | Met in SKILL forbidden list + fixture source set |
| Propose-only; harness writes MEMORY.md | Met; tests do not persist |
| Isolation sourced; tests never write operator `~/.hermes` | Met in setup; no hermes exec; snapshot still weak (Minor) |
| Skip live N=5 is not a pass; fail-closed if live forced without binary | Encoded and probed (77 / 1); missing live eval not a failure |
| Label hygiene: persist iff n≥2; family allow-list; no mixed missing_elements | Fixtures OK; awk parser OK (`hygiene_cases=9 errors=0`) |
| No keyword/regex free-text scorer as N=5 stand-in | Met |

```json
{
  "packet_id": "03-review-retry",
  "status": "done",
  "verdict": "approve",
  "findings": [
    {
      "priority": "Minor",
      "file": "tests/assessment_eval.bats:361",
      "issue": "Isolation test only checks the HERMES_HOME string; it does not snapshot REAL_HERMES_* absence.",
      "fix": "Snapshot real profile paths before/after and assert they were not created."
    }
  ]
}
```
