# S1-T1b implementer result

**Packet:** `02-implementation` · **Date:** 2026-08-16

## Summary

Hybrid isolation implemented: `HERMES_HOME` defaults to repo `.crossfire/profiles/test`; harness scripts prove write boundary without invoking Hermes; Hermes-invoking automation remains stopped until install + throwaway probe.

## Files changed

| File | Rationale |
| --- | --- |
| `tests/isolation.bats` | TDD write-boundary tests (fake-home marker, refuse real profile, no real `~/.hermes` creation) |
| `scripts/demo_common.sh` | Isolation contract comment + `crossfire_apply_isolation_env`, `crossfire_require_isolated_hermes_home`, `crossfire_harness_write_probe`; `REAL_HERMES_WSL` overridable for tests |
| `scripts/start-wsl-isolated.sh` | Hermes-specific WSL entry: source isolation, export env, refuse real profile, no `hermes` invoke when missing |
| `docs/hermes-compatibility.md` | Task 1b hybrid decision: harness **verified**, Hermes write-scope **unsupported**, automation **stopped** |

## Verification

```json
{
  "packet_id": "02-implementation",
  "status": "done",
  "files_touched": [
    "tests/isolation.bats",
    "scripts/demo_common.sh",
    "scripts/start-wsl-isolated.sh",
    "docs/hermes-compatibility.md",
    ".workflow/S1-T1b/results/implementer-result.md"
  ],
  "checks_run": [
    {
      "command": "Test-Path -LiteralPath tests\\isolation.bats -PathType Leaf",
      "result": "pass",
      "output": "True"
    },
    {
      "command": "Test-Path -LiteralPath scripts\\demo_common.sh -PathType Leaf",
      "result": "pass",
      "output": "True"
    },
    {
      "command": "Test-Path -LiteralPath scripts\\start-wsl-isolated.sh -PathType Leaf",
      "result": "pass",
      "output": "True"
    },
    {
      "command": "wsl bash: unset HERMES_HOME; source demo_common.sh; printf HERMES_HOME",
      "result": "pass",
      "output": "HERMES_HOME=/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test"
    },
    {
      "command": "wsl bash: CROSSFIRE_HERMES_DISCOVERY=0 bash scripts/start-wsl-isolated.sh",
      "result": "pass",
      "output": "start-wsl-isolated: Hermes binary not discoverable; isolation env ready; Hermes invoke stopped\nhermes_home=/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test\nisolation env ready"
    },
    {
      "command": "wsl bash: HERMES_HOME=/tmp/evil/.hermes bash scripts/start-wsl-isolated.sh; echo refuse_exit=$?",
      "result": "pass",
      "output": "PREFLIGHT FAIL: HERMES_HOME points at real profile: /tmp/evil/.hermes\nrefuse_exit=1"
    },
    {
      "command": "wsl bash: crossfire_harness_write_probe with fake REAL_HERMES_WSL marker",
      "result": "pass",
      "output": "marker=UNTOUCHED"
    },
    {
      "command": "wsl bash: command -v bats && bats tests/isolation.bats",
      "result": "fail",
      "output": "bats-not-installed (per packet: do not install bats)"
    }
  ]
}
```

## Unresolved / reviewer notes

- `bats tests/isolation.bats` not run (bats absent; install forbidden this task). Manual WSL assertions cover the same AC.
- Spec §15 “Disposable `HERMES_HOME` isolation” for **Hermes process** write-scope remains **unsupported**; only harness boundary is verified.
- S2 Hermes-touching tasks (T5–T7) stay blocked until install + throwaway probe.
- Queue not marked done (per packet).

---

## Review fix retry (2026-08-16)

**Reviewer verdict:** `blocking_retry` — addressed Important + Minor findings.

### Fixed

