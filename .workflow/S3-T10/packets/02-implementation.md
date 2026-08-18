# Packet 02-implementation: Timed ~90s demo assembly

Researcher skipped: compose existing scripts; no path fork. If measured time exceeds 90s, drop extra question-bank items before touching process separation or the three demo questions.

## Files allowed

- `scripts/demo.sh`
- `tests/demo_e2e.bats`
- `docs/demo-script.md`

Plus `.workflow/S3-T10/results/implementer-result.md` and optional bash-assertions.sh. Do not commit. Do not duplicate session-one/two logic — call existing scripts. Do not edit demo_session_1.sh / demo_session_2.sh.

## Do (TDD)

Full-sequence smoke: preflight; session one; restart; memory-only opener; evidence display; risk beat. Distinct IDs + layer labels. Failure exits early with recovery instruction. Narrow reset/prep that never deletes unrelated Hermes state (demo_prepare on disposable profile only). Scripted bad answer remains ≥2 missing.

Timed 90s after pre-warm: if you cannot enforce wall-clock in bats, record a measured rehearsal in implementer-result (packet allows that for verification). Default tests may use CROSSFIRE_ASSESSOR=stub for deterministic smoke.

Isolation fail-closed. Never real ~/.hermes. Do not install bats. Bash-equivalent passed=N failed=0.
