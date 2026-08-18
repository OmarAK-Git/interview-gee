# Acceptance checklist — Hermes Interview Sparring Partner (Crossfire)

Spec authority: `sparring-1.0.0` §17 (`docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md`). Plan Task 12: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-plan.md`.

This checklist maps **demo-blocking** acceptance criteria to verifier evidence. It does **not** claim passing live e2e against real `~/.hermes`. Automated proof uses disposable profiles under `.crossfire/profiles/` and task-scoped bash-equivalents where `bats` is not installed.

## How to run the demo (clean terminal)

From WSL (Hermes reference machine):

```bash
export REPO_ROOT="/mnt/c/Users/oalan/interview-gee"   # adjust to your checkout
export HERMES_HOME="${REPO_ROOT}/.crossfire/profiles/stage"
bash scripts/demo.sh --prepare
bash scripts/demo.sh
```

No undocumented manual steps are required between `--prepare` and the timed run. Spoken beat sheet: `docs/demo-script.md`. Full operator guide: `README.md`.

**Live spoken demo** (optional; after pre-warm):

```bash
export CROSSFIRE_LIVE=1
export CROSSFIRE_ASSESSOR=live CROSSFIRE_OPENER=live CROSSFIRE_RISK_BEAT=live
bash scripts/demo.sh
```

Time cut: `export CROSSFIRE_SKIP_RISK_BEAT=1` — never cut isolation, process separation, three questions, automatic persist, or the memory-only opener.

---

## Demo-blocking criteria

| # | Criterion (spec §17) | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Session two targets the weak area with **no operator prompt that names it** | **held** | `.workflow/S2-T7/results/verifier-result.md` (numbered opener; no naming prompt; clean s1→s2 targets persisted behavioral weakness). `.workflow/S2-GE/results/verifier-result.md` gate AC1. `tests/demo_session_2.bats` (read; not executed — `bats` absent). |
| 2 | Weakness **visible on disk** (`MEMORY.md` diff or archive) and candidate **`SKILL.md` visible in staging** | **held** | Session-one persist: `.workflow/S2-T5/results/verifier-result.md` (`1 weakness(es) persisted`, spool→finalize). Staging: `.workflow/S2-T6/results/verifier-result.md` (candidate under `.crossfire/candidate-skills/`, never-write-live). Evidence display: `.workflow/S3-T8/results/verifier-result.md` (stdout weakness-block diff + full staged SKILL.md). |
| 3 | Reviewer can state: **target** from prompt memory; **wording** from stable interviewer; **candidate did not select the opener** | **held** | Opener prints `opening_target_source=MEMORY.md` before `Question:` — S2-T7, S2-GE. Layer labels in `docs/demo-script.md` § Layer attribution; `scripts/demo.sh` emits `layer_attribution:` lines — `.workflow/S3-GE/results/verifier-result.md` AC2. Candidate excluded at opener: S2-T6, S2-T7 (`crossfire_assert_candidates_excluded_from_live`). |
| 4 | Session one and two are **different processes and session IDs** | **held** | `.workflow/S2-GE/results/verifier-result.md` (PIDs 3265/3266; sessions `sess_stub` / `sess_stub_s2`; parent continues after child). `.workflow/S2-T7/results/verifier-result.md` (distinct PIDs 1307/1308; equal IDs fail-closed). |
| 5 | Tests **never mutate real `~/.hermes`** | **held** | `.workflow/S1-T1b/results/verifier-result.md` (isolation contract; tripwire when operator homes absent). `.workflow/S2-GE/results/verifier-result.md` AC4 (fail-closed on `/home/fish/.hermes`; fingerprint unchanged vs S2-T5; Windows `%USERPROFILE%\.hermes` absent). `tests/isolation.bats` (read only — not executed against real home). |
| 6 | **Three questions** asked; none dropped for time | **held** | `.workflow/S2-T5/results/verifier-result.md` (`three_questions_order`, fixture answers). Full sequence: `.workflow/S3-T10/results/verifier-result.md` (stub smoke through session one). |
| 7 | **`/done` / harness finalize** produced artifacts; raw quit/SIGKILL documented as not guaranteed | **held** | `.workflow/S2-T5/results/verifier-result.md` (deferred finalize until harness `/done`; spool before finalize; `done_same_finalize_fn`). `skills/crossfire-interviewer/SKILL.md` and `README.md` document propose-only YAML and harness-owned durable writes. |

### Sprint gate rollup (demo-blocking slices)

| Gate | Verdict | Load-bearing evidence |
| --- | --- | --- |
| **S2-GE** — memory-only opener across processes | **pass** | `.workflow/S2-GE/results/verifier-result.md`, `.workflow/S2-GE/results/test-runner-result.md` |
| **S3-GE** — evidence + risk beat artifacts | **pass** | `.workflow/S3-GE/results/verifier-result.md`; siblings S3-T8, S3-T9, S3-T10 |

### Supporting task evidence (by concern)

| Concern | Tasks | Verifier path |
| --- | --- | --- |
| Isolation fail-closed | S1-T1b, S2-T5, S2-GE | `.workflow/S1-T1b/results/verifier-result.md`, `.workflow/S2-T5/results/verifier-result.md`, `.workflow/S2-GE/results/verifier-result.md` |
| Deferred persist + three questions | S2-T5 | `.workflow/S2-T5/results/verifier-result.md` |
| Candidate staging + exclusion | S2-T6, S2-T7 | `.workflow/S2-T6/results/verifier-result.md`, `.workflow/S2-T7/results/verifier-result.md` |
| Two-process memory-only opener | S2-T7, S2-GE | `.workflow/S2-T7/results/verifier-result.md`, `.workflow/S2-GE/results/verifier-result.md` |
| Artifact evidence on stdout | S3-T8 | `.workflow/S3-T8/results/verifier-result.md` |
| Unverified-learning risk beat | S3-T9 | `.workflow/S3-T9/results/verifier-result.md` |
| Full demo orchestration ≤90s (stub) | S3-T10 | `.workflow/S3-T10/results/verifier-result.md` |

---

## Should-pass / known limitations

These items are **not demo blockers**. They are logged honestly per spec §17 and plan Task 12.

| Item | Status | Notes |
| --- | --- | --- |
| **`bats` not installed** | known limitation | All task verifiers substituted `.workflow/*/bash-assertions.sh` or independent WSL runs. `tests/*.bats` exist but were not executed in verifier sessions. Install `bats` and run `export HERMES_HOME="${REPO_ROOT}/.crossfire/profiles/test"; bats tests/` for full suite replay. |
| **Live free-form Q&A transcript (S4-T11)** | **human_needed** — not a demo blocker | `.workflow/S4-T11/results/verifier-result.md` **pass** with `human_needed: true`. `tests/interactive_smoke.md` records honest stub/procedure; `LIVE RUN (pending)` block empty. Operator must run WSL procedure when Hermes is reachable. |
| **MEMORY.md YAML round-trip probe** | **probe-pending** | `docs/hermes-compatibility.md` § MEMORY.md delimited YAML round-trip. HTML-comment delimiters **not proven to survive** Hermes write round-trip. Harness uses agent-direct delimited block in isolated profiles; fallback path documented (`opening_target_source=SESSION_SEARCH`). |
| **Live spoken 90s wall-clock** | not re-measured in acceptance pass | Stub rehearsals ≤90s: `.workflow/S3-T10/results/verifier-result.md`. Timed live demo is operator rehearsal (`docs/demo-script.md` § Timing evidence). |
| **Monday durable persist** | manual merge | Free-form sessions emit propose-only YAML; operator merges qualifying observations into `MEMORY.md` (`README.md`). No auto-copy from stage demo profile. |
| **Auto-generated skill encodes bad answer** | by design (honesty beat) | S3-T9 shows unverified follow-up; no promotion gate in MVP (spec §17). |
| **Question-bank breadth beyond three demo questions** | optional / cuttable | `skills/crossfire-interviewer/questions.md` exists; demo three in `SKILL.md` unchanged. |
| **Historical S1-T1b first-run leak** | documented | Do not claim first S1-T1b run never mutated real `~/.hermes`. Going-forward harness fail-closes. `docs/hermes-compatibility.md` Task 1b incident. |
| **WSL `/home/fish/.hermes` install tree** | pre-existing | Hermes install tree on reference machine; tests fail-closed rather than write. Fingerprint unchanged across S2-T5 and S2-GE gates. |

---

## Reviewer attestation (after full demo)

After `bash scripts/demo.sh` (stub or live), a reviewer can truthfully state:

1. Session-two **target** came from `MEMORY.md` (`opening_target_source=MEMORY.md` printed before the question).
2. Session-two **wording** came from the stable `crossfire-interviewer` skill.
3. The **candidate skill did not select the opener** (excluded from live dir until after opener; optional risk beat is a separate process).
4. Session one and two used **distinct process and session IDs**.
5. The scripted bad answer was **persisted automatically** without operator confirmation.
6. No automated step wrote to real `~/.hermes` (disposable profile only).

Optional step 6 (risk beat): audience saw **UNVERIFIED LEARNING RISK DEMO** label and warning before the follow-up influenced the next turn.

---

## Isolation audit (read-only)

Do **not** point acceptance checks at real `~/.hermes`.

| Check | Expected |
| --- | --- |
| `HERMES_HOME` for demo/tests | Under `<repo>/.crossfire/profiles/` (`test` or `stage`) |
| Real home on Windows | `%USERPROFILE%\.hermes` absent |
| Harness on real home | `PREFLIGHT FAIL: HERMES_HOME points at real profile` (fail-closed) |
| Stage → Monday auto-copy | **None** — `.workflow/S4-T11/results/verifier-result.md` |

---

## Checklist completeness

- [x] All seven spec §17 demo-blocking criteria mapped to verifier evidence
- [x] S2-GE and S3-GE gate evidence cited
- [x] Isolation, two-process opener, deferred persist, candidate exclusion covered
- [x] Clean-terminal demo path documented (`--prepare` then `demo.sh`)
- [x] Should-pass items logged as known limitations (`bats`, live transcript, YAML probe-pending)
- [x] No invented passing live e2e against real `~/.hermes`
