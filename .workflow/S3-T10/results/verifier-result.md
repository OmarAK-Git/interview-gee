# S3-T10 skeptic-verifier result

**Verdict: pass**

Task-scoped. Treated implementation and review claims as unevidenced. Did not use `implementer-result.md` or `code-reviewer-result.md` as proof. Did not mark the queue done (`S3-T10` remains `verifying`). Did not commit. Did not install packages (including `bats`). Did not write real `~/.hermes`.

---

## Claim restated

S3-T10 is done: `scripts/demo.sh` composes a full-sequence smoke that completes within 90s after pre-warm, calling existing session scripts (not duplicating them). Three consecutive rehearsals finish in ≤90s and produce expected evidence and opener. Failure exits early with recovery. Reset/prep never deletes unrelated Hermes state. Isolation fail-closed.

Vague parts held only if independently shown:

- **Full sequence:** preflight → session one (three questions) → restart → evidence → memory-only opener → risk beat.
- **≤90s:** wall-clock of the product `demo.sh` stub path, measured this run, three consecutive times after `--prepare`.
- **Calls existing scripts:** `demo.sh` execs `demo_session_1.sh` / `demo_session_2.sh` / `demo_risk_beat.sh`; those files exist; `demo.sh` has no question loop.
- **Isolation / prep:** real `HERMES_HOME` and `*/.hermes` outside `.crossfire/profiles/` fail closed with recovery; prepare wipes only disposable trees.

---

## 1. Existence (Test-Path)

Cwd: `C:\Users\oalan\interview-gee`

```
Test-Path -LiteralPath scripts\demo.sh -PathType Leaf
True
Test-Path -LiteralPath tests\demo_e2e.bats -PathType Leaf
True
Test-Path -LiteralPath docs\demo-script.md -PathType Leaf
True
```

Also present: `scripts\demo_session_1.sh`, `scripts\demo_session_2.sh`, `scripts\demo_risk_beat.sh`, `.workflow\S3-T10\bash-assertions.sh`.

`Test-Path` `%USERPROFILE%\.hermes` → `False` before probes and `False` after all probes/rehearsals.

Existence alone is not a pass.

---

## 2. Bash-equivalent (bats missing)

`Get-Command bats` empty. Did not install bats.

Command (fresh this run, Git Bash):

```
"C:\Program Files\Git\bin\bash.exe" --noprofile --norc .workflow/S3-T10/bash-assertions.sh
```

Output:

```
PASS: demo_script_exists
PASS: isolation_recovery
PASS: demo_prepare_reset
PASS: full_sequence_smoke
PASS: distinct_ids
PASS: layer_labels
PASS: bad_answer_gaps
PASS: failure_recovery
PASS: skip_risk_beat
passed=9 failed=0
EXIT:0
```

`tests/demo_e2e.bats` has 10 `@test` blocks. Bash-equivalent covers 9 behavioral locks; it omits `demo does not exec hermes directly`. Independent grep this run: `NO_DIRECT_HERMES=yes` (no uncommented `hermes` exec in `scripts/demo.sh`).

Bash-equivalent isolation greps the fail message and does not assert rc (`|| true`). Independent probes below assert rc.

---

## 3. Independent: isolation fail-closed

Direct `bash scripts/demo.sh` (no wrapper that continues after failure). Git Bash, this run:

| HERMES_HOME | rc | stdout/err | continued |
| --- | --- | --- | --- |
| `/home/fish/.hermes` | **1** | `DEMO FAIL: HERMES_HOME points at real profile: /home/fish/.hermes` + `Recovery:` | no (script exited) |
| `C:/Users/oalan/.hermes` (`%USERPROFILE%`) | **1** | same class; path `C:/Users/oalan/.hermes` | no |
| `/tmp/not-crossfire/.hermes` | **1** | same class | no |
| `${tmp}/not-crossfire/profile` (not disposable) | **1** | `DEMO FAIL: demo_prepare refuses non-disposable HERMES_HOME` + `Recovery:` | no |

