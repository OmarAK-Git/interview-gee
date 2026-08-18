# S3-T9 code review — Labeled unverified-learning risk beat

**Packet:** `02-implementation` (no `03-review.md` in run dir; reviewed against that packet + queue S3-T9 + spec/plan)
**Reviewer:** code-reviewer (did not author this; did not implement, commit, or mark the queue done)
**Date:** 2026-08-18
**Scope:** `scripts/activate_candidate_skill.sh`, `scripts/demo_risk_beat.sh`, `tests/risk_beat.bats`, `docs/demo-script.md`. `.workflow/S3-T9/bash-assertions.sh` as test evidence only. `demo_session_2.sh` / `demo_common.sh` / `stage_candidate_skill.sh` checked for blast radius only (not in T9 allowed files; T9 did not edit them).
**Spec / plan:** `sparring-1.0.0` §7 item 7 (optional honesty beat), §14 (candidate lives in staging until after opener; activation after opener; unverified metadata; missing-elements follow-up). Plan Task 9. Packet: TDD; namespaced live path; startup-only new process; isolation fail-closed.

**Blocking if:** activation can precede opener; label/warning missing before influence; candidate replaces stable `crossfire-interviewer`; isolation not fail-closed.

**Verdict:** `approve`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 0 |
| Minor | 3 |
| Blocking | 0 |

**Retry:** no

---

## Blocking criteria

| Criterion | Result | Evidence |
| --- | --- | --- |
| Activation cannot precede opener | **Met** | `crossfire_require_opener_complete` (`scripts/activate_candidate_skill.sh:30-46`) fail-closes unless `CROSSFIRE_OPENER_COMPLETE=1` or `CROSSFIRE_RUNS_DIR/<run_id>/opener-complete.flag`. `crossfire_activate_candidate_skill` (`:85`) and `crossfire_risk_beat_main` (`scripts/demo_risk_beat.sh:118`) both call it before copy. Bats `activation fails before opener completes` (`tests/risk_beat.bats:69-76`) asserts rc≠0, `opener not complete`, and no live `unverified-behavioral-followup/SKILL.md`. |
| Label + warning before influence | **Met** | `crossfire_print_risk_beat_label` (`scripts/demo_risk_beat.sh:16-18`, `:124`) runs before `crossfire_activate_candidate_skill` (`:126`). Label `UNVERIFIED LEARNING RISK DEMO`; warning states unverified + trained on a bad answer. Bats `risk beat prints label and warning before candidate influence` (`:78-92`) requires label line number **<** `candidate_live_path=` and `WARNING:` + `unverified` present. Independent Git Bash assertions: `label_warning_before_influence` PASS. |
| Candidate does not replace `crossfire-interviewer` | **Met** | Live path is `unverified-<family>-followup` via `crossfire_candidate_skill_dir_name` (`scripts/stage_candidate_skill.sh:19-22`; family validated). Activate refuse-case (`scripts/activate_candidate_skill.sh:93-97`) plus restore of interviewer if missing (`:109-111`). Bats `candidate installs to namespaced live path not crossfire-interviewer` (`:94-105`): live path contains `/skills/unverified-behavioral-followup/SKILL.md`, interviewer `SKILL.md` still present, live path not under `/crossfire-interviewer/`. |
| Isolation fail-closed | **Met** | Activate and risk-beat mains call `crossfire_require_isolated_hermes_home` before writes (`activate:84`, `demo_risk_beat.sh:117`). Sourcing `demo_common.sh` fail-closes real `HERMES_HOME`. Bats `isolation fail-closed when HERMES_HOME is real profile path` (`:57-67`): rc≠0 + `HERMES_HOME points at real profile`. Independent probe: `ISO_RC=1`, message present, `SHOULD_NOT_REACH` absent. Windows `%USERPROFILE%\.hermes` **absent** before/after. |

---

## Spec / plan / packet checks

| Requirement | Result |
| --- | --- |
| §7 item 7: load unverified candidate after opener; show it shaping a follow-up | Met in stub: copy to live dir after opener gate, then follow-up sentence from skill `missing_elements` (`scripts/demo_risk_beat.sh:43-48`, `:135`). Optional/cuttable documented in `docs/demo-script.md`. |
| §14: staged outside live dir until after opener | Met. Activate blocked without opener complete; no live file in before-opener test. |
| §14: `status: unverified` + provenance; do not treat bad answer as model | Met. Verbatim staged copy; post-copy greps for `status: unverified` and `name: unverified-` (`activate:104-107`). Bats metadata test greps id/name/status/weakness_id/source_session_id/answer_ref/observation_count and `Do not praise or imitate`. |
| §14 activation test: after opener, next question requests missing elements | Met in stub (`Follow-up:` + action/result). Live Hermes path implemented, not CI-exercised (documented). |
| Namespaced live path, not replacing interviewer | Met (see blocking table). |
| New process if startup-only | Met as documented-fallback: message + `( ) &` child (`scripts/demo_risk_beat.sh:89-109`, `:131-135`). See Minor 2 for test/`$$` weakness. |
| Candidate persists after beat unless cleaned up | Met. Bats `activated candidate remains available after risk beat` (`:146-154`). |
| Files allowed | Met. Product: the four allowed files. Optional `bash-assertions.sh` + implementer result. `demo_session_2.sh` not edited (no risk-beat/opener-complete symbols). |
| Never real `~/.hermes` | Met. Isolation fail-closed on activate/risk-beat. Assertions and probe used disposable `.crossfire/profiles/test` only. |

