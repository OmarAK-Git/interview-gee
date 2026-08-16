# DOCUMENT 2 — IMPLEMENTATION PLAN

## Planning assumptions

Paths under `~/.hermes` are provisional until Task 1 verifies the installed version. Repo files live under `/home/fish/crossfire`. Complexity: **S** < 30 min, **M** 30–60 min, **L** 60–90 min.

**Time reality (CRITIC FIX):** The full 12 tasks total roughly 4.5–6 hours — more than the 4-hour window. Sprints 1–2 (Tasks 1, 1b, 2, 3, 5, 6, 7) are the demo. Tasks 4, 8–12 are quality/hardening and are cut in order if time runs short. Do not start the risk beat until the memory-only opener works end to end.

## Task 1 — Verify the installed Hermes contract

**Complexity:** M · **Dependencies:** none

**Test first:** failing preflight that checks Hermes executable/version discoverable; effective `MEMORY.md` and skill-dir paths; a new invocation yields a distinct session/process ID; skill loading timing (startup-only vs reloadable); learning-loop trigger and artifact latency (measured, not assumed); Curator can be paused/isolated/snapshotted; `session_search` observability.

**Files:** `scripts/preflight.sh`, `docs/hermes-compatibility.md`, `tests/preflight.bats`.

**Implementation:** read-only discovery first. Record findings; replace all provisional paths/commands with shared variables in `demo_common.sh`. **Also record: who writes `MEMORY.md` (agent-direct vs Hermes-mediated) and whether a delimited YAML section survives a write round-trip.** Pick one Curator strategy.

**Done when:** every required capability is reported verified / unsupported / documented-fallback; the MEMORY.md write mechanism is characterized; no public-doc assumption remains implicit.

## Task 1b — Enforce environment isolation (BUILD-BLOCKING, CRITIC FIX)

**Complexity:** S · **Dependencies:** Task 1

**Test first:** assert that setting the isolation mechanism (e.g., `HERMES_HOME` override or the existing `scripts/start-wsl-isolated.sh`) makes Hermes read/write a disposable directory, and that a marker file written to the real `~/.hermes` is never touched by a test run.

**Files:** `scripts/start-wsl-isolated.sh` (exists — verify/adapt), `scripts/demo_common.sh`, `tests/isolation.bats`.

**Implementation:** every subsequent script and test sources the isolation env. If no override exists, tests run against a copied throwaway `~/.hermes`; automation NEVER points at the real one.

**Done when:** an automated run provably leaves real Hermes state unchanged. If this cannot be achieved, STOP automating against Hermes and hand-script the demo only (recorded decision).

## Task 2 — Weakness schema and deterministic merge

**Complexity:** M · **Dependencies:** Task 1, 1b

**Test first (strict TDD — deterministic shell logic):** insert complete record; reject missing fields; merge same topic/family; dedup identical `source_session_id+answer_ref`; increment only on new observation; preserve `first_seen`, update `last_seen`; evict oldest on 4th topic; preserve unrelated `MEMORY.md` content; leave original intact on validation failure.

**Files:** `scripts/weakness_memory.sh`, `tests/weakness_memory.bats`, `tests/fixtures/memory-empty.md`, `tests/fixtures/memory-three-weaknesses.md`.

**Implementation:** delimited machine-readable section + atomic update; conservative topic normalization, no fuzzy semantic merge in MVP; write into the delimited block form confirmed survivable in Task 1.

**Done when:** all schema/merge/dedup/cap/eviction/preservation/failure-safety tests pass.

## Task 3 — Family-specific assessment contract

**Complexity:** M · **Dependencies:** none (but validated after Task 1b for env)

**Test first (tolerance eval, not strict equality — CRITIC FIX):** strong/weak fixtures per family; assert correct family selected; weakness proposed only when ≥2 required elements missing; output names missing elements + concise evidence; technical answers not scored with STAR; one missing element does not persist. Run each case N times; require it to hold in the large majority, and flag flakiness rather than hard-failing a single off-run.

