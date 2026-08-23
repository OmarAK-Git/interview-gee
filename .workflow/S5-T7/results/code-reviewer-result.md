# S5-T7 code review — Docs half

**Packet:** `.workflow/S5-T7/packets/03-review.md`
**Reviewer:** code-reviewer (did not author this code)
**Date:** 2026-08-23
**Kind:** scoped review of plan Task 7 **docs half** only
**Scope:** `docs/sparring-1.1.0-practice.md`, `README.md`, `tests/interactive_smoke.md`
**Spec:** plan Task 7 Steps 1–2 + pending live checklist (`docs/superpowers/plans/2026-08-23-practice-interviewer.md` § Task 7), plus S5-T7 ruling (do not mark design spec `implemented`)

Implementer report treated as unevidenced. Diff vs HEAD for the three review files only. Also inspected (read-only, not in product diff): design spec status line; `git status` for extra test/spec writes.

**Verdict:** `approve`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 0 |
| Minor | 2 |
| Blocking | 0 |

**Retry:** no

**Strongest issue:** `docs/sparring-1.1.0-practice.md:33` (Composer / weaknesses panel) still describes generic “cards (family, topic, missing elements, last seen, quote)” and never says `{source} · {family}` buckets or “not `q_live_N` transcripts.” The required Session JD section below it is correct; this leftover is the only place an operator can still read the old transcript-card model.

---

## Required confirms

| Check | Result | Evidence |
| --- | --- | --- |
| Session JD required (pack or paste) | **Yes** | Addendum `docs/sparring-1.1.0-practice.md:48-50` heading **Session JD (required)** + “exactly one job description: pick a shipped pack under `skills/crossfire-interviewer/sources/` or paste JD text.” README `README.md:14-16` “one session = one JD” + **Required JD** pack-or-paste before New session. No remaining “start with no JD” language in the addendum (full-file search). |
| Persona optional | **Yes** | Addendum `:50` “Optional persona flavors interviewer voice.” README `:17` **Optional persona**; empty = default Crossfire voice. |
| Temperature 1–5 default 2 | **Yes** | Addendum `:50` “Temperature 1–5 (default 2) changes the next question only.” README `:18` same range, default, next-question-only. |
| Skip | **Yes** | Addendum `:50` “Skip asks again without assessing.” README `:19` same JD; no assess, no persist, no report line. |
| End report | **Yes** | Addendum `:52` “End session shows Weak and Strong for this session” + `{source} · {family}` buckets, not `q_live_N practice gap` transcripts. README `:20` Weak and Strong report; `{source} · {family}` buckets, not transcript cards. |
| Design spec status is **not** `implemented` | **Yes** | `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md:4` still `approved design (awaiting implementation plan)`. File is **not** in `git status` / `git diff`. Smoke note `tests/interactive_smoke.md:104` records that status and `human_needed`. |
| No new automated test writes real `~/.hermes` | **Yes** | Diff adds markdown only (`tests/interactive_smoke.md` +38). No new `.sh` / `.py` test. New section is a **manual** pending checklist (`:103-104` `human_needed`, all 7 rows `pending`). Monday `HERMES_HOME` is the live operator path, not an automated home write. Isolation block `:19-28` still says demo/test never create real `~/.hermes`. |

---

## Spec compliance (Task 7 docs half)

| Requirement | Result | Evidence |
| --- | --- | --- |
| Step 1: add **Session JD (required)** as specified | **Met** | `docs/sparring-1.1.0-practice.md:48-54` is the plan block verbatim (pack/paste, optional persona, temperature 1–5 default 2 next-question-only, Skip without assessing, End Weak/Strong, `{source} · {family}` not `q_live_N practice gap`, `--max-turns 1` / `--reasoning low` / `gpt-5.6-luna`). |
| Step 1: remove implication start can run with no JD | **Met** | New heading is required. Full-file grep of the addendum finds no “no JD” / “optional JD” / “start without” leftover. |
| Step 2: README practice UI bullets + design spec pointer | **Met** | `README.md:11` design spec path. `:14-20` required JD, optional persona, temperature, Skip, End report. |
| Step 4 live pass **not** claimed; checklist pending | **Met** | `tests/interactive_smoke.md:101-135` dated 2026-08-23, status `human_needed`, steps 1–7 match plan Step 4 (praetor / thin answer / temp 4 / Skip / strong+weak / End report+panel / paste JD no leak + optional persona). Transcript placeholder empty. |
| Design spec status → `implemented` only after live pass | **Met** | Status line unchanged. Ruling followed. |
| No 1.0.0 demo script edits | **Met** | Diff is the three docs files (+ `memory-bank/activeContext.md` out of this review’s product scope). |

Nothing extra in the product surface: no design-spec status flip, no new automated suite, no demo-path edits.

---

## Correctness

- Addendum Session JD text matches the plan snippet exactly; README expands Skip to the locked spec §2 contract (`no assess, no persist, no report line`) and End to family buckets. No contradiction between the two new surfaces on JD / persona / temperature / Skip / End.
- Live checklist rows 1–7 are the plan’s seven acceptance steps, all `pending`. The file does not treat stub or implementer tests as the live bar.
- README removed the bash comment “Weaknesses panel shows cards, not the on-disk YAML,” which would have fought the new End-report bullet. Correct.

---

## Security / isolation

- Docs-only. No secrets, no harness config, no new process that writes a home profile.
- New smoke section names Monday WSL `HERMES_HOME` for the **operator** live pass (plan: “Consumes: Tasks 1–6 working on Monday `HERMES_HOME`”). That is not a new automated test and does not punch `demo_common.sh` fail-closed.

---

## Simplicity

- Addendum repeats `--max-turns 1` / `--reasoning low` / Luna already stated in Inference (`:46` vs `:54`). Copied from the plan snippet; not extra product scope.
- No new abstractions.

---

## Tests

- No new automated tests. `tests/interactive_smoke.md` is a manual ledger; every new Pass? cell is `pending`, so it cannot pass without the live behavior (it does not claim pass).
- Existing `practice_*.sh` isolation (`HOME` tempdir + `$HOME/.hermes` under that tempdir) is unchanged by this diff.

---

## Findings

### Minor 1 — leftover panel wording in the addendum

**File:** `docs/sparring-1.1.0-practice.md:31-33`

**Composer and weaknesses panel** still says the aside “renders cards (family, topic, missing elements, last seen, quote), not YAML.” Task 7 / spec §2 say the right panel is merged `{source} · {family}` buckets, not `q_live_N` transcripts. The new Session JD section (`:52`) states that; this earlier dedicated panel heading does not. An operator who stops at Composer can still picture the old transcript-card model.

**Fix:** One clause on `:33` — family-bucket titles `{source} · {family}`, not `q_live_N practice gap` transcripts.

### Minor 2 — README key-paths row omits the new checklist

**File:** `README.md:154`

`tests/interactive_smoke.md` is still “Manual free-form smoke record (live transcript **human_needed**)” (S4-T11 only). The S5-T7 practice-JD checklist now lives in the same file.

**Fix:** Mention the pending practice-JD / Luna close-out section.

---

## Out of scope (not scored)

- Live Codex/Luna pass (Task 7 Step 4) — correctly `human_needed`.
- Static suite results claimed in implementer-result (`practice_jd.sh` host gap) — verifier owns that; no test file in this docs diff.
- `memory-bank/activeContext.md` bookkeeping.
