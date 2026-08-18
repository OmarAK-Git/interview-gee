# S3-T10 code review — Timed ~90s demo assembly

**Packet:** `02-implementation` (no `03-review.md` in run dir; reviewed against that packet + queue S3-T10 + spec/plan)
**Reviewer:** code-reviewer (did not author this; did not implement, commit, or mark the queue done)
**Date:** 2026-08-18
**Scope:** `scripts/demo.sh`, `tests/demo_e2e.bats`, `docs/demo-script.md`. `.workflow/S3-T10/bash-assertions.sh` as test evidence only. Session scripts / `demo_common.sh` / stage / activate / risk-beat checked for blast radius (compose-only; not T10 write scope).
**Spec / plan:** `sparring-1.0.0` §6 (`demo_prepare` never deletes unrelated Hermes state), §7 (spoken sequence; cut risk-beat polish not the three questions), §13 opener, §14 candidate. Plan Task 10. Packet: compose existing scripts; TDD; isolation fail-closed; timed rehearsal may live in implementer-result.

**Blocking if:** duplicates session logic instead of calling existing scripts; can mutate real `~/.hermes`; prepare deletes unrelated Hermes state; no early-exit recovery; three demo questions cut.

**Verdict:** `approve`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 0 |
| Minor | 4 |
| Blocking | 0 |

**Retry:** no

---

## Blocking criteria

| Criterion | Result | Evidence |
| --- | --- | --- |
| Does not duplicate session logic; calls existing scripts | **Met** | `scripts/demo.sh` invokes `bash .../demo_session_1.sh` (`:198`), `demo_session_2.sh` (`:226`), `demo_risk_beat.sh` (`:251`). No question loop, assessor, or opener wording copied into `demo.sh`. Staging / evidence / opener-complete are existing helpers (`crossfire_stage_candidates_for_run`, `crossfire_print_artifact_evidence`, `crossfire_mark_opener_complete`). Packet forbids editing session scripts; T10 product files do not. |
| Cannot mutate real `~/.hermes` | **Met** | Early fail-closed before sourcing `demo_common.sh` (`scripts/demo.sh:44-47`, `:16-42`) treats exact WSL/Win real homes and any `*/.hermes` path outside `.crossfire/profiles/`. Independent probes: `HERMES_HOME=/home/fish/.hermes` → `ISO_RC=1`, `DEMO FAIL` + `Recovery:`, `ISO_CONTINUED=no`; `HERMES_HOME=%USERPROFILE%/.hermes` → `ISO2_RC=1`, same messages. Windows `%USERPROFILE%\.hermes` **absent** before and after isolation, prepare, and stub smoke. |
| Prepare does not delete unrelated Hermes state | **Met** | `crossfire_demo_validate_disposable_profile` (`:80-87`) requires `*/.crossfire/profiles/*` after `crossfire_require_isolated_hermes_home`. Candidate/runs wipes go through `crossfire_demo_safe_to_wipe_tree` (`:90-105`) which refuses `is_real_hermes_home` and `*/.hermes` outside `.crossfire/profiles` or `candidate-skills`. Independent prepare: stray skill gone, fixture `MEMORY.md` restored, interviewer restored, sibling `unrelated.txt` kept, `%USERPROFILE%\.hermes` still absent. `CROSSFIRE_RUNS_DIR` pointed at a temp `.../.hermes` tree: `FAKE_HERMES_SKILL_KEPT=yes`. |
| Early-exit recovery | **Met** | `crossfire_demo_fail_early` / `crossfire_demo_fail` (`:10-14`, `:74-78`) print `DEMO FAIL:` + `Recovery: bash scripts/demo.sh --prepare`. Isolation and invalid disposable path (`HERMES_HOME=.../not-crossfire/profile`) both emit those lines (bats `:47-57`, `:142-150`; bash-assertions `isolation_recovery`, `failure_recovery`). Independent isolation probe confirmed both strings and nonzero rc. |
| Three demo questions not cut | **Met** | Orchestrator does not skip or subset questions; session one still loops `for i in 0 1 2` (`scripts/demo_session_1.sh:214`). Time cut is `CROSSFIRE_SKIP_RISK_BEAT=1` only (`scripts/demo.sh:334-338`; `docs/demo-script.md` Cut policy). Independent stub smoke: `HAS_q_technical_01=yes`, `HAS_q_behavioral_01=yes`, `HAS_q_product_01=yes`, scripted bad-answer quote present. Spec §7 (cut optional risk-beat, not questions) wins over plan wording “drop one question.” |

