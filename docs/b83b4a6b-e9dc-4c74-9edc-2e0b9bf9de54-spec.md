# Hermes Interview Sparring Partner

**Spec version:** `sparring-1.0.0`  
**Date:** 2026-08-16  
**Source session:** `b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54`

This specification is the authority of record. If the companion implementation plan disagrees with this document, this document wins. The plan must cite `sparring-1.0.0`.

## 1. What we are building

A CLI interview partner on **Hermes Agent** that gets better at interviewing the operator across sessions.

Session one asks three questions drawn from the live job search. A weak answer is detected with a fixed family checklist and written automatically into durable memory. Session two starts as a **new Hermes process** with a **new session ID**, reads that memory, and opens on the weak area **without the operator naming it**.

The demo must make the learning loop visible on disk. A reviewer must be able to point at the moment the agent learned, say which layer caused the opener, and see that an auto-generated skill from the bad answer is unverified.

## 2. Fixed constraints

- Platform is Hermes Agent. Do not swap frameworks.
- Build window is about four hours. MVP demo is Shopify Builders Sunday.
- Spoken demo is about 90 seconds after pre-warm.
- No web UI. No multi-user. No scoring-model training. No promotion gate in MVP.
- The four-hour build learns Hermes memory and skill layers by using them.

## 3. Non-goals

- Do not build PolicyGate / quarantine / replay promotion. Show the missing gate honestly.
- Do not invent employer facts beyond the source material below.
- Do not let session-two success depend on both sessions sharing a context window.

## 4. Source material

Use only these as interview content:

- McCain Foods. Cyber Defense Engineer. Late-stage rounds.
- Mastercard. Agent Suite PM role, R-281517.
- Project Praetor. LangGraph SOAR disposition engine. Advisory-only output, hash-chained audit ledger, never-contain list.
- Project ALTER_EGO. UEBA behavioral drift detection. Cumulative KL-divergence, shadow profiles, freeze-under-suspicion.

## 5. Decisions already made

| Topic | Decision |
| --- | --- |
| Where weak areas live | At most three structured records in `MEMORY.md` |
| How coaching is done on the critical path | One stable interviewer skill generates questions |
| Auto-generated skill | Created from the bad answer, **used in a later turn/session**, never used to *select* the session-two opener |
| Persist rule | Automatic. No yes/no confirmation |
| Freshness proof | Kill process one, start process two, show distinct session IDs, print the exact memory record used |
| Opener source | `MEMORY.md` is the sole source of the opening *target*. `session_search` is allowed only after the first question |

The auto-generated skill is part of the learning-loop proof. Catching that it was built from a bad answer is the honesty beat. Gating it behind a promotion check is out of scope.

## 6. Profiles

| Profile | Path | Used by | Persistence |
| --- | --- | --- | --- |
| Test | `.crossfire/profiles/test` via `HERMES_HOME` (or the verified equivalent) | Automated tests | Disposable. Restored by `demo_prepare` |
| Stage | `.crossfire/profiles/stage` | Live 90s demo | Persists across the two demo sessions of one `run_id` |
| Monday | Real `~/.hermes` | Free-form use after the event | Not written by automated tests. Demo weaknesses do **not** auto-copy here |

Hard stop: if tests cannot be isolated from real `~/.hermes`, stop automating against Hermes and hand-script the demo. Record that decision.

Each rehearsal gets a unique `run_id`. Session IDs, buffers, snapshots, locks, and candidate paths are scoped under `.crossfire/runs/<run_id>/`. Artifacts from other `run_id`s are not selectable.

`demo_prepare` restores only the disposable test or stage profile after validating the resolved path. It never deletes unrelated Hermes state.

**Rehearsal shape:** start clean, run session one, carry *only* that session-one state into session two, then stop. Do not accumulate weaknesses across rehearsals.

## 7. Spoken 90-second demo

Pre-warm Hermes and the stage profile before the clock starts. Do **not** drop a question to save time. If the sequence still exceeds 90 seconds, cut the optional risk-beat polish and extra evidence narration, not process separation, isolation, or the three questions.

