# S3-T10 implementer result

## Status

**done** (pending code-review + skeptic-verify; queue not marked done per instructions)

## Files touched

| File | Rationale |
| --- | --- |
| `scripts/demo.sh` | Full-sequence orchestrator: `demo_prepare`, stub/live preflight, session one/two via existing scripts, artifact evidence, layer labels, opener-complete gate, risk beat; early isolation recovery; PATH sanitize for Windows python stub |
| `tests/demo_e2e.bats` | TDD: isolation, prepare scope, full stub smoke, distinct IDs, layer labels, bad-answer gaps, failure recovery, skip-risk-beat |
| `docs/demo-script.md` | `demo.sh` usage, prepare/reset contract, timing evidence, cut policy |
| `.workflow/S3-T10/bash-assertions.sh` | Bash-equivalent mirror (9 assertions) for hosts without bats |
| `.workflow/S3-T10/results/implementer-result.md` | This report |

## Behavior

- **`demo_prepare` / `--prepare`:** Restores only disposable `HERMES_HOME` under `.crossfire/profiles/` plus validated `.crossfire/` run/candidate trees; never touches real `~/.hermes`.
- **Sequence:** preflight → session one (`demo_session_1.sh`) → stage candidates → artifact evidence → session two (`demo_session_2.sh`) in new process with distinct PID → layer attribution → mark opener complete → risk beat (`demo_risk_beat.sh`).
- **Failure:** `DEMO FAIL:` + recovery line (`bash scripts/demo.sh --prepare`); early gate before `demo_common` source for real-profile paths.
- **Stub smoke:** `CROSSFIRE_ASSESSOR=stub`, `CROSSFIRE_OPENER=stub`, `CROSSFIRE_RISK_BEAT=stub`, `CROSSFIRE_HERMES_DISCOVERY=0`.
- **Time cut:** `CROSSFIRE_SKIP_RISK_BEAT=1` skips optional beat only.

## Verification

```text
$ bash .workflow/S3-T10/bash-assertions.sh
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
```

bats not installed on this host; bash-equivalent used per task instructions.

## Timed rehearsal (stub, after pre-warm)

Wall-clock not enforced in bats. Three consecutive stub rehearsals (Git Bash, isolated temp profile):

| Run | elapsed_sec |
| --- | --- |
| 1 | 28 |
| 2 | 28 |
| 3 | 28 |

All well under 90s after pre-warm. Live spoken demo may differ; re-measure with `CROSSFIRE_LIVE=1` on stage profile.

## Unresolved

- None within S3-T10 write scope. Session scripts unchanged; `demo.sh` calls them only.
