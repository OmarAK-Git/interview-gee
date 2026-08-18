# S3-T8 skeptic-verifier result

**Verdict: pass**

Task-scoped. Treated implementation and review claims as unevidenced. Did not use `implementer-result.md` or `code-reviewer-result.md` as proof. Did not mark the queue done (`S3-T8` remains `verifying`). Did not commit. Did not install packages (including `bats`). Did not write real `~/.hermes`.

---

## Claim restated

S3-T8 is done: a reviewer sees durable artifacts without filesystem navigation, with bounded timeouts. Success and timeout paths pass. Helpers live in `scripts/demo_common.sh`; tests in `tests/artifact_evidence.bats`.

Vague parts of the claim: “without filesystem navigation” and “bounded.” Held only if stdout itself contains the weakness-block diff and full staged SKILL.md, and a missing-artifact wait returns nonzero in about `CROSSFIRE_ARTIFACT_TIMEOUT_SEC` (not an unbounded `while true`).

---

## 1. Existence (Test-Path)

Cwd: `C:\Users\oalan\interview-gee`

```
Test-Path -LiteralPath tests\artifact_evidence.bats -PathType Leaf
True
```

`Test-Path` `%USERPROFILE%\.hermes` → `False` before probes and `False` after.

Existence alone is not a pass.

---

## 2. Bash-equivalent (bats missing)

`Get-Command bats` empty (`BATS_ABSENT`). Did not install bats.

Command (fresh this run, Git Bash):

```
"C:\Program Files\Git\bin\bash.exe" .workflow/S3-T8/bash-assertions.sh
```

Output:

```
PASS: snapshot_before
PASS: success_evidence
PASS: sete_direct_print
PASS: timeout_memory
PASS: timeout_candidate
PASS: isolation_fail_closed
passed=6 failed=0
EXIT:0
```

`tests/artifact_evidence.bats` has 6 `@test` blocks; bash-equivalent names map 1:1. Wall-clock of this script (~23s) is not a timeout-bound measurement (nested work + two waits + Git Bash overhead). Bound is measured independently in §4.

---

## 3. Independent sourced `set -e` print (not command substitution)

Nested `bash -c` with `set -euo pipefail`, disposable `HERMES_HOME=/tmp/crossfire-s3t8-sete.*/.crossfire/profiles/test` (never real `~/.hermes`). Direct `crossfire_print_artifact_evidence` then `printf '%s\n' REACHED_AFTER_PRINT`.

| Check | Result |
| --- | --- |
| `SHELLOPTS` contains `errexit` | yes |
| Process exit | `SETE_NEST_RC=0` |
| Weakness-block unified diff | yes (`artifact_evidence: MEMORY.md weakness-block diff`, `CROSSFIRE-WEAKNESSES:START`) |
| Labeled diff headers | `memory-before (weakness block)` / `memory-after (weakness block)` |
| `candidate_path=` under `.crossfire/candidate-skills/unverified-behavioral-followup/SKILL.md` | yes |
| `status: unverified` / `source_session_id: sess_ae` | yes |
| Banner `--- candidate SKILL.md ---` | yes |
| SKILL.md body `Do not praise or imitate` | **present** |
| `REACHED_AFTER_PRINT` | **reached** |
| `printf: --: invalid option` | **absent** |
| Fixture prose `Personal Memory` / `favorite prompt` | **absent** (relevant block only) |

Product banner is `printf '%s\n' '--- candidate SKILL.md ---'` (`scripts/demo_common.sh:818`). Bare `printf '--- candidate SKILL.md ---'` on this Git Bash is `OLD_PRINTF_RC=2`; `%s` form is `NEW_PRINTF_RC=0`.

S2 helpers still present after sourcing: `crossfire_extract_yaml_from_live_stdout`, `crossfire_select_newest_weakness`. `CROSSFIRE_RUNS_DIR` override honored (`SNAP_PATH=.../runs/run_verify_sete/memory-before.md`).

