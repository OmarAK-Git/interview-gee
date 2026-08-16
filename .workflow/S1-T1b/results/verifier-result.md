# Skeptic verification — S1-T1b restore (packet 04-verify-restore)

**packet_id:** `04-verify-restore`  
**verdict:** `survives`  
**strongest_reason:** Independent live probe (source `demo_common.sh` → `start-wsl-isolated.sh` → `crossfire_harness_write_probe`) from the restored baseline left both operator homes absent; docs record the first-run leak (do not claim never-mutated); bats no-create + fake-marker logic matches the going-forward claim; Hermes-invoking automation is documented stopped.

Implementer transcripts were not used as evidence.

---

## Claim restated

After operator-approved removal of the leaked empty `/home/fish/.hermes`, going forward from the restored baseline: Windows `%USERPROFILE%\.hermes` and WSL `/home/fish/.hermes` stay absent under isolation harness use; sourcing / `start-wsl-isolated` does not recreate them; `tests/isolation.bats` would fail if a previously absent operator path appeared or a fake-home marker were touched; subsequent scripts must source isolation; Hermes-invoking automation is recorded stopped. This is **not** a claim that the first 1b run never mutated real `~/.hermes`.

---

## Evidence gathered

### Baseline paths (expect absent)

| Check | Result |
| --- | --- |
| `Test-Path tests\isolation.bats` | `True` |
| `Test-Path scripts\demo_common.sh` | `True` |
| `Test-Path $env:USERPROFILE\.hermes` | `False` (`USERPROFILE=C:\Users\oalan`) |
| `wsl: test ! -e /home/fish/.hermes` | exit `0` (absent; `stat` → No such file) |

### Docs — Task 1b incident (no “never mutated” overclaim)

`docs/hermes-compatibility.md:115-143`:

- Records leak: empty `/home/fish/.hermes` born **2026-08-16 14:59:15** during first S1-T1b; creator **uncertain**; operator `rmdir` restore.
- Explicit: **Do not claim** the first S1-T1b run never mutated real `~/.hermes`.
- Shared-var rows `:104-105`: absent **after restore**; point at incident.
- Going-forward: harness does not mkdir operator paths; same-process absence snapshots; Hermes-invoking automation **stopped** until throwaway probe.
- Contract: subsequent scripts/tests must source `demo_common.sh` or `start-wsl-isolated.sh`.

No remaining “first run never mutated” claim found in that doc.

### Script / test reads (tripwire not inert from restored absence)

- `scripts/demo_common.sh:1-9,221-227` — isolation contract; sole product `mkdir -p` under disposable `HERMES_HOME` in `crossfire_harness_write_probe`.
- `scripts/start-wsl-isolated.sh:1-25` — sources demo_common; never mkdir operator paths; does not invoke Hermes (discovery message only).
- `scripts/preflight.sh:5` — sources `demo_common.sh`.
- `tests/isolation.bats:32-75` — same-process snapshot of `REAL_HERMES_*` absence **before** full source / `start-wsl-isolated`; **fails** if a previously absent path appears (tripwire **armed** when baseline absent).
- `tests/isolation.bats:77-95` — fake-home marker under overridden `REAL_HERMES_WSL` must stay `UNTOUCHED` after harness write probe.
- If operator homes **already existed** at test start, no-create branches set `*_was_absent=0` and would not fail on “creation” — inert in that state; **post-restore both absent**, so tripwire is live for the claim under test.

### Optional live probe (did not mkdir operator paths; did not install bats)

Ran `/tmp/probe-restore.sh` (CRLF-stripped copy of a disposable probe) in WSL:

```
BEFORE_WSL=absent / BEFORE_WIN=absent
HERMES_HOME=/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test
REAL_HERMES_WSL=/home/fish/.hermes
REAL_HERMES_WIN=/mnt/c/Users/oalan/.hermes
AFTER_SOURCE_*=absent
start-wsl-isolated: Hermes binary not discoverable; isolation env ready; Hermes invoke stopped
AFTER_START_*=absent
probe wrote only under .crossfire/profiles/test/.crossfire-harness-probe
AFTER_PROBE_*=absent
```

