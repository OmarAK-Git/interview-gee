# Skeptic verification — S1-GE phase-exit gate

**packet_id:** `S1-GE`  
**role:** skeptic-verifier (`cursor-grok-4.5-high`)  
**verdict:** `pass`  
**survives_equivalent:** `survives`  
**strongest_reason:** Spec §15 Status cells use only {verified, unsupported, documented-fallback} with no `unverified`; isolation.bats + docs encode going-forward “real ~/.hermes untouched” from the restored-absent baseline (leak/rmdir recorded); weakness merge and assessment fixture artifacts are present and content-matched to the Sprint 1 “core logic testable” exit.

Implementer / test-runner transcripts were not trusted blindly; paths and file contents were re-checked.

---

## Claim restated

Sprint 1 exit: platform contract known, isolation enforced, core logic testable. Verify-only. Missing S2 demo sessions are out of scope. Hermes binary **unsupported** and Hermes-invoking automation **stopped** are acceptable when recorded.

---

## AC checklist

| AC | Result | Evidence |
| --- | --- | --- |
| 1. `docs/hermes-compatibility.md` §15 Status ∈ {verified, unsupported, documented-fallback}; no `unverified` | **pass** | Spec §15 table lines 63–71: Status cells are only **unsupported** or **documented-fallback**. Grep for `unverified` in the file: no matches. Hermes binary **unsupported** and Hermes-invoking automation **stopped** recorded (inventory #1; Task 1b layer table). |
| 2. Isolation tests exist; claim real `~/.hermes` untouched from restored baseline | **pass** | `tests/isolation.bats` present. No-create tests (lines 32–75) fail if previously absent `REAL_HERMES_WIN`/`REAL_HERMES_WSL` appear; fake-marker test (77–95) requires `UNTOUCHED`. Docs Task 1b (115–143) record first-run empty WSL leak + operator `rmdir` + going-forward harness boundary; explicitly forbid “first run never mutated.” Fresh probe: Win + WSL operator homes **absent**. |
| 3. Weakness merge + assessment fixture artifacts exist | **pass** | `tests/weakness_memory.bats`, `scripts/weakness_memory.sh`, `tests/fixtures/memory-empty.md`, `tests/fixtures/memory-three-weaknesses.md`; `tests/assessment_eval.bats`, `tests/fixtures/assessment-cases.md`, `skills/crossfire-interviewer/SKILL.md`. |

---

## Commands / path checks (fresh)

| Check | Result |
| --- | --- |
| `Test-Path docs\hermes-compatibility.md` | `True` |
| `Test-Path tests\isolation.bats` | `True` |
| `Test-Path tests\weakness_memory.bats` | `True` |
| `Test-Path tests\assessment_eval.bats` | `True` |
| `Test-Path scripts\weakness_memory.sh` | `True` |
| `Test-Path tests\fixtures\assessment-cases.md` | `True` |
| `Test-Path tests\fixtures\memory-empty.md` | `True` |
| `Test-Path tests\fixtures\memory-three-weaknesses.md` | `True` |
| `$USERPROFILE\.hermes` | absent |
| WSL `/home/fish/.hermes` | absent |

Test-runner result (`.workflow/S1-GE/results/test-runner-result.md`) claimed the four gate `Test-Path`s True; independently re-confirmed. Gate verification commands are existence checks only — bats suites were **not** re-executed in this gate turn (not required by packet commands). Content of the bats/docs/fixtures was read for AC substance.

No packages installed. No `~/.hermes` mutation by this verifier.

---

## AC1 detail — Spec §15 Status cells

| Capability | Status cell |
| --- | --- |
| Disposable `HERMES_HOME` isolation | **unsupported** (Hermes write-scope); harness boundary noted as verified in Evidence only |
| Distinct process + session ID | **unsupported** |
| Durable weakness store | **unsupported** |
| `MEMORY.md` delimited round-trip | **documented-fallback** |
| Pause / isolate Curator | **documented-fallback** |
| Disable `session_search` / log | **documented-fallback** |
| Learning-loop ≤ 8s | **documented-fallback** |
| Exclude candidate before session two | **unsupported** |
| Skill reload without new process | **documented-fallback** |

**Non-blocking note:** Discovery inventory row #10 Status is **agent-direct** (product choice), not one of the three capability labels. That row is outside the Spec §15 capability Status column; it is not `unverified` and does not fail this gate AC.

**Do not inflate:** Harness isolation is **verified**; Hermes process write-scope remains **unsupported**. Hermes-invoking automation is **stopped** until install + throwaway probe.

---

## AC2 detail — isolation claim shape

- `tests/isolation.bats` asserts disposable default `HERMES_HOME`, rejects real-profile overrides, same-process no-create of operator homes, fake real-home marker untouched after `crossfire_harness_write_probe`, and docs contract grep (`Task 1b`, `Hermes-invoking automation`).
- Compatibility doc records leak birth **2026-08-16 14:59:15**, uncertain creator, operator restore, post-restore absence — going-forward baseline is the accepted claim per gate instructions.
- Live homes remain absent at verify time (matches restored baseline).

---

## AC3 detail — core logic testable

- Weakness: bats cover insert/merge/dedup/evict/validation/isolation; script implements delimited YAML merge under `crossfire_require_isolated_hermes_home`.
- Assessment: static SKILL.md contract + `assessment-cases.md` (≥9 cases, strong/one/weak per family) + live N=5 skip/fail-closed hooks. Live §10 N=5 is **unsupported** (no Hermes) and must not be narrated as passed — artifacts still satisfy “core logic testable” for Sprint 1.

---

## Refutations attempted (failed to refute)

| Attack | Outcome |
| --- | --- |
| §15 Status still says `unverified` | Refuted — no `unverified` in file; §15 Status cells clean |
| Isolation claims “never mutated ever” including first 1b run | Refuted — docs forbid that claim; going-forward only |
| Weakness/assessment only empty stubs | Refuted — substantive bats + fixtures + script/SKILL present |
| Fail gate because Hermes missing / S2 sessions missing | Out of scope / explicitly allowed when recorded |

---

## Machine-readable

```json
{
  "packet_id": "S1-GE",
  "verdict": "pass",
  "survives_equivalent": "survives",
  "strongest_reason": "Spec §15 Status cells are only verified/unsupported/documented-fallback (no unverified); isolation.bats + restored-baseline docs claim real ~/.hermes untouched going forward; weakness_memory and assessment_eval artifacts exist with related scripts/fixtures.",
  "evidence": [
    "docs/hermes-compatibility.md Spec §15 table Status cells (unsupported|documented-fallback only); no unverified; Hermes-invoking automation stopped recorded",
    "tests/isolation.bats no-create + fake-marker tests; docs Task 1b leak/rmdir/going-forward",
    "REAL_HERMES_WIN absent; REAL_HERMES_WSL absent (fresh probe)",
    "tests/weakness_memory.bats + scripts/weakness_memory.sh + tests/fixtures/memory-*.md",
    "tests/assessment_eval.bats + tests/fixtures/assessment-cases.md + skills/crossfire-interviewer/SKILL.md",
    "Test-Path re-check: hermes-compatibility.md, isolation.bats, weakness_memory.bats, assessment_eval.bats all True"
  ]
}
```