---

## Spec / plan / packet checks

| Requirement | Result |
| --- | --- |
| §7 full sequence: preflight → three Qs → finalize → restart → evidence → memory-only opener → optional risk beat | Met in stub. Smoke greps `preflight:`, `CROSSFIRE q_technical_01`, `session one finalized`, `artifact_evidence:`, `opening_target_source=MEMORY.md`, `Question:`, `UNVERIFIED LEARNING RISK DEMO`, `Follow-up:`, `demo: complete`. Session two is a new `bash demo_session_2.sh` process; distinct PIDs asserted. |
| Distinct IDs + layer labels | Met. Prints `CROSSFIRE_SESSION_ONE_PID` / session-two PID from child; `session_identifiability: distinct`; `layer_attribution:` lines for MEMORY.md target, stable interviewer wording, candidate excluded. |
| Scripted bad answer ≥2 missing | Met. Orchestrator fail-closes unless spool has `missing_elements: [action, result]` (`scripts/demo.sh:258-268`). Bats + bash-assertions check quote + spool. |
| Isolation fail-closed; never real `~/.hermes` | Met (blocking table). |
| Narrow `demo_prepare` / `--prepare` | Met for Hermes. Also restores empty memory fixture and stable interviewer copy. Unconditional prepare at start of `crossfire_demo_main` matches spec rehearsal “start clean.” |
| Files allowed | Met. Product: the three allowed files. Optional `bash-assertions.sh` + implementer result. |
| Timed ≤90s after pre-warm | Not enforced in bats (packet-allowed). Implementer recorded 3×28s stub. Independent Git Bash full stub smoke completed in this review (`SMOKE_RC=0`, wall-clock ~40s including surrounding probes). Live spoken timing not re-measured here. |

---

## Minor (track, not blocking)

### Minor 1 — `IFS=:` leak after PATH sanitize

`crossfire_demo_sanitize_path` (`scripts/demo.sh:61-72`) sets global `IFS=':'` and never restores it. Session one is backgrounded (subshell), so that leak dies with the job; session two and the risk-beat wrappers run **in the parent**, so `IFS` stays `:` through `crossfire_mark_opener_complete` and later helpers. Independent sourced probe: `IFS_BEFORE=$' \t\n'` → `IFS_AFTER=:`. Current helpers mostly quote expansions, and Git Bash `pwd` paths have no colon, so stub smoke still works. Sanitize exists for Windows `WindowsApps`; Windows `C:/...` paths would split on unquoted expansions. **Fix if tightening:** `local IFS=':'` (or save/restore).

### Minor 2 — E2E smoke does not lock all three question IDs

`tests/demo_e2e.bats:90-102` (and bash-assertions `full_sequence_smoke`) require `CROSSFIRE q_technical_01` plus the behavioral bad-answer quote, not `q_behavioral_01` / `q_product_01`. Product still asks all three via session one. A later time-cut that dropped only the product question would still pass T10 e2e. **Fix if tightening:** grep all three `CROSSFIRE q_*` IDs in the full-sequence test.

### Minor 3 — Same-process `fail_closed` skips the Recovery line

