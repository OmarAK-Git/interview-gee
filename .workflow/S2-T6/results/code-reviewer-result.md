# S2-T6 code review (retry)

**Packet:** `03-review` (re-review after `blocking_retry`)  
**Reviewer:** code-reviewer (did not author the fix; did not implement, commit, dispatch subagents, or mark the queue done)  
**Date:** 2026-08-18  
**Prior:** `.workflow/S2-T6/results/code-reviewer-result.md` (`blocking_retry`, Critical 1 + Important 1–2)  
**Scope:** Re-read `scripts/stage_candidate_skill.sh`, `tests/candidate_skill.bats`, `docs/hermes-compatibility.md`; independent stray-live probe on disposable `HERMES_HOME` only. Spec `sparring-1.0.0` §8 / §13 / §14; plan Task 6; packet blocking list.  
**Ruling honored:** `scripts/demo_session_1.sh` finalize not hooked is not a defect.

**Verdict:** `approve`

---

## Prior findings

### Critical 1 — Stage asserts live exclusion before snapshot — **ADDRESSED**

**Was:** `crossfire_stage_candidate_skill` and `crossfire_stage_candidates_for_run` asserted first, so a stray live candidate aborted staging and stayed loadable. Tests never staged while a leftover existed.

**Now:** both entry points snapshot then assert:

- `scripts/stage_candidate_skill.sh:291-292` (`crossfire_stage_candidate_skill`)
- `scripts/stage_candidate_skill.sh:352-353` (`crossfire_stage_candidates_for_run`)

New coverage: `tests/candidate_skill.bats:129-148` and `.workflow/S2-T6/bash-assertions.sh:128-149` (`stage_snapshots_stray_then_stages`).

**Independent probe** (WSL, `HERMES_HOME=/tmp/crossfire-s2t6-rereview.*/.crossfire/profiles/test`, never real `~/.hermes`): planted `$HERMES_SKILLS_DIR/unverified-behavioral-followup/SKILL.md`, called stage.

| Check | `crossfire_stage_candidate_skill` | `crossfire_stage_candidates_for_run` (spool present) |
| --- | --- | --- |
| rc | 0 | 0 |
| live `SKILL.md` remains | **no** | **no** |
| snapshotted under `live-skill-snapshot/` | **yes** | **yes** |
| staged candidate written | **yes** | **yes** |
| stdout | staged `SKILL.md` path | staged `SKILL.md` path only |

---

### Important 1 — Skip counted as exclusion pass; `--skills` would hit barrier flag — **ADDRESSED**

**Was:** `ok live_skipped` incremented `passed`; `crossfire_write_candidate_barrier_flag` printed the flag path on stdout before staged paths; optional live `--skills` used `head -1` of that mix; exclude-candidate row **verified** without citing researcher live evidence.

**Now:**

1. `.workflow/S2-T6/bash-assertions.sh:219-221` prints `SKIP: live` and does **not** call `ok`. `passed=13` does not include the skip. `CROSSFIRE_LIVE=1` with undiscoverable Hermes fail-closes (`:223-229` `live_fail_closed_no_hermes`; probe `PROBE4_LIVE_FAIL_CLOSED_RC=1`). Bats optional live tests still `skip` when unset — that is not counted as exclusion proof.
2. Barrier writer (`scripts/stage_candidate_skill.sh:180-196`) writes the flag file only; `crossfire_stage_candidates_for_run` stdout is staged paths (`:371`). Probe: `PROBE2_FLAG_IN_STDOUT=no`, `PROBE2_HEAD1_IS_STAGED=yes`. Live `--skills` uses the staged **directory** (`tests/candidate_skill.bats:215-220`; bash-assertions `:201`).
3. `docs/hermes-compatibility.md:70` **verified** cites S2-T6 researcher probe (`hermes skills list` absent + `--skills` → `Unknown skill(s)`) plus harness never-write-live / snapshot-before-assert — not the skip.

---

### Important 2 — Tests never assert §14 `source_session_id` / `answer_ref` — **ADDRESSED**

**Was:** stage assertions checked id/status/weakness_id/observation_count/missing_elements only; dropping the two session provenance fields would still pass.

**Now:** greps on the produced file:

- `tests/candidate_skill.bats:89-90`, `:103-104`, `:146-147`
- `.workflow/S2-T6/bash-assertions.sh:85-86`, `:99-100`, `:144-145`

Independent spool → `crossfire_stage_candidates_for_run` frontmatter:

```text
id: crossfire.candidate.behavioral
name: unverified-behavioral-followup
status: unverified
weakness_id: w-847d45c82e2b
source_session_id: sess_stub
answer_ref: run_probe2/q_behavioral_01/0
observation_count: 1
```

`PROBE2_SOURCE_SESSION_ID=yes`, `PROBE2_ANSWER_REF=yes`, `PROBE2_BAD_ANSWER_IN_BODY=no`.

---

## New Critical / Important in the fix

None. New blocking count: **0**.

Prior Minor 1 (second persist-eligible spool fail-closes instead of patch) and Minor 2 (behavioral n>1 always action+result) remain as previously recorded; they are not blocking for this packet. Prior Minor 3 (shared tempfile) was fixed with distinct `before`/`after` temps (`scripts/stage_candidate_skill.sh:111-115`) and is not re-opened.

---

## Spec / locked-path compliance (non-findings)

| Requirement | Result |
| --- | --- |
| Harness-relocated authorship | Unchanged: harness writes §14 YAML; skill still forbids staging. |
| never-write-live | Dest refuse under `$HERMES_SKILLS_DIR` (`:298-300`); probe live remaining **no**. Snapshot-then-assert is fallback. |
| Staging layout | `.crossfire/candidate-skills/unverified-<family>-followup/SKILL.md`. |
| §14 body not a model answer | Probe `PROBE2_BAD_ANSWER_IN_BODY=no`. |
| Barrier flag | Written on `stage_candidates_for_run`; not mixed into stdout. |
| Isolation fail-closed | Probe `HERMES_HOME=/home/fish/.hermes` → `PROBE3_ISO_RC=1`. |
| Skip as exclusion proof | Not treated as pass. |
| Finalize hook | Still out of write set — not a defect. |

---

## Isolation check

**Pass for real `~/.hermes`.** Probe used only disposable `HERMES_HOME` under `/tmp/crossfire-s2t6-rereview.*/.crossfire/profiles/`. WSL `/home/fish/.hermes` mtime:size `1786910797:4096` unchanged before/after. Windows `%USERPROFILE%\.hermes` absent. Did not install bats.

---

## Checks run

- Re-read prior `blocking_retry` result, packet `03-review`, `stage_candidate_skill.sh`, `candidate_skill.bats`, `hermes-compatibility.md`, bash-assertions, researcher locked paths.
- Independent WSL probes: plant stray → both stage entry points; stdout is staged path not flag; provenance fields; isolation fail-closed; `CROSSFIRE_LIVE=1` without Hermes fail-closed; real-home snapshot.
- `bash .workflow/S2-T6/bash-assertions.sh` → `passed=13 failed=0` with `SKIP: live` outside `passed`.

---

```json
{
  "packet_id": "03-review",
  "verdict": "approve",
  "retry_required": false,
  "prior_findings": {
    "critical_1": "ADDRESSED",
    "important_1": "ADDRESSED",
    "important_2": "ADDRESSED"
  },
  "findings": {
    "critical": 0,
    "important": 0,
    "minor": 0
  },
  "blocking_count": 0,
  "new_blocking_count": 0,
  "isolation": "pass_real_hermes",
  "blocking": ""
}
```
