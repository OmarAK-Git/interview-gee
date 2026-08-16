# Packet 01-research: Session-one buffer and Hermes drive path

## Objective

Choose one path for (1) assessment buffering, (2) driving three scripted answers against installed Hermes, and (3) proving deferred MEMORY.md persistence — with evidence, not public-doc guesses.

## Context

Workspace: `C:\Users\oalan\interview-gee` (Windows host; Hermes on WSL Ubuntu user `fish`).

Hermes Agent **v0.20.2** is installed. Isolation is verified for profile data: `HERMES_HOME=<repo>/.crossfire/profiles/test`. Nous Portal login exists on that throwaway profile. Free-tier chat works with `stepfun/step-3.7-flash:free` (`hermes chat -Q -q pong` returned `pong`).

Locked: MEMORY.md writer is **agent-direct** (harness). Curator strategy is **isolated**. Persistence branch is still **probe-pending** (first attempt: memory-md-block). YAML CROSSFIRE round-trip is **not proven**.

Spec wins if the plan disagrees. Spec artifact root is `.crossfire/runs/<run_id>/` (plan's `.crossfire/run/` is superseded).

Authoritative:
- Spec: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` §8, §10 live demo gate, §11 three questions, §12 session lifecycle
- Plan Task 5: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-plan.md` lines 65–75
- Compatibility: `docs/hermes-compatibility.md`
- Shared isolation: `scripts/demo_common.sh`
- Persist API: `scripts/weakness_memory.sh` → `crossfire_persist_weakness`
- Skill: `skills/crossfire-interviewer/SKILL.md` (propose-only assessments)

## Files or Sources

Read-only except the result file:
- Hermes CLI: `hermes --help`, `hermes chat --help`, `hermes session --help` / `hermes sessions --help` if present
- Isolated profile only: `/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test` (config.yaml, sessions/, memories/)
- Install tree (read-only): `/home/fish/.hermes/hermes-agent` — do not write
- Existing probe scripts under `.workflow/S2-T5/`
- Spec, plan, SKILL.md, demo_common.sh, weakness_memory.sh persist function signature

Allowed throwaway probes (isolated `HERMES_HOME` only, never real `~/.hermes`):
- `hermes doctor`
- `hermes chat --help` / related subcommands
- At most one short `hermes chat -Q --max-turns 1 --safe-mode` ping if help is insufficient to decide native session resume
- Optional: disable/`--toolsets` probe for the `memory` tool so MEMORY.md cannot be rewritten mid-session

Do **not** run a full three-question interview in research. Do **not** write the CROSSFIRE block (implementer does that). Do **not** mkdir/write `/home/fish/.hermes` or Windows `%USERPROFILE%\.hermes`.

## Ownership

researcher (read-only product files; result file only)

## Do

Resolve these forks with evidence and pick **one** combination:

### Fork A — Assessment buffer (plan: Hermes-native if verified, else file buffer)

1. **Hermes-native session state** — resume/session-id APIs exist and can hold three assessments until finalize.
2. **Harness spool** — session-ID-scoped files under `.crossfire/runs/<run_id>/spool/` (spec §8). Commit only on explicit session-complete / `/done` path.

### Fork B — How session one is driven

1. **Live Hermes chat** for all three questions, answers piped from `tests/fixtures/demo-answers.txt`.
2. **Harness-orchestrated Q&A** that prints the three spec §11 questions and feeds answers; Hermes used only as assessor (`-Q`) per answer.
3. **Hybrid** — harness asks/records; Hermes assesses; harness finalizes.

CRITIC FIX: answers MUST come from the scripted input file, not operator typing.

### Fork C — Test strategy

1. Full live E2E in `tests/demo_session_1.bats` (flaky free-tier).
2. Deterministic harness tests (buffer, no MEMORY.md until finalize, persist on `/done`) plus a live isolated run that may skip unless Hermes+model are present; force-live fails closed.
3. Live-only with skip-as-pass (reject unless you can prove it still meets "session one runs against installed Hermes").

Also record:
- Exact `hermes chat` flags for non-interactive / max-turns / resume / `/done`
- Whether `/done` is a Hermes slash command or a harness finalize alias
- How to keep MEMORY.md unchanged until finalize (disable `memory` tool? skill instruction? both?)
- Session/process ID capture method for later S2-T7 (record, do not implement session two)
- Whether YAML round-trip must be probed now or can wait because harness is the sole writer during session one
- Implementer must-encode test list (TDD)

## Do Not

- Implement `demo_session_1.sh` / bats / fixtures (implementer)
- Stage candidate skills (Task 6)
- Implement session-two opener (Task 7)
- Install packages, clone, or write outside the workspace except isolated-profile Hermes probes above
- Mark the queue item done
- Point any command at real `~/.hermes`

## Expected Output

Write `.workflow/S2-T5/results/researcher-result.md` plus a structured JSON summary in your final message:

```json
{
  "packet_id": "01-research",
  "status": "done | blocked | failed",
  "chosen_paths": {
    "buffer": "hermes-native | harness-spool | hybrid",
    "driver": "live-chat | harness-orchestrated | hybrid",
    "tests": "live-e2e | deterministic-plus-live | other",
    "finalize": "hermes-/done | harness-finalize-equivalent | both",
    "memory_guard": "disable-memory-tool | skill-only | other"
  },
  "why": "string",
  "opportunity_cost": [{"path": "string", "rejected": true, "why": "string"}],
  "hermes_cli": {
    "chat_flags": ["string"],
    "resume": "verified | unsupported | documented-fallback",
    "done_command": "string",
    "session_id_how": "string"
  },
  "tests_must_encode": ["string"],
  "implementer_notes": ["string"],
  "open_questions": ["string"]
}
```

## Verification

Every chosen path cites `file:line` or a command actually run. Public-doc-only claims are labeled unverified. Isolation: no writes under real `~/.hermes`.
