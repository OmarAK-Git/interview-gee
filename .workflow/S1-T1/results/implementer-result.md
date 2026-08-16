# S1-T1 implementer result

**Packet:** `02-implementation` · **Status:** done · **Date:** 2026-08-16

## Files changed

| File | Rationale |
| --- | --- |
| `tests/preflight.bats` | TDD first: encodes fail-closed preflight, isolated paths, session-ID/skill-timing/Curator/session_search checks, and compatibility-doc coverage |
| `scripts/demo_common.sh` | Shared Hermes discovery vars, WSL/Windows real-profile guards, and preflight helper functions |
| `scripts/preflight.sh` | Read-only discovery script: prints capability summary and exits nonzero when Hermes is missing |
| `docs/hermes-compatibility.md` | Task 1 capability table with verified/unsupported/unverified labels, MEMORY.md writer, Curator strategy, and public-doc risks |

## Verification commands (actual results)

### Required PowerShell

```
Test-Path -LiteralPath docs\hermes-compatibility.md -PathType Leaf
→ True

Test-Path -LiteralPath scripts\preflight.sh -PathType Leaf
→ True

Test-Path -LiteralPath tests\preflight.bats -PathType Leaf
→ True

Select-String -Path docs\hermes-compatibility.md -Pattern 'MEMORY.md|Curator|session_search|verified|unsupported|fallback' | Measure-Object | Select-Object -ExpandProperty Count
→ 45
```

### `scripts/preflight.sh` (WSL Ubuntu, user fish)

Command: `wsl -e bash -lic 'cd /mnt/c/Users/oalan/interview-gee && bash scripts/preflight.sh; echo EXIT:$?'`

```
hermes_executable: unsupported (not on Windows PATH or WSL login PATH for user fish)
=== Hermes preflight capability summary ===
repo_root: /mnt/c/Users/oalan/interview-gee
hermes_home: /mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test
memory_md: /mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test/memories/MEMORY.md
skills_dir: /mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test/skills
state_db: /mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test/state.db
config: /mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test/config.yaml
real_hermes_win: /mnt/c/Users/oalan/.hermes
real_hermes_wsl: /home/fish/.hermes
wsl_distro: Ubuntu
wsl_user: fish
curator_strategy: isolated
memory_writer: agent-direct
persistence_branch: memory-md-block (probe pending on throwaway profile)
session_search: unverified
skill_loading_timing: startup-only (public-doc: memory injection startup-frozen; live reload unverified)
learning_loop_latency: unverified (public-doc: auxiliary.background_review; spec fallback: pre-persist before timed run)
session_identifiability: fail-closed (no Hermes binary; cannot verify distinct session/process IDs)
PREFLIGHT FAIL: Hermes binary not discoverable; install required before demo automation
EXIT:1
```

**Result:** pass (fail-closed as expected with no Hermes install).

### `bats tests/preflight.bats`

Command: `wsl -e bash -lic 'command -v bats'`

**Result:** bats not installed on WSL (command not found). Tests not executed; not installed per approval-first rule. Test file encodes required behavior for when bats is available.

### Bash availability

- Windows: `C:\Windows\System32\bash.exe` present
- WSL: `/usr/bin/bash` present

## Unresolved items

1. Hermes not installed — preflight cannot pass until operator installs (approval-first).
2. `bats` not installed — `tests/preflight.bats` not run in CI/local yet.
3. MEMORY.md YAML round-trip, session-id uniqueness, `session_search` disable/logging, and `HERMES_HOME` write boundary remain **unverified** until throwaway profile probes (Task 1b+).
4. Shell scripts written on Windows required LF normalization for WSL execution (done in-session).

## JSON summary

```json
{
  "packet_id": "02-implementation",
  "status": "done",
  "files_touched": [
    "scripts/preflight.sh",
    "scripts/demo_common.sh",
    "docs/hermes-compatibility.md",
    "tests/preflight.bats",
    ".workflow/S1-T1/results/implementer-result.md"
  ],
  "checks_run": [
    {
      "command": "Test-Path -LiteralPath docs\\hermes-compatibility.md -PathType Leaf",
      "result": "pass",
      "output": "True"
    },
    {
      "command": "Test-Path -LiteralPath scripts\\preflight.sh -PathType Leaf",
      "result": "pass",
      "output": "True"
    },
    {
      "command": "Test-Path -LiteralPath tests\\preflight.bats -PathType Leaf",
      "result": "pass",
      "output": "True"
    },
    {
      "command": "Select-String pattern count on docs/hermes-compatibility.md",
      "result": "pass",
      "output": "45"
    },
    {
      "command": "wsl -e bash -lic 'bash scripts/preflight.sh'",
      "result": "pass",
      "output": "exit 1 fail-closed; capability summary printed; isolated HERMES_HOME paths"
    },
    {
      "command": "wsl -e bash -lic 'command -v bats'",
      "result": "fail",
      "output": "bats not installed; tests not run"
    }
  ],
  "open_questions": [
    "Install Hermes (WSL recommended) before preflight can pass",
    "Install bats or wire test runner before automated test verification",
    "Throwaway HERMES_HOME probe: CROSSFIRE-WEAKNESSES YAML round-trip after install",
    "Confirm HERMES_HOME=.crossfire/profiles/test without hermes profile create",
    "Disable Hermes memory tool / background review so harness remains sole MEMORY.md writer"
  ]
}
```

