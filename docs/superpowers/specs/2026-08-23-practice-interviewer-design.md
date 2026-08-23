# Practice interviewer, one JD, temperature, close-out

**Date:** 2026-08-23  
**Status:** approved design (awaiting implementation plan)  
**Authority:** this document wins for the practice UI path. `sparring-1.0.0` remains the 90s CLI demo contract. `docs/sparring-1.1.0-practice.md` still wins for isolation, Monday home, voice, and inference plumbing unless this file names a change.

## 1. Problem

The learning loop, persist rule, and cross-session opener are in place. The practice interviewer is still an assessment contract plus “ask something from McCain / Mastercard / Praetor / ALTER_EGO.” Live sessions do not show which job is in play, do not let the operator paste a JD, do not control curveball rate, and End session only writes `q_live_N practice gap` cards that look like a transcript.

The operator will demo the **live** path. Stub practice is not the acceptance bar.

## 2. Locked decisions

| Topic | Decision |
| --- | --- |
| Runtime | Hermes Agent is the harness. We write a skill, source packs, and thin practice UI chrome. We do not add a competency picker or a second memory store. |
| Memory | Hermes `MEMORY.md` remains the store. Weaknesses stay in the existing delimited block. This increment does not change who writes that block. |
| Session JD | Every new session requires **exactly one** job description. Hot path. |
| JD source | Pick a shipped pack **or** paste JD text. Paste is in scope. |
| Persona | Optional free text (title, what they do, tenure). Not schema-enforced. Empty = default Crossfire voice. |
| Question wording | Skill-generated from the session JD. No pre-written tail question list. |
| Temperature | 1–5, default **2**. Mid-session change applies to the **next** question. Selection entropy only (rare-but-plausible, still in-role). |
| Skip | First-class control. No assess, no persist, no report line. Ask a different question from the same JD. |
| Close-out | End session produces a report of **weak and strong**. Right panel is family buckets, not a transcript. |
| Demo 1.0.0 | Untouched: three questions, isolation, memory-only opener, no packs/temp/Skip/paste. |
| Persist rule | Unchanged: recommend persist iff `≥ 2` missing elements of one family. Judgment stays deterministic. |
| Latency | Practice invokes: `--max-turns 1`, `--reasoning low`. Codex default model `gpt-5.6-luna`. Already injected in `crossfire_practice_speed_tune`. Override with `CROSSFIRE_CODEX_MODEL` / `CROSSFIRE_REASONING`. |
| Verification | Live practice path. Do not treat stub sessions as proof. Static pack/skill contract checks (no Hermes) are still allowed. |

## 3. Architecture

```text
Practice UI (chrome)
  ├── New session: required JD (pack | paste) + optional persona + temperature + inference
  ├── Visible context of that one JD
  ├── Mid-session temperature + Skip
  └── End: show report; refresh weakness buckets

Hermes (runtime)
  ├── --resume session, skill load, MEMORY.md in context
  ├── Interviewer skill: pick competency, word question, probe, propose YAML
  └── Optional one-line spoken closer on End

Existing practice wrapper (thin pipe only)
  ├── Pass JD text or pack id, persona, temperature into the Hermes prompt
  ├── Skip turn = do not spool/persist
  ├── End = existing persist flush + aggregate this session’s strong/weak
  └── Must not grow a question-selection engine
```

Non-determinism is allowed for **question wording**. It is not allowed for the persist rule.

## 4. Source packs

Shipped presets live at `skills/crossfire-interviewer/sources/`. This increment migrates spec §4 into four packs:

- `mccain-cyber-defense`
- `mastercard-r-281517`
- `praetor`
- `alter-ego`

Each pack:

```yaml
id: mastercard-r-281517
employer: Mastercard
role: Agent Suite PM
requisition: R-281517
families: [product]
```

- **Allowed facts** — only tokens the interviewer may treat as true for that pack.
- **Competencies** — 4–6 rows: `id`, one `family`, `band` (`core` \| `edge`), one-line competency.
- No pre-written question scripts.

Cross-pack leaks are forbidden (Praetor “advisory-only” must not appear on a Mastercard pack). Adding a JD to the **library** later is a new file in `sources/`. Demo questions in `SKILL.md` stay verbatim and do not read packs.

## 5. Session start (hot path)

**New session** does not start without a JD.

Operator sets:

1. **Job description (required, exactly one)**
   - **Pick pack:** one of the four shipped packs (or a later library file), or
   - **Paste:** raw JD text for this session only. Not written into the repo unless the operator later adds a pack by hand.
2. **Visible context** before the first question: employer/role/requisition and competencies for a pack; the pasted text (scrollable) for a paste.
3. **Interviewer persona (optional):** free text. Passed through to the skill.
4. **Temperature:** default 2, 1–5, changeable later.
5. **Inference:** existing Nous / Codex toggle (Codex → Luna). Applies on New session only.

