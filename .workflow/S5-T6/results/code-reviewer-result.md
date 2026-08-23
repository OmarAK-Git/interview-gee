# S5-T6 code review — Close-out report and family buckets

**Packet:** `.workflow/S5-T6/packets/03-review.md`
**Reviewer:** code-reviewer (did not author this code)
**Date:** 2026-08-23
**Kind:** scoped review of plan Task 6 only
**Scope:** `scripts/practice_session.sh` (`crossfire_practice_end`), `app/server.py` `kv_parse`, `app/static/app.js` End handler, `tests/practice_jd.sh`, `tests/test_memory_view.py`
**Spec:** plan Task 6 only (`docs/superpowers/plans/2026-08-23-practice-interviewer.md` through the line before Task 7)

Implementer report treated as unevidenced. Diff vs HEAD is the five files above only (`scripts/crossfire_lib.sh`, `scripts/weakness_memory.sh`, `skills/crossfire-interviewer/SKILL.md` unchanged).

**Verdict:** `block`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 1 |
| Minor | 2 |
| Blocking | 1 |

**Retry:** yes — persist the truncated evidence prefix without appending `...`, so `crossfire_weakness_evidence_valid` still accepts quote evidence after the 180-char cap.

**Strongest issue:** Evidence truncation appends `...`, which fails the unchanged quote-substring persist validator. Any `evidence.value` longer than 180 characters is dropped at End (`persisted_count` stays 0) even on a host that can write `MEMORY.md`.

---

## Required confirms

| Check | Result | Evidence |
| --- | --- | --- |
| Persist topic is `{label} · {family}` | **Yes** | `practice_session.sh:353` `topic="${CROSSFIRE_JD_SOURCE_LABEL:-practice} · ${family}"`. Old `question_id` + ` practice gap` assignment is gone from this file (`git diff` `-topic=$(crossfire_spool_field "$f" question_id)` / `-topic="${topic} practice gap"`). |
| Topic is never `q_live_01 practice gap` | **Yes (code)** | No `practice gap` string remains in `practice_session.sh`. `q_live_*` is still the spool `question_id` (`:197`) only — End no longer reads it for `topic`. |
| Persist rule (`≥ 2`) unchanged | **Yes** | `crossfire_spool_should_persist` (`crossfire_lib.sh:408-424`) not in the diff: `persist_recommended` contains `true`, else `count(missing) >= 2`. End still gates persist with that helper (`practice_session.sh:349`) and classifies Weak/Strong with the same helper (`:390`). Skill/demo persist text not edited. |
| `MEMORY.md` not written on this host | **Host persist gap, not a Task 6 product defect** | See section below. Topic assignment and persist *call* are present; write dies in pre-existing `crossfire_weakness_fsync_file`. |

---

## Spec compliance

| Requirement | Result | Evidence |
| --- | --- | --- |
| Persist `topic` = `${CROSSFIRE_JD_SOURCE_LABEL} · ${family}` | **Met** | `:353`. Fallback `practice` if label empty — still not `q_live_N practice gap`. |
| `topic_key` via existing `crossfire_normalize_topic_key` | **Met** | Persist engine computes it from `topic` (`weakness_memory.sh:454`, `:472`). End still uses the helper for candidate-skill id (`practice_session.sh:370`). Same label+family therefore merges. |
| Evidence value truncated to 180; do not persist full `submitted_answer` as the quote | **Met in form, broken in effect** | Truncate at `:362-364`; 9th persist arg is `ev_val`, 10th remains `submitted` (`:366-368`). Appending `...` makes long quotes fail validation (Important 1). |
| End kv: `report_weak`, `report_strong`, `report_text` with `Weak:` / `Strong:` | **Met** | Wrapper emits `report_weak` / `report_strong` plus `report_line=` (`:400-402`). Independent stub End stdout: `report_weak=behavioral:[action, result]`, `report_line=Weak: …`, `report_line=Strong: none`. `kv_parse` joins `report_line` → `report_text` (`server.py:41-48`). Independent parse of that stdout: `report_text == "Weak: behavioral:[action, result]\nStrong: none"`. |
| UI shows `report_text` instead of only `Persisted N` | **Met** | `app.js:262-263`. `Persisted ${data.persisted_count` string removed (diff vs previous End bubble). |
| Skip omitted from report | **Met** | Skip writes no spool YAML (unchanged). Report scans `spool/*.yaml` only. |
| Packet AC: MEMORY.md topic is not `q_live_01 practice gap` | **Met in code; unproven on disk here** | Source never writes that topic. Host does not create `MEMORY.md` (below). |

Nothing extra in the product surface: `persisted_count` kv remains (plan did not remove it). No persist-engine rewrite. Demo scripts untouched.

---

## Findings

### Critical

None.

### Important (fix before proceeding)

#### Important 1 — `scripts/practice_session.sh:362-364` ellipsis breaks quote persist validation

Task 6 adds:

```bash
if [ ${#ev_val} -gt 180 ]; then
  ev_val="${ev_val:0:177}..."
fi
```

`crossfire_persist_weakness` still requires quote evidence to be a substring of `submitted_answer` (`weakness_memory.sh:119-121`):

