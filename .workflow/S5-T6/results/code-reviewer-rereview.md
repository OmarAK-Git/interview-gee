# S5-T6 code re-review — evidence truncation fix

**Packet:** `.workflow/S5-T6/packets/03-review.md` (scoped re-review of open Important 1)
**Prior review:** `.workflow/S5-T6/results/code-reviewer-result.md` (verdict `block`)
**Reviewer:** code-reviewer (did not author this code)
**Date:** 2026-08-23
**Kind:** scoped re-review of Important 1 only (ellipsis vs quote-substring persist)
**Scope:** `scripts/practice_session.sh` `crossfire_practice_end` ev_val truncate (`:362-364`); validator `crossfire_weakness_evidence_valid` (`weakness_memory.sh:114-121`) unchanged
**Spec:** plan Task 6 evidence truncate + persist quote-substring invariant (`docs/superpowers/plans/2026-08-23-practice-interviewer.md`)

Implementer report treated as unevidenced. Working-tree End truncate is `ev_val="${ev_val:0:180}"` (`git diff HEAD -- scripts/practice_session.sh`). Packet `03-review-diff.md` still shows the old `177...` form and is stale.

**Verdict:** `approve`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 0 |
| Minor (still open, not blocking) | 2 (unchanged from first review) |
| Blocking | 0 |

---

## Open finding status

### Important 1 — ellipsis breaks quote persist validation — **ADDRESSED**

**Required fix:** truncate to `<=180` of the original quote; do not append `...`.

**Current code** (`scripts/practice_session.sh:362-364`):

```bash
if [ ${#ev_val} -gt 180 ]; then
  ev_val="${ev_val:0:180}"
fi
```

- 9th persist arg remains `"${ev_val:-}"`; 10th remains `"$submitted"` (`:366-368`).
- Source no longer contains `${ev_val:0:177}...` (`grep` on `practice_session.sh`).
- Prefix of a quote that is a substring of `submitted_answer` is still a substring, so `[[ "$answer" == *"$value"* ]]` (`weakness_memory.sh:119-121`) can pass.

Independent probe (sourced validator, 201-char answer, same shape as first review):

```
len_answer=201
len_ellipsis=180
len_prefix180=180
len_current=180
ellipsis_valid=0          # first 177 + "..."  (old form, still fails)
prefix180_valid=1         # first 180 of original
current_truncate_valid=1  # End if-block as written
current_is_original_prefix=1
current_has_ellipsis=0
source_has_180_prefix=1
source_has_ellipsis=0
```

Plan Step 3 still *shows* `ev_val="${ev_val:0:177}..."` (`2026-08-23-practice-interviewer.md:1145`). Persist validation wins over that snippet (same ruling as first review / implementer note). Product code correctly diverges. Do not re-open this finding for matching the plan snippet.

---

## New findings

### Critical

None.

### Important

None.

The one-line swap does not change topic assignment, persist gate (`crossfire_spool_should_persist`), report kv, `kv_parse`, or UI End bubble. No new blast-radius defect from the fix.

### Minor (still open from first review; not re-opened as new)

- **Minor 1** — `practice_jd.sh` “no q_live” is vacuous when `MEMORY.md` is absent.
- **Minor 2** — report / UI tests do not lock values, `kv_parse`, or the >180-char quote path. Suite still cannot catch a regression that re-adds `...`. Track only.

---

## Required confirms (re-checked for the fix)

| Check | Result | Evidence |
| --- | --- | --- |
| Truncate `<=180` of original, no ellipsis | **Yes** | `:362-364`; probe `len_current=180`, `current_has_ellipsis=0`, `current_is_original_prefix=1` |
| Quote-substring persist still valid after truncate | **Yes** | `current_truncate_valid=1`; old ellipsis form still `0` |
| 10th persist arg is still `submitted` | **Yes** | `:366-368` |
| Topic still `{label} · {family}` | **Yes** | `:353` unchanged by this fix |
| Persist rule (`≥ 2`) unchanged | **Yes** | `crossfire_lib.sh` / `weakness_memory.sh` not in this fix |

Host `MEMORY.md` write gap (python3 Store stub) is unchanged and still not a Task 6 product defect.

---

## Verdict rationale

Important 1 is closed in product code with independent validator evidence. No new Critical or Important. Approve Task 6 review gate.
