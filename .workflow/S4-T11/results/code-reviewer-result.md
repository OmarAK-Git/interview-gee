# S4-T11 code review (re-review) — Free-form Monday usability

**Packet:** `02-implementation` (no `03-review.md` in run dir; re-reviewed against that packet + prior review + implementer retry)
**Reviewer:** code-reviewer (did not author the fix; did not implement, commit, or mark the queue done)
**Date:** 2026-08-18
**Kind:** scoped re-review after Important 1 retry
**Scope:** `tests/interactive_smoke.md`, `README.md`, `skills/crossfire-interviewer/SKILL.md`. Prior Important 1 must be ADDRESSED. Missing live transcript is `human_needed`, not blocking.

**Prior verdict:** `request_changes` (Important 1: `cp` into missing skill dir)
**This verdict:** `approve`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important (open) | 0 |
| Important 1 | **ADDRESSED** |
| Minor (carry-forward) | 3 |
| New blocking | **0** |

**Retry:** no

---

## Prior Important 1 — ADDRESSED

**Original finding:** `tests/interactive_smoke.md` created `${HERMES_HOME}/skills` then copied a single `SKILL.md` into `${HERMES_HOME}/skills/crossfire-interviewer/` without creating that nested directory. GNU `cp` would fail before Hermes steps. Also omitted `questions.md`.

**Required fix:** `mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills"` and `cp -r skills/crossfire-interviewer "${HERMES_HOME}/skills/"`. Do not invent a live transcript.

**Current evidence** (`tests/interactive_smoke.md:39-41`):

```bash
mkdir -p "${HERMES_HOME}/memories" "${HERMES_HOME}/skills"
cp tests/fixtures/memory-three-weaknesses.md "${HERMES_HOME}/memories/MEMORY.md"
cp -r skills/crossfire-interviewer "${HERMES_HOME}/skills/"
```

| Check | Result |
| --- | --- |
| Uses `cp -r` of the skill directory | **Yes** — `cp -r skills/crossfire-interviewer "${HERMES_HOME}/skills/"` |
| Parent `skills/` created first | **Yes** — `mkdir -p ... "${HERMES_HOME}/skills"` |
| Nested dest exists for GNU `cp -r` | **Yes** — dest directory exists; copy lands at `.../skills/crossfire-interviewer/` |
| Includes `questions.md` | **Yes** — directory copy; `skills/crossfire-interviewer/questions.md` exists in-repo |
| Live transcript invented to “fix” this | **No** — pending `LIVE RUN` block unchanged (`:80-93`) |

Matches README isolated rehearsal copy shape (`README.md:91`) and adds the `mkdir` of `skills/` that the prior finding required.

**Status:** ADDRESSED.

---

## Stub vs live transcript (unchanged judgment)

Packet: honest stub allowed; do not fake a live transcript.

| Question | Judgment |
| --- | --- |
| Missing live Hermes transcript | **`human_needed`** — not Important, not blocking. Environment still records WSL `E_UNEXPECTED`, Hermes not on Windows PATH, real `%USERPROFILE%\.hermes` absent. Pending `LIVE RUN` block is empty of invented Q&A. |
| Retry implementer for transcript? | **No.** |

---

## Blocking criteria (re-checked)

| Criterion | Result | Evidence |
| --- | --- | --- |
| Demo weaknesses do not auto-copy to real `~/.hermes` | **Met** | No `cp` of stage `MEMORY.md` or candidate skills into `$HOME/.hermes`. README `:12`, `:81`; smoke `:28`, `:97`; SKILL `:186`. Rehearsal copies fixture memory into `.crossfire/profiles/test` only. |
| README requires editing prompts | **Met** | `README.md:31` no prompt/`SOUL.md` edits. Monday start `:58-67` is `hermes chat --skills crossfire-interviewer --toolsets skills,memory --source cli`. |
| SKILL.md breaks the demo contract | **Met (no break)** | Spec §11 three questions remain. Persist ≥2 unchanged. Propose-only. Session-two target selection still harness-owned. Monday section gated “without the demo harness”. Retry did not touch SKILL.md. |