Early gate in `scripts/demo.sh:44-47` runs **before** sourcing `demo_common.sh`. Fail helper `crossfire_demo_fail_early` (`:10-14`) prints `DEMO FAIL:` + `Recovery:` and `exit 1`.

Windows `%USERPROFILE%\.hermes` absent before and after. `HOME/.hermes` absent. `/home/fish/.hermes` absent. Probe writes only under `/tmp/crossfire-s3t10-*`.

---

## 4. Independent: demo.sh calls existing session scripts

Files exist (`Test-Path` True). Product invokes them as subprocesses, not inlined loops:

```
scripts/demo.sh:198    bash "${_demo_dir}/demo_session_1.sh"
scripts/demo.sh:226    bash "${_demo_dir}/demo_session_2.sh"
scripts/demo.sh:251    bash "${_demo_dir}/demo_risk_beat.sh"
```

`scripts/demo.sh` has **no** `for i in 0 1 2` question loop (only a spool path check for `q_behavioral_01`). The loop lives in `scripts/demo_session_1.sh:214`. Timed rehearsal stdout included `CROSSFIRE q_technical_01`, `q_behavioral_01`, `q_product_01`, `session one finalized`, `opening_target_source=MEMORY.md`, `Question:`, and `UNVERIFIED LEARNING RISK DEMO` — output from those child scripts, not greps of `demo.sh` itself.

---

## 5. Independent: prepare does not delete unrelated Hermes state

Disposable `HERMES_HOME=/tmp/crossfire-s3t10-prep.*/.crossfire/profiles/test`. `--prepare` `PREP_RC=0`.

| Check | Result |
| --- | --- |
| stray live skill | **gone** |
| old MEMORY.md content | **absent**; fixture `Personal Memory` restored |
| staged candidate under `.crossfire/candidate-skills` | **gone** |
| sibling `${tmp}/sibling/unrelated.txt` | **kept** |
| interviewer copy restored | **yes** (`skills/crossfire-interviewer/SKILL.md`) |
| `CROSSFIRE_RUNS_DIR` pointed at `${tmp}/unrelated/.hermes` | `PREP2_RC=0`; fake tree skill **kept** (`FAKE_HERMES_SKILL_KEPT=yes`) |
| `%USERPROFILE%\.hermes` | still absent |

---

## 6. Timed 90s: three consecutive stub rehearsals (re-measured)

Wall-clock is **not** enforced in bats. Packet allows a measured stub rehearsal. This verifier re-measured; did not copy implementer timings.

Host: Git Bash. Isolated temp profile (never real `~/.hermes`). Env: `CROSSFIRE_ASSESSOR=stub` `CROSSFIRE_OPENER=stub` `CROSSFIRE_RISK_BEAT=stub` `CROSSFIRE_HERMES_DISCOVERY=0`. Pre-warm: `bash scripts/demo.sh --prepare` (`PREP_RC=0`, not on the clock). Clock: Python `time.time()` around `bash scripts/demo.sh`.

| Run | rc | elapsed_sec | needles | distinct PIDs | bad-answer spool ≥2 missing |
| --- | --- | --- | --- | --- | --- |
| 1 | 0 | **29.310** | all | 2228 ≠ 2952 | yes (`20260818_160036_005bb8`) |
| 2 | 0 | **30.599** | all | 3635 ≠ 4359 | yes (`20260818_160108_007b7f`) |
| 3 | 0 | **31.126** | all | 5042 ≠ 5766 | yes (`20260818_160138_005ae9`) |

All three under 90s. Needles required this run (all present on every rehearsal): `preflight:`, three `CROSSFIRE q_*` IDs, `session one finalized`, `artifact_evidence:`, `opening_target_source=MEMORY.md`, `Question:`, `UNVERIFIED LEARNING RISK DEMO`, `Follow-up:`, `demo: complete`, distinct session PIDs, `session_identifiability: distinct`, `layer_attribution:` (`opening_target=MEMORY.md`, `opener_wording=stable_interviewer_skill`, `candidate_excluded_from_opener`), scripted bad-answer quote.

Run 1 opener line (fresh):

```
opening_target_source=MEMORY.md
Question: Tell me about a time a detection you owned was wrong — specifically, what action did you take and what measurable result followed?
```

