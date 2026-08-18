# S4-T12 code review — Final safety and acceptance

**Packet:** `02-implementation` (no `03-review.md` in run dir; reviewed against that packet + spec §17 + plan Task 12)
**Reviewer:** code-reviewer (did not author this; did not implement, commit, or mark the queue done)
**Date:** 2026-08-18
**Kind:** scoped review of checklist + README + memory-bank
**Scope:** `docs/acceptance-checklist.md`, `README.md`, `memory-bank/activeContext.md`, `memory-bank/progress.md`, `memory-bank/tasks.md`. `memory-bank/decisions.md` is dirty in the tree but was not claimed as T12 work (pre-existing uncommitted).

**Blocking if:** checklist invents pass evidence; points tests at real `~/.hermes`; omits demo-blocking criteria from spec §17.

**Verdict:** `approve`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 0 |
| Minor | 3 |
| Blocking | 0 |

**Retry:** no

---

## Blocking criteria

| Criterion | Result | Evidence |
| --- | --- | --- |
| Checklist invents pass evidence | **Met (does not invent)** | All seven AC rows are **held** via sibling verifier paths that exist and contain the cited tokens (PIDs `3265`/`3266`, `sess_stub`/`sess_stub_s2`, `three_questions_order`, `1 weakness(es) persisted`, `opening_target_source=MEMORY.md` before `Question:`, `done_same_finalize_fn`). Gate rollup **pass** matches `.workflow/S2-GE/results/verifier-result.md` and `.workflow/S3-GE/results/verifier-result.md`. Live free-form is cited as S4-T11 **pass** with `human_needed: true` (verifier JSON line 156). Preface and completeness box explicitly refuse a live e2e pass against real `~/.hermes`. `bats` rows are marked read/not-executed. |
| Points tests at real `~/.hermes` | **Met (does not)** | Checklist isolation audit forbids pointing acceptance checks at real home; `HERMES_HOME` expected under `<repo>/.crossfire/profiles/`. README Tests (`:101-107`) export `HERMES_HOME="${REPO_ROOT}/.crossfire/profiles/test"` then `bats tests/`. Isolation bats default is repo `.crossfire/profiles/test`, not `~/.hermes` (`tests/isolation.bats:7-11`). Monday `$HOME/.hermes` is the documented free-form profile, not a test/check path. |
| Omits spec §17 demo-blocking criteria | **Met (all seven present)** | Checklist table rows 1–7 match spec §17 items 1–7 (no-naming opener; weakness + staged `SKILL.md` on disk; layer attribution; distinct process/session IDs; tests never mutate real `~/.hermes`; three questions none dropped for time; `/done`/finalize + SIGKILL not guaranteed). Spec should-pass bullets are in the known-limitations table (honesty beat / no promotion gate; Monday no auto-import; question-bank breadth cuttable). |

No blocking findings.

---

## Spec / plan / packet checks

| Requirement | Result |
| --- | --- |
| Files allowed | Met. Product: checklist, README, `memory-bank/`. Results under `.workflow/S4-T12/results/`. Did not commit; queue not marked done. |
| Cite existing verifier evidence; do not invent live e2e vs real `~/.hermes` | Met. See blocking table. |
| Evidence paths: S2-GE, isolation, two-process opener, deferred persist, candidate exclusion | Met. Gate rollup + supporting table cite S2-GE, S1-T1b/S2-T5 isolation, S2-T7/S2-GE opener, S2-T5 persist, S2-T6/S2-T7 exclusion. |
| Clean-terminal demo: `bash scripts/demo.sh --prepare` then `bash scripts/demo.sh` | Met in checklist `:11-15` and README `:37-41` with documented `REPO_ROOT` + isolated `HERMES_HOME`. No extra undocumented steps between prepare and timed run. |
| Known limitations: bats missing, live free-form pending, YAML round-trip probe-pending | Met in checklist `:69-73`, `memory-bank/activeContext.md`, `memory-bank/progress.md`. YAML wording matches `docs/hermes-compatibility.md` (not proven to survive). T11 live transcript called **human_needed**, not a demo blocker. |
| Plan Task 12 “full suite in isolated profile” | Not re-run; logged as bats-missing limitation instead of a fake suite pass. Packet-correct. |
| Plan Task 12 read-only audit extras (real `MEMORY.md` malformed/duplicate, namespace collision, fixture leak, Curator) | Not recorded as observed-this-pass. Packet did not require a new probe of real `~/.hermes` (that would fight the isolation block). Isolation audit is an **Expected** table, not a fresh fingerprint. Track only — not §17. |

### Citation spot-checks (not re-executed)