No new blocking findings.

---

## Spec / plan / packet checks

| Requirement | Result |
| --- | --- |
| Files allowed | Met. Same three product paths. Results only under `.workflow/S4-T11/results/`. |
| Honest stub if live cannot run | Met. Retry did not fill a fake transcript. |
| Isolation: never write real `~/.hermes` | Met in recorded procedure. |
| Demo three questions / persist / isolation / memory-only opener not cut | Met. |

---

## Carry-forward Minor (not blocking; not required for this retry)

### Minor 1 — Three disjoint `hermes chat` invocations

`tests/interactive_smoke.md:43-61` still uses one-shot `-q`, then a new REPL without `--resume`, then `--resume latest`. Unchanged. Track.

### Minor 2 — Monday vs demo opener both live in one skill

SKILL Monday (`:173`) vs session-two harness-owned targeting (`:132-134`). Unchanged. Track.

### Minor 3 — `questions.md` install copy swallowed

`README.md:25-26` still `2>/dev/null || true`. Unchanged. Track.

README isolated rehearsal (`:89-91`) still `mkdir`s only `memories` (not `skills/`) before `cp -r ... "${HERMES_HOME}/skills/"`. Smoke now mkdir’s `skills/` correctly. Not treated as a new Important: Monday install path already `mkdir -p .../skills/crossfire-interviewer`; isolated rehearsal is optional and the recorded smoke procedure (the prior finding’s file) is fixed.

---

## Tests vs behavior

Verification remains `Test-Path` existence checks. Expected for a docs/stub task. No bats added; none required. Did not run `bats`; did not invoke Hermes; did not write `~/.hermes`.

---

## Isolation

No product write under real `~/.hermes`. Smoke/README/SKILL still forbid copying stage `MEMORY.md` into Monday.

Did not mutate git state or the queue (`S4-T11` remains `in_progress`).

---

## Checks run

- Re-read packet `02-implementation.md`, plan Task 11, prior `code-reviewer-result.md`, implementer retry section.
- Confirmed `tests/interactive_smoke.md:41` is `cp -r skills/crossfire-interviewer "${HERMES_HOME}/skills/"`.
- Confirmed `mkdir -p` includes `${HERMES_HOME}/skills` (`:39`).
- `git diff` on `skills/crossfire-interviewer/SKILL.md`; `README.md` and `tests/interactive_smoke.md` untracked allowed paths.
- Confirmed pending live transcript not filled (`:80-93`).
- Re-checked blocking criteria; no new blockers.

```json
{
  "packet_id": "03-review",
  "status": "done",
  "verdict": "approve",
  "retry_required": false,
  "important_1": "ADDRESSED",
  "findings": {
    "critical": 0,
    "important_open": 0,
    "important_addressed": 1,
    "minor": 3
  },
  "blocking_count": 0,
  "new_blocking_count": 0,
  "isolation": "pass_real_hermes",
  "blocking": "none",
  "stub_transcript": "human_needed_not_blocking",
  "items": [
    {
      "priority": "important",
      "id": "smoke_cp_missing_skill_dir",
      "status": "ADDRESSED",
      "file": "tests/interactive_smoke.md",
      "line": 41
    },
    {
      "priority": "minor",
      "id": "smoke_fragmented_hermes_invocations",
      "status": "open",
      "file": "tests/interactive_smoke.md",
      "line": 43
    },
    {
      "priority": "minor",
      "id": "monday_opener_vs_harness_dual_instruction",
      "status": "open",
      "file": "skills/crossfire-interviewer/SKILL.md",
      "line": 173
    },
    {
      "priority": "minor",
      "id": "readme_questions_copy_swallowed",
      "status": "open",
      "file": "README.md",
      "line": 25
    }
  ]
}
```
