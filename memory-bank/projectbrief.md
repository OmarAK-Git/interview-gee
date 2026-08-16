# Project Brief

## Product

**Hermes Interview Sparring Partner** (Crossfire / `interview-gee`) is a CLI interview partner on **Hermes Agent** that gets better at interviewing the operator across sessions.

Session one asks three questions drawn from the live job search. A weak answer is detected with a fixed family checklist and written automatically into durable memory. Session two starts as a **new Hermes process** with a **new session ID**, reads that memory, and opens on the weak area **without the operator naming it**.

The demo must make the learning loop visible on disk. A reviewer must be able to point at the moment the agent learned, say which layer caused the opener, and see that an auto-generated skill from the bad answer is unverified.

## Audience and success

- Spoken demo is about 90 seconds after pre-warm (Shopify Builders Sunday).
- Build window is about four hours.
- Demo-blocking bar: two-process memory-only opener, weakness visible on disk, candidate skill staged but not selecting the opener, tests never mutate real `~/.hermes`.

## Stack and delivery

- Platform is Hermes Agent. Do not swap frameworks.
- No web UI. No multi-user. No scoring-model training. No promotion gate in MVP.
- Planned layout: harness scripts under `scripts/`, stable skill under `skills/crossfire-interviewer/`, isolated profiles under `.crossfire/`, tests under `tests/` (`bats`).

## Source material (do not invent beyond this)

- McCain Foods. Cyber Defense Engineer. Late-stage rounds.
- Mastercard. Agent Suite PM role, R-281517.
- Project Praetor. LangGraph SOAR disposition engine.
- Project ALTER_EGO. UEBA behavioral drift detection.

## Scope and ship target

Sprints 1–2 (Tasks 1, 1b, 2, 3, 5, 6, 7) are the deliverable demo. The never-cut chain is: isolation, distinct processes, three demo questions, automatic persist of the scripted bad answer, memory-only opener.

Tasks 4, 8–12 are quality/hardening and are cut in order if time runs short. Do not start the risk beat until the memory-only opener works end to end.

## Open risks

- Installed Hermes contract is unverified (paths, session IDs, skill load timing, Curator, `MEMORY.md` round-trip).
- Environment isolation from real `~/.hermes` is build-blocking.
- Four-hour window vs ~4.5–6 hours of planned work; cut order is already locked in the spec.