Live `CROSSFIRE_LIVE=1` spoken timing was **not** measured (Hermes not required for this stub packet). Residual below; not faked.

`%USERPROFILE%\.hermes` still absent after rehearsals.

---

## AC mapping

| AC | Status | Evidence |
| --- | --- | --- |
| Three consecutive rehearsals complete within 90s and produce expected evidence and opener | **held** | Independent stub timings 29.310 / 30.599 / 31.126s; rc=0; evidence + MEMORY.md opener + three questions on all three runs |
| Failure exits early with recovery | **held** | Isolation and non-disposable profile: rc=1, `DEMO FAIL:` + `Recovery:` this run |
| Reset/prep never deletes unrelated Hermes state | **held** | Disposable prepare restored fixture and interviewer; sibling file kept; fake `*/.hermes` runs tree kept; real home absent |
| Isolation fail-closed | **held** | Direct rc=1 on WSL real home, Windows `%USERPROFILE%/.hermes`, and glob `*/.hermes` outside `.crossfire/profiles/` |
| `demo.sh` calls existing session scripts | **held** | Child `bash` at `demo.sh:198,226,251`; session files exist; no duplicated question loop in `demo.sh` |

Packet locks (bash-equivalent + isolation + compose-existing): **held** by this run, not by implementer transcript.

---

## Residuals (non-blocking)

- `bats` absent; not installed. Coverage is bash-equivalent (9) plus independent CLI probes plus the 10th bats lock (`no direct hermes exec`) via grep.
- Bash-equivalent isolation checks the fail message, not rc. Independent probes asserted `ISO_RC=1`.
- Full-sequence bats/bash greps `CROSSFIRE q_technical_01` and the bad-answer quote, not all three IDs. Independent timed runs grepped all three `q_*` IDs; they were present.
- `crossfire_demo_sanitize_path` sets global `IFS=:` (`demo.sh:63`). Stub rehearsals still completed; live Windows path splitting not exercised.
- After sourcing `demo_common.sh`, helper `fail_closed` prints `PREFLIGHT FAIL:` without `Recovery:`. Isolation and non-disposable paths — the packet cases — do print Recovery.
- Session-one ID is taken from `CROSSFIRE_STUB_SESSION_ID`, not parsed from session-one output (`demo.sh:309-310`). Stub still produced distinct PIDs and session IDs (`sess_time_s1` vs `sess_time_s2`).
- Live spoken 90s (`CROSSFIRE_LIVE=1`) not re-measured. Packet and this verifier’s order were stub rehearsal.

---

## Isolation

Windows `%USERPROFILE%\.hermes` absent before and after. Product early-gates real homes before sourcing helpers or preparing. Prepare wipe paths go through `crossfire_demo_safe_to_wipe_tree`. All verifier writes used `/tmp/crossfire-s3t10-*` disposable `.crossfire/profiles/` trees.

---

## Verdict JSON

```json
{
  "packet_id": "04-verify",
  "status": "done",
  "verdict": "pass",
  "retry_required": false,
  "acs": {
    "three_consecutive_rehearsals_within_90s_evidence_and_opener": "held",
    "failure_exits_early_with_recovery": "held",
    "reset_prep_never_deletes_unrelated_hermes_state": "held",
    "isolation_fail_closed": "held",
    "demo_sh_calls_existing_session_scripts": "held"
  },
  "evidence_path": ".workflow/S3-T10/results/verifier-result.md",
  "commands": {
    "test_path_demo_sh": true,
    "test_path_demo_e2e_bats": true,
    "test_path_demo_script_md": true,
    "bash_assertions": "passed=9 failed=0 EXIT:0",
    "bats": "absent_not_installed",
    "isolation_wsl_win_glob": "ISO_RC=1 ISO2_RC=1 ISO3_RC=1 FAIL_RC=1",
    "timed_stub_rehearsals_sec": [29.31, 30.599, 31.126],
    "timed_stub_rehearsals_rc": [0, 0, 0]
  },
  "isolation": "pass_real_hermes_absent",
  "queue": "not_marked_done",
  "commit": "not_made"
}
```