Final re-stat: `Test-Path C:\Users\oalan\.hermes` → `False`; WSL `/home/fish/.hermes` still absent.

`bats` not installed — bats suite not executed (per packet: do not install). “Would fail” assessed from test source + live harness probe, not bats run output.

### AC map

| AC | Assessment |
| --- | --- |
| 1 Automated run from restored baseline leaves real Hermes state unchanged | **Met for harness** — live source/start/probe; Hermes process write-scope still unsupported (out of claim: automation stopped). |
| 2 Subsequent scripts/tests documented to source isolation | **Met** — demo_common / start-wsl-isolated headers; compatibility Task 1b contract; preflight sources. |
| 3 Hermes-invoking automation recorded stopped | **Met** — `hermes-compatibility.md:135,143`; start-wsl-isolated does not invoke. |

### Attack angles checked (did not refute)

- Docs still claiming first run never mutated → **no** (explicit anti-claim).
- Tripwire inert → **no** from restored absence (armed); would be inert only if homes pre-existed.
- Sourcing isolation recreating WSL home → **no** (live probe).
- Tests that cannot fail if operator `~/.hermes` were created mid-run from absence → **no** (no-create tests exit 1 on appearance).

---

## Commands run

```text
Test-Path -LiteralPath tests\isolation.bats -PathType Leaf   # True
Test-Path -LiteralPath scripts\demo_common.sh -PathType Leaf # True
Test-Path -LiteralPath $env:USERPROFILE\.hermes              # False
wsl -e bash -lc 'test ! -e /home/fish/.hermes; ...'          # absent
wsl -e bash -lc "tr -d '\r' < .../_probe-restore.sh > /tmp/probe-restore.sh && bash /tmp/probe-restore.sh"
  # source demo_common + start-wsl-isolated + crossfire_harness_write_probe; both homes still absent
Test-Path $env:USERPROFILE\.hermes ; wsl re-stat             # still absent
# bats: not installed (skipped per packet)
```

Files read: `tests/isolation.bats`, `scripts/demo_common.sh`, `scripts/start-wsl-isolated.sh`, `scripts/preflight.sh`, `docs/hermes-compatibility.md` (Task 1b).

---

## Machine-readable

```json
{
  "packet_id": "04-verify-restore",
  "verdict": "survives",
  "strongest_reason": "Live source/start/write-probe from restored baseline left Win and WSL operator ~/.hermes absent; docs record first-run leak (anti-claim); bats no-create + fake-marker logic armed for absence; Hermes invoke documented stopped.",
  "evidence": [
    "Test-Path USERPROFILE\\.hermes = False; wsl test ! -e /home/fish/.hermes exit 0 before and after probe",
    "Live WSL probe: source demo_common.sh, CROSSFIRE_HERMES_DISCOVERY=0 start-wsl-isolated.sh, crossfire_harness_write_probe → AFTER_*_WSL/WIN=absent; probe only under .crossfire/profiles/test",
    "docs/hermes-compatibility.md:115-127 incident table + Do not claim first run never mutated; :135-143 stopped + contract",
    "tests/isolation.bats:32-75 same-process absence snapshot fail-closed; :77-95 fake-home marker UNTOUCHED",
    "demo_common.sh sole mkdir under disposable HERMES_HOME; start-wsl-isolated does not invoke hermes; preflight sources demo_common",
    "bats not installed — suite not executed (packet forbids install)"
  ],
  "commands_run": [
    "Test-Path -LiteralPath tests\\isolation.bats -PathType Leaf",
    "Test-Path -LiteralPath scripts\\demo_common.sh -PathType Leaf",
    "Test-Path -LiteralPath $env:USERPROFILE\\.hermes",
    "wsl -e bash -lc 'test ! -e /home/fish/.hermes; ls/stat'",
    "wsl bash /tmp/probe-restore.sh (source + start-wsl-isolated + harness write probe + re-stat)",
    "final Test-Path and wsl re-stat of both homes"
  ]
}
```
