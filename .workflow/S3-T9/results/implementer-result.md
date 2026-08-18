# S3-T9 implementer result

## Status

**done** (pending code-review + skeptic-verify; queue not marked done per instructions)

## Files touched

| File | Rationale |
| --- | --- |
| `scripts/activate_candidate_skill.sh` | Opener-complete gate; copy staged candidate to namespaced live path preserving unverified metadata |
| `scripts/demo_risk_beat.sh` | Label + warning before activation; startup-only new-process follow-up; stub/live modes |
| `tests/risk_beat.bats` | TDD: opener gate, label order, namespaced install, metadata, isolation, persistence |
| `docs/demo-script.md` | Spoken sequence docs including optional honesty beat and layer attribution |
| `.workflow/S3-T9/bash-assertions.sh` | Bash-equivalent mirror (10 assertions) for hosts without bats |
| `.workflow/S3-T9/results/implementer-result.md` | This report |

## Behavior

- **Opener gate:** `crossfire_require_opener_complete` requires `CROSSFIRE_OPENER_COMPLETE=1` or `${CROSSFIRE_RUNS_DIR}/<run_id>/opener-complete.flag` (via `crossfire_mark_opener_complete`).
- **Label + warning:** Printed before `crossfire_activate_candidate_skill` runs.
- **Namespaced live path:** `skills/unverified-<family>-followup/SKILL.md`; `crossfire-interviewer` untouched.
- **Startup-only:** Documents new-process follow-up per `SKILL_LOADING_TIMING=startup-only`.
- **Metadata:** Activated copy is a verbatim staged copy; `status: unverified` enforced.

## Verification

```text
$ bash .workflow/S3-T9/bash-assertions.sh
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
```

bats not installed on this host; bash-equivalent used per task instructions.

## Unresolved

- `demo_session_2.sh` not edited (per scope); callers must `crossfire_mark_opener_complete` before risk beat (documented in `docs/demo-script.md` for future `demo.sh` wiring).
- Live risk beat path (`CROSSFIRE_RISK_BEAT=live`) implemented but not exercised without Hermes in CI.
