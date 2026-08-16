# Packet 02-implementation: Hermes contract artifacts

## Objective

Ship `docs/hermes-compatibility.md`, `scripts/demo_common.sh`, `scripts/preflight.sh`, and `tests/preflight.bats` from the researcher findings. Do not install Hermes.

## Context

Research: `.workflow/S1-T1/results/researcher-result.md` ([researcher](75187334-58e7-4da9-b11b-b87bb8f35ade)).
Spec: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` §15 capability table.
Plan Task 1: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-plan.md` lines 9–19.

Chosen paths (locked for this task):
- memory_writer: agent-direct
- persistence_branch: memory-md-block (pending throwaway probe after install)
- curator_strategy: isolated
- isolation_mechanism: HERMES_HOME

Hermes is not installed. Real `~/.hermes` is absent on Windows and WSL. That is a valid Task 1 outcome: record unsupported/unverified, and make preflight fail closed.

## Files or Sources

Write only:
- `scripts/preflight.sh`
- `scripts/demo_common.sh`
- `docs/hermes-compatibility.md`
- `tests/preflight.bats`

Do not write `memory-bank/` (controller projects after verifier pass).

## Ownership

implementer (`composer-2.5`)

## Do

1. TDD: write `tests/preflight.bats` first encoding: executable/version discoverable; effective MEMORY.md and skill-dir paths; distinct session/process ID check; skill loading timing; learning-loop latency placeholder; Curator isolatable; session_search observability. When Hermes is missing, tests must assert that `preflight.sh` fails closed (nonzero) rather than skip silently.
2. `scripts/demo_common.sh`: shared variables from researcher table (`HERMES_BIN`, `HERMES_VERSION`, `HERMES_HOME`, `HERMES_MEMORY_MD`, `HERMES_SKILLS_DIR`, `HERMES_STATE_DB`, `HERMES_CONFIG`, `WSL_DISTRO`, `WSL_USER`, `REAL_HERMES_WIN`, `REAL_HERMES_WSL`). Default `HERMES_HOME` to repo `.crossfire/profiles/test`. Never default tests to real `~/.hermes`.
3. `scripts/preflight.sh`: source demo_common; fail if Hermes binary missing; print discovered paths; do not start a Hermes session; do not write `~/.hermes`.
4. `docs/hermes-compatibility.md`: every spec §15 capability as verified / unsupported / documented-fallback / unverified with evidence. Characterize MEMORY.md writer and YAML round-trip. Record one Curator strategy. Label every public-doc claim. No implicit assumptions.

## Do Not

- Install Hermes, bats, or any package (approval-first)
- Mutate real `~/.hermes` or start Hermes chats
- Implement isolation.bats / weakness merge / demo sessions
- Widen beyond files_allowed
- Mark the queue item done

## Expected Output

Changed files + rationale, commands run with actual results, unresolved items. Write `.workflow/S1-T1/results/implementer-result.md`.

## Verification (run these; do not invent pass)

```powershell
Test-Path -LiteralPath docs\hermes-compatibility.md -PathType Leaf
Test-Path -LiteralPath scripts\preflight.sh -PathType Leaf
Test-Path -LiteralPath tests\preflight.bats -PathType Leaf
Select-String -Path docs\hermes-compatibility.md -Pattern 'MEMORY.md|Curator|session_search|verified|unsupported|fallback' | Measure-Object | Select-Object -ExpandProperty Count
```

If `bash` or `bats` exists, run `preflight.sh` and `bats tests/preflight.bats` and record output. Do not install them if missing.
