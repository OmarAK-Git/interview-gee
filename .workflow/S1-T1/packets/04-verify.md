# Packet 04-verify: S1-T1 skeptic verification

## Claim to refute

S1-T1 is done: every required capability is reported verified/unsupported/documented-fallback; MEMORY.md writer and YAML round-trip are characterized; one Curator strategy is recorded; no public-doc assumption remains implicit; tests/preflight.bats exists and encodes the required capability checks.

## Goal (verbatim)

Replace every provisional Hermes path and capability assumption with verified, fallback, or unsupported evidence.

## Acceptance criteria

1. Every required capability is reported verified, unsupported, or documented-fallback in docs/hermes-compatibility.md.
2. The MEMORY.md write mechanism is characterized (agent-direct vs Hermes-mediated) including whether a delimited YAML section survives a write round-trip.
3. One Curator strategy is recorded.
4. No public-doc assumption remains implicit.
5. tests/preflight.bats exists and encodes the required capability checks.

## Scope

Task-scoped. Ignore missing isolation.bats, demo sessions, weakness merge. Hermes not installed may be documented as unsupported/unverified.

## Changed files (do not trust prior agent transcripts)

- docs/hermes-compatibility.md
- scripts/demo_common.sh
- scripts/preflight.sh
- tests/preflight.bats

## Commands (run yourself from repo root)

```
Test-Path -LiteralPath docs\hermes-compatibility.md -PathType Leaf
Test-Path -LiteralPath scripts\preflight.sh -PathType Leaf
Test-Path -LiteralPath tests\preflight.bats -PathType Leaf
Select-String -Path docs\hermes-compatibility.md -Pattern 'MEMORY.md|Curator|session_search|verified|unsupported|fallback' | Measure-Object | Select-Object -ExpandProperty Count
```

Optional if available (do not install): `wsl -e bash -c "cd /mnt/c/Users/oalan/interview-gee && CROSSFIRE_HERMES_DISCOVERY=0 bash scripts/preflight.sh"; echo EXIT:$LASTEXITCODE`

## Manual checks

None in the queue item.

## Do not

- Include or trust implementer reasoning
- Modify product files
- Install packages
- Mutate ~/.hermes
- Fail the task because later sprint work is missing

## Expected output

Verdict `refuted` or `survives`. Write `.workflow/S1-T1/results/verifier-result.md` with commands run, file:line reads, and the single strongest reason.
