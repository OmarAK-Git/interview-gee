# S5-T7 implementer result — Docs and static close-out

**Task:** S5-T7 docs half (Task 7 Step 1–3 docs; Step 4 live deferred)  
**Branch:** `practice-live-ui`  
**Date:** 2026-08-23  
**Status:** **done (docs half)** — live Luna pass **human_needed**

## Summary

Documented one-JD practice sessions in the practice addendum and README, appended a dated pending live checklist to `tests/interactive_smoke.md`, and refreshed memory-bank active context. Design spec status intentionally **not** set to `implemented` (live pass pending).

## Files changed

| File | Rationale |
| --- | --- |
| `docs/sparring-1.1.0-practice.md` | Added **Session JD (required)** section per plan Task 7: required pack/paste JD, optional persona, temperature 1–5 default 2, Skip, End Weak/Strong report, `{source} · {family}` panel buckets, practice invoke flags. |
| `README.md` | Expanded **Live practice (WSL)** with practice UI bullets (required JD, optional persona, temperature, Skip, End report) and pointer to design spec. |
| `tests/interactive_smoke.md` | Appended **Practice JD — live Luna close-out (S5-T7)** section dated 2026-08-23 with `human_needed` status and full 7-step live checklist + transcript placeholder. |
| `memory-bank/activeContext.md` | Recorded S5-T7 docs half complete; live Luna still pending. |
| `.workflow/S5-T7/results/implementer-result.md` | This report. |

## Not changed (per scope)

- `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md` — status remains `approved design (awaiting implementation plan)` until live pass recorded.
- `.workflow/autopilot-queue.json` — not marked done.
- 1.0.0 demo scripts — untouched.
- Real `~/.hermes` — not touched.

## Verification

### Python (PASS)

```
py -3 -m unittest tests.test_packs tests.test_memory_view -v
```

```
Ran 14 tests in 0.585s
OK
```

All 14 tests passed (pack files, JD/temperature contract, memory view HTTP smoke, UI contract).

### Bash — `tests/source_packs.sh` (PASS)

Via Git Bash (`C:\Program Files\Git\bin\bash.exe`):

```
source_packs: passed=13 failed=0
```

### Bash — `tests/practice_jd.sh` (PARTIAL — Windows host gap)

```
practice_jd: passed=15 failed=1
FAIL: topic missing source label
```

Root cause: `grep` on `$HERMES_HOME/memories/MEMORY.md` — file absent on Windows host (`grep: .../MEMORY.md: No such file or directory`). Same host-gapped MEMORY write limitation noted at S5-T6 verifier. JD fail-closed, Skip, report Weak/Strong KVs, and no `q_live_01 practice gap` checks all passed where they did not depend on on-disk MEMORY.md content.

Also observed: `Python was not found` warning mid-run (Git Bash `python3` alias); script continued via stub path.

### Not run (out of packet scope / live-only)

- `tests/practice_session_stub.sh`
- `tests/practice_inference.sh`
- Live Codex/Luna demo (Step 4) — **human_needed**

## Acceptance criteria

| Criterion | Result |
| --- | --- |
| Practice addendum states JD required (pack or paste), persona optional, temperature 1–5 default 2, Skip, End report | **PASS** |
| README practice UI bullets match | **PASS** |
| No new automated test writes real `~/.hermes` | **PASS** (tests use temp dirs / stub) |
| Design spec status → `implemented` only after live pass | **PASS** (not changed) |
| Live checklist recorded in `tests/interactive_smoke.md` | **PASS** (pending section appended) |

## Concerns

1. **human_needed: live Luna pass** — Operator must run the 7-step checklist in `tests/interactive_smoke.md` (S5-T7 section) on Monday WSL `HERMES_HOME` with Codex / `gpt-5.6-luna`. Only after recording outcomes should the design spec status flip to `implemented` and S5-GE gate proceed.
2. **`practice_jd.sh` topic label check** — Fails on Windows when MEMORY.md is not written to disk; re-run on WSL/Linux for full 16/16 pass before treating static suite as green on all hosts.
3. **No commit** — Per packet instruction; parent/dispatcher owns commit after live pass or separate policy.

## Operator next steps

1. `bash scripts/practice_ui.sh` on WSL Monday profile.
2. Complete checklist rows 1–7 in `tests/interactive_smoke.md`.
3. If all pass: update design spec status to `implemented`, commit docs bundle, mark queue `S5-T7` done.
