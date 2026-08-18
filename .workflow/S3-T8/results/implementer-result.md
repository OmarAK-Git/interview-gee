# S3-T8 implementer result

## Status

**done** (pending code-review + skeptic-verify)

## Files touched

| File | Rationale |
| --- | --- |
| `scripts/demo_common.sh` | Added artifact-evidence helpers: before-snapshot, bounded wait, weakness-block diff print, staged candidate print |
| `tests/artifact_evidence.bats` | TDD bats: success path, timeout paths (memory + candidate), isolation fail-closed |
| `.workflow/S3-T8/bash-assertions.sh` | Bash-equivalent mirror for environments without bats |
| `.workflow/S3-T8/results/implementer-result.md` | This report |

## Helpers added (demo_common.sh)

- `crossfire_snapshot_memory_md_before` — run-scoped `memory-before.md` under `CROSSFIRE_RUNS_DIR/<run_id>/`
- `crossfire_wait_for_artifact` — bounded poll (`CROSSFIRE_ARTIFACT_TIMEOUT_SEC` default 8s, `CROSSFIRE_ARTIFACT_POLL_SEC` 0.2s)
- `crossfire_print_weakness_block_diff` — unified diff of delimited weakness block only
- `crossfire_print_candidate_artifact` — prints `candidate_path=` + frontmatter metadata + full SKILL.md
- `crossfire_print_artifact_evidence` — orchestrator: wait for block change + run-scoped candidate, then print both

Existing helpers preserved (CROSSFIRE_RUNS_DIR override, YAML extract, newest-weakness select).

## Verification

```text
$ bash .workflow/S3-T8/bash-assertions.sh
PASS: snapshot_before
PASS: success_evidence
PASS: timeout_memory
PASS: timeout_candidate
PASS: isolation_fail_closed
passed=5 failed=0
```

bats not installed on this host; bash-equivalent used per task instructions.

## Unresolved

- None within S3-T8 scope. `demo.sh` / risk beat intentionally not implemented.

---

## Code-review retry (2026-08-18)

**Critical fixed:** `crossfire_print_candidate_artifact` banner now uses `printf '%s\n' '--- candidate SKILL.md ---'` so Git Bash does not treat `---` as options under sourced `set -e`.

**Important fixed:** Added sourced `set -e` direct-call test (`sete_direct_print` in bash-assertions; bats `artifact evidence direct set -e call prints full SKILL.md body`). Success assertions now require SKILL.md body (`Do not praise or imitate`) and forbid fixture prose (`Personal Memory`, `favorite prompt`).

**Minor addressed:** `diff -u` uses `--label 'memory-before (weakness block)'` / `memory-after (weakness block)'`.

**Re-verification:**

```text
$ bash .workflow/S3-T8/bash-assertions.sh
PASS: snapshot_before
PASS: success_evidence
PASS: sete_direct_print
PASS: timeout_memory
PASS: timeout_candidate
PASS: isolation_fail_closed
passed=6 failed=0
```