`CROSSFIRE_OPENER_COMPLETE=1` is an explicit caller attestation equivalent to writing the flag file (`docs/demo-script.md:41-46`). Session two does not call activate; the env var does not load the candidate during the opener. Not treated as a bypass of the gate.

---

## Minor (track, not blocking)

### Minor 1 — Namespaced test does not lock interviewer *content*

`tests/risk_beat.bats:103` and bash-assertions `namespaced_live_path` only require interviewer `SKILL.md` to **exist**. A regression that overwrote that file with candidate text and also wrote the namespaced path would still pass. Product does not overwrite (`activate:90-97`, dir name `unverified-<family>-followup`). **Fix if tightening:** cksum or grep that interviewer still matches repo `skills/crossfire-interviewer/SKILL.md` and lacks `id: crossfire.candidate.`.

### Minor 2 — “New process” test is string-only; child PID uses `$$`

`tests/risk_beat.bats:123-133` asserts stdout contains `startup-only`, `new process`, and `CROSSFIRE_RISK_BEAT_PID=`. Those strings are printed by the parent (`demo_risk_beat.sh:131-133`) even if follow-up ran in-process. Product does fork `( ) &` (`:89-109`). In bash, `$$` inside that subshell is still the parent PID, so `CROSSFIRE_RISK_BEAT_CHILD_PID=$$` (`:103`) is not a distinct-PID proof. **Fix if tightening:** assert `BASHPID` ≠ parent, or that `CROSSFIRE_RISK_BEAT_CHILD_PID` differs from `CROSSFIRE_RISK_BEAT_PID`.

### Minor 3 — Direct activate CLI has no label; metadata fail-closed is after `mv`

`scripts/activate_candidate_skill.sh:116-118` (script entry) copies to live without printing `UNVERIFIED LEARNING RISK DEMO` / `WARNING:`. Spec §7 item 7 influence is the honesty beat; `demo_risk_beat.sh` prints both before activate — locked by bats. Direct CLI is a helper. Also, unverified greps (`activate:104-107`) run **after** `mv` (`:102`); a malformed staged copy can remain live while the function fail-closes. Re-running session two would then hit `crossfire_assert_candidates_excluded_from_live`. **Fix if tightening:** print the beat label in the CLI path, or validate staged frontmatter before `mv`.

---

## Tests vs behavior

Required packet locks actually exercise behavior (not source greps of success strings):

- Before-opener: invoke activate, assert nonzero + no live file.
- Label order: run `demo_risk_beat.sh`, compare line numbers.
- Isolation: invoke `crossfire_require_isolated_hermes_home` against `/home/fish/.hermes`, assert rc≠0 (bats) + message.
- Namespaced path + unverified metadata: inspect files on disk.

bash-assertions isolation checks the message only (not rc); bats covers rc. Not blocking.

Live `CROSSFIRE_RISK_BEAT=live` / comma-separated `--skills` (`demo_risk_beat.sh:62`) is untested without Hermes — same limitation the implementer recorded; stub beat is the CI proof.

---

## Isolation

No product write under real `~/.hermes`. Assertions used `HERMES_HOME` under disposable `.crossfire/profiles/test`. Independent isolation child: `ISO_RC=1`, `HERMES_HOME points at real profile`, `SHOULD_NOT_REACH` absent. Windows `%USERPROFILE%\.hermes` absent. Did not install bats. Did not mutate git state or the queue (`S3-T9` remains `in_progress`).

---

## Checks run

- Read packet `02-implementation.md`, plan Task 9, spec §7 item 7 / §14 / §15 skill-reload fallback, queue S3-T9, implementer result, the four product files, `stage_candidate_skill.sh` dir-name helper, `demo_session_2.sh` (no activate/mark-opener; not edited).
- Confirmed T9 product files are new/untracked allowed paths; `demo_common.sh` dirty diff is prior S2/S3-T8 helpers, not T9.
- `bash .workflow/S3-T9/bash-assertions.sh` (Git Bash) → `passed=10 failed=0`.
- Independent isolation child against `/home/fish/.hermes` → nonzero, fail-closed message, no continue.

```json
{
  "packet_id": "03-review",
  "status": "done",
  "verdict": "approve",
  "retry_required": false,
  "findings": {
    "critical": 0,
    "important": 0,
    "minor": 3
  },
  "blocking_count": 0,
  "isolation": "pass_real_hermes",
  "blocking": "none",
  "items": [
    {
      "priority": "minor",
      "id": "interviewer_content_not_locked",
      "file": "tests/risk_beat.bats",
      "line": 103
    },
    {
      "priority": "minor",
      "id": "new_process_string_only",
      "file": "tests/risk_beat.bats",
      "line": 123
    },
    {
      "priority": "minor",
      "id": "cli_activate_no_label_validate_after_mv",
      "file": "scripts/activate_candidate_skill.sh",
      "line": 104
    }
  ]
}
```
