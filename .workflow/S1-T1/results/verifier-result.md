# Verifier result — S1-T1 / 04-verify-retry

**packet_id:** `04-verify-retry`  
**Verdict:** `survives`  
**Status:** `done`

**Claim restated:** S1-T1 is complete against ACs 1–5: every Spec §15 required capability Status cell is verified|unsupported|documented-fallback (not unverified); MEMORY.md writer + YAML round-trip characterized; one Curator strategy recorded; no public-doc assumption left implicit; `tests/preflight.bats` exists and encodes required capability checks. Task-scoped: ignore missing isolation.bats / demo / weakness merge; Hermes absent may be unsupported.

**Strongest reason:** Independent re-read of `docs/hermes-compatibility.md` Spec §15 table shows all nine required Status cells use only **unsupported** or **documented-fallback** (zero `unverified`); MEMORY.md writer + not-proven YAML round-trip, Curator **isolated**, explicit public-doc tags, and `tests/preflight.bats` + fail-closed preflight all match ACs 2–5.

## Evidence gathered (independent)

Did **not** read `implementer-result.md` or `researcher-result.md`.

### Product files read

| File | Lines / focus |
| --- | --- |
| `docs/hermes-compatibility.md` | Full file; §15 Status cells L63–71; MEMORY/Curator/session_search; locked choices |
| `scripts/demo_common.sh` | Full file; `CURATOR_STRATEGY`, paths, preflight helpers |
| `scripts/preflight.sh` | Full file; discovery + fail-closed |
| `tests/preflight.bats` | Full file; capability-encoded tests |

### Spec §15 Status cells (parsed)

| Capability | Status |
| --- | --- |
| Disposable `HERMES_HOME` isolation | **unsupported** |
| Distinct process + session ID | **unsupported** |
| Durable weakness store | **unsupported** |
| `MEMORY.md` delimited block survives round-trip | **documented-fallback** |
| Pause / isolate Curator | **documented-fallback** |
| Disable `session_search` or log calls | **documented-fallback** |
| Learning-loop write ≤ 8s | **documented-fallback** |
| Exclude candidate from live dir | **unsupported** |
| Skill reload without new process | **documented-fallback** |

`unverified` count in compatibility doc: **0**.

### Commands run

| Command | Result |
| --- | --- |
| `Test-Path docs\hermes-compatibility.md` | `True` |
| `Test-Path scripts\preflight.sh` | `True` |
| `Test-Path tests\preflight.bats` | `True` |
| `Select-String … MEMORY.md\|Curator\|session_search\|verified\|unsupported\|fallback \| Measure-Object` on compatibility doc | Count **43** |
| Same pattern counts: `preflight.sh` / `preflight.bats` | **6** / **14** |
| `Select-String … unverified` on four product files | no matches |
| `wsl -e bash -lc '… CROSSFIRE_HERMES_DISCOVERY=0 bash scripts/preflight.sh'` | Exit **1**; capability summary printed; `PREFLIGHT FAIL: Hermes binary not discoverable…` (fail-closed OK) |
| `wsl -l -v` | Ubuntu Running |
| `Test-Path C:\Users\oalan\.hermes` | `False` |
| `wsl … test -d /home/fish/.hermes; command -v hermes` | absent / not found |
| Python parse of §15 Status column | `ALL_OK True` |

Bats not installed; per instructions did **not** install bats or mutate `~/.hermes`.

## AC checklist

