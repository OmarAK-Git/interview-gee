# S5-T7 verifier result

Verdict: **survives**

Claim checked: S5-T7 **docs half** is done. Live Codex/Luna pass is **human_needed**. Docs claim treated as unevidenced until independently read and command-checked.

Implementer report was not read.

**Residual:** live Luna / Codex practice-UI pass is `human_needed`. Do not fail the docs half because the operator has not run Luna. Do not flip the design spec to `implemented` until that pass is recorded.

## Strongest reason

The addendum now contains the exact **Session JD (required)** section from the plan (`docs/sparring-1.1.0-practice.md:48-54`): JD is required as pack-or-paste, persona optional, temperature 1–5 default 2, Skip, End Weak/Strong report. README practice-UI bullets state the same five facts and point at the design spec (`README.md:12-20`). No new automated test was added; `py -3 -m unittest tests.test_packs tests.test_memory_view` ran 14 tests OK against tempfile/`HERMES_HOME` only; `Test-Path $env:USERPROFILE\.hermes` is still False after that run. Design spec status remains `approved design (awaiting implementation plan)` (`docs/superpowers/specs/2026-08-23-practice-interviewer-design.md:4`), word `implemented` count 0.

## Acceptance criteria independently confirmed

| AC | Result | Evidence |
| --- | --- | --- |
| 1. Practice addendum states JD is required (pack or paste), persona optional, temperature 1-5 default 2, Skip, End report | **confirmed** | `docs/sparring-1.1.0-practice.md:48-52`. Heading `## Session JD (required)`. Body: exactly one JD via shipped pack under `skills/crossfire-interviewer/sources/` or paste; optional persona; Temperature 1–5 (default 2); Skip without assessing; End session Weak and Strong. `Select-String … 'Session JD'` count **1**. No leftover “no JD / optional JD / without a JD” wording in the addendum. |
| 2. README practice UI bullets match | **confirmed** | `README.md:14-20` bullets: Required JD (pack or paste), Optional persona, Temperature 1–5 default 2 next-question-only, Skip, End session Weak and Strong + `{source} · {family}` buckets. Line 12 points at the design spec. Same five facts as the addendum; README Skip is slightly richer (`no persist, no report line`) and agrees with the design spec, not a contradiction. Diff is +11/−1 on README, not a stale pre-task file. |
| 3. No new automated test writes real ~/.hermes | **confirmed** | `git status --short -- tests/` shows only `M tests/interactive_smoke.md` (manual checklist, not an automated test). `test_packs.py` reads repo `sources/` only. `test_memory_view.py` sets `HERMES_HOME` to `tempfile.mkdtemp()` (`:59-64`, `:117-123`). Packet unittests: 14/14 OK. After the run, `%USERPROFILE%\.hermes` is absent. |

## Extra packet checks (not extra ACs)

| Check | Result | Evidence |
| --- | --- | --- |
| Design spec is not `implemented` | **confirmed** | `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md:4` — `approved design (awaiting implementation plan)`. `git diff --stat` does not include this file. `Select-String implemented` count **0**. |
| Live pass explicitly `human_needed` | **confirmed** | `tests/interactive_smoke.md:101-104` — **human_needed**, checklist rows 1–7 `pending`, live-transcript placeholder empty. `memory-bank/activeContext.md:4,8` — docs half done; live Luna **human_needed**; do not flip spec until recorded. |

## Commands run (this verifier)

```
Select-String -Path docs\sparring-1.1.0-practice.md -Pattern 'Session JD' | Measure-Object
  → 1

py -3 -m unittest tests.test_packs tests.test_memory_view
  → Ran 14 tests in 0.567s  OK

git status --short
  → M README.md
    M docs/sparring-1.1.0-practice.md
    M memory-bank/activeContext.md
    M tests/interactive_smoke.md
    (no new tests/*.py)

git diff --stat -- README.md docs/sparring-1.1.0-practice.md tests/interactive_smoke.md docs/superpowers/specs/2026-08-23-practice-interviewer-design.md memory-bank/activeContext.md
  → README.md                       | 11 ++++++++++-
    docs/sparring-1.1.0-practice.md |  8 ++++++++
    memory-bank/activeContext.md    |  4 ++--
    tests/interactive_smoke.md      | 38 ++++++++++++++++++++++++++++++++++++++
    (design spec not in the diff)

Test-Path -LiteralPath "$env:USERPROFILE\.hermes"
  → False

Select-String -Path docs\superpowers\specs\2026-08-23-practice-interviewer-design.md -Pattern '^\*\*Status:\*\*'
  → **Status:** approved design (awaiting implementation plan)

(Select-String -Path docs\superpowers\specs\2026-08-23-practice-interviewer-design.md -Pattern 'implemented').Count
  → 0

Select-String -Path docs\sparring-1.1.0-practice.md -Pattern 'without a JD|no JD|optional JD|JD optional'
  → (no matches)
```

## file:line reads

- `docs/sparring-1.1.0-practice.md:48-54` — Session JD (required) section; pack or paste; optional persona; temp 1–5 default 2; Skip; End Weak/Strong; `{source} · {family}`.
- `README.md:12-20` — design-spec pointer + five practice-UI bullets matching the addendum.
- `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md:4` — status not `implemented`.
- `tests/interactive_smoke.md:101-134` — S5-T7 live Luna section, `human_needed`, all seven checklist rows pending.
- `memory-bank/activeContext.md:4,8` — docs half vs live Luna residual.
- `tests/test_packs.py` — no home writes; repo `SOURCES` only.
- `tests/test_memory_view.py:59-77,117-147` — isolated `HERMES_HOME` tempfile; restore + rmtree.

## Isolation

Packet unittests used repo fixtures and temp `HERMES_HOME` only. Verifier did not create or write `%USERPROFILE%\.hermes`. That path remains absent.

## What would have refuted (not found)

- Addendum missing pack-or-paste, persona-optional, temp 1–5/default 2, Skip, or End Weak/Strong.
- Leftover addendum wording that start can run with no JD.
- README bullets omitting one of those five facts, or contradicting the addendum.
- Design spec status flipped to `implemented` before the live pass.
- A new automated test (or an edit to `test_packs` / `test_memory_view`) targeting real `~/.hermes`.
- Live Luna claimed recorded while the checklist is still empty (would refute a “fully done” claim; the docs-half claim correctly leaves it `human_needed`).

## human_needed

Live practice UI on Codex / `gpt-5.6-luna`: one pack session, one paste session, mid-session temperature, one Skip, End shows Weak and Strong, panel title `{source} · {family}`. Checklist in `tests/interactive_smoke.md` is pending. Operator must run it. Not used to refute the docs-half claim.
