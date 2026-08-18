# S3-T8 code review (re-review) — Artifact evidence and bounded waits

**Packet:** `02-implementation` (no `03-review.md` in run dir; reviewed against that packet + queue item + prior `code-reviewer-result.md`)
**Reviewer:** code-reviewer (did not author the fix; did not implement, commit, or mark the queue done)
**Date:** 2026-08-18
**Kind:** scoped re-review of prior Critical (`printf ---` banner under sourced `set -e`)
**Scope:** `scripts/demo_common.sh` artifact helpers; confirm S2 helpers still present (`CROSSFIRE_RUNS_DIR` override, YAML extract, newest-weakness); `tests/artifact_evidence.bats`; `.workflow/S3-T8/bash-assertions.sh` as test evidence only.
**Spec / plan:** `sparring-1.0.0` §7 step 4 (show MEMORY.md weakness-block diff + staged candidate SKILL.md); plan Task 8; packet: before-snapshot, relevant diff only, candidate print, bounded timeout with **nonzero** status, never wait indefinitely, isolation fail-closed.

**Verdict:** `approve`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 0 |
| Minor | 0 |
| Blocking | 0 |

**Retry:** no

**Prior Critical:** **ADDRESSED**
**New blocking count:** **0**

---

## Prior Critical 1 — `printf '--- …'` aborts sourced `set -e` before SKILL.md body — **ADDRESSED**

`scripts/demo_common.sh:818` is now:

```bash
printf '%s\n' '--- candidate SKILL.md ---'
cat "$skill_path"
```

No remaining `printf '--- …'` in product scripts. Git Bash still rejects the old form (`OLD_PRINTF_RC=2`, `printf: --: invalid option`); the `%s` form is `NEW_PRINTF_RC=0`.

Independent probe (disposable `HERMES_HOME=/tmp/crossfire-s3t8-rereview.*/.crossfire/profiles/test`, never real `~/.hermes`, Git Bash, nested `bash -c` with `set -euo pipefail`, **direct call** not `$(…)`):

| Check | Result |
| --- | --- |
| `SHELLOPTS` contains `errexit` / `ERREXIT=yes` | yes |
| Weakness-block unified diff printed | yes |
| Frontmatter grep (`status: unverified`, `candidate_path=`) | yes |
| Banner `--- candidate SKILL.md ---` | yes (in helper stdout) |
| `Do not praise or imitate` / SKILL.md body | **present** |
| `AFTER_PRINT` / `REACHED_AFTER_PRINT` | **reached** |
| `printf: --: invalid option` in helper output | **absent** |
| Process exit | **0** |
| Fixture prose `Personal Memory` / `favorite prompt` | absent |
| Labeled diff headers (`memory-before (weakness block)`) | present |

---

## Prior Important 1 — Success tests cannot catch Critical 1 — **ADDRESSED**

- Success assertions require SKILL.md body (`Do not praise or imitate`) and forbid fixture prose (`Personal Memory`, `favorite prompt`): `tests/artifact_evidence.bats:89-91`, `.workflow/S3-T8/bash-assertions.sh:98-100`.
- Sourced `set -e` direct invocation (not `run` / `$(…)`): bash-assertions `sete_direct_print` (`:106-164`) nested `bash -c` with `set -euo pipefail`, asserts rc=0, body, banner, `REACHED_AFTER_PRINT`, and absence of `printf: --: invalid option`.
- Bats `artifact evidence direct set -e call prints full SKILL.md body` (`:94-104`) calls the helper directly (not `run`) and forbids the Git Bash printf error.

Independent `bash .workflow/S3-T8/bash-assertions.sh` → `passed=6 failed=0` **after** the printf fix (includes `sete_direct_print`).

---

## Prior Minor 1 / Minor 2 — **ADDRESSED** (non-blocking)

- Success path now negative-asserts fixture prose (relevant-diff-only lock). Independent probe `HAS_PERSONAL_MEMORY=0`, `HAS_FAVORITE=0`.
- `diff -u --label 'memory-before (weakness block)' --label 'memory-after (weakness block)'` (`scripts/demo_common.sh:796-797`). Probe headers match; no mktemp paths in the printed diff.

---

## Spec / plan / packet checks

| Requirement | Result |
| --- | --- |
| Before-snapshot of MEMORY.md | Met. `crossfire_snapshot_memory_md_before` (`:667-681`) copies to `CROSSFIRE_RUNS_DIR/<run_id>/memory-before.md`. |
| Print only the relevant weakness-block diff | Met. Block extract + labeled `diff -u`. Locked by negative fixture asserts + independent probe. |
| Print candidate skill + metadata under `.crossfire/candidate-skills/` | **Met on sourced `set -e` direct call** (prior Critical ADDRESSED). Metadata + full body `cat`. |
| Timeout missing artifact: nonzero + useful message; never wait indefinitely | Met. `crossfire_wait_for_artifact` (`:756-775`) polls then `return 1`. bash-assertions `timeout_memory` / `timeout_candidate` pass. |
| Isolation fail-closed | Met. Snapshot + orchestrator call `crossfire_require_isolated_hermes_home`. Isolation test + assertions: rc≠0, `HERMES_HOME points at real profile`. |
| Files allowed | Met. Product writes: `demo_common.sh` + `artifact_evidence.bats`. `bash-assertions.sh` allowed as optional. `demo.sh` / risk beat not implemented. |
| S2: `CROSSFIRE_RUNS_DIR` override | **Present.** `:232`. Probe: `S2_OVERRIDE=yes`. |
| S2: YAML extract | **Present.** `crossfire_extract_yaml_from_live_stdout`. Probe: `YAML_EXTRACT=present`. |
| S2: newest-weakness | **Present.** `crossfire_select_newest_weakness`. Probe: `NEWEST_WEAKNESS=present`. |

---

## Isolation

No product write under real `~/.hermes`. Windows `%USERPROFILE%\.hermes` **absent** before and after independent probe and bash-assertions. Probes used `/tmp/crossfire-s3t8-rereview.*` / `/tmp/crossfire-ae-*` only. Did not install bats. Did not mutate git state or the queue (`S3-T8` remains `in_progress`).

---

## Checks run

- Read packet `02-implementation.md`, plan Task 8, spec §7 step 4, queue S3-T8, implementer retry note, prior blocking review, `demo_common.sh` artifact section + S2 helpers, `tests/artifact_evidence.bats`, bash-assertions.
- Confirmed `scripts/demo_common.sh:818` uses `printf '%s\n' '--- candidate SKILL.md ---'`; grepped product scripts for remaining `printf '---`.
- Independent Git Bash: bare `printf '---…'` → rc=2; `printf '%s\n' '---…'` → rc=0; sourced `set -e` **direct** `crossfire_print_artifact_evidence` → rc=0, skill body present, `REACHED_AFTER_PRINT`, no printf-options error.
- `bash .workflow/S3-T8/bash-assertions.sh` → `passed=6 failed=0` (Git Bash).

```json
{
  "packet_id": "03-review",
  "status": "done",
  "verdict": "approve",
  "retry_required": false,
  "prior_critical": "ADDRESSED",
  "new_blocking_count": 0,
  "findings": {
    "critical": 0,
    "important": 0,
    "minor": 0
  },
  "blocking_count": 0,
  "isolation": "pass_real_hermes",
  "blocking": "none",
  "s2_helpers": {
    "CROSSFIRE_RUNS_DIR_override": "present",
    "crossfire_extract_yaml_from_live_stdout": "present",
    "crossfire_select_newest_weakness": "present"
  },
  "items": []
}
```
