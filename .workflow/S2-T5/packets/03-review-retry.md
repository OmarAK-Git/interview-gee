# Packet 03-review-retry: scoped re-review of Critical 1 fix

Prior packet: `.workflow/S2-T5/packets/03-review.md`  
Prior verdict: `.workflow/S2-T5/results/code-reviewer-result.md` (`blocking_retry`)  
Fix diff vs HEAD: `.workflow/S2-T5/packets/03-review-retry-diff.patch`

## Open findings from first review (verbatim)

### Critical 1
Live assessor stdout is consumed as persist YAML with no extraction and no harness-injected `submitted_answer`; `CROSSFIRE_LIVE=1` finalize aborts without writing MEMORY.md. Files: `scripts/demo_session_1.sh:86-93`, `138`, `182-183`. Required: extract YAML from live stdout; overlay `submitted_answer`, `answer_ref`, `question_id`, `source_session_id`; do not use `crossfire_spool_field evidence_value` as persist fallback; deterministic test of skill-shaped live YAML (preamble, no `submitted_answer`) asserts persist + ack.

### Minor 1
`/done` == auto-finalize is asserted by grep count, not behavior (`tests/demo_session_1.bats:148-152`).

### Minor 2
Deterministic tests never feed live-shaped spool YAML (`tests/demo_session_1.bats:162-176`).

## Re-review contract

For each finding: **ADDRESSED** or **NOT ADDRESSED** with file:line evidence. Flag **new** Critical/Important breakage in the fix diff only. Out-of-scope observations are Minor and must not extend the loop.

Write `.workflow/S2-T5/results/code-reviewer-result.md` (replace or clearly mark as retry). Verdict `approve` only if Critical 1 is ADDRESSED and no new Critical/Important. Else `blocking_retry`.

Independently probe isolated finalize of skill-shaped YAML with preamble and no `submitted_answer`. Never write real `~/.hermes`. Do not install bats.
