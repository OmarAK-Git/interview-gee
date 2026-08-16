# S1-T2 code review retry (weakness merge)

**Packet:** `03-review-retry`  
**Reviewer:** code-reviewer (did not author the diff)  
**Date:** 2026-08-16  
**Scope:** Task 2 product files only (`scripts/weakness_memory.sh`, `tests/weakness_memory.bats`, `tests/fixtures/memory-empty.md`, `tests/fixtures/memory-three-weaknesses.md`)  
**Spec:** `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` §8 write protocol and §9 (schema, merge, dedup, cap 3, eviction inverse of selection, preserve unrelated content, fail leaves original intact)  
**Prior review:** `.workflow/S1-T2/results/code-reviewer-result.md` (packet `03-review`, verdict `blocking_retry`)

**Verdict:** `approve`

Prior Important items are fixed. Independent WSL probe (isolated `HERMES_HOME` under `mktemp`): eviction keeps refreshed alpha and drops oldest `last_seen`; sort key field 1 is `last_seen` not `first_seen`; persist traces `python3 os.fsync` then `mv -f` on a same-dir temp; validation failure leaves original bytes.

---

## Prior Important — recheck

### 1. Eviction key is `last_seen` (field 7) — fixed

```156:163:scripts/weakness_memory.sh
crossfire_weakness_sort_key_evict() {
  local record="$1"
  local last_seen obs wid
  last_seen=$(crossfire_weakness_record_field "$record" 7)
  obs=$(crossfire_weakness_record_field "$record" 8)
  wid=$(crossfire_weakness_record_field "$record" 1)
  printf '%s\t%s\t%s\t%s' "$last_seen" "$obs" "$wid" "$record"
}
```

Render still maps field 6 → `first_seen`, field 7 → `last_seen`. Probe packed `first_seen=2026-08-01T00:00:00Z` / `last_seen=2026-08-20T20:00:00Z`; sort key field 1 was `2026-08-20T20:00:00Z`.

Cap path is still sort then drop-from-front. Sort keys: `last_seen` asc, `observation_count` numeric asc, `weakness_id` reverse. That is the inverse of selection.

### 2. Test that would fail on `first_seen` sort — fixed

```131:160:tests/weakness_memory.bats
@test "evict by last_seen not first_seen when timestamps disagree" {
  ...
  grep -q "w-e00e42cd5216" "$MEMORY_MD"
  [[ "$yaml" != *"w-1ee6d6febe17"* ]]
  ...
}
```

Sequence: insert alpha (08-01), beta (08-10), gamma (08-15); refresh alpha so `first_seen` stays 08-01 and `last_seen` becomes 08-20; insert delta. Spec evicts beta (oldest `last_seen`). A `first_seen` sort would evict alpha instead.

Independent persist of that sequence: kept `w-e00e42cd5216` (`first_seen` 08-01, `last_seen` 08-20, `observation_count` 2), dropped `w-1ee6d6febe17`, kept gamma, inserted `delta-gap`, count 3.

The older fixture cap test remains (aligned first/last order). It is no longer the only eviction assertion.

### 3. §8 protocol + behavioral persist test — fixed

`crossfire_persist_weakness` now:

1. Advisory `flock -x 9` on `${memory_md}.lock` when `flock` exists (WSL has util-linux flock).
2. Re-read after lock (`fingerprint` + `split` + parse).
3. Validate incoming **after** lock/re-read; on failure release lock and return without write.
4. Merge, then compare dest fingerprint to the post-lock snapshot; mismatch → release lock, retry (max 5).
5. `crossfire_weakness_fsync_file` on the temp (python3 `os.fsync`, else `sync -f`); failure `rm`s tmp and returns 1 (not `sync || true`).
6. `mktemp "${memory_md}.XXXXXX"` then `mv -f` onto dest (same directory).
7. Lock fd closed and lock file removed on release.

The grep-only atomic test is gone. Replacement:

```278:300:tests/weakness_memory.bats
@test "atomic persist renames temp into MEMORY.md with expected content" {
  ...
  [ -f "$MEMORY_MD" ]
  [[ "$(wm_snapshot)" != "$before" ]]
  grep -q "topic_key: atomic-check" "$MEMORY_MD"
  ...
}
```

That persist path was exercised in the probe: dest content changed, expected fields present, lock file gone after return. Trace showed fsync of `MEMORY.md.XXXXXX` then rename onto `MEMORY.md`.

---

## Check 1 — Schema and identity

Unchanged and still met: `w-` + first 12 hex of SHA-256(`family` + `\n` + `topic_key`); family allow-list; RFC3339 `Z`; `answer_ref` `^[^/]+/[^/]+/[0-9]+$`; quote substring / `byte_offset` `start:end` over `wc -c` bytes. No fuzzy merge.

