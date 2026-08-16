# Progress

## Implementation

Sprint 1 complete and gated.

- S1-T1 done — Hermes not installed; fail-closed preflight; §15 statuses allowed set
- S1-T1b done — harness isolation from restored baseline; operator-approved rmdir of leaked empty `/home/fish/.hermes`
- S1-T2 done — deterministic weakness-block merge (last_seen eviction, atomic persist)
- S1-T3 done — assessment contract encoded; live N=5 skip/fail-closed
- S1-GE pass — gate model cursor-grok-4.5-high
- S2-T5 unblocked after operator-approved WSL install (v0.20.2) and HERMES_HOME profile-data probe. Live chat still needs a model/API key.

## Evidence

- `.workflow/S1-T1/results/verifier-result.md`
- `.workflow/S1-T1b/results/verifier-result.md`
- `.workflow/S1-T2/results/verifier-result.md`
- `.workflow/S1-T3/results/verifier-result.md`
- `.workflow/S1-GE/results/test-runner-result.md`
- `.workflow/S1-GE/results/verifier-result.md`
