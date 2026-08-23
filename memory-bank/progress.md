# Progress

## Implementation

Sprint 1 complete and gated. Sprint 2 session-one harness complete. S3-GE pass. S4-T11 pass.

- S1-T1 done — Hermes not installed; fail-closed preflight; §15 statuses allowed set
- S1-T1b done — harness isolation from restored baseline; operator-approved rmdir of leaked empty `/home/fish/.hermes`
- S1-T2 done — deterministic weakness-block merge (last_seen eviction, atomic persist)
- S1-T3 done — assessment contract encoded; live N=5 skip/fail-closed
- S1-GE pass — gate model cursor-grok-4.5-high
- S2-T5 done — hybrid three-question demo; spool until harness `/done`; stub + live-shaped YAML persist
- S2-T6 done — harness-relocated unverified candidate; never-write-live
- S2-T7 done — memory-only opener; print-before-question; candidate live-dir barrier
- S3-T4 done — static question bank; no invented employer facts
- S3-T8 done — bounded artifact evidence (weakness diff + candidate print)
- S3-T9 done — unverified-learning risk beat
- S3-T10 done — full demo orchestrator ≤90s stub
- S3-GE pass — evidence + layer attribution gate
- S4-T11 pass — Monday free-form procedure; live transcript human_needed
- S4-T12 done — acceptance checklist + README + known limitations
- S4-GE pass — gate model cursor-grok-4.6-high-fast
- Practice UI T1 — Enter sends; weakness cards (YAML stays on disk); Web Speech STT Speak/Done
- Practice UI inference toggle — Hermes `--provider nous|openai-codex` on New session
- S5-T1 done — four JD packs + stdlib `app/packs.py`; leak check 8/0
- S5-T2 done — Practice interviewer (session JD) in SKILL.md; ensure_skill copies sources
- S5-T3 done — start requires one JD; GET /api/packs; pack_id sanitized
- S5-T4 done — JD preamble on every turn; Skip without persist; inbound temp survives load_state

## Evidence

- `.workflow/S1-T1/results/verifier-result.md`
- `.workflow/S1-T1b/results/verifier-result.md`
- `.workflow/S1-T2/results/verifier-result.md`
- `.workflow/S1-T3/results/verifier-result.md`
- `.workflow/S1-GE/results/test-runner-result.md`
- `.workflow/S1-GE/results/verifier-result.md`
- `.workflow/S2-T5/results/verifier-result.md`
- `.workflow/S2-T6/results/verifier-result.md`
- `.workflow/S2-T7/results/verifier-result.md`
- `.workflow/S2-GE/results/test-runner-result.md`
- `.workflow/S2-GE/results/verifier-result.md`
- `.workflow/S3-T4/results/verifier-result.md`
- `.workflow/S3-T8/results/verifier-result.md`
- `.workflow/S3-T9/results/verifier-result.md`
- `.workflow/S3-T10/results/verifier-result.md`
- `.workflow/S3-GE/results/verifier-result.md`
- `.workflow/S4-T11/results/verifier-result.md`
- `.workflow/S4-T12/results/verifier-result.md`
- `.workflow/S4-GE/results/test-runner-result.md`
- `.workflow/S4-GE/results/verifier-result.md`
- `.workflow/S5-T1/results/verifier-result.md`
- `.workflow/S5-T2/results/verifier-result.md`
- `.workflow/S5-T3/results/verifier-result.md`
- `.workflow/S5-T4/results/verifier-result.md`
- `docs/acceptance-checklist.md`

## Known limitations

- **`bats` missing** — full suite not executed in verifier sessions; bash-equivalents substituted.
- **Live free-form transcript** — S4-T11 pass with `human_needed: true`; not a demo blocker.
- **YAML round-trip probe-pending** — HTML-comment delimiters not proven to survive Hermes writes; fallback documented in `docs/hermes-compatibility.md`.