---

## 4. Timeout path: nonzero and bounded

Independent calls with `export CROSSFIRE_ARTIFACT_TIMEOUT_SEC=1`, disposable `/tmp/crossfire-s3t8-verify.*` profile, Git Bash `date +%s` wall clock.

| Case | rc | elapsed | stderr/stdout |
| --- | --- | --- | --- |
| Weakness block unchanged | **1** | **1s** | `artifact_evidence: timeout waiting for MEMORY.md weakness-block change after 1s` |
| Candidate missing (block present) | **1** | **2s** | `artifact_evidence: timeout waiting for staged candidate SKILL.md after 1s` |

Default after source: `CROSSFIRE_ARTIFACT_TIMEOUT_SEC=8`, poll `0.2s`. Wait loop (`scripts/demo_common.sh:756-775`) compares integer elapsed to `timeout_sec` then `return 1`. Two sequential waits in the orchestrator are still bounded by `2 * timeout_sec`, not an open-ended hang.

Isolation fail-closed (independent nested bash, `HERMES_HOME=/home/fish/.hermes`): `ISO_RC=1`, `PREFLIGHT FAIL: HERMES_HOME points at real profile: /home/fish/.hermes`.

---

## AC mapping

| AC | Status | Evidence |
| --- | --- | --- |
| Success path passes | **held** | bash-equivalent `success_evidence` + `sete_direct_print`; independent nested `set -e` print `SETE_NEST_RC=0` with diff + full SKILL.md + `REACHED_AFTER_PRINT` |
| Timeout path passes (nonzero + useful message; never wait indefinitely) | **held** | `TIMEOUT_MEM_RC=1` in 1s; `TIMEOUT_CAND_RC=1` in 2s; messages name the missing artifact and `after 1s`; wait helper `return 1` at elapsed ≥ timeout |
| Reviewer sees durable artifacts without filesystem navigation | **held** | stdout contains weakness-block diff and full staged SKILL.md body; fixture MEMORY.md prose absent |

---

## Residuals (non-blocking)

- `bats` absent; not installed. Coverage is the bash-equivalent plus independent probes.
- Bash-equivalent timeout checks do not assert wall-clock bound; this run measured it.
- Probe `awk` on `set -o` printed `ERREXIT=off` while `SHELLOPTS` listed `errexit` (Git Bash `set -o` field split). `SHELLOPTS` used as the set -e signal.
- Worst-case missing-both-artifacts wait is two timeouts in sequence (`2 * CROSSFIRE_ARTIFACT_TIMEOUT_SEC`). Still bounded.
- Default timeout 8s is larger than the test override of 1s; still a finite default.

---

## Isolation

Windows `%USERPROFILE%\.hermes` absent before and after. Probes used `/tmp/crossfire-s3t8-verify.*` and `/tmp/crossfire-s3t8-sete.*` only. Product helpers call `crossfire_require_isolated_hermes_home` before snapshot/print. Isolation nested call never created a real profile.

---

## Verdict JSON

```json
{
  "packet_id": "04-verify",
  "status": "done",
  "verdict": "pass",
  "retry_required": false,
  "acs": {
    "success_path": "held",
    "timeout_path_nonzero_bounded": "held",
    "reviewer_sees_artifacts_without_fs_nav": "held"
  },
  "evidence_path": ".workflow/S3-T8/results/verifier-result.md",
  "commands": {
    "test_path_artifact_evidence_bats": true,
    "bash_assertions": "passed=6 failed=0 EXIT:0",
    "bats": "absent_not_installed",
    "sete_direct_print": "SETE_NEST_RC=0 REACHED_AFTER_PRINT body_present",
    "timeout_memory": "rc=1 elapsed=1s after 1s",
    "timeout_candidate": "rc=1 elapsed=2s after 1s"
  },
  "isolation": "pass_real_hermes_absent",
  "queue": "not_marked_done",
  "commit": "not_made"
}
```
