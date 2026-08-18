# S3-T9 skeptic-verifier result

**Verdict: pass**

Task-scoped. Treated implementation and review claims as unevidenced. Did not use `implementer-result.md` or `code-reviewer-result.md` as proof. Did not mark the queue done (`S3-T9` remains `verifying`). Did not commit. Did not install packages (including `bats`). Did not write real `~/.hermes`.

---

## Claim restated

S3-T9 is done: the optional honesty beat visibly uses the generated candidate skill on a later turn, cannot contaminate session-two opener attribution, and truthfully presents unverified status.

Vague parts held only if independently shown:

- **Uses the generated skill:** follow-up after opener is sourced from the activated candidate (not the stable interviewer).
- **Cannot contaminate opener attribution:** activation is blocked until opener-complete; no live candidate file appears before that; session-two script does not activate.
- **Truthfully unverified:** audience-visible label + warning, and on-disk `status: unverified`, before influence.

---

## 1. Existence (Test-Path)

Cwd: `C:\Users\oalan\interview-gee`

```
Test-Path -LiteralPath scripts\demo_risk_beat.sh -PathType Leaf
True
Test-Path -LiteralPath tests\risk_beat.bats -PathType Leaf
True
```

Also present: `scripts\activate_candidate_skill.sh`, `docs\demo-script.md`, `.workflow\S3-T9\bash-assertions.sh`.

`Test-Path` `%USERPROFILE%\.hermes` → `False` before probes and `False` after.

Existence alone is not a pass.

---

## 2. Bash-equivalent (bats missing)

`Get-Command bats` empty. Did not install bats.

Command (fresh this run, Git Bash):

```
"C:\Program Files\Git\bin\bash.exe" .workflow/S3-T9/bash-assertions.sh
```

Output:

```
PASS: isolation_fail_closed
PASS: activation_before_opener
PASS: no_live_before_opener
PASS: label_warning_before_influence
PASS: namespaced_live_path
PASS: unverified_metadata
PASS: startup_only_new_process
PASS: followup_missing_elements
PASS: candidate_persists
PASS: env_opener_complete
passed=10 failed=0
EXIT:0
```

`tests/risk_beat.bats` has 9 `@test` blocks; bash-equivalent splits the before-opener case into `activation_before_opener` + `no_live_before_opener` (10 names). Mapping is 1:1 on behavior.

Bash-equivalent isolation greps the message and does not assert rc. Independent probes below assert rc.

---

## 3. Independent: activation fails before opener

Disposable `HERMES_HOME=/tmp/crossfire-s3t9-v.*/.crossfire/profiles/test` (never real `~/.hermes`). Staged behavioral candidate; **no** `opener-complete.flag` and **no** `CROSSFIRE_OPENER_COMPLETE`.

| Check | Result |
| --- | --- |
| Product CLI `bash scripts/activate_candidate_skill.sh` | `ACT_CLI_RC=1`; stdout/err contains `opener not complete`; live `unverified-behavioral-followup/SKILL.md` **absent** before and after |
| Sourced `crossfire_activate_candidate_skill` | `ACT_FN_RC=1`; same message; live file still **absent** |
| Product CLI `bash scripts/demo_risk_beat.sh` before opener | `RISK_BEFORE_OPENER_RC=1`; `PREFLIGHT FAIL: candidate activation blocked: session-two opener not complete`; live file **absent**; label count `S2_LABEL_WITHOUT_OPENER=0` |

`scripts/demo_session_2.sh` contains **no** `activate_candidate`, `demo_risk_beat`, `opener-complete`, or `OPENER_COMPLETE` symbols. Opener path cannot install the candidate.

---

## 4. Independent: label prints before `candidate_live_path`

After `crossfire_mark_opener_complete` + isolated interviewer copy, product CLI `bash scripts/demo_risk_beat.sh` (`CROSSFIRE_RISK_BEAT=stub`): `RISK_RC=0`.

Stdout line numbers (fresh this run):

| Line | Content |
| --- | --- |
| 1 | `=== UNVERIFIED LEARNING RISK DEMO ===` |
| 2 | `WARNING: The next follow-up is shaped by an auto-generated skill marked status: unverified. It was trained on a bad answer and is not promoted or validated.` |
| 3 | `candidate_live_path=.../skills/unverified-behavioral-followup/SKILL.md` |

`LABEL_BEFORE_LIVE=1`. `WARN_BEFORE_LIVE=1`. Follow-up is line 17, after the live path.

Live file after beat:

- exists under namespaced path, **not** under `crossfire-interviewer/`
- `status: unverified`, `name: unverified-behavioral-followup`, `id: crossfire.candidate.behavioral`
- provenance: `weakness_id: w-deadbeeffeed`, `source_session_id: sess_stub`, `answer_ref: run_label_ind/q_behavioral_01/0`, `observation_count: 1`
- body contains `Do not praise or imitate`
- interviewer `SKILL.md` cksum **unchanged** vs repo `skills/crossfire-interviewer/SKILL.md` (`1665177257 9117`); interviewer has **zero** `id: crossfire.candidate` lines