**Files:** `skills/crossfire-interviewer/SKILL.md`, `tests/fixtures/assessment-cases.md`, `tests/assessment_eval.bats`.

**Done when:** the fixture suite reliably (within tolerance) produces expected family/missing-element/persist decisions.

## Task 4 — Question bank (CUT FIRST under time pressure)

**Complexity:** S · **Dependencies:** Task 3

**Test first:** static validation — covers McCain/Mastercard/Praetor/ALTER_EGO and all three families; every question has stable ID + declared family; demo questions concise; no invented employer facts.

**Files:** `skills/crossfire-interviewer/questions.md`, `tests/question_bank.bats`.

**Done when:** static tests pass; three demo questions complete within the measured session-one budget.

## Task 5 — Three-question demo mode with deferred persistence and scripted answers

**Complexity:** L · **Dependencies:** Tasks 1, 1b, 2, 3

**Test first:** E2E against the isolated profile — exactly three questions; answers read from the scripted input file (CRITIC FIX); assessments buffered; `MEMORY.md` unchanged before the third answer completes; session completion writes qualifying observations; no confirmation; concise output.

**Files:** `skills/crossfire-interviewer/SKILL.md`, `scripts/demo_session_1.sh`, `scripts/demo_common.sh`, `tests/demo_session_1.bats`, `tests/fixtures/demo-answers.txt`.

**Implementation:** Hermes-native session state if verified, else session-ID-scoped buffer under `.crossfire/run/`; commit only on explicit session-complete path.

**Done when:** E2E shows deferred automatic persistence and session one runs against installed Hermes in the isolated profile.

## Task 6 — Create and stage the unverified candidate skill

**Complexity:** L · **Dependencies:** Tasks 1, 1b, 2, 5

**Test first:** candidate created/patched after completion; `status: unverified`; contains `weakness_id`, `source_session_id`, `answer_ref`, `observation_count`; reuses one provenance key; lands outside the loaded skill dir; snapshotted immediately on creation before any Curator window; survives to the risk beat under the chosen Curator strategy.

**Files:** `scripts/stage_candidate_skill.sh`, `.crossfire/candidate-skills/.gitkeep`, `tests/candidate_skill.bats`, `skills/crossfire-interviewer/SKILL.md`.

**Implementation:** prefer the verified learning-loop mechanism; if Hermes writes into the live dir, snapshot immediately then disable/move the live copy reversibly. Document whether the artifact is Hermes-authored, skill-authored, or harness-relocated.

**Done when:** a poor answer produces a visible provenance-linked candidate `SKILL.md` and a pre-session-two assertion proves it is not loadable. If exclusion is impossible, record the degraded path.

## Task 7 — Fresh-process, memory-only opener

**Complexity:** L · **Dependencies:** Tasks 1, 1b, 2, 5, 6

**Test first:** integration — end process one; start process two with a different session ID; fail if any candidate skill is in the live dir (unless degraded path recorded); select newest weakness deterministically; print `opening_target_source=MEMORY.md`, weakness ID, source session before the question; ask a matching opener; detect and fail on any pre-opener `session_search`.

**Files:** `scripts/demo_session_2.sh`, `scripts/demo_common.sh`, `skills/crossfire-interviewer/SKILL.md`, `tests/demo_session_2.bats`.

**Implementation:** encode deterministic selection; add process/session evidence; instrument tool-call logging if supported, else structure the opener path so no archive-search action is available until selection returns.

**Done when:** automated and manual runs both show session two targeting the persisted weakness with no naming prompt, no loaded candidate (or disclosed degraded path), no pre-opener search. **This is the demo's minimum success bar.**

## Task 8 — Artifact evidence and bounded waits

**Complexity:** S · **Dependencies:** Tasks 5–7

**Test first:** before-snapshot of `MEMORY.md`; print only the relevant diff after completion; print candidate skill + metadata; time out with nonzero status and useful message when an artifact is missing; never wait indefinitely.

**Files:** `scripts/demo_common.sh`, `tests/artifact_evidence.bats`.

