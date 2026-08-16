# Packet 01-research: Installed Hermes contract

## Objective

Replace every provisional Hermes path and capability assumption with verified, fallback, or unsupported evidence. Choose one path where alternatives exist.

## Context

Workspace: `C:\Users\oalan\interview-gee` (Windows; Hermes may be on PATH, under WSL, or missing).

Authoritative spec: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` (`sparring-1.0.0`), especially §6 profiles, §8 architecture, §9 persistence-layer branch, §15 capability table.

Plan task: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-plan.md` Task 1.

Open decisions (memory-bank/decisions.md): MEMORY.md writer, delimited YAML round-trip, Curator strategy, isolation mechanism.

## Files or Sources

- Installed Hermes binary, `--help`, version, config, and local source if present
- Real `~/.hermes` **read-only** (Windows `%USERPROFILE%\.hermes` and WSL `~/.hermes` if WSL exists)
- Spec §15 capability table
- Do not treat public marketing docs as verified unless checked against the install

## Ownership

researcher (read-only)

## Do

Verify or classify each capability as `verified` / `unsupported` / `documented-fallback` with evidence:

1. Hermes executable + version discoverable
2. Effective MEMORY.md path
3. Effective skill-dir path
4. New invocation yields a distinct session/process ID
5. Skill loading timing (startup-only vs reloadable)
6. Learning-loop trigger and artifact latency (measured if safe, else explicitly unverified)
7. Curator can be paused / isolated / snapshotted — pick **one** strategy
8. `session_search` observability (tool-call logging and/or disable for opener)
9. Isolation env (`HERMES_HOME` or equivalent) — record for Task 1b; do not implement isolation tests
10. Who writes MEMORY.md (agent-direct vs Hermes-mediated)
11. Whether a delimited YAML section (CROSSFIRE-WEAKNESSES markers from spec §9) would survive a Hermes write round-trip
12. Persistence-layer branch recommendation: MEMORY.md block vs session archive vs STOP

Propose shared variables for `scripts/demo_common.sh` (names + values or discovery commands).

## Do Not

- Modify product files or real `~/.hermes`
- Run commands that create/update Hermes sessions against the real profile
- Install packages, clone repos, or write outside the workspace
- Implement preflight.sh / tests (implementer does that)
- Implement isolation enforcement (Task 1b)

## Expected Output

Write `.workflow/S1-T1/results/researcher-result.md` plus a structured JSON summary in your final message:

```json
{
  "packet_id": "01-research",
  "status": "done | blocked | failed",
  "chosen_paths": {
    "memory_writer": "agent-direct | hermes-mediated | unknown",
    "persistence_branch": "memory-md-block | session-archive | stop-hand-script",
    "curator_strategy": "paused | isolated | snapshotted",
    "isolation_mechanism": "HERMES_HOME | other | none"
  },
  "capabilities": [{"name": "string", "status": "verified | unsupported | documented-fallback | unverified", "evidence": "path-or-command", "notes": "string"}],
  "demo_common_vars": [{"name": "string", "value_or_discovery": "string"}],
  "open_questions": ["string"]
}
```

## Verification

Every status has file:line or command evidence. Public-doc-only claims are labeled unverified.
