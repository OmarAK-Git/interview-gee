# S5-T1 verifier result

**Verdict:** survives

**Claim restated:** S5-T1 is done: four spec-section-4 JD packs exist and parse, the cross-pack leak check passes, `require_session_jd` rejects a missing JD and returns `source_id` / `source_label` / `context_text` on pack and paste paths, and `normalize_temperature` defaults to 2 and rejects 0 and 6. Practice UI / later Sprint 5 wiring is out of scope.

**Single strongest reason:** Fresh commands plus an independent parse of all four packs show the four task ACs hold in the shipped files, not only in the unittest surface.

## Commands run

```
Test-Path -LiteralPath skills\crossfire-interviewer\sources\praetor.md -PathType Leaf
→ True

Test-Path -LiteralPath app\packs.py -PathType Leaf
→ True

py -3 -m unittest tests.test_packs -v
→ 6 tests, OK, 0.001s

& "C:\Program Files\Git\bin\bash.exe" tests/source_packs.sh
→ 8 PASS / 0 FAIL, exit 0
  exists: mccain-cyber-defense, mastercard-r-281517, praetor, alter-ego
  leak: mccain, mastercard, praetor, alter-ego
```

Independent probe (`%TEMP%\s5t1-probe.py`, not a repo file): imported `app/packs.py`, parsed all four packs, called `require_session_jd` / `normalize_temperature` outside the unittest cases.

## File:line reads

- `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md:54-77` — §4 pack contract (facts, 4–6 competencies, one family per row, core|edge, no question scripts, leak example).
- `app/packs.py:14-23` — `normalize_temperature` default 2, reject n<1 or n>5.
- `app/packs.py:34-87` — `parse_pack_file` (front matter, facts, competency table, family/band allowlists, 4–6 comps).
- `app/packs.py:90-92` — `list_source_packs` globs `*.md`.
- `app/packs.py:95-131` — `require_session_jd` reject + pack/paste return keys.
- `tests/test_packs.py:22-80` — unittest coverage (IDs + Mastercard shape only; JD/temp cases).
- `tests/source_packs.sh:10-31` — existence + token leak greps.
- `skills/crossfire-interviewer/sources/mccain-cyber-defense.md:1-21`
- `skills/crossfire-interviewer/sources/mastercard-r-281517.md:1-22`
- `skills/crossfire-interviewer/sources/praetor.md:1-24`
- `skills/crossfire-interviewer/sources/alter-ego.md:1-24`

## AC table (independently confirmed)

| AC | Result | Evidence |
| --- | --- | --- |
| 1. Four packs exist and parse (id, facts, 4–6 competencies, core and edge, one family each) | **Confirmed** | Independent `parse_pack_file` on all four. Each: matching `id`, nonempty facts (3/4/6/6), 5 competencies, both `core` and `edge`, each competency has exactly one family in {behavioral, technical, product}. `list_source_packs` returns exactly those four ids. alter-ego pack-level `families` is `technical,behavioral` (matches the plan pack); each row still has one family. |
| 2. Cross-pack leak check passes | **Confirmed** | `tests/source_packs.sh` 8/0. Independent grep of Praetor / ALTER_EGO / Agent Suite / R-281517 / advisory-only / never-contain / McCain / KL-divergence / shadow profile / Mastercard: distinctive tokens stay in their own pack. |
| 3. `require_session_jd` rejects missing JD; pack and paste return `source_id`, `source_label`, `context_text` | **Confirmed** | Raises on `(None,None,None)`, `("pack",None,None)`, `("paste",None,"   ")`, unknown pack. Pack `praetor` and `mastercard-r-281517` return all three keys. Paste `Acme SWE\n…` → `source_id=pasted-acme-swe`, `source_label=Acme SWE`, `context_text` stripped body. |
| 4. `normalize_temperature` defaults to 2 and rejects 0 and 6 | **Confirmed** | `None`/`""` → 2; `0`/`6`/`"0"`/`"6"` raise `ValueError`. Unittest also passed. |

## Attacks that did not refute

- **Tests weaker than AC1.** `test_four_required_packs_exist` only asserts the id set. `parse_pack_file` does not require nonempty facts or both bands. McCain / Praetor / Alter-ego shape is not unit-tested. That would let a facts-less or core-only pack pass CI. The shipped files themselves still satisfy AC1 (verified by parse, not by trusting the test).
- **Paste `source_label` untested.** `test_require_paste_slugs_first_line` never asserts `source_label`. Live call still returns `Acme SWE`.
- **Goal phrase “used by practice start.”** No `app/` consumer imports `packs` yet. Packet/queue scope forbids practice UI this task; later Sprint 5 work ignored.
- **Path join on `pack_id`.** `sources_dir / f"{pack_id}.md"` is unsanitized. Not an S5-T1 AC; later HTTP concern.
- **Shared word “freeze”** on Mastercard and Alter-ego. Spec leak example is employer-specific tokens (e.g. Praetor `advisory-only` on Mastercard). Not in the leak script; not a cross-pack fact leak.

## Residual (non-blocking)

- Parser does not enforce facts or both bands; CI would not catch a later pack that drops them.
- `REQUIRED_IDS` in `app/packs.py` is unused.

No implementation files, git state, or queue were modified.
