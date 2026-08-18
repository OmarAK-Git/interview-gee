# S2-T6 implementer result

**Packet:** `02-implementation` · **Status:** done · **Date:** 2026-08-18

## Summary

Implemented harness-relocated candidate skill staging under `.crossfire/candidate-skills/` with never-write-live exclusion, barrier flag, and snapshot fallback. Session-one finalize hook is **not** wired (out of write scope).

## Files touched

| File | Rationale |
| --- | --- |
| `scripts/stage_candidate_skill.sh` | New staging module: root path, stage one/family, assert live exclusion, barrier flag, snapshot fallback |
| `.crossfire/candidate-skills/.gitkeep` | Preserve empty staging root in git |
| `tests/candidate_skill.bats` | TDD bats for §14 shape, exclusion, isolation, one-per-family, snapshot fallback, optional live |
| `docs/hermes-compatibility.md` | Exclude-candidate row → **verified** (harness staging; never-write-live) |
| `skills/crossfire-interviewer/SKILL.md` | Clarify harness owns staging on finalize; skill still forbids staging |
| `.workflow/S2-T6/bash-assertions.sh` | Bash-equivalent runner (no bats install) |

## Verification

```text
$ wsl.exe -e bash -lc 'cd /mnt/c/Users/oalan/interview-gee && bash .workflow/S2-T6/bash-assertions.sh'
PASS: gitkeep
PASS: assert_live_candidate
PASS: assert_allows_interviewer
PASS: stage_under_candidate_root
PASS: body_no_bad_answer
PASS: barrier_flag
PASS: one_per_family
PASS: snapshot_fallback
PASS: isolation_real_home
PASS: weakness_id_matches_persist
PASS: docs_and_skill
PASS: live_skipped
passed=12 failed=0
```

Optional live probes (`CROSSFIRE_LIVE=1`) not run in this session; bash runner records `live_skipped` when unset.

## JSON

```json
{
  "packet_id": "02-implementation",
  "status": "done",
  "files": [
    "scripts/stage_candidate_skill.sh",
    ".crossfire/candidate-skills/.gitkeep",
    "tests/candidate_skill.bats",
    "docs/hermes-compatibility.md",
    "skills/crossfire-interviewer/SKILL.md"
  ],
  "verification": {
    "command": "bash .workflow/S2-T6/bash-assertions.sh",
    "passed": 12,
    "failed": 0,
    "live_skipped": true
  },
  "chosen_paths": {
    "authorship": "harness-relocated",
    "exclusion": "never-write-live",
    "staging_root": ".crossfire/candidate-skills/"
  }
}
```

## Concerns / follow-ups

1. **`crossfire_session_one_finalize` does not call staging yet** — per packet write set; Task 7+ should invoke `crossfire_stage_candidates_for_run` after persist.
2. **`CROSSFIRE_CANDIDATE_SKILLS_ROOT` env override** — tests isolate staging tree under `TEST_ROOT`; production default remains `${REPO_ROOT}/.crossfire/candidate-skills`.
3. **Windows CRLF** — new shell scripts need LF endings for WSL bash (converted before verify).
4. **`demo_prepare` wipe of prior run candidates** — open from research; not implemented here.
5. **Live exclusion** — researcher evidence stands; optional live bats/assertions require `CROSSFIRE_LIVE=1` + discoverable Hermes.

## Out of scope (unchanged)

- `scripts/demo_session_1.sh` — not edited
- Queue / memory-bank — not edited
- Session-two opener, candidate activation — not implemented

---

## Review retry (03-review blocking_retry)

**Date:** 2026-08-18

### Fixes applied

| Finding | Fix |
| --- | --- |
| **Critical 1** | `crossfire_stage_candidate_skill` and `crossfire_stage_candidates_for_run` now call `crossfire_snapshot_live_candidates_if_any` **before** `crossfire_assert_candidates_excluded_from_live`. New test `stage snapshots live stray then writes staged candidate`. |
| **Important 1** | Removed skip-as-pass (`live_skipped` no longer increments `passed`). Live block uses staged skill **directory** for `--skills`, not `head -1` of mixed stdout. `crossfire_write_candidate_barrier_flag` no longer prints flag path on stdout. Added `live_fail_closed_no_hermes` probe. Docs cite S2-T6 researcher probe evidence. |
| **Important 2** | Tests grep `^source_session_id:` and `^answer_ref:` on staged SKILL.md. |
| **Minor 3** | Distinct before/after temps in `crossfire_candidate_observation_count_from_memory`. |

### Verification (retry)

```text
$ bash .workflow/S2-T6/bash-assertions.sh
PASS: gitkeep
PASS: assert_live_candidate
PASS: assert_allows_interviewer
PASS: stage_under_candidate_root
PASS: body_no_bad_answer
PASS: barrier_flag
PASS: one_per_family
PASS: stage_snapshots_stray_then_stages
PASS: snapshot_fallback
PASS: isolation_real_home
PASS: weakness_id_matches_persist
PASS: docs_and_skill
SKIP: live (set CROSSFIRE_LIVE=1 to run Hermes exclusion probes)
PASS: live_fail_closed_no_hermes
passed=13 failed=0
```

Skip recorded outside `passed`; `CROSSFIRE_LIVE=1` without Hermes fails via `live_fail_closed_no_hermes`.
