# S1-T2 implementer result

**Packet:** `02-implementation` · **Status:** done · **Date:** 2026-08-16

## Files changed

| File | Rationale |
| --- | --- |
| `scripts/weakness_memory.sh` | Deterministic MEMORY.md weakness-block merge: schema validation, dedup, cap/eviction, advisory lock, atomic rename; sources `demo_common.sh` for isolation |
| `tests/weakness_memory.bats` | Strict TDD coverage for all 17 spec §9 behaviors (insert, reject, merge, dedup, observation_count, cap, preservation, validation safety, topic_key, weakness_id, families, answer_ref, timestamps, evidence, atomic lock, single block, isolated HERMES_HOME) |
| `tests/fixtures/memory-empty.md` | Fixture with unrelated content and no weakness block |
| `tests/fixtures/memory-three-weaknesses.md` | Fixture at cap=3 with computed `weakness_id` values and eviction-order timestamps |

## Verification commands (actual results)

### Required PowerShell queue

```
Test-Path scripts\weakness_memory.sh          → True
Test-Path tests\weakness_memory.bats          → True
Test-Path tests\fixtures\memory-empty.md      → True
Test-Path tests\fixtures\memory-three-weaknesses.md → True
```

### `bats tests/weakness_memory.bats`

Command: `wsl -e bash -lic 'command -v bats'`

**Result:** bats not installed on WSL (`BATS_MISSING`). Test file written per spec; not executed via bats.

### Bash equivalent assertions (WSL)

Ran inline assertion harness covering all required behaviors during implementation (insert, reject missing fields, merge, dedup, observation_count increment, cap/eviction, unrelated content preservation, validation failure safety, topic_key, weakness_id, byte_offset evidence).

**Result:** `passed=27 failed=0`

### Isolation

All test writes use disposable `HERMES_HOME` under `mktemp` paths beneath `.crossfire/profiles/`; `crossfire_require_isolated_hermes_home` enforced before any MEMORY.md write.

## Implementation notes

- Delimited block format matches spec §9 markers and fenced YAML.
- `weakness_id` = `w-` + first 12 hex of SHA-256(`family` + `\n` + `topic_key`) UTF-8.
- Eviction order: `last_seen` asc, `observation_count` asc, `weakness_id` desc.
- Write protocol: `flock` advisory lock, re-read after lock, validate, merge, temp file + `sync` + atomic `mv`.
- Shell scripts/fixtures normalized to LF for WSL execution (Windows-authored files).

## Unresolved

1. `bats` not installed — `tests/weakness_memory.bats` not run through bats runner (approval-first).
2. Advisory `flock` is Linux/WSL-oriented; native Windows bash may need alternate locking (documented-fallback).

## JSON summary

```json
{
  "packet_id": "02-implementation",
  "status": "done",
  "files_touched": [
    "scripts/weakness_memory.sh",
    "tests/weakness_memory.bats",
    "tests/fixtures/memory-empty.md",
    "tests/fixtures/memory-three-weaknesses.md",
    ".workflow/S1-T2/results/implementer-result.md"
  ],
  "checks_run": [
    {
      "command": "Test-Path scripts\\weakness_memory.sh",
      "result": "True"
    },
    {
      "command": "Test-Path tests\\weakness_memory.bats",
      "result": "True"
    },
    {
      "command": "Test-Path tests\\fixtures\\memory-empty.md",
      "result": "True"
    },
    {
      "command": "Test-Path tests\\fixtures\\memory-three-weaknesses.md",
      "result": "True"
    },
    {
      "command": "wsl bash equivalent assertions (27 cases)",
      "result": "passed=27 failed=0"
    },
    {
      "command": "wsl -e bash -lic 'command -v bats'",
      "result": "BATS_MISSING — bats tests not run"
    }
  ]
}
```

---

## Review fix retry (2026-08-16)

**Trigger:** `code-reviewer-result.md` verdict `blocking_retry`

### Fixed

1. **Eviction sort key** — `crossfire_weakness_sort_key_evict` now reads record field **7** (`last_seen`), not field 6 (`first_seen`). Spec §9 eviction order: `last_seen` asc → `observation_count` asc → `weakness_id` desc.
2. **Cap test with disagreeing timestamps** — added bats case `evict by last_seen not first_seen when timestamps disagree`: alpha gets oldest `first_seen` but newest `last_seen` after refresh; inserting a fourth topic evicts beta (oldest `last_seen`), keeps refreshed alpha. Would fail if eviction keyed on `first_seen`.
3. **§8 write protocol** — `crossfire_persist_weakness` now: advisory `flock` → re-read → validate → merge → fingerprint check → fail-closed `fsync` (python3 `os.fsync` or `sync -f`) → atomic `mv` → retry (up to 5) if dest fingerprint changed under lock. Lock file removed on release. Refuse writes when dest dirname resolves to real `~/.hermes`.
4. **Behavioral atomic test** — replaced source grep test with persist exercise: asserts MEMORY.md content updated at same path, expected weakness fields present, no leftover `MEMORY.md.*` temps (excluding `.lock`).

### Files touched (retry)

- `scripts/weakness_memory.sh`
- `tests/weakness_memory.bats`
- `.workflow/S1-T2/results/implementer-result.md`

### Verification (retry)

```
Review-fix WSL checks (9 cases): passed=9 failed=0
  - keep refreshed alpha (w-e00e42cd5216)
  - evict beta (oldest last_seen w-1ee6d6febe17)
  - cap 3 with delta-gap inserted
  - sort key uses field 7 last_seen
  - atomic persist updates content, no temp leftovers
bats: BATS_MISSING (not run)
```

```json
{
  "packet_id": "02-implementation",
  "status": "review_fix",
  "files_touched": [
    "scripts/weakness_memory.sh",
    "tests/weakness_memory.bats",
    ".workflow/S1-T2/results/implementer-result.md"
  ],
  "fixed": [
    "Eviction sort uses last_seen (field 7) not first_seen (field 6)",
    "Added cap test with disagreeing first_seen/last_seen that fails if eviction uses first_seen",
    "Write protocol: lock, re-read, validate after lock, fail-closed fsync, atomic rename, retry on concurrent change",
    "Replaced atomic source-grep test with behavioral persist assertion"
  ],
  "checks_run": [
    {
      "command": "wsl review-fix verification (9 cases)",
      "result": "passed=9 failed=0"
    }
  ]
}
```
