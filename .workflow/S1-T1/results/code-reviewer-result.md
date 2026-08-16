# S1-T1 code review (AC1 retry)

**Packet:** `03-review-ac1`  
**Reviewer:** code-reviewer (did not author the diff)  
**Date:** 2026-08-16  
**Scope:** Task 1 product files only (`docs/hermes-compatibility.md`, `scripts/demo_common.sh`, `scripts/preflight.sh`, `tests/preflight.bats`)  
**Diff source:** product files read in full (`git diff` empty; files are untracked / already in the working tree)

**Verdict:** `approve`

No Critical or Important findings. Prior skeptic-verifier refute (Spec §15 Status cells used **unverified**) is addressed in the current files. Hermes-not-installed remains an accepted documented outcome. Missing later-sprint files (`isolation.bats`, demo sessions, weakness merge) are out of scope.

---

## Check 1 — Spec §15 Status cells: only {verified, unsupported, documented-fallback}

Table at `docs/hermes-compatibility.md:59-71`. Status (column 3) for all nine rows:

| Capability | Status |
| --- | --- |
| Disposable `HERMES_HOME` isolation | **unsupported** |
| Distinct process + session ID | **unsupported** |
| Durable weakness store | **unsupported** |
| `MEMORY.md` delimited block survives round-trip | **documented-fallback** |
| Pause / isolate Curator | **documented-fallback** |
| Disable `session_search` or log calls | **documented-fallback** |
| Learning-loop write ≤ 8s | **documented-fallback** |
| Exclude candidate from live dir | **unsupported** |
| Skill reload without new process | **documented-fallback** |

`unverified` does not appear in `docs/hermes-compatibility.md`, `scripts/`, or `tests/preflight.bats`. Legend (`:3-9`) defines only the three allowed labels. No §15 Status cell is **verified**.

---

## Check 2 — Labels are honest

- **unsupported** rows are looked-and-absent (no binary / no profile tree) or not built (candidate exclusion). Hard-stops are not dressed up as fallbacks.
- **documented-fallback** §15 rows name the spec §15 “If unsupported” path: archive + `SESSION_SEARCH`; isolated profile; disk artifact + distinct process; pre-persist; start new process.
- Nothing in §15 is **verified** without observation.

---

## Check 3 — YAML round-trip is explicitly answered

`docs/hermes-compatibility.md:34-40` and §15 row `:66`: status **documented-fallback**, evidence **not proven to survive**, fallback session archive + `opening_target_source=SESSION_SEARCH` (spec §9 #2). Writer locked **agent-direct**. Live persistence branch **probe-pending** (first attempt `memory-md-block`) in `scripts/demo_common.sh:41-44`.

---

## Check 4 — One Curator strategy

Chosen strategy is **isolated** only (`docs/hermes-compatibility.md:21`, `:49`; `CURATOR_STRATEGY="isolated"` at `scripts/demo_common.sh:41`). Pause CLI is recorded as not run; it is not a second chosen strategy.

---

## Check 5 — Tests not weakened to skip ACs

`tests/preflight.bats` still encodes:

- fail-closed missing binary via `CROSSFIRE_HERMES_DISCOVERY=0` (`:9-13`, `:89-97`)
- isolated `HERMES_HOME` / MEMORY.md / skill-dir paths (`:15-38`)
- reject `/.hermes` throwaway (`:40-44`)
- session-ID fail-closed stub (`:46-51`)
- skill timing, learning-loop placeholder, Curator isolated, session_search, writer + YAML “not proven to survive”, §15 label vocabulary, capability summary before fail-closed

Learning-loop assertion now expects `documented-fallback` instead of `unverified` — that is the AC1 relabel, not a skipped check. Fail-closed stub was not relaxed to pass when Hermes is installed (discovery still gated by `CROSSFIRE_HERMES_DISCOVERY=0`).

---

## Check 6 — Public-doc claims labeled (AC4)

Evidence/Notes use *public-doc (not checked against install)* where Hermes docs were not exercised (`:11-13`, MEMORY.md table, Curator pause, session_search tool, §15 isolation/YAML/skill-reload rows). Preflight skill-timing echo also tags public-doc (`scripts/demo_common.sh:185`). Public docs are not treated as **verified**.

---

## Other review axes

- **Security / real `~/.hermes`:** neither script mkdir/writes/copies/deletes under `REAL_HERMES_WIN` / `REAL_HERMES_WSL`. Default `HERMES_HOME` is `<repo>/.crossfire/profiles/test`. `preflight_check_paths` refuse-lists known real profiles and `*/.hermes` outside `.crossfire/profiles/`.
- **Fail-closed:** `scripts/preflight.sh` prints the capability summary, then `fail_closed` when the binary is missing; it does not start a session.
- **Simplicity:** no extra product files beyond the task allow-list.

---

## Findings

### Minor (track; does not block)

1. **`tests/preflight.bats:83-87`** — The §15 coverage test greps the three allowed labels anywhere in the file (legend is enough). It would still pass if **unverified** returned in a Status cell. Keep as a doc lock; do not treat as AC1 enforcement.

2. **`docs/hermes-compatibility.md:46`** — `hermes curator pause` / snapshot is labeled **documented-fallback** though pause was not executed and is not the chosen strategy. Notes are honest (public-doc, not run). The §15 row correctly names **isolated** as the spec fallback.

---

## Spec AC mapping

| AC | Result |
| --- | --- |
| Every required capability reported verified / unsupported / documented-fallback | Met. §15 Status cells use only those three labels. No unverified. |
| MEMORY.md writer + YAML round-trip | Met: agent-direct; survival **documented-fallback** / **not proven to survive**; archive fallback named. |
| One Curator strategy | Met: **isolated**. |
| No public-doc assumption remains implicit | Met: public-doc tagged in evidence/notes. |
| `tests/preflight.bats` encodes required checks | Met for Task 1: fail-closed stub, paths, Curator, session_search, writer/YAML, capability summary. |

```json
{
  "packet_id": "03-review-ac1",
  "status": "done",
  "verdict": "approve",
  "findings": [
    {
      "priority": "Minor",
      "file": "tests/preflight.bats:83",
      "issue": "§15 coverage grep matches allowed labels anywhere in the file, so it would not catch unverified returning in Status cells.",
      "fix": "Keep as a doc lock; optionally grep the §15 table region and assert unverified is absent from Status cells."
    },
    {
      "priority": "Minor",
      "file": "docs/hermes-compatibility.md:46",
      "issue": "Pause/snapshot CLI is labeled documented-fallback though it was not executed and is not the chosen Curator strategy.",
      "fix": "Label pause unsupported (not run); keep isolated as the single documented-fallback strategy."
    }
  ]
}
```
