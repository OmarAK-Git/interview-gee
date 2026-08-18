# Packet 02-implementation: Artifact evidence

Researcher skipped: spec already names before-snapshot, relevant diff, candidate print, bounded timeout. No path fork.

## Files allowed

- `scripts/demo_common.sh`
- `tests/artifact_evidence.bats`

Plus `.workflow/S3-T8/results/implementer-result.md` and optional bash-assertions.sh. Do not commit. Do not implement risk beat or demo.sh.

## Do (TDD)

Helpers in demo_common.sh:
- Snapshot MEMORY.md before session complete
- After persist, print only the relevant weakness-block diff (not full filesystem navigation)
- Print staged candidate SKILL.md + metadata (path under `.crossfire/candidate-skills/`)
- If an artifact is missing, time out with **nonzero** status and a useful message; never wait indefinitely (bounded wait, e.g. CROSSFIRE_ARTIFACT_TIMEOUT_SEC default small)

Tests: success path (artifacts present → prints diff + candidate); timeout path (missing artifact → nonzero + message). Isolation fail-closed. Source demo_common. Never real ~/.hermes.

Do not install bats. Bash-equivalent passed=N failed=0.

Write implementer-result.md.