Allowlist for the session is **this JD only**. A paste is not bound to spec §4. A shipped pack is. Do not mix a second employer’s facts into the same session.

If `MEMORY.md` already has weaknesses, the opener may target the newest gap that fits **this** JD’s families. Do not speak `weakness_id`. Do not ask the operator to name the weakness.

## 6. Interviewer procedure

Practice section of `skills/crossfire-interviewer/SKILL.md` (demo contracts above it stay as-is).

**Start.** One question from this JD. Core competency at temperature 2. Persona flavors voice if present. Do not invent facts beyond the JD.

**After a real answer.**

1. Declare exactly one family.
2. `missing_elements` = what was actually absent, not the full checklist.
3. Same propose-only YAML. `persist_recommended` only if `≥ 2` missing.
4. Probe the story when thin (last time, I not we, a number, what changed, how they would know they were wrong), or move to a new competency.

**Temperature (next question only).**

- **1:** core competency only; prefer staying on the current story (probe).
- **2 (default):** core competency, typical angle; may open a new core competency after a complete answer.
- **3–5:** edge competency or rarer in-role angle, still fact-bound.
- Mid-session slider does not rewrite the question already on screen.

**Skip.** Operator control. No YAML, no persist, no report line. Ask a different question from the same JD. If they skipped because it sounded invented, the replacement must stay inside this JD.

The skill does not write `MEMORY.md`, pick the JD, or render the report.

## 7. Close-out

### End-session report (this session only)

Chat (or a report block) after End, not only “Persisted N weakness(es).”

- **Weak:** families that hit persist (`≥ 2` missing). Name the missing pieces, not the raw answer.
- **Strong:** families assessed this session that did **not** persist.
- Skips omitted.

The wrapper aggregates this session’s assessments. Hermes may add one spoken closer. No new scorer.

### Right panel (across sessions)

Category buckets from `MEMORY.md`, not a transcript.

- Merge key: `{source_id} + family`. `source_id` is the pack `id`, or for a paste a slug from the first employer/role line (`pasted-acme-swe`). If that line is empty, `pasted-jd`.
- Title: `{source label} · {family}` — never `q_live_01 practice gap`.
- Tags: only actual missing elements.
- `Seen N times · date`.
- One short evidence quote, not the full answer.
- Same merge key increments `observation_count`. Strong answers never get a card.
- Global cap remains **3** records (`sparring-1.0.0`). Extra records drop by the existing freshness rule. The panel shows whatever is in `MEMORY.md` (all JDs), each card labeled with its source.

During the session the panel may show prior memory. After End it refreshes with merges from this session.

## 8. UI chrome (practice only)

- New session: JD picker **or** paste box (one required), persona box, temperature, existing inference + Start.
- Visible context region for the active JD.
- Temperature control live during the session (next question).
- **Skip** next to Send.
- End → report in chat; refresh buckets.

Do not build JD-library management UI beyond pick-or-paste.

## 9. Failure behavior

- Live parse failure: keep the operator text, log raw stdout under `.crossfire/runs/<run_id>/skipped/`, skip assessment, continue. Never `fail_closed` mid-session.
- One model pass per answer. No demo K=3 retry.
- Invention: operator Skip. No auto-detector.
- Missing JD on Start: do not start.
- Empty persona: allowed.
- 90s demo path never loads packs, paste, temperature, or Skip.

## 10. Tests and live demo

**Acceptance is a live practice session** (Luna, `--reasoning low`, `--max-turns 1`): pick or paste one JD, optional persona, several answers, mid-session temperature, at least one Skip, End → report with weak and strong, panel shows family buckets not `q_live_N` transcripts.

**Allowed without Hermes**

- Four packs parse (id, facts, 4–6 competencies, core/edge, one family each).
- Cross-pack leak check.
- `SKILL.md` still contains the three demo questions verbatim plus the practice procedure.
- Start without a JD is rejected (UI or wrapper contract).

**Not the bar**

- Expanding `CROSSFIRE_PRACTICE_STUB` as proof of this design.
- N=5 live wording gold files.
- Changing the 1.0.0 demo harness.

## 11. Out of scope

- Session history / reread past sessions (already a 1.1.0 named cut).
- Candidate-skill promotion gate.
- Dual-maintaining 90s demo theater.
- Auto-saving a paste into `sources/` (operator can add a pack file later).
- Reopening who writes the `MEMORY.md` weakness block.
- Model sampling temperature (this is question-selection entropy only).

## 12. Implementation slices (for the plan)

1. Packs + skill procedure (JD allowlist, probes, temperature, Skip wording).
2. New-session chrome: required pick-or-paste, visible context, optional persona, live temperature.
3. Close-out: persist topic `{source label} · {family}`, merge buckets, End report (strong + weak).
4. Live demo pass on Luna / low / max-turns 1.