Follow-up (demo missing elements `action,result`):

```
Follow-up: Ask the candidate to describe the specific action they took and the result that followed.
```

`CROSSFIRE_OPENER_COMPLETE=1` without a flag file: `ENV_RC=0`, live file created under the disposable profile.

---

## 5. Isolation fail-closed

Independent nested `bash -c` sourcing `scripts/activate_candidate_skill.sh`:

| HERMES_HOME | rc | message | `SHOULD_NOT_REACH` |
| --- | --- | --- | --- |
| `/home/fish/.hermes` | **1** | `HERMES_HOME points at real profile` | absent |
| `C:\Users\oalan/.hermes` (`%USERPROFILE%`) | **1** | same | absent |
| `/tmp/not-crossfire/.hermes` | **1** | same | absent |

Windows `%USERPROFILE%\.hermes` absent before and after. Probe `WROTE_HOME_HERMES=0`, `WROTE_USERPROFILE_HERMES=0`. Writes only under `/tmp/crossfire-s3t9-*`.

---

## AC mapping

| AC | Status | Evidence |
| --- | --- | --- |
| The beat visibly uses the generated skill | **held** | After opener, CLI copies staged candidate to `skills/unverified-behavioral-followup/SKILL.md`, prints that path, dumps candidate frontmatter, then a follow-up that requests the demo missing elements (`action`, `result`) from that skill |
| It cannot contaminate opener attribution | **held** | Activate CLI, activate function, and `demo_risk_beat.sh` all fail closed before opener; no live candidate file; risk-beat label is not printed if opener is incomplete; `demo_session_2.sh` does not activate |
| It truthfully presents unverified status | **held** | Label + `WARNING:` with `status: unverified`, trained-on-bad-answer, not promoted; stdout and live file both show `status: unverified` **before** follow-up |

Packet locks (activation-before-opener, label+warning before influence, isolation fail-closed): **held** by independent probes, not by implementer transcript.

---

## Residuals (non-blocking)

- `bats` absent; not installed. Coverage is bash-equivalent plus independent CLI probes.
- Bash-equivalent isolation checks the fail message, not rc. Independent probes asserted `ISO_RC=1`.
- Bats/bash follow-up assertion greps the whole transcript (`action`/`result`), which also appears in dumped `missing_elements`. Independent check used the `Follow-up:` line; for the demo CSV it requests action and result.
- Staging helper `crossfire_candidate_followup_sentence` (not in T9 allowed files) hardcodes the behavioral n>1 sentence to action/result. Probe with `situation,task` still printed that sentence while dumping `missing_elements: [situation,task]`. Demo scripted gap is `action,result`; live Hermes prompt (untested here) interpolates the CSV.
- `CROSSFIRE_RISK_BEAT_CHILD_PID` uses `$$` and matched the parent PID (`933` / `2291`). Product still forks `( ) &` + `wait`. Tests lock the `startup-only` / `new process` strings, not distinct OS PIDs. Documented-fallback; live Hermes invoke not CI-exercised.
- Direct `activate_candidate_skill.sh` CLI has no honesty label (beat script does). Unverified greps run after `mv`; malformed staged copy could remain live while activate fail-closes. Not hit with valid staged skills in this run.
- `demo_session_2.sh` does not mark opener complete (out of T9 scope; documented for later `demo.sh` wiring).

---

## Isolation

Windows `%USERPROFILE%\.hermes` absent before and after. Product activate and risk-beat call `crossfire_require_isolated_hermes_home` before writes. Sourcing `demo_common.sh` fail-closes a real `HERMES_HOME` at source time.

---

## Verdict JSON

```json
{
  "packet_id": "04-verify",
  "status": "done",
  "verdict": "pass",
  "retry_required": false,
  "acs": {
    "beat_uses_generated_skill": "held",
    "cannot_contaminate_opener_attribution": "held",
    "truthfully_presents_unverified_status": "held"
  },
  "evidence_path": ".workflow/S3-T9/results/verifier-result.md",
  "commands": {
    "test_path_demo_risk_beat_sh": true,
    "test_path_risk_beat_bats": true,
    "bash_assertions": "passed=10 failed=0 EXIT:0",
    "bats": "absent_not_installed",
    "activation_before_opener_cli": "ACT_CLI_RC=1 no live file",
    "risk_beat_before_opener": "RISK_BEFORE_OPENER_RC=1 no live file no label",
    "label_before_candidate_live_path": "line 1 < line 3 RISK_RC=0",
    "isolation_wsl_win_glob": "ISO_RC=1 WIN_ISO_RC=1 GLOB_ISO_RC=1"
  },
  "isolation": "pass_real_hermes_absent",
  "queue": "not_marked_done",
  "commit": "not_made"
}
```
