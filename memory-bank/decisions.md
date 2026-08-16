# Decisions

Locked in `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` (`sparring-1.0.0`). If this file and the spec disagree, the spec wins.

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

## Persistence layer branch (Task 1 output — open)

1. Prefer the `MEMORY.md` delimited block if it survives a Hermes write round-trip.
2. Else persist the same YAML in the session archive and set `opening_target_source=SESSION_SEARCH`.
3. If neither layer is durably writable, STOP and hand-script the demo.

## Open implementation decisions (plan)

- Who writes `MEMORY.md` (agent-direct vs Hermes-mediated) and whether a delimited YAML section survives a write round-trip.
- One Curator strategy (paused / isolated / snapshotted).
- Isolation mechanism (`HERMES_HOME` override vs `scripts/start-wsl-isolated.sh` vs copied throwaway profile).
- Session-one buffer: Hermes-native session state vs `.crossfire/run/` session-ID-scoped buffer.
- Candidate skill authorship: Hermes-authored, skill-authored, or harness-relocated.
