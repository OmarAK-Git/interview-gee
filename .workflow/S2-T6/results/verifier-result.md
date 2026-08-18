# S2-T6 skeptic-verifier result

**Verdict: pass**

Task-scoped. Treated implementation claims as unevidenced. Did not use `implementer-result.md` as evidence. Ignored session-two opener and risk-beat gaps. Did not mark the queue done. Did not commit. Did not install packages. Did not write real `~/.hermes`.

`bats` is absent (`Get-Command bats` empty; WSL `command -v bats` → `BATS_MISSING`). Re-ran `.workflow/S2-T6/bash-assertions.sh` plus an independent WSL stray-plant under a disposable `HERMES_HOME`. Existence checks alone are not a pass.

---

## Claim restated

S2-T6 is done: a poor answer produces a visible provenance-linked candidate `SKILL.md` that is not loadable before session two; `scripts/stage_candidate_skill.sh`, `tests/candidate_skill.bats`, and `.crossfire/candidate-skills/.gitkeep` exist; isolation fail-closes; live Hermes skip is not counted as pass.

---

## 1. Existence (Test-Path)

Cwd: `C:\Users\oalan\interview-gee`

```
Test-Path -LiteralPath scripts\stage_candidate_skill.sh -PathType Leaf
True
Test-Path -LiteralPath tests\candidate_skill.bats -PathType Leaf
True
Test-Path -LiteralPath .crossfire\candidate-skills\.gitkeep -PathType Leaf
True
```

`.gitkeep` is a 0-byte leaf. Existence alone is not a pass.

---

## 2. Bash-equivalent (bats missing)

Command:

```
wsl.exe -e bash -lc 'cd /mnt/c/Users/oalan/interview-gee && bash .workflow/S2-T6/bash-assertions.sh; echo EXIT:$?'
```

Fresh output:

```
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
EXIT:0
```

Coverage mapped to required behaviors:

| Required | Check | Result |
| --- | --- | --- |
| Staging under `.crossfire/candidate-skills/`, never live | `stage_under_candidate_root` | PASS |
| §14 provenance including `source_session_id` and `answer_ref` | `stage_under_candidate_root`, `body_no_bad_answer` | PASS |
| Live exclusion assert fail-closed when candidate is live | `assert_live_candidate` | PASS |
| Snapshot-then-assert when a stray live candidate exists | `stage_snapshots_stray_then_stages`, `snapshot_fallback` | PASS |
| Isolation fail-closed on real `HERMES_HOME` | `isolation_real_home` | PASS |
| Skip is not a pass | `SKIP: live` echoed; `passed` not incremented | confirmed |
| `CROSSFIRE_LIVE=1` without Hermes fails closed | `live_fail_closed_no_hermes` | PASS |

Skip counting: `bash-assertions.sh` live branch only `echo`s `SKIP` (does not call `ok`). Optional live probes (`live_list_excludes`, `live_unknown_skill`) were not run. `passed=13` equals the twelve non-live `ok()` paths plus `live_fail_closed_no_hermes`. If skip were counted as pass, `passed` would be 14 or 15.

---

## 3. Independent stray plant (disposable HERMES_HOME)

Not the bash-assertions helper. Script: `/tmp/s2t6-ind.sh` (copied from `%TEMP%\s2t6-ind.sh`, CRLF stripped). Disposable tree: `/tmp/s2t6-ind.UkbTb2/.crossfire/profiles/verify` — not real `~/.hermes`.

Planted `${HERMES_SKILLS_DIR}/unverified-behavioral-followup/SKILL.md` with `id: crossfire.candidate.behavioral` and body marker `STRAY_MARKER_S2T6_INDEPENDENT`. Then called product `crossfire_stage_candidate_skill`.

```
HERMES_HOME=/tmp/s2t6-ind.UkbTb2/.crossfire/profiles/verify
HERMES_SKILLS_DIR=/tmp/s2t6-ind.UkbTb2/.crossfire/profiles/verify/skills
ISOLATED_OK=yes
BEFORE_LIVE=EXISTS
STAGE_RC=0
STAGED=/tmp/s2t6-ind.UkbTb2/.crossfire/candidate-skills/unverified-behavioral-followup/SKILL.md
AFTER_LIVE_SKILL=MISSING
AFTER_LIVE_DIR=MISSING
SNAPSHOT=EXISTS
SNAPSHOT_HAS_STRAY=yes
STAGED_CLEAN=yes
```

Staged frontmatter (product renderer, not fixture copy):

```
id: crossfire.candidate.behavioral
name: unverified-behavioral-followup
status: unverified
weakness_id: w-deadbeeffeed
source_session_id: sess_ind
answer_ref: run_independent_stray/q_behavioral_01/0
observation_count: 1
target_family: behavioral
missing_elements: [action,result]
```

Body includes `Do not praise or imitate the recorded answer`. Snapshot retained the stray marker; staged file did not. Stage succeeding while a live candidate existed implies snapshot ran before `crossfire_assert_candidates_excluded_from_live` (assert-first would fail-closed).

Independent isolation / live fail-closed (same probe):

```
ISOLATION_RC=1
ISOLATION_FAIL_CLOSED=ok
LIVE_FC_RC=1
LIVE_FC_OUT=PREFLIGHT FAIL: CROSSFIRE_LIVE=1 but Hermes binary not discoverable (CROSSFIRE_HERMES_DISCOVERY=0)
LIVE_FAIL_CLOSED=ok
```

Temp tree removed (`CLEANED_TEST_ROOT=yes`).