| Checklist claim | Source | Match |
| --- | --- | --- |
| S2-GE PIDs 3265/3266; `sess_stub` / `sess_stub_s2` | `.workflow/S2-GE/results/verifier-result.md:75-82` | Yes |
| S2-T7 PIDs 1307/1308 | `.workflow/S2-T7/results/verifier-result.md:183-185` | Yes |
| `three_questions_order`; `1 weakness(es) persisted`; `done_same_finalize_fn` | `.workflow/S2-T5/results/verifier-result.md:62,71,123` | Yes |
| Candidate staging / never-write-live | `.workflow/S2-T6/results/verifier-result.md` claim + `stage_under_candidate_root` | Yes |
| S3-T8 stdout weakness-block + staged SKILL.md | `.workflow/S3-T8/results/verifier-result.md:13` | Yes |
| S3-GE layer attribution AC2 | `.workflow/S3-GE/results/verifier-result.md:15-18` | Yes |
| S3-T10 three `q_*` IDs; stub ≤90s | `.workflow/S3-T10/results/verifier-result.md:102,134` | Yes (checklist cell undersells this as “through session one”) |
| S4-T11 `human_needed: true` | `.workflow/S4-T11/results/verifier-result.md:5,156` | Yes |
| SIGKILL not guaranteed | `skills/crossfire-interviewer/SKILL.md:185` | Yes in SKILL.md; **not** in README (Minor 2) |

Cited paths exist: S1-T1b, S2-T5/T6/T7, S2-GE (+ test-runner), S3-T8/T9/T10, S3-GE, S4-T11 verifier results.

---

## Minor (track, not blocking)

### Minor 1 — `memory-bank/tasks.md` Sprint 3 status contradicts itself and `progress.md`

`memory-bank/tasks.md:20-21` still says `S3-T9` pending — next and `S3-T8` … `S3-GE` pending (nice) while the same section lists `S3-T8` done (`:19`) and `progress.md` records S3-T9 / S3-GE done. Packet required memory-bank known-limitations (those landed in `activeContext.md` / `progress.md`). This rollup is internally false. Autopilot queue is the operational SoT, so not retry-blocking. **Fix if tightening:** drop the pending S3 lines; mark S3-T4…S3-GE done.

### Minor 2 — Criterion 7 evidence cites README for SIGKILL documentation README does not contain

Spec §17.7 second sentence: raw quit/SIGKILL documented as not guaranteed. Product coverage is `skills/crossfire-interviewer/SKILL.md:185`. README has no `SIGKILL` string; it documents propose-only YAML and `/quit` for Monday (`README.md:80`). The evidence cell (`docs/acceptance-checklist.md:42`) bundles SKILL.md **and** README as documenting “propose-only YAML and harness-owned durable writes,” which is true but does not pin the SIGKILL clause. Finalize half is correctly cited to S2-T5. **Fix if tightening:** cite `SKILL.md` SIGKILL sentence; do not imply README covers it.

### Minor 3 — README isolated rehearsal still `mkdir`s only `memories/`

`README.md:89-92` copies `cp -r skills/crossfire-interviewer "${HERMES_HOME}/skills/"` after `mkdir -p "${HERMES_HOME}/memories"` only. S4-T11 smoke procedure already `mkdir`s `skills/` as well. Carry-forward from T11; optional rehearsal path; Monday install still `mkdir -p .../skills/crossfire-interviewer`. **Fix if tightening:** `mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills"` to match `tests/interactive_smoke.md`.

---

## Tests vs behavior

This task is a citation rollup, not a new harness. Completeness is whether cited evidence exists and matches — checked above. Did not run `bats`. Did not invoke Hermes. Did not write `~/.hermes`. README test command points at `.crossfire/profiles/test`. Checklist does not add a command that sets `HERMES_HOME=$HOME/.hermes` for tests.

---

## Isolation

No product write under real `~/.hermes`. Checklist and README keep demo/tests on disposable profiles. Monday real-home path is explicit and separate. Historical S1-T1b first-run leak is logged as a limitation, not rewritten as a clean first run.

Did not mutate git state or the queue (`S4-T12` remains in progress).

---

## Checks run

- Read packet `02-implementation.md`, implementer result, spec §17, plan Task 12.
- `git diff` on `README.md`, `docs/acceptance-checklist.md`, `memory-bank/activeContext.md`, `memory-bank/progress.md`, `memory-bank/tasks.md`. `decisions.md` dirty but unclaimed.
- Spot-checked cited verifier tokens (S2-GE, S2-T5, S2-T6, S2-T7, S3-T8, S3-T10, S3-GE, S4-T11, S1-T1b).
- Confirmed `tests/isolation.bats` defaults to repo test profile; README Tests export isolated `HERMES_HOME`.
- Confirmed all seven §17 demo-blocking rows and three should-pass bullets are present.
- Confirmed SIGKILL sentence in SKILL.md; absent from README.
- Did not run demo, bats, or Hermes; did not write real `~/.hermes`.

```json
{
  "packet_id": "03-review",
  "status": "done",
  "verdict": "approve",
  "retry_required": false,
  "findings": {
    "critical": 0,
    "important": 0,
    "minor": 3,
    "blocking": 0
  },
  "isolation": "pass_real_hermes",
  "blocking": "none",
  "invented_pass_evidence": false,
  "tests_point_at_real_hermes": false,
  "spec_17_demo_blocking_omitted": false,
  "items": [
    {
      "priority": "minor",
      "id": "tasks_md_s3_status_contradiction",
      "status": "open",
      "file": "memory-bank/tasks.md",
      "line": 20
    },
    {
      "priority": "minor",
      "id": "criterion_7_readme_sigkill_citation",
      "status": "open",
      "file": "docs/acceptance-checklist.md",
      "line": 42
    },
    {
      "priority": "minor",
      "id": "readme_isolated_rehearsal_mkdir_skills",
      "status": "open",
      "file": "README.md",
      "line": 90
    }
  ]
}
```