| AC | Outcome | Notes |
| --- | --- | --- |
| 1 Capability statuses | **PASS** | All nine §15 Status cells are allowed labels; prior refute (unverified rows) no longer holds on current file. |
| 2 MEMORY.md writer + YAML RT | **PASS** | Writer **agent-direct** (`hermes-compatibility.md` L19, L36; `demo_common.sh` `MEMORY_WRITER`). Round-trip explicitly **not proven to survive** + **documented-fallback** + archive/`SESSION_SEARCH` fallback (L37, L66) — characterized. |
| 3 Curator strategy | **PASS** | One strategy: **isolated** (`hermes-compatibility.md` L21, L49; `demo_common.sh` L41; bats asserts `CURATOR_STRATEGY=isolated`). |
| 4 No implicit public-doc | **PASS** | Public Hermes claims tagged *public-doc (not checked against install)*; doc states public docs are never **verified** unless explicit (L11–13). Path conventions recorded as **unsupported** / convention, not verified. |
| 5 `tests/preflight.bats` | **PASS** | Exists. Encodes fail-closed missing Hermes, isolated `HERMES_HOME`, MEMORY/skill paths, session-ID fail-closed, skill timing, learning-loop fallback, Curator isolated, session_search + MEMORY/YAML doc checks. Fail-closed observed via direct preflight run. |

## Residual skepticism (non-blocking for these ACs)

- Several bats assertions are doc-grep / constant checks (letter-level); acceptable for Task 1 discovery when Hermes is absent and fail-closed is required.
- Live binary probes remain deferred (open items L112–116); correctly labeled unsupported/documented-fallback, not verified.

## Verdict JSON

```json
{
  "packet_id": "04-verify-retry",
  "status": "done",
  "verdict": "survives",
  "strongest_reason": "All nine Spec §15 Status cells are unsupported or documented-fallback (no unverified); MEMORY.md writer/YAML, Curator isolated, explicit public-doc tags, and preflight.bats + fail-closed preflight satisfy ACs 2–5.",
  "evidence": [
    "docs/hermes-compatibility.md L63-71: nine §15 Status cells = unsupported|documented-fallback; unverified count 0",
    "docs/hermes-compatibility.md L19,L36-37,L49: agent-direct writer; YAML not-proven + documented-fallback; Curator strategy isolated",
    "Test-Path docs/hermes-compatibility.md, scripts/preflight.sh, tests/preflight.bats => True,True,True",
    "Select-String compatibility doc pattern count => 43",
    "CROSSFIRE_HERMES_DISCOVERY=0 bash scripts/preflight.sh => exit 1 fail-closed with capability summary",
    "tests/preflight.bats encodes fail-closed, paths, session ID, skill timing, learning-loop, Curator, session_search, MEMORY/YAML checks"
  ],
  "commands_run": [
    {
      "command": "Test-Path docs\\hermes-compatibility.md; Test-Path scripts\\preflight.sh; Test-Path tests\\preflight.bats",
      "result": "True; True; True"
    },
    {
      "command": "Select-String -Path docs\\hermes-compatibility.md -Pattern 'MEMORY\\.md|Curator|session_search|verified|unsupported|fallback' | Measure-Object | Select-Object -ExpandProperty Count",
      "result": "43"
    },
    {
      "command": "Select-String -Path docs\\hermes-compatibility.md,scripts\\demo_common.sh,scripts\\preflight.sh,tests\\preflight.bats -Pattern 'unverified' -SimpleMatch",
      "result": "no matches"
    },
    {
      "command": "wsl -e bash -lc 'cd /mnt/c/Users/oalan/interview-gee && CROSSFIRE_HERMES_DISCOVERY=0 bash scripts/preflight.sh; echo EXIT:$?'",
      "result": "EXIT:1; hermes_executable unsupported; capability summary; PREFLIGHT FAIL: Hermes binary not discoverable"
    },
    {
      "command": "python parse of Spec §15 Status column from docs/hermes-compatibility.md",
      "result": "9/9 rows ALL_OK True; labels only unsupported|documented-fallback"
    },
    {
      "command": "wsl -l -v; Test-Path C:\\Users\\oalan\\.hermes; wsl hermes/home checks",
      "result": "Ubuntu Running; win ~/.hermes absent; WSL ~/.hermes absent; hermes binary absent"
    }
  ]
}
```