---

## 4. Isolation: never real `~/.hermes`

| Check | Result |
| --- | --- |
| Windows `%USERPROFILE%\.hermes` | `Test-Path` False (before and after) |
| WSL `/mnt/c/Users/oalan/.hermes` | `WIN_HERMES_IN_WSL=ABSENT` |
| WSL `/home/fish/.hermes/skills` unverified-* count | before=0 after=0 |
| WSL `/home/fish/.hermes/skills` mtime | `1786910797` unchanged |
| Repo `.crossfire/profiles/test/skills` | bundled dirs + `crossfire-interviewer` only; no `unverified-*` |
| Repo `.crossfire/candidate-skills/` | `.gitkeep` only |

Tests used `HERMES_HOME` under `.crossfire/profiles/` inside `mktemp`. Isolation source-path fail-closed was re-run against `/home/fish/.hermes`.

---

## Spec §8 / §13 / §14 (product files read)

- §8: harness owns `.crossfire/candidate-skills/`. `skills/crossfire-interviewer/SKILL.md` forbids staging (`Do **not** stage candidate skills`; harness owns `scripts/stage_candidate_skill.sh`).
- §13 candidate barrier: `crossfire_assert_candidates_excluded_from_live` + `.crossfire/runs/<run_id>/candidate-excluded.flag` (`barrier_flag` PASS). Session-two launcher not in scope.
- §14 fields present on staged `SKILL.md`: `id`, `name`, `status: unverified`, `weakness_id`, `source_session_id`, `answer_ref`, `observation_count`, `target_family`, `missing_elements`. Body is checklist + follow-up template; submitted bad-answer text absent (`body_no_bad_answer`). One candidate per family (`one_per_family` fail-closed). Exclusion possible, so degraded-path AC is not triggered; `docs/hermes-compatibility.md` exclude-candidate row is **verified** (never-write-live + snapshot-before-assert).

---

## AC mapping

| AC | Status | Evidence |
| --- | --- | --- |
| A poor answer produces a visible provenance-linked candidate SKILL.md | **held** | `body_no_bad_answer` + `stage_under_candidate_root` + independent staged frontmatter (`source_session_id`, `answer_ref`) |
| A pre-session-two assertion proves it is not loadable | **held** | live assert fail-closed; stage never writes `$HERMES_SKILLS_DIR`; independent plant removed from live dir; barrier flag. Optional Hermes `skills list` SKIP not counted as pass |
| If exclusion is impossible, the degraded path is recorded | **held** | Exclusion is possible (never-write-live + snapshot fallback verified this run). Compatibility row remains **verified**, not degraded |

---

## Refutations attempted (did not stick)

- Existence-only pass: rejected; behavioral bash-equivalent + independent plant required and run.
- Skip-as-pass: rejected; `SKIP: live` did not increment `passed`.
- Snapshot claimed but not executed: rejected; independent stray gone from live, present in `live-skill-snapshot` with original marker.
- Isolation theater: rejected; real-home source fail-closes; disposable `HERMES_HOME` only; real skills mtime unchanged.
- Live Hermes list as the only “not loadable” proof: optional probes skipped and not counted as pass. Harness assert + absent live file is the S2-T6 barrier; opener/Hermes-list gaps ignored per packet.

Non-blocking (out of packet): `demo_session_1.sh` finalize hook not in `files_allowed`; bats not installed.

---

## Commands run

```
Test-Path -LiteralPath scripts\stage_candidate_skill.sh -PathType Leaf   # True
Test-Path -LiteralPath tests\candidate_skill.bats -PathType Leaf         # True
Test-Path -LiteralPath .crossfire\candidate-skills\.gitkeep -PathType Leaf  # True
wsl.exe -e bash -lc '... bash .workflow/S2-T6/bash-assertions.sh'        # passed=13 failed=0 EXIT:0
wsl.exe -e bash -lc 'tr -d \\r < .../s2t6-ind.sh > /tmp/s2t6-ind.sh && bash /tmp/s2t6-ind.sh'
# bats: not installed
# hermes chat/skills list: not invoked (CROSSFIRE_LIVE unset; skip not pass)
```

---

## Strongest reason it survives

Independent plant under disposable `HERMES_HOME=/tmp/s2t6-ind.UkbTb2/.crossfire/profiles/verify` showed `BEFORE_LIVE=EXISTS` → `STAGE_RC=0` → `AFTER_LIVE_SKILL=MISSING` with §14 `source_session_id`/`answer_ref` on the staged file; bash-equivalent `passed=13 failed=0` with live SKIP uncounted.

---

## Machine-readable

```json
{
  "packet_id": "04-verify",
  "task": "S2-T6",
  "verdict": "pass",
  "claim": "survives",
  "acs_held": [
    "poor answer produces visible provenance-linked candidate SKILL.md",
    "pre-session-two assertion proves not loadable",
    "exclusion possible; degraded path not required"
  ],
  "acs_failed": [],
  "evidence_path": ".workflow/S2-T6/results/verifier-result.md",
  "commands": {
    "test_path_stage": true,
    "test_path_bats": true,
    "test_path_gitkeep": true,
    "bash_assertions": "passed=13 failed=0",
    "independent_stray": "AFTER_LIVE_SKILL=MISSING STAGE_RC=0",
    "skip_counted_as_pass": false,
    "live_fail_closed_no_hermes": true,
    "isolation_fail_closed": true,
    "bats": "absent"
  },
  "queue_marked_done": false,
  "committed": false
}
```