1. Start session one. The agent asks **three** concise questions.
2. Answer question 2 from the scripted bad-answer fixture (missing at least two required elements of its family).
3. After the third answer the harness invokes `/done` (same finalize path as typing `/done`). Wait for acknowledgement.
4. Kill process one. Show the `MEMORY.md` weakness-block diff and the staged candidate `SKILL.md`.
5. Assert the candidate is **not** in the live skill dir. Only then start session two as a new process with a new session ID.
6. Session two opens on the persisted weak area. Print `opening_target_source=MEMORY.md`, `weakness_id`, `family`, and `source_session_id` before the question is spoken.
7. Optional if time remains: load the unverified candidate skill and show it shaping a follow-up (the honesty beat).

## 8. Architecture

```text
Harness (owner of durable writes)
  ├── weakness block in MEMORY.md
  ├── candidate staging dir
  └── opener directive for session two

Hermes
  ├── stable skill: skills/crossfire-interviewer/SKILL.md  (always loaded)
  ├── proposes assessments on stdout / run-scoped spool
  └── must not edit the weakness block or candidate staging dir

MEMORY.md          always-in-context facts (weaknesses live here)
USER.md / SOUL.md  unchanged except a firm opener instruction in SOUL.md
Candidate SKILL.md staged outside the live skill dir until after the opener
session_search     disabled until after question 1 of session two
Curator            paused or isolated for the whole demo run
```

**One writer per artifact.** The harness exclusively owns:

- the delimited weakness block in `MEMORY.md`
- `.crossfire/candidate-skills/`

Hermes may emit structured records to stdout or `.crossfire/runs/<run_id>/spool/`. It may not edit those two targets.

**Write protocol for the weakness block:** advisory lock, re-read after lock, validate, merge, `fsync`, atomic rename, retry if the file changed under the lock.

## 9. Weakness schema

The harness maintains exactly one delimited block in `MEMORY.md`. Unrelated file content is preserved.

```markdown
<!-- CROSSFIRE-WEAKNESSES:START -->
```yaml
version: 1
weaknesses:
  - weakness_id: w-a1b2c3d4e5f6
    family: behavioral
    topic: "alter-ego validation evidence"
    topic_key: alter-ego-validation-evidence
    missing_elements: [evidence, outcome]
    first_seen: 2026-08-16T18:01:02Z
    last_seen: 2026-08-16T18:01:02Z
    observation_count: 1
    source_session_id: sess_01
    answer_ref: run_7f3a/q_behavioral_01/0
    evidence:
      kind: quote
      value: "I just kind of watched the dashboard."
```
<!-- CROSSFIRE-WEAKNESSES:END -->
```

### Field contract

| Field | Rule |
| --- | --- |
| `weakness_id` | `w-` + first 12 hex chars of SHA-256 of `family + "\n" + topic_key` in UTF-8 |
| `family` | Exactly one of `behavioral`, `technical`, `product` |
| `topic` | Human-readable, derived from the question's topic slug |
| `topic_key` | `topic` lowercased; non-alphanumerics to hyphens; collapse repeats; strip edges |
| `missing_elements` | Non-empty subset of that family's required elements |
| `first_seen` / `last_seen` | UTC RFC3339 with `Z` |
| `observation_count` | Integer ≥ 1 |
| `source_session_id` | Hermes session ID of the latest observation |
| `answer_ref` | `<run_id>/<question_id>/<answer_index>` with `answer_index` 0-based in that session |
| `evidence.kind` | `quote` or `byte_offset` |
| `evidence.value` | For `quote`, a substring of the submitted answer. For `byte_offset`, `"start:end"` over the UTF-8 answer bytes |

Reject the write (leave the original block intact) if any required field is missing, `family` is unknown, timestamps are not UTC RFC3339, `answer_ref` does not match `^[^/]+/[^/]+/[0-9]+$`, or `evidence` does not quote or offset the submitted answer.

### Merge, dedup, cap, order

- Same `weakness_id` (same family + `topic_key`): merge. Keep `first_seen`. Update `last_seen`, `source_session_id`, `answer_ref`, `evidence`. Union `missing_elements`.
- Identical `source_session_id` + `answer_ref`: no-op (dedup).
- New observation otherwise: increment `observation_count`.
- Cap: **3** active records. Evict using the **inverse** of selection order.
- **Selection order** (newest weakness): `last_seen` desc, then `observation_count` desc, then `weakness_id` asc.
- **Eviction order:** `last_seen` asc, then `observation_count` asc, then `weakness_id` desc.