---

## Retry (code-review `blocking_retry`, 2026-08-16)

**Review source:** `.workflow/S1-T1/results/code-reviewer-result.md`

### Fixes applied

| ID | Fix |
| --- | --- |
| Important-1 | `tests/preflight.bats` full-script tests use `CROSSFIRE_HERMES_DISCOVERY=0`; assert exact `Hermes binary not discoverable` (no generic `PREFLIGHT FAIL` fallback) |
| Important-2 | `discover_hermes_bin` / `discover_hermes_version` use non-interactive `bash -c`; WSL candidate must be absolute and `test -x`; ambiguous discovery clears `HERMES_BIN` and fail-closed |
| Minor-3 | `normalize_path` + separator normalization in `is_real_hermes_home` |
| Minor-4 | Negative bats test: `HERMES_HOME=/tmp/crossfire-fake/.hermes` rejected by `preflight_check_paths` |
| Minor-6 | Docs: live persistence branch `probe-pending`; first attempt `memory-md-block` |
| Minor-7 | Docs: durable weakness store row relabeled **unverified** (not **unsupported**) |

### Verification (retry)

```
wsl -e bash -lic 'cd /mnt/c/Users/oalan/interview-gee && bash scripts/preflight.sh'
→ exit 1; prints capability summary; ends with "PREFLIGHT FAIL: Hermes binary not discoverable; install required before demo automation"

wsl -e bash -lic 'cd /mnt/c/Users/oalan/interview-gee && env CROSSFIRE_HERMES_DISCOVERY=0 bash scripts/preflight.sh'
→ exit 1; same missing-binary message (stubbed; independent of ambient PATH)

wsl -e bash -lic 'export HERMES_HOME=/tmp/crossfire-fake/.hermes; source scripts/demo_common.sh; preflight_check_paths'
→ exit 1; "HERMES_HOME points at real profile: /tmp/crossfire-fake/.hermes"

bats tests/preflight.bats
→ not run (bats not installed; approval-first)
```

```json
{
  "packet_id": "02-implementation-retry",
  "status": "done",
  "files_touched": [
    "scripts/demo_common.sh",
    "scripts/preflight.sh",
    "tests/preflight.bats",
    "docs/hermes-compatibility.md",
    ".workflow/S1-T1/results/implementer-result.md"
  ],
  "fixed": [
    "Important-1",
    "Important-2",
    "Minor-3",
    "Minor-4",
    "Minor-6",
    "Minor-7"
  ],
  "checks_run": [
    {
      "command": "wsl -e bash -lic 'bash scripts/preflight.sh'",
      "result": "pass",
      "output": "exit 1 fail-closed with exact missing-binary message"
    },
    {
      "command": "wsl -e bash -lic 'env CROSSFIRE_HERMES_DISCOVERY=0 bash scripts/preflight.sh'",
      "result": "pass",
      "output": "exit 1 stubbed discovery; Hermes binary not discoverable"
    },
    {
      "command": "wsl -e bash -lic 'HERMES_HOME=/tmp/crossfire-fake/.hermes preflight_check_paths via demo_common'",
      "result": "pass",
      "output": "exit 1 rejects throwaway /.hermes path"
    },
    {
      "command": "wsl -e bash -lic 'command -v bats'",
      "result": "fail",
      "output": "bats not installed; automated bats suite not run"
    }
  ]
}
```

---

## Retry 2 (skeptic-verifier refuted AC1, 2026-08-16)

**Verifier source:** `.workflow/S1-T1/results/verifier-result.md` — Spec §15 Status cells must use only {verified, unsupported, documented-fallback}.

### §15 row relabeling

| Capability | New status |
| --- | --- |
| Disposable `HERMES_HOME` isolation | **unsupported** |
| Distinct process + session ID | **unsupported** |
| Durable weakness store | **unsupported** |
| `MEMORY.md` delimited block survives round-trip | **documented-fallback** (not proven to survive) |
| Pause / isolate Curator | **documented-fallback** (isolated profile chosen) |
| Disable `session_search` or log calls | **documented-fallback** |
| Learning-loop write ≤ 8s | **documented-fallback** |
| Exclude candidate from live dir | **unsupported** |
| Skill reload without new process | **documented-fallback** |

Also: removed **unverified** as a §15/inventory Status label; YAML round-trip explicitly **not proven to survive**; bats grep patterns updated; preflight echoes use `documented-fallback` / `unsupported` where printed.

```json
{
  "packet_id": "02-implementation-retry-ac1",
  "status": "done",
  "files_touched": [
    "docs/hermes-compatibility.md",
    "scripts/demo_common.sh",
    "scripts/preflight.sh",
    "tests/preflight.bats",
    ".workflow/S1-T1/results/implementer-result.md"
  ],
  "section_15_statuses": {
    "disposable_hermes_home_isolation": "unsupported",
    "distinct_process_session_id": "unsupported",
    "durable_weakness_store": "unsupported",
    "memory_md_block_survives_round_trip": "documented-fallback",
    "pause_isolate_curator": "documented-fallback",
    "disable_session_search_or_log": "documented-fallback",
    "learning_loop_write_le_8s": "documented-fallback",
    "exclude_candidate_from_live_dir": "unsupported",
    "skill_reload_without_new_process": "documented-fallback"
  }
}
```