After the early isolation gate, `demo.sh` sources `demo_common.sh`. Helper `fail_closed` (`scripts/demo_common.sh:67-69`) prints `PREFLIGHT FAIL:` and `exit 1` with no `Recovery:`. Session scripts are subprocesses, so their failures are wrapped by `crossfire_demo_fail`. In-process staging / evidence / mark-opener `fail_closed` is not. Isolation and non-disposable profile paths — the cases the packet tests — do print Recovery. **Fix if tightening:** trap ERR / wrap helper calls so every `demo.sh` abort goes through `crossfire_demo_fail`.

### Minor 4 — Session-one ID is the stub env default, not parsed from session one

`scripts/demo.sh:309-310` sets `s1_sid="${CROSSFIRE_STUB_SESSION_ID:-sess_demo_s1}"` rather than parsing session-one output. Stub still gets distinct IDs because session two uses `CROSSFIRE_STUB_SESSION_TWO_ID`. Live Hermes session IDs from session one are not forwarded; distinctness would rely on session two’s live id differing from the stub string. **Fix if tightening:** parse `source_session_id` / a session-one `CROSSFIRE_SESSION_ONE_ID=` line if/when session one emits it.

---

## Tests vs behavior

Required locks actually invoke `demo.sh` (not only source greps of success strings):

- Isolation: run against `/home/fish/.hermes`, assert nonzero + `DEMO FAIL` / real-profile message + `Recovery:` (bats also checks rc). Independent probe confirmed rc=1 and no continue.
- Prepare scope: restore fixture memory, delete stray skill + staged candidate; bats snapshots absence of `REAL_HERMES_*` paths.
- Full stub smoke / distinct PIDs / layer labels / bad-answer spool / skip-risk-beat: run the orchestrator and inspect stdout + spool file.
- `demo.sh exists and sources isolation contract` and `demo does not exec hermes directly` are greps; behavior is covered by the run tests.

bash-assertions isolation greps messages only (`|| true`); bats covers rc. Same pattern as S3-T9; not blocking.

---

## Isolation

No product write under real `~/.hermes`. Assertions used disposable `.crossfire/profiles/test` under a temp root. Independent children:

- `/home/fish/.hermes` → `ISO_RC=1`, `DEMO FAIL: HERMES_HOME points at real profile`, `Recovery:`, `ISO_CONTINUED=no`
- `%USERPROFILE%/.hermes` → `ISO2_RC=1`, same class of messages, path still absent
- Prepare + stub smoke: Windows real home still absent

Did not install bats. Did not mutate git state or the queue (`S3-T10` remains `in_progress`).

---

## Checks run

- Read packet `02-implementation.md`, plan Task 10, spec §6–§7 / §13–§14, queue S3-T10, implementer result, the three product files, session one/two + risk-beat + stage/activate for compose/blast-radius only.
- Confirmed T10 product files are new/untracked allowed paths. `demo_session_1.sh` is dirty vs HEAD from prior work; T10 `demo.sh` does not duplicate its question loop.
- `bash .workflow/S3-T10/bash-assertions.sh` (Git Bash) → `passed=9 failed=0`.
- Independent isolation, prepare-scope, IFS, and three-question smoke probes (Git Bash) as above.

```json
{
  "packet_id": "03-review",
  "status": "done",
  "verdict": "approve",
  "retry_required": false,
  "findings": {
    "critical": 0,
    "important": 0,
    "minor": 4
  },
  "blocking_count": 0,
  "isolation": "pass_real_hermes",
  "blocking": "none",
  "items": [
    {
      "priority": "minor",
      "id": "ifs_colon_leak_after_sanitize",
      "file": "scripts/demo.sh",
      "line": 63
    },
    {
      "priority": "minor",
      "id": "e2e_smoke_missing_q_product_id",
      "file": "tests/demo_e2e.bats",
      "line": 94
    },
    {
      "priority": "minor",
      "id": "fail_closed_skips_recovery",
      "file": "scripts/demo.sh",
      "line": 51
    },
    {
      "priority": "minor",
      "id": "session_one_id_stub_default",
      "file": "scripts/demo.sh",
      "line": 309
    }
  ]
}
```