---

## Check 2 — Merge, dedup, cap

Same `weakness_id`: keep `first_seen`, update `last_seen` / session / `answer_ref` / evidence, union `missing_elements`, increment `observation_count`. Identical `source_session_id` + `answer_ref` is a no-op. Cap 3 after insert/merge. Eviction key is now `last_seen`.

---

## Check 3 — Preservation and failure-safety

Unrelated content still preserved via delimiter split. Validation failures snapshot-compare in bats. Probe: bad family left `memory-three-weaknesses.md` byte-identical and returned non-zero.

`write_memory_atomic` and `persist` both refuse dest dirnames that `is_real_hermes_home` accepts (prior Minor #2). Tests still use `mktemp` + `.crossfire/profiles/`.

---

## Findings

### Critical

None.

### Important

None. Prior three Important items are fixed.

### Minor

1. **Atomic leftover glob fails after lock unlink**  
   - File: `tests/weakness_memory.bats:294`  
   - What’s wrong: `for t in "${temps[@]:-}"` with `nullglob` and no `MEMORY.md.*` matches iterates once with an empty string, so leftovers length is 1. That is the success path after `release_lock` removes `.lock`. Independently: empty glob → count 1 via `:-`, count 0 via `"${temps[@]}"`. Persist content assertions still hold.  
   - Fix: iterate `"${temps[@]}"` (no `:-`), or `compgen -G`.

2. **Isolation test still does not observe the write**  
   - File: `tests/weakness_memory.bats:268`  
   - What’s wrong: asserts the setup `MEMORY_MD` string; second `[[ ]]` is still `A || A`.  
   - Fix: snapshot resolved `REAL_HERMES_*` absence around persist; assert the written file is under `$HERMES_HOME`.

3. **No negative test that similar topics stay distinct**  
   - File: `tests/weakness_memory.bats`  
   - What’s wrong: merge coverage uses the same `topic_key` with different case only.  
   - Fix: persist “alpha story” and “alpha stories”; assert two records.

4. **Unlinking the flock lock file can split the lock inode under contention**  
   - File: `scripts/weakness_memory.sh:197`  
   - What’s wrong: `rm -f "$lock_file"` after unlock is a known flock footgun; fingerprint retry is the backstop.  
   - Fix: leave the lock file; close fd 9 only.

---

## Spec / packet AC mapping

| AC | Result |
| --- | --- |
| Schema (id, family, topic_key, timestamps, answer_ref, evidence) | Met |
| Merge same family+topic_key; keep first_seen; union missing | Met |
| Dedup identical session+answer_ref is no-op | Met |
| Cap 3 | Met |
| Eviction inverse of selection (`last_seen` asc, …) | Met (field 7; disagreeing-timestamp test + probe) |
| Preserve unrelated MEMORY.md | Met |
| Validation failure leaves original intact | Met (bats + probe) |
| No fuzzy merge | Met in code; no negative test (Minor) |
| §8 lock / re-read / validate / fsync / atomic rename / retry | Met in persist path; leftover glob in atomic test is Minor |
| Tests never write real `~/.hermes`; isolated/temp paths | Met in setup; dest also checked with `is_real_hermes_home`; isolation test still weak (Minor) |
| Fixtures not mutated in place | Met |

```json
{
  "packet_id": "03-review-retry",
  "status": "done",
  "verdict": "approve",
  "findings": [
    {
      "priority": "Minor",
      "file": "tests/weakness_memory.bats:294",
      "issue": "Leftover glob uses temps[@]:- which fabricates one empty leftover when no MEMORY.md.* remains after lock unlink; bats atomic test can fail on the success path. Persist content assertions independently verified.",
      "fix": "Iterate \"${temps[@]}\" without :- , or use compgen -G."
    },
    {
      "priority": "Minor",
      "file": "tests/weakness_memory.bats:268",
      "issue": "Isolation test only checks the setup MEMORY_MD string; second assertion is tautological.",
      "fix": "Snapshot REAL_HERMES_* absence and assert the written file is under HERMES_HOME."
    },
    {
      "priority": "Minor",
      "file": "tests/weakness_memory.bats",
      "issue": "No test that similar-but-different topics do not merge.",
      "fix": "Persist alpha story vs alpha stories and assert two records."
    },
    {
      "priority": "Minor",
      "file": "scripts/weakness_memory.sh:197",
      "issue": "Lock file is unlinked after flock release, which can split lock inodes under contention.",
      "fix": "Leave the lock file in place; close fd 9 only."
    }
  ]
}
```