**Done when:** success and timeout paths pass; a reviewer sees the durable artifacts without filesystem navigation.

## Task 9 — Labeled unverified-learning risk beat

**Complexity:** M · **Dependencies:** Tasks 6–8

**Test first:** activation cannot occur before the opener completes; `UNVERIFIED LEARNING RISK DEMO` label + warning appear before candidate influence; candidate installs to a namespaced live path; new process started if loading is startup-only; active candidate keeps unverified metadata; candidate available in a later session unless cleaned up.

**Files:** `scripts/activate_candidate_skill.sh`, `scripts/demo_risk_beat.sh`, `tests/risk_beat.bats`, `docs/demo-script.md`.

**Done when:** the beat visibly uses the generated skill, cannot contaminate opener attribution, and truthfully presents its unverified status. Cut if time-constrained; the opener demo stands alone.

## Task 10 — Assemble and time the ~90-second demo

**Complexity:** M · **Dependencies:** Tasks 7–9

**Test first:** full-sequence smoke — preflight passes; session one, restart, memory-only opener, evidence display, risk beat all complete; distinct IDs + layer labels appear; total ≤90s after pre-warm; any failure exits early with a recovery instruction.

**Files:** `scripts/demo.sh`, `tests/demo_e2e.bats`, `docs/demo-script.md`.

**Implementation:** compose existing scripts without duplicating logic; scripted bad answer unambiguously missing ≥2 elements; narrow, explicit reset/prep command that never deletes unrelated Hermes state. If measured time exceeds 90s, drop one question before touching process separation or attribution.

**Done when:** three consecutive rehearsals complete within 90s and produce the expected evidence and opener.

## Task 11 — Free-form Monday usability

**Complexity:** S · **Dependencies:** Tasks 3–8

**Test first:** non-demo run — agent continues beyond three questions; sensible no-weakness behavior; targets an existing weakness without demo-only chatter; optional `session_search` only after the opener and degrades gracefully; exit still flushes buffered qualifying observations.

**Files:** `tests/interactive_smoke.md`, `skills/crossfire-interviewer/SKILL.md`, `README.md`.

**Done when:** a manual free-form run is recorded and the tool is useful without editing prompts or files.

## Task 12 — Final safety and acceptance pass

**Complexity:** S · **Dependencies:** all prior

**Test first:** full suite in the isolated profile, then a read-only audit — real `MEMORY.md` has no malformed/duplicate section; candidate and stable skill namespaces cannot collide; no fixture leaked into live Hermes state; Curator handling matches the compatibility note; every demo-blocking acceptance criterion has recorded evidence.

**Files:** `docs/acceptance-checklist.md`, `README.md`.

**Done when:** demo-blocking tests pass, the checklist is complete, and the demo runs from a clean terminal without undocumented manual steps. Should-pass items are logged as known limitations if cut.

## Sprint groupings

**Sprint 1 — Platform proof + deterministic core (60–80 min):** Task 1, Task 1b, Task 2, Task 3. Exit: platform contract known, isolation enforced, core logic testable.

**Sprint 2 — Cross-session learning (75–95 min):** Task 5, Task 6, Task 7. Exit: memory-only opener works across separate processes with candidate exclusion (or recorded degraded path). **This is the deliverable demo.**

**Sprint 3 — Evidence + risk beat (45–60 min, cuttable):** Task 8, Task 9, Task 10. Task 4 slots here if not yet done. Exit: audience sees what was learned, which layer caused each behavior, and why ungated learning is dangerous.

**Sprint 4 — Usability + hardening (30–45 min, cuttable):** Task 11, Task 12. Exit: documented repeatable operating path.

## Critical dependency chain

`Hermes verification → environment isolation → MEMORY.md write proven → weakness persistence → deferred session-one commit → candidate isolation → fresh-process memory-only opener → risk-beat activation → timed demo`

Under time loss, preserve this chain. Cut in order: question-bank breadth (Task 4), free-form mode (Task 11), risk beat (Task 9), then artifact polish (Task 8) — never process separation, single-layer attribution, or environment isolation.