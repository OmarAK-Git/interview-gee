# Decisions

Locked in `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` (`sparring-1.0.0`). If this file and the spec disagree, the spec wins.

## Workflow standing orders

1. **Gate and verifier model (set 2026-08-16):** GSD autoloop gates and `skeptic-verifier` default to `cursor-grok-4.6-high-fast`. This replaces the 2026-07-30 `cursor-grok-4.5-high` standing order. Historical Sprint 1 gate evidence remains Grok 4.5.

## Locked product decisions

1. **Platform:** Hermes Agent. Do not swap frameworks.
2. **Where weak areas live:** at most three structured records in `MEMORY.md`.
3. **Coaching on the critical path:** one stable interviewer skill generates questions.
4. **Auto-generated skill:** created from the bad answer, used in a later turn/session, never used to *select* the session-two opener.
5. **Persist rule:** automatic. No yes/no confirmation.
6. **Freshness proof:** kill process one, start process two, show distinct session IDs, print the exact memory record used.
7. **Opener source:** `MEMORY.md` is the sole source of the opening *target*. `session_search` is allowed only after the first question.
8. **Harness owns durable writes:** delimited weakness block in `MEMORY.md` and `.crossfire/candidate-skills/`. Hermes must not edit those two targets.
9. **Isolation hard stop:** if tests cannot be isolated from real `~/.hermes`, stop automating against Hermes and hand-script the demo.
10. **No PolicyGate / quarantine / replay promotion in MVP.** Show the missing gate honestly.
11. **Three demo questions are never cut.** Extra question-bank breadth is the first cut.

## Persistence layer branch (Task 1 output — recorded)

1. Writer: **agent-direct** (harness writes the delimited block). Hermes-mediated `memory` tool is rejected as a second writer.
2. Live persistence branch: **probe-pending**. First post-install attempt: `MEMORY.md` delimited block. YAML HTML-comment markers are **not proven to survive**. If the probe fails: session archive + `opening_target_source=SESSION_SEARCH`. If neither layer is writable: STOP / hand-script.
3. Curator: **isolated** via disposable `HERMES_HOME` (pause/snapshot CLIs not run).
4. Hermes executable: **verified** on WSL Ubuntu user `fish` — Hermes Agent v0.20.2 at `/home/fish/.local/bin/hermes`. Windows PATH has no `hermes`.
5. Isolation: **verified** for profile data. `HERMES_HOME=<repo>/.crossfire/profiles/test` receives `memories/`, `sessions/`, `state.db`, `SOUL.md`. Real `/home/fish/.hermes` is the install tree (`bin`, `hermes-agent`, `node`) only. `__pycache__` under `hermes-agent/` updates when the binary runs.
6. Session-one buffer: **harness-spool** under `.crossfire/runs/<run_id>/spool/` (S2-T5).
7. Candidate skill authorship: **harness-relocated** into `.crossfire/candidate-skills/`; **never-write-live** (S2-T6). Snapshot-then-move is fallback only.

## Practice inference (2026-08-22)

- Hermes remains the harness. Practice may pass `--provider nous` or `--provider openai-codex` on `hermes chat`.
- Toggle applies on New session only. Session state stores `CROSSFIRE_INFERENCE`.
- Not a Cursor API / SDK path. Not an xAI path.

## Open implementation decisions (plan)

- (closed) Isolation: `HERMES_HOME` disposable profile.
- (closed) Session-one buffer: harness-spool.
- (closed) Candidate skill authorship: harness-relocated.
