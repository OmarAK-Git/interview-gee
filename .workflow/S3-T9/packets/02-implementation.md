# Packet 02-implementation: Unverified-learning risk beat

Researcher skipped: spec §7 optional honesty beat and §14 activation after opener are locked. Exclusion until opener completes is already T6/T7.

## Files allowed

- `scripts/activate_candidate_skill.sh`
- `scripts/demo_risk_beat.sh`
- `tests/risk_beat.bats`
- `docs/demo-script.md`

Plus `.workflow/S3-T9/results/implementer-result.md` and optional bash-assertions.sh. Do not commit. Do not edit demo_session_2.sh. Activation cannot occur before opener completes.

## Do (TDD)

- Print `UNVERIFIED LEARNING RISK DEMO` label + warning before candidate influence
- Install candidate to a **namespaced** live path (not replacing `crossfire-interviewer`)
- New process if loading is startup-only (S1: startup-only documented-fallback)
- Active candidate keeps unverified metadata
- Cannot contaminate opener attribution (activation after opener)
- Tests: fail if activated before opener; label+warning appear; isolation fail-closed

Source demo_common / stage_candidate_skill as needed (do not edit them). Never real ~/.hermes. Do not install bats. Bash-equivalent passed=N failed=0.