### Persistence layer branch (Task 1 output)

1. Prefer the `MEMORY.md` delimited block if it survives a Hermes write round-trip.
2. If it does not survive, persist the same YAML in the session archive and set `opening_target_source=SESSION_SEARCH`.
3. If neither layer is durably writable, **STOP** and hand-script the demo. Record the decision.

Do not assume the block survives. Task 1 records which branch is live.

## 10. Assessment contract

Every question declares **exactly one** family. Mixed-family scoring is forbidden. A technical answer is never scored with STAR.

Persist a weakness **automatically** when **≥ 2** required elements of that family are missing. One missing element does not persist. Do not ask the operator to confirm.

| Family | Required elements | Typical source |
| --- | --- | --- |
| `behavioral` | `situation`, `task`, `action`, `result` | McCain / career stories |
| `technical` | `problem`, `approach`, `tradeoff`, `verification` | Praetor / ALTER_EGO |
| `product` | `user`, `constraint`, `decision`, `metric` | Mastercard Agent Suite PM |

The assessment output names the family, the missing elements, and evidence that quotes or byte-offsets the submitted answer.

**Fixture eval (not the live demo):** run each case **N = 5** times. Pass if **≥ 4** runs match the expected persist decision. Flag flakiness; do not hard-fail a single off-run.

**Live demo gate:** session one is not complete until at least one qualifying weakness for the scripted bad answer is persisted and asserted present in the weakness block. Re-run assessment up to **K = 3** times, then abort with a clear message. The scripted bad answer is a fixture that rehearsal has already shown is flagged deterministically.

## 11. Demo questions (not cuttable)

These three live in session-one fixtures, not in the cuttable question bank.

| ID | Family | Question | Scripted answer |
| --- | --- | --- | --- |
| `q_technical_01` | `technical` | Walk through how Praetor decides not to contain. What is the advisory boundary, and how would you know the decision was wrong? | Strong: names never-contain list, hash-chained ledger, verification. |
| `q_behavioral_01` | `behavioral` | Tell me about a time a detection you owned was wrong. What did you do, and what changed afterward? | **Bad:** omits `action` and `result` (for example “I just kind of watched the dashboard.”). |
| `q_product_01` | `product` | For Mastercard Agent Suite (R-281517), how would you sequence rollout when a false positive could freeze a merchant? | Strong: names user, constraint, decision, metric. |

Broader McCain / Mastercard / Praetor / ALTER_EGO coverage may live in `questions.md` and is the first thing cut under time pressure. These three demo questions are never cut.

## 12. Session lifecycle

`/done` is the only normal completion command.

After the third answer, the harness invokes the same finalize operation as `/done` and waits for acknowledgement before exit.

| Signal | Persistence |
| --- | --- |
| `/done` or harness finalize after answer 3 | Required. Wait for ack |
| EOF or SIGINT | One bounded finalize attempt, then exit |
| SIGTERM / SIGKILL | No persistence guarantee |

Do not say “quit” in the spoken script. Say `/done` or let the harness finalize.

Session-one assessments are buffered. `MEMORY.md` must be unchanged until finalize. Finalize writes qualifying observations, then stages the candidate skill.

**Latency budget:** a harness-owned artifact must appear within **8 seconds** of finalize. Task 1 measures this. If the Hermes learning loop is slower than 8 seconds, pre-persist session-one artifacts before the timed run and narrate them as already durable. Do not wait live inside the 90-second clock.

## 13. Session-two opener

Opener **target selection is a harness operation**, not an LLM judgment.

1. Parse only the weakness block (or the archive fallback from §9).
2. Select the newest record by the total order in §9.
3. Emit a typed directive: `weakness_id`, `family`, `missing_elements`, `opening_target_source`.
4. Start Hermes with `session_search` disabled until after question 1, using a verified tool allowlist from Task 1.
5. The stable interviewer skill turns the directive into wording.

**Attribution line (print both roles):**

`target selected by prompt memory; wording generated under stable interviewer procedure`

If Task 1 cannot provide (a) `session_search` tool-call logging **or** (b) the ability to disable `session_search` for the opener turn, drop the search-detection assertion. Prove “not context carryover” with: `MEMORY.md` (or archive) diff on disk, candidate skill absent from the live dir, and a distinct process/session ID.

