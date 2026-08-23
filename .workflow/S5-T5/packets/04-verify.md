# Packet 04-verify: S5-T5

Claim: S5-T5 is done. Treat that claim as unevidenced.

## Goal

Operator can pick or paste one JD, set optional persona and temperature, see context, and Skip.

## Acceptance criteria

1. HTML has jd-kind, pack-id, jd-paste, persona, temperature, jd-context, skip.
2. app.js fetches /api/packs and posts jd_kind on start.
3. Start without a JD is rejected in the UI (400 surfaced).

## Commands

```
py -3 -m unittest tests.test_memory_view.UiContractTest
```

Also read index.html and app.js. Confirm start catch bubbles HTTP 400. Do not use real ~/.hermes.

Write `.workflow/S5-T5/results/verifier-result.md`.
