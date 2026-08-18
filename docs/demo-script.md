# Demo script — Hermes Interview Sparring Partner (Crossfire)

Spec authority: `sparring-1.0.0` §7 (spoken sequence), §13 (session-two opener), §14 (candidate skill).

Pre-warm Hermes and the isolated stage profile before the clock starts. Never write to real `~/.hermes`.

## One-command rehearsal

```bash
# Reset disposable profile + run full stub smoke (tests / CI)
export HERMES_HOME="${REPO_ROOT}/.crossfire/profiles/stage"   # or test profile
bash scripts/demo.sh --prepare   # narrow reset only; never touches real ~/.hermes
bash scripts/demo.sh             # preflight → session one → evidence → session two → risk beat
```

**Live spoken demo** (after pre-warm, clock starts on step 1):

```bash
export HERMES_HOME="${REPO_ROOT}/.crossfire/profiles/stage"
export CROSSFIRE_LIVE=1
export CROSSFIRE_ASSESSOR=live CROSSFIRE_OPENER=live CROSSFIRE_RISK_BEAT=live
bash scripts/demo.sh
```

**Time cut:** if the sequence exceeds 90 seconds, drop the risk beat (not the opener):

```bash
export CROSSFIRE_SKIP_RISK_BEAT=1
bash scripts/demo.sh
```

Any step failure prints `DEMO FAIL:` plus a recovery line. Reset and retry with `bash scripts/demo.sh --prepare`.

## Isolation and reset (`demo_prepare`)

- `HERMES_HOME` must be under `.crossfire/profiles/` (disposable test or stage profile).
- `demo_prepare` (also `bash scripts/demo.sh --prepare`) restores only that profile: empty `MEMORY.md` fixture, cleared live skills except stable interviewer copy, cleared run-scoped staging under validated `.crossfire/` trees.
- Never deletes real `~/.hermes` or paths outside the disposable profile / repo `.crossfire/` areas.
- Stable skill: repo `skills/crossfire-interviewer/` copied to `${HERMES_HOME}/skills/crossfire-interviewer/`.
- Staged candidates live under `.crossfire/candidate-skills/` until after the session-two opener.

## Spoken sequence (~90 seconds after pre-warm)

| Step | Script | What the audience sees |
| --- | --- | --- |
| 0 | `bash scripts/demo.sh --prepare` | Disposable profile reset (not timed) |
| 1 | `scripts/demo.sh` → session one | Three interview questions; question 2 uses the scripted bad answer |
| 2 | finalize (inside session one) | Weakness persisted to `MEMORY.md`; candidate staged outside live skills |
| 3 | restart | Distinct process ends; `CROSSFIRE_SESSION_ONE_PID` recorded |
| 4 | artifact evidence | Weakness-block diff + staged candidate `SKILL.md` metadata |
| 5 | session two (`demo_session_2.sh`) | **Memory-only opener** — attribution lines before the question; candidate still excluded from live dir |
| 6 | risk beat (`demo_risk_beat.sh`) | **Optional honesty beat** (omit with `CROSSFIRE_SKIP_RISK_BEAT=1` if time-constrained) |

Steps 1–5 are the deliverable demo. Step 6 proves self-learning risk without contaminating opener attribution.

## Session two opener (step 5)

Before the opener question is spoken, the harness prints:

```text
opening_target_source=MEMORY.md
weakness_id=...
family=...
source_session_id=...
target selected by prompt memory; wording generated under stable interviewer procedure
Question: ...
```

The candidate skill must **not** be in `${HERMES_HOME}/skills/` during this step. A `candidate-excluded.flag` under the run records staged paths.

After session two completes, `demo.sh` marks the opener done automatically before the risk beat. Manual equivalent:

```bash
crossfire_mark_opener_complete "$CROSSFIRE_RUN_ID"
# or export CROSSFIRE_OPENER_COMPLETE=1
```

## Unverified-learning risk beat (step 6, optional)

Script: `scripts/demo_risk_beat.sh`

Activation **cannot** occur before the opener completes. The beat:

1. Prints the label `UNVERIFIED LEARNING RISK DEMO` and a warning that the follow-up is shaped by an **unverified** skill trained on a bad answer.
2. Installs the staged candidate to a **namespaced** live path (e.g. `skills/unverified-behavioral-followup/SKILL.md`) — it does **not** replace `crossfire-interviewer`.
3. Because skill loading is **startup-only** (documented-fallback), starts a **new process** for the follow-up turn.
4. Preserves `status: unverified` and full provenance metadata on the active copy.
5. Leaves the activated candidate in the live dir for a later session unless explicitly cleaned up.

Example (stub, isolated profile):

```bash
export HERMES_HOME="${REPO_ROOT}/.crossfire/profiles/demo"
export CROSSFIRE_RUN_ID="run_demo_001"
export CROSSFIRE_OPENER_FAMILY=behavioral
crossfire_mark_opener_complete "$CROSSFIRE_RUN_ID"
bash scripts/demo_risk_beat.sh
```

Expected stdout includes the label, warning, `candidate_live_path=`, `skill_loading_timing: startup-only`, and `Follow-up:` with language requesting the recorded missing elements.

## Layer attribution (reviewer checklist)

After the full sequence a reviewer can state:

- Session-two **target** came from prompt memory (`MEMORY.md`).
- Session-two **wording** came from the stable interviewer skill.
- The **candidate skill did not select the opener** (excluded until after opener).
- The optional beat shows what an ungated, unverified auto-skill would do next.

## Cut policy

If time exceeds 90 seconds, set `CROSSFIRE_SKIP_RISK_BEAT=1` and trim extra evidence narration — never cut process separation, isolation, the three demo questions, automatic persist of the bad answer, or the memory-only opener.

## Timing evidence

Automated tests use stub assessor/opener and do not enforce wall-clock 90s. Record timed rehearsals separately (three consecutive runs under 90s after pre-warm). Example:

```bash
bash scripts/demo.sh --prepare
/usr/bin/time -f 'elapsed_sec=%e' bash scripts/demo.sh
```