**Candidate barrier:** session two must not launch until the harness asserts the candidate skill is outside the live skill dir. Use a lock/flag file the launcher checks. If the move cannot be guaranteed, take the recorded degraded path and disclose attribution.

## 14. Candidate skill

Created or patched on finalize. Lives in `.crossfire/candidate-skills/` until after the opener.

It must not treat the submitted bad answer as a model answer.

```markdown
---
id: crossfire.candidate.behavioral
name: unverified-behavioral-followup
status: unverified
weakness_id: w-a1b2c3d4e5f6
source_session_id: sess_01
answer_ref: run_7f3a/q_behavioral_01/0
observation_count: 1
target_family: behavioral
missing_elements: [action, result]
---

# Unverified follow-up

Do not praise or imitate the recorded answer. Ask for the missing elements.

## Corrective checklist
- action
- result

## Follow-up template
Ask the candidate to describe the specific action they took and the result that followed.
```

Patch by `target_family` (one candidate per family). Activation test: after the opener, loading this skill makes the next question request the recorded missing elements.

The opener must still succeed if this skill is absent. Using it afterward is the self-learning proof, including the failure mode that it was trained on a bad answer.

## 15. Capability table

| Capability | Required for MVP | If unsupported |
| --- | --- | --- |
| Disposable `HERMES_HOME` (or equivalent) isolation | Hard stop | Stop automating; hand-script; record decision |
| Distinct process + session ID for session two | Hard stop | Stop the demo build |
| Durable weakness store (MEMORY.md block **or** session archive) | Hard stop | Hand-script |
| `MEMORY.md` delimited block survives round-trip | Preferred | Archive + `opening_target_source=SESSION_SEARCH` |
| Pause / isolate Curator | Required for demo run | Isolate the profile so Curator cannot see it |
| Disable `session_search` for opener **or** log its tool calls | Preferred | Disk artifact + distinct process; drop search-detection |
| Learning-loop write ≤ 8s | Preferred | Pre-persist before timed run; narrate as already durable |
| Exclude candidate from live dir before session two | Required for clean attribution | Degraded path with explicit disclosure |
| Skill reload without new process | Optional | Start a new process to load the candidate after opener |

## 16. Wall-clock gates

Clock starts when implementation begins, not when the spoken demo starts.

| Gate | By | Must have |
| --- | --- | --- |
| Compatibility | T+30 min | Capability table filled; live persistence branch chosen |
| Isolated merge | T+75 min | Weakness block (or archive fallback) writes in the isolated profile |
| Vertical slice | T+150 min | Two-process memory-only opener works once |
| Freeze | T+210 min | Features frozen; remaining time is rehearsal |

If a gate expires, ship the last passing slice plus a recorded fallback. Do not spend the remaining window re-litigating Hermes internals.

## 17. Acceptance

Demo-blocking:

1. Session two targets the weak area with no operator prompt that names it.
2. The weakness is visible on disk (`MEMORY.md` diff or archive equivalent) and the candidate `SKILL.md` is visible in staging.
3. A reviewer can state: target came from prompt memory (or the recorded archive fallback); wording came from the stable interviewer skill; the candidate skill did not select the opener.
4. Session one and two are different processes and session IDs.
5. Tests never mutate real `~/.hermes`.
6. Three questions are asked. None are dropped for time.
7. `/done` / harness finalize produced the artifacts. A raw quit/SIGKILL path is documented as not guaranteed.

Should-pass / honest limitations:

- Auto-generated skill may encode the bad answer. Show that. Do not hide it behind a promotion gate.
- Monday-morning usefulness is the same harness + stable skill pointed at the real profile, with no automatic import of stage-demo weaknesses.
- Question-bank breadth beyond the three demo questions may be absent.

## 18. Cut order (plan must match)

Never cut: isolation, distinct processes, three demo questions, automatic persist of the scripted bad answer, memory-only opener.

Cut first: extra question-bank breadth. Then free-form Monday polish. Then candidate-skill honesty-beat narration. Then extra artifact pretty-printing.

The opener demo stands alone if the honesty beat is cut. The generated skill is still created and shown on disk even if it is not loaded live.
