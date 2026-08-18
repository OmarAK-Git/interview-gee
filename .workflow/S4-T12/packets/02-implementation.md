# Packet 02-implementation: Final safety and acceptance

Researcher skipped: checklist is spec-locked.

## Files allowed

- `docs/acceptance-checklist.md`
- `README.md`
- `memory-bank/`

Plus `.workflow/S4-T12/results/implementer-result.md`. Do not commit. Do not point checks at real ~/.hermes. Optional sprint items logged as known limitations if incomplete — T11 live transcript is human_needed, not a demo blocker.

## Do

Write `docs/acceptance-checklist.md` covering demo-blocking criteria with evidence paths (S2-GE, isolation, two-process opener, deferred persist, candidate exclusion). README: demo from a clean terminal without undocumented steps (`bash scripts/demo.sh --prepare` then `bash scripts/demo.sh`). memory-bank: known limitations (bats missing, live free-form Q&A pending, YAML round-trip probe-pending).

Do not invent passing live e2e against real ~/.hermes. Cite existing verifier evidence.

ACs: Demo-blocking tests pass (cite evidence). Checklist complete. Demo runs from a clean terminal without undocumented manual steps. Should-pass items logged as known limitations if cut.
