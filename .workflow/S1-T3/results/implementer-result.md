# S1-T3 implementer result

**Packet:** `02-implementation` · **Status:** done · **Date:** 2026-08-16  
**Chosen path:** 3 — `SKILL.md` + `assessment-cases.md` + `assessment_eval.bats`; live §10 N=5 **skipped** when Hermes missing; **fail-closed** if `CROSSFIRE_LIVE_ASSESSMENT=1` without binary.

## Files changed

| File | Rationale |
| --- | --- |
| `skills/crossfire-interviewer/SKILL.md` | Stable interviewer assessment contract: families + required elements, persist iff ≥2 missing, one-missing no persist, mixed-family forbidden, technical never STAR, output shape (family / missing_elements / quote\|byte_offset evidence), propose-only (harness writes `MEMORY.md`), three spec §11 demo questions |
| `tests/fixtures/assessment-cases.md` | Nine labeled cases: strong / weak (≥2 missing) / one-missing per family; `q_behavioral_01` bad answer with `action`+`result` missing → `expected_persist: true`; label hygiene `expected_persist == (n_missing >= 2)` |
| `tests/assessment_eval.bats` | Static contract greps on `SKILL.md`; fixture label-consistency parser; isolation via `demo_common.sh`; live N=5 hook skips with reason when Hermes undiscoverable; forced live fails closed; never treats skip as N=5 pass |

## Verification commands (actual results)

### Required PowerShell queue

```
Test-Path skills\crossfire-interviewer\SKILL.md     → True
Test-Path tests\fixtures\assessment-cases.md        → True
Test-Path tests\assessment_eval.bats                → True
```

### WSL fixture sanity

```
grep -c 'CASE END' tests/fixtures/assessment-cases.md → 9
grep 'missing_elements: [action, result]' (q_behavioral_01) → present
HERMES_HOME default → .../.crossfire/profiles/test (isolated)
```

### `bats tests/assessment_eval.bats`

Command: `wsl -e bash -lic 'command -v bats'`

**Result:** bats not installed on WSL (`BATS_MISSING`). Test file written per spec; not executed via bats runner.

## Implementation notes

- **Propose-only:** skill and tests emit/validate assessment proposals; no `crossfire_persist_weakness`, no `MEMORY.md` writes (S1-T2 harness owns persist).
- **Live §10 N=5:** encoded as skip/fail-closed hook only — **not** claimed as tolerance eval passed. Post-install wiring deferred.
- **No keyword scorer:** static checks validate contract text and human fixture labels, not free-text assessment.
- **Demo questions:** all three spec §11 IDs and verbatim question text in `SKILL.md`; bad-answer quote matches spec.
- Shell/fixtures normalized to LF for WSL execution.

## Unresolved

1. `bats` not installed — `tests/assessment_eval.bats` not run through bats runner (approval-first).
2. Live N=5 assessor loop unproven until Hermes install + throwaway `HERMES_HOME` probe.

## JSON summary

```json
{
  "packet_id": "02-implementation",
  "status": "done",
  "files_touched": [
    "skills/crossfire-interviewer/SKILL.md",
    "tests/fixtures/assessment-cases.md",
    "tests/assessment_eval.bats",
    ".workflow/S1-T3/results/implementer-result.md"
  ],
  "checks_run": [
    {
      "command": "Test-Path skills\\crossfire-interviewer\\SKILL.md",
      "result": "True"
    },
    {
      "command": "Test-Path tests\\fixtures\\assessment-cases.md",
      "result": "True"
    },
    {
      "command": "Test-Path tests\\assessment_eval.bats",
      "result": "True"
    },
    {
      "command": "wsl grep -c CASE END tests/fixtures/assessment-cases.md",
      "result": "9"
    },
    {
      "command": "wsl python3 fixture label hygiene (9 cases)",
      "result": "errors=0"
    },
    {
      "command": "wsl -e bash -lic 'command -v bats'",
      "result": "BATS_MISSING — bats tests not run"
    }
  ]
}
```

---

## Review fix retry (2026-08-16)

**Trigger:** `code-reviewer-result.md` verdict `blocking_retry`

### Fixed

1. **awk concatenation** — `assessment_case_field` in `tests/assessment_eval.bats` now uses awk adjacency `buf = (buf == "" ? $0 : buf "\n" $0)` instead of invalid Perl-style `.` concatenation. WSL hygiene verified on all 9 fixture cases (`hygiene_cases=9 awk_ok=1`).
2. **Empty `missing_elements`** — `SKILL.md` output table allows empty `[]` when the answer covers all required elements; `persist_recommended: false` when empty. Aligns with spec §10 zero-missing / no-persist path and strong fixtures.

### Also fixed (minor review items)

3. Persist-rule grep uses `grep -qiE 'not.*persist'` to match markdown-bold `**not**`.
4. Live skip test requires exit `77` and skip/unsupported reason (no longer accepts status `0`).

### Files touched (retry)

- `tests/assessment_eval.bats`
- `skills/crossfire-interviewer/SKILL.md`
- `.workflow/S1-T3/results/implementer-result.md`

### Verification (retry)

```
WSL assessment_case_field awk compile + 9-case hygiene → hygiene_cases=9 awk_ok=1
grep -qiE 'not.*persist' SKILL.md → match
SKILL.md contains 'may be empty' for missing_elements → present
bats: BATS_MISSING (not run)
```

```json
{
  "packet_id": "02-implementation",
  "status": "review_fix",
  "files_touched": [
    "tests/assessment_eval.bats",
    "skills/crossfire-interviewer/SKILL.md",
    ".workflow/S1-T3/results/implementer-result.md"
  ],
  "fixed": [
    "assessment_case_field awk adjacency concatenation (WSL compile + hygiene)",
    "SKILL.md allows empty missing_elements; persist_recommended false when empty",
    "Persist grep matches markdown-bold not",
    "Live skip test requires exit 77 only"
  ],
  "checks_run": [
    {
      "command": "wsl run-hygiene-check.sh (9-case label hygiene via fixed awk)",
      "result": "hygiene_cases=9 awk_ok=1"
    },
    {
      "command": "grep -qiE 'not.*persist' skills/crossfire-interviewer/SKILL.md",
      "result": "match"
    },
    {
      "command": "grep 'may be empty' skills/crossfire-interviewer/SKILL.md",
      "result": "present"
    }
  ]
}
```
