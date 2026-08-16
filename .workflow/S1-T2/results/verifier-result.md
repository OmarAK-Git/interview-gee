# S1-T2 skeptic-verifier result

**Packet:** `04-verify`  
**Claim:** S1-T2 is done — deterministic MEMORY.md weakness-block merge meets spec §9 and ACs.  
**Verdict:** `survives`

## Strongest reason

Independent persist runs under an isolated temp `HERMES_HOME` (repo `.workflow/S1-T2/verifier-tmp-*`, never operator `~/.hermes`) exercised insert, validation-reject (original intact), merge (`first_seen` kept / `last_seen`+union+count), dedup no-op, **eviction by `last_seen`**, unrelated-content preservation, and additional fail-safes — **13/13 passed** — and `tests/weakness_memory.bats` encodes the same §9 behaviors.

## Spec §9 read

`docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` §9 (lines 110–161): single delimited block; field contract; reject invalid writes leaving original intact; merge/dedup/cap=3; eviction = inverse of selection (`last_seen` asc, then `observation_count` asc, then `weakness_id` desc).

## Artifact existence (queue commands)

| Path | Exists |
| --- | --- |
| `scripts/weakness_memory.sh` | True |
| `tests/weakness_memory.bats` | True |
| `tests/fixtures/memory-empty.md` | True |
| `tests/fixtures/memory-three-weaknesses.md` | True |

## Tests encode ACs (bats not installed; read + equivalent runs)

| Behavior | bats coverage (names) | Independent check |
| --- | --- | --- |
| Schema (`topic_key`, `weakness_id`, families, evidence) | normalization, weakness_id SHA, family enum, byte_offset | PASS schema helpers; IDs match fixtures |
| Insert | insert complete record | PASS insert |
| Reject / fail-safe | missing fields; bad family; bad answer_ref; non-UTC ts; quote not in answer | PASS reject + 4 fail-safes |
| Merge | keep `first_seen`, union missing, update last_seen/session/ref | PASS merge |
| Dedup | identical `source_session_id`+`answer_ref` no-op | PASS dedup |
| Cap / eviction | evict by `last_seen` not `first_seen`; fourth topic → 3 remain | PASS evict last_seen + cap3 from fixture |
| Preserve unrelated | header/footer outside block | PASS preserve |
| Isolation | writes under `.crossfire/profiles/` | PASS isolation path |

`bats` was **not** installed or executed (per instructions). Equivalent bash against temp fixtures substituted.

## Adversarial notes (non-blocking)

- `weakness_memory.sh` is a sourced library (`crossfire_persist_weakness`); no CLI `persist` subcommand. Plan/files treat it as the merge harness; bats sources it the same way.
- Secondary eviction keys (`observation_count`, `weakness_id`) are implemented in `crossfire_weakness_sort_records_for_eviction` (`scripts/weakness_memory.sh` ~156–233) and exercised mainly via `last_seen`-dominant cases; primary AC (evict by `last_seen`) is independently confirmed.
- Isolation assertion in bats is slightly weak (`||` form); independent path check used an explicit `.crossfire/profiles/` temp tree.

## JSON

```json
{
  "packet_id": "04-verify",
  "verdict": "survives",
  "strongest_reason": "Independent isolated persist scenarios (insert/reject/merge/dedup/evict-by-last_seen/preserve/fail-safes) all passed 13/13, and weakness_memory.bats encodes the §9 behaviors claimed by the ACs.",
  "evidence": [
    "Test-Path: scripts/weakness_memory.sh, tests/weakness_memory.bats, tests/fixtures/memory-empty.md, tests/fixtures/memory-three-weaknesses.md → all True",
    "Read spec §9 docs/...-spec.md:110-161; scripts/weakness_memory.sh (persist/merge/cap/validate); tests/weakness_memory.bats (schema through fail-safe); fixtures memory-empty.md and memory-three-weaknesses.md",
    "crossfire_compute_weakness_id behavioral/alpha-story → w-e00e42cd5216 (matches fixture); technical/beta-tradeoff → w-1ee6d6febe17; product/gamma-metric → w-b2f32d5ee0be",
    "Verifier temp HERMES_HOME under .workflow/S1-T2/verifier-tmp-*/.crossfire/profiles/verify — not ~/.hermes",
    "PASS insert, reject intact, merge, dedup, evict last_seen, preserve, schema topic_key+weakness_id, isolation, fail-safe family/answer_ref/ts/quote, cap3 fixture eviction (SUMMARY pass=13 fail=0)",
    "Eviction check: after bumping alpha last_seen, fourth topic dropped beta (earliest last_seen), retained alpha+gamma+delta, count=3"
  ],
  "commands_run": [
    "Test-Path scripts\\weakness_memory.sh; Test-Path tests\\weakness_memory.bats; Test-Path tests\\fixtures\\memory-empty.md; Test-Path tests\\fixtures\\memory-three-weaknesses.md",
    "wsl -e bash .../verifier-run.sh  # source weakness_memory.sh; persist insert/reject/merge/dedup/evict/preserve/fail-safes under temp HERMES_HOME",
    "wsl -e bash .../id-debug.sh  # confirm weakness_id vs fixtures",
    "wsl -e bash .../hash-check.sh  # SHA-256 of family\\\\n topic_key"
  ]
}
```
