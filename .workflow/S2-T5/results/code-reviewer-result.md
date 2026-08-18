# S2-T5 code review (retry)

**Packet:** `03-review-retry`  
**Prior packet / verdict:** `03-review` / `blocking_retry`  
**Reviewer:** code-reviewer (did not author the fix; did not implement, commit, or mark queue done)  
**Date:** 2026-08-18  
**Scope:** Re-review of Critical 1 fix. Prior findings vs current `scripts/demo_session_1.sh`, `scripts/demo_common.sh`, `tests/demo_session_1.bats`, `skills/crossfire-interviewer/SKILL.md`. New Critical/Important only from `.workflow/S2-T5/packets/03-review-retry-diff.patch`.  
**Spec:** `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` §8, §10 live demo gate, §11, §12  

**Verdict:** `approve`

---

## Prior findings

### Critical 1 — ADDRESSED

**Was:** Live assessor stdout consumed as persist YAML with no extraction and no harness-injected `submitted_answer`; `CROSSFIRE_LIVE=1` finalize aborted without MEMORY.md. Required: extract YAML; overlay `submitted_answer`, `answer_ref`, `question_id`, `source_session_id`; do not use `crossfire_spool_field evidence_value` as persist fallback; deterministic test of skill-shaped live YAML (preamble, no `submitted_answer`) asserts persist + ack.

**Evidence it is fixed:**

- Extract + overlay before spool write: `scripts/demo_session_1.sh:87` calls `crossfire_normalize_live_proposal` (no `proposal=$(cat "$stdout")`). Helpers: `scripts/demo_common.sh:439-490` (`crossfire_extract_yaml_from_live_stdout`), `:505-520` (`crossfire_overlay_spool_harness_fields`), `:522-527` (`crossfire_normalize_live_proposal`). Overlay always appends `question_id`, `answer_ref`, `source_session_id`, `submitted_answer: |` from the harness answer (`demo_common.sh:515-519`).
- Persist fallback removed: `scripts/demo_session_1.sh:178-181` reads `submitted_answer` from spool and `fail_closed` if empty. `grep` of `scripts/demo_session_1.sh` + `scripts/demo_common.sh`: **no** `crossfire_spool_field … evidence_value`; **no** `${submitted_answer:-…}` fallback. `crossfire_spool_field` is only used for `question_id`, `family`, `missing_elements`, `source_session_id`, `answer_ref` (`demo_session_1.sh:169-175`). Nested `evidence.value` is still parsed by awk for the persist API (`:177`), not as a `submitted_answer` substitute.
- Deterministic test: `tests/demo_session_1.bats:168-198` feeds preamble + skill-shaped YAML **without** `submitted_answer`, asserts overlay + finalize ack + MEMORY.md quote/session.
- Skill contract documents injection: `skills/crossfire-interviewer/SKILL.md:116`.

**Independent probe** (WSL, disposable `HERMES_HOME=/tmp/crossfire-s2t5-rereview.*/.crossfire/profiles/test`, never real `~/.hermes`; bats not installed):

Skill-shaped stdout (reasoning preamble including `family: this is a behavioral question…`, exact skill example YAML, **no** `submitted_answer`):

| Check | Result |
| --- | --- |
| `RAW_HAS_SUBMITTED` | 0 |
| `NORMALIZE_RC` | 0 |
| extracted `family` | `behavioral` (stolen preamble family line count = 0) |
| overlay `submitted_answer` / `answer_ref` | present; `answer_ref=live_shape_probe1/q_behavioral_01/0` |
| finalize `CROSSFIRE_FINALIZE_RUN_ID` | **rc=0** |
| ack | `CROSSFIRE: session one finalized; 1 weakness(es) persisted.` |
| MEMORY.md | written; quote + `sess_probe1` + 1 `weakness_id` |

Same YAML written **directly to spool without overlay**: finalize **rc=1**, `PREFLIGHT FAIL: spool missing submitted_answer for q_behavioral_01`, MEMORY.md **absent**, no ack. Confirms persist does **not** fall back to `evidence_value`.

Fenced skill YAML and preamble-free skill YAML also normalize (`FENCE_NORMALIZE_RC=0`, `NOPREAMBLE_NORMALIZE_RC=0`).

Real `/home/fish/.hermes` mtime:size unchanged (`1786910797:4096`). Windows `C:\Users\oalan\.hermes` absent before and after. Probe tree deleted.

---

### Minor 1 — ADDRESSED

**Was:** `/done` == auto-finalize asserted by grep count, not behavior (`tests/demo_session_1.bats:148-152`).

**Now:** `tests/demo_session_1.bats:148-166` runs post-Q3 auto-finalize (1 `weakness_id`, quote) and `CROSSFIRE_FINALIZE_RUN_ID` (ack + 1 `weakness_id` + quote). Comment documents harness `/done` equivalent. Shared persist side effects, not a call-site grep.

---

### Minor 2 — ADDRESSED

**Was:** Deterministic tests never feed live-shaped spool YAML (`tests/demo_session_1.bats:162-176`).

**Now:** `tests/demo_session_1.bats:168-198` is that test. Independent probe reproduced the same persist+ack outcome.

---

## New findings in the fix diff

### Critical

None.

### Important

None.

### Minor (must not extend the loop)

1. **`if (in_fence || 1)` is always true** (`scripts/demo_common.sh:470`). Fence markers still save/reset blocks; extraction worked for fenced YAML in the probe. Dead condition, not a product miss.
2. **`trap - RETURN` in finalize/main** (`scripts/demo_session_1.sh:201`, `:260`) after removing the live-assessor RETURN temp-file trap. No-op if unset; leftover, not a persist defect.

---

## Isolation check

**Pass for real `~/.hermes`.** Probe HERMES_HOME under `.crossfire/profiles/` only; `is_real_hermes_home` = no. Product still fail-closes on real profiles (`demo_common.sh:228-230`, `:76-98`). Tests mkdir only under `mktemp` `TEST_ROOT` (`tests/demo_session_1.bats:8-10`). Did not write real `~/.hermes`. Did not install bats.

---

## Checks run (this retry)

- Full read of packet `03-review-retry.md`, prior `code-reviewer-result.md`, `03-review-retry-diff.patch`, and the four product files named in the packet.
- Source grep: no `crossfire_spool_field evidence_value` persist fallback.
- Independent WSL finalize probe: skill-shaped preamble YAML (no `submitted_answer`) → persist + ack + MEMORY.md; no-overlay spool → fail_closed; fenced + no-preamble extract; real-home snapshot unchanged.

---

```json
{
  "packet_id": "03-review-retry",
  "verdict": "approve",
  "retry_required": false,
  "prior_findings": {
    "critical_1": "ADDRESSED",
    "minor_1": "ADDRESSED",
    "minor_2": "ADDRESSED"
  },
  "new_findings": {
    "critical": 0,
    "important": 0,
    "minor": 2
  },
  "new_blocking_count": 0,
  "isolation": "pass_real_hermes",
  "blocking": "none; live skill-shaped YAML extracts, overlays submitted_answer, finalizes with ack and MEMORY.md"
}
```