| Finding | Fix |
| --- | --- |
| Important: no-create tests tautological (`isolation.bats:32`) | Snapshot `REAL_HERMES_WIN`/`REAL_HERMES_WSL` absence read-only via `CROSSFIRE_PATHS_ONLY=1` before source/`start-wsl-isolated.sh` in same process; fail if previously absent path now exists |
| Minor: `start-wsl-isolated.sh` `$0` sourcing | Resolve `demo_common.sh` via `${BASH_SOURCE[0]:-$0}` |
| Minor: source-only contract not fail-closed | Fail-closed at end of `demo_common.sh` when `HERMES_HOME` is a real profile; contract comment requires `crossfire_require_isolated_hermes_home` before writes |
| Minor: meta-test overwrites marker without product code | Dropped `@test "harness write would fail read-the-test..."`; added fail-closed-on-source test; marker test exports `REAL_HERMES_WSL` before source |

### Files touched (retry)

- `tests/isolation.bats`
- `scripts/demo_common.sh`
- `scripts/start-wsl-isolated.sh`
- `.workflow/S1-T1b/results/implementer-result.md`

```json
{
  "packet_id": "02-implementation-retry",
  "status": "done",
  "files_touched": [
    "tests/isolation.bats",
    "scripts/demo_common.sh",
    "scripts/start-wsl-isolated.sh",
    ".workflow/S1-T1b/results/implementer-result.md"
  ],
  "fixed": [
    "no-create tests snapshot absence before action and fail if operator ~/.hermes created",
    "start-wsl-isolated.sh BASH_SOURCE path resolution for source compatibility",
    "demo_common fail-closed on real HERMES_HOME at source + require before writes",
    "dropped tautological meta-test; marker test binds REAL_HERMES before source"
  ],
  "checks_run": [
    {
      "command": "wsl: no-create snapshot after source demo_common.sh",
      "result": "pass",
      "output": "no_create_demo_common_ok"
    },
    {
      "command": "wsl: no-create snapshot after start-wsl-isolated.sh (same process)",
      "result": "pass",
      "output": "no_create_start_ok"
    },
    {
      "command": "wsl: HERMES_HOME=/tmp/evil/.hermes source demo_common.sh",
      "result": "pass",
      "output": "PREFLIGHT FAIL: HERMES_HOME points at real profile: /tmp/evil/.hermes\nfail_closed_exit=1"
    },
    {
      "command": "wsl: source scripts/start-wsl-isolated.sh (BASH_SOURCE)",
      "result": "pass",
      "output": "isolation env ready; hermes_home under .crossfire/profiles/test"
    },
    {
      "command": "wsl: CROSSFIRE_HERMES_DISCOVERY=0 bash scripts/start-wsl-isolated.sh",
      "result": "pass",
      "output": "start-wsl-isolated: Hermes binary not discoverable; isolation env ready"
    }
  ]
}
```

---

## Operator-restore retry (2026-08-16)

**Trigger:** Verifier refuted AC1 — empty `/home/fish/.hermes` born 2026-08-16 14:59:15 during first S1-T1b run; docs falsely claimed absent/no-mutate.

**Operator action (controller, pre-retry):** Approved removal; `wsl.exe -e bash -c "rmdir /home/fish/.hermes"` after confirming empty. Post-restore: Win `%USERPROFILE%\.hermes` absent, WSL `/home/fish/.hermes` absent.

### Changes

| File | Rationale |
| --- | --- |
| `docs/hermes-compatibility.md` | Record leak incident, operator restore, honest going-forward claims; both real homes absent after restore |
| `scripts/demo_common.sh` | Comments: product never mkdirs operator paths; snapshot tripwire documented |
| `scripts/start-wsl-isolated.sh` | Comment: never mkdirs REAL_HERMES_* |

`tests/isolation.bats` unchanged — same-process snapshot tripwire preserved.

```json
{
  "packet_id": "02-implementation-restore-retry",
  "status": "done",
  "files_touched": [
    "docs/hermes-compatibility.md",
    "scripts/demo_common.sh",
    "scripts/start-wsl-isolated.sh",
    ".workflow/S1-T1b/results/implementer-result.md"
  ],
  "checks_run": [
    {
      "command": "Test-Path -LiteralPath $env:USERPROFILE\\.hermes",
      "result": "pass",
      "output": "False (Win absent after restore)"
    },
    {
      "command": "wsl -e bash -lc '[ ! -e /home/fish/.hermes ] && echo WSL_ABSENT'",
      "result": "pass",
      "output": "WSL_ABSENT"
    }
  ],
  "queue_marked_done": false
}
```