```bash
[[ "$answer" == *"$value"* ]]
```

Independent probe (sourced validator, 201-char answer):

```
ellipsis_valid=0   # first 177 chars + "..."
prefix_valid=1     # first 177 chars only
dashboard_valid=1  # stub quote unchanged
```

So the dashboard/acceptance quote still validates, but any live `evidence.value` longer than 180 characters fails validation, persist returns non-zero, and End continues with `persisted_count=0`. The family-bucket card never lands in `MEMORY.md` — the same symptom as the host fsync gap, including on Linux.

Tests never emit a >180-char quote, so `practice_jd.sh` cannot catch this.

**Fix:** persist `${ev_val:0:180}` (or `:177`) with no `...` suffix. The prefix is a substring of `submitted_answer`. Keep `submitted` as the 10th arg.

### Minor (track)

#### Minor 1 — `tests/practice_jd.sh:75-78` “no q_live” is vacuous when `MEMORY.md` is absent

```
if grep -q 'q_live_01 practice gap' "$HERMES_HOME/memories/MEMORY.md"; then
  bad "old practice-gap topic"
else
  ok "no q_live practice-gap topic"
fi
```

Independent `practice_jd.sh` this review: `grep: .../MEMORY.md: No such file or directory` then `PASS: no q_live practice-gap topic`. That assertion cannot distinguish “correct new topic + persist write failed” from “old topic + persist write failed.” Topic correctness on this host is source-only (`:353`), not disk-proven. The companion `topic uses source label` check correctly failed (15 pass / 1 fail).

#### Minor 2 — report / UI tests do not lock values or `kv_parse`

- `practice_jd.sh:71-74` only `grep -q 'report_weak='` / `'Weak:'` / `'Strong:'`. Empty `report_weak=` would still pass.
- `UiContractTest` (`tests/test_memory_view.py:103-104`) is substring presence of `report_text` and absence of `Persisted ${data.persisted_count`. No HTTP End test. Server join is untested in-suite (verified out-of-band this review).

---

## Host persist gap (not a Task 6 product defect)

`MEMORY.md` is **not** written on this Windows host. That is a **pre-existing host persist gap**, not a missing topic assignment or a changed `≥ 2` rule.

Independent isolated stub (temp `HOME` / `HERMES_HOME`, pack label `Project Praetor`, dashboard answer, `end`):

```
DASH_PERSIST=true
END_RC=0
report_weak=behavioral:[action, result]
report_line=Weak: behavioral:[action, result]
report_line=Strong: none
persisted_count=0
MEMORY_EXISTS=0
python3_fsync_exit=49
```

Spool still had `question_id: q_live_01`, but End no longer copies that into `topic`. Persist **was** invoked (validation had to pass to reach fsync; python3 Store error printed on End stderr). Write died in `crossfire_weakness_fsync_file` (`weakness_memory.sh:183-184`):

```
command -v python3  →  /c/Users/oalan/AppData/Local/Microsoft/WindowsApps/python3
python3 --version   →  "Python was not found" (Microsoft Store alias)
```

Because `command -v python3` succeeds, the function never falls through to `sync -f` (and `sync` *is* present at `/usr/bin/sync`). Real interpreters exist (`python` → Python312, `py` launcher) but this helper does not use them. Task 6 did not edit `weakness_memory.sh`. Plan: “Do not add a new persist engine.”

Do not treat “`MEMORY.md` missing on this machine” as a Task 6 functional miss. Do not treat `PASS: no q_live practice-gap topic` as proof the new topic was written.

---

## Correctness / security / simplicity (checked, no extra findings)

- Weak/Strong classification uses the same `crossfire_spool_should_persist` as persist (`≥ 2` / `persist_recommended`). Dashboard stub → Weak `behavioral:[action, result]`; no second spool → `Strong: none`. Skip omitted.
- Second spool scan after `shopt -u nullglob` is safe: missing glob is not a file; `[ -f ]` continues; empty session reports `Weak: none` / `Strong: none`.
- `kv_parse` last-wins for ordinary keys; `report_line` / `attribution_line` are collected. End JSON is passthrough of that dict (`server.py:243-249`).
- UI report uses `textContent` via `bubble()` — no HTML injection of the report.
- Demo persist topic (`qid demo gap` in `demo_session_1.sh` / `stage_candidate_skill.sh`) untouched.

---

## Tests vs behavior

| Test | What it actually proves |
| --- | --- |
| `practice_jd.sh` report greps | Wrapper stdout contains the keys/words. Independent run: keys have real Weak content. |
| `practice_jd.sh` MEMORY greps | Negative check passes if the file is missing. Positive source-label check fails on this host (fsync). |
| `UiContractTest` `report_text` | JS source contains the identifier and dropped the old Persisted template. Does not exercise `/api/session/end`. |

`py -3 -m unittest tests.test_memory_view.UiContractTest` this review: OK.

---

## Verdict rationale

Acceptance report kv + UI wiring + topic *assignment* + unchanged `≥ 2` rule are in the diff and independently confirmed. The host `MEMORY.md` miss is not a product defect. Block is solely Important 1: the new 180-char truncate can prevent the family-bucket persist this task exists to land, and the suite cannot see it.
