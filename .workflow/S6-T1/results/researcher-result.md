# S6-T1 researcher: practice weave path

**Packet:** `01-research` · **Status:** done · **Date:** 2026-08-23  
**Authority:** `docs/superpowers/specs/2026-08-23-practice-weave-addendum.md` (live UI). Demo `sparring-1.0.0` session-two opener is untouched.

## Verdict

**Chosen path: harness + skill (path 2).** Stop using the practice memory-opener branch for the first spoken question. Always start with the fresh JD `-q`. Keep MEMORY.md selection for attribution kv only. Inject the newest fitting gap as **follow-up bias** on the answer turn (at most one in-story probe, then move on). Rewrite the Practice interviewer skill section so Session-two / Monday return-session opener rules do not win on the live UI.

## Why path 2

The addendum replaces S5 Task 4 live-UI behavior. Product rule: JD owns the question stream; MEMORY.md seasons follow-ups; attribution may print but **must not force Q1 to be the drill** (`practice-weave-addendum.md:20–29`). Practice New session is a mock for one JD, not a restatement of the newest gap (`:16`).

Current start path already has two branches. When `MEMORY.md` has a weakness block:

| Surface | Memory-opener (today) | Fresh JD (today, no memory) |
| --- | --- | --- |
| Live `-q` | `Session-two style opener… Ask ONE question that targets those missing elements…` (`practice_session.sh:134–136`) | `Ask ONE interview question from this JD only.` (`:139–140`) |
| Stub spoken Q | `crossfire_stub_opener_question` — action/result, tradeoff/verification, or product-gap drill (`practice_session.sh:126–127` → `crossfire_lib.sh:599–618`) | Fixed Praetor advisory question (`practice_session.sh:129`) |
| Skill | “first question **may target** those missing elements” (`SKILL.md:196`) | Same section still authorizes targeting |

The bounded question is the **spoken** first question on New session. Path 1 keeps the branch that *selects* the newest weakness and *puts* `weakness_id` / `family` / `missing_elements` into the Q1 prompt. Rewriting the words “targets those missing elements” does not remove that payload. Models will still open on the listed gap. Stub New session after persist already *is* the drill (`crossfire_lib.sh:604`).

Answer today has **no** MEMORY seasoning (`practice_session.sh:233–236`: assess + one follow-up per temperature). Path 1 never adds that, so it also misses “at most one probe inside the current story, then move on” (`addendum.md:25`).

Hermes may still have `MEMORY.md` in context. If Practice still says Q1 may target the gap, and Session-two / Return-session opener (`SKILL.md:132–173`) still say “ask one question that targets the newest weakness,” a “fresh JD” `-q` can still produce the drill. Path 2 must **override** those sections for the practice wrapper.

Attribution can stay: detect block, `crossfire_print_opener_attribution`, `opening_target_source=MEMORY.md` kv (`practice_session.sh:116–122`, `:162`; `addendum.md:29`). Do not feed that selection into start `-q`.

Skip already asks a different JD question (`practice_session.sh:316–317`). Addendum adds: Skip / “I don’t want this topic” is a **new JD question**, not hesitation about the same gap (`addendum.md:27`). Small skip `-q` tweak only.

## Rejected path (skill-only) — opportunity cost

**What it is:** keep `if [ "$target_source" = "MEMORY.md" ]` for the first `-q`; change that string so it does not say “targets those missing elements”; tweak `SKILL.md:196`.

**Why cheaper:** one live prompt + one skill sentence. `tests/practice_session_stub.sh:75` already only asserts `opening_target_source=MEMORY.md`, not the spoken drill. Demo helpers stay unused.

**Cost of taking it (why rejected):**

1. Q1 prompt still ships the newest gap. Live New session will often restatement Praetor/tradeoff/verification. **Fails the bounded question.**
2. Stub session-two start still calls `crossfire_stub_opener_question` — deterministic drill, not a JD competency question.
3. No follow-up bias on answer. Addendum’s “MEMORY seasons follow-ups” is unimplemented.
4. Skill bleed: Monday return-session opener and Session-two wording remain in the same skill file the practice preamble tells Hermes to follow (`practice_session.sh:41`).
5. S5 Task 4 behavior is mostly unchanged; S6 “replaces that live-UI behavior” (`addendum.md:18`) is not met.

**Cost of rejecting it:** two harness prompts (start + answer) plus a Practice-section rewrite; stub test must distinguish attribution vs spoken Q; slightly more review surface. That is the price of a structural guarantee.

## Exact implementer edit list

Do **not** edit: `scripts/demo.sh`, `scripts/demo_session_2.sh`, `crossfire_build_opener_cmdline` / `crossfire_stub_opener_question` (demo), `SKILL.md` Session-two opener or Free-form Monday return-session opener, `app/*`, `sparring-1.0.0`, design §5 body (addendum already amends it).

### 1. `scripts/practice_session.sh` — `crossfire_practice_start`

- Keep MEMORY detection + attribution (`:116–122`). Still set `target_source` and print kv (`:162`, `:168`).
- **Delete** the live memory-opener `-q` (`:134–137`). Live start **always** uses the fresh JD prompt (`:139–140`).
- **Delete** stub `crossfire_stub_opener_question` (`:126–127`). Stub start **always** uses the existing JD stub question (`:129`).
- Persist opener fields on `practice.state` if needed for answer bias (`CROSSFIRE_OPENER_FAMILY`, `CROSSFIRE_OPENER_MISSING_CSV`, `CROSSFIRE_OPENER_WEAKNESS_ID`) — selection already runs at start; answer must not re-open as a drill.
- Optional one preamble line (`:32–44`): first spoken question is a JD competency question; MEMORY.md seasons follow-ups only; do not speak `weakness_id`.

### 2. `scripts/practice_session.sh` — `crossfire_practice_answer` live `-q` (`:233–236`)

When start selected a MEMORY gap, append follow-up bias: known `family` + `missing_elements`; **at most one** probe that listens for a missing element *inside the current story*; then move on; do not restart the same drill; do not speak `weakness_id`; do not ask the operator to name the weakness. If no MEMORY gap, leave today’s assess + temperature follow-up as-is.

### 3. `scripts/practice_session.sh` — skip live `-q` (`:316–317`)

Add: if they declined a topic, ask a **new** JD question, not hesitation about the same gap. No assessment YAML (already true).

### 4. `skills/crossfire-interviewer/SKILL.md` — **Practice interviewer only** (`:188–225`)

Replace `:196` with addendum rules:

- This section **wins** when the practice wrapper is driving. Do not apply Session-two opener or Return-session opener.
- First question: normal in-role question from **this JD** (core at temperature 2). Not a restatement of the newest MEMORY.md gap.
- MEMORY.md: at most one follow-up probe inside the current story for a known missing element, then move on. Do not make the gap the session subject.
- Skip / “I don’t want this topic”: new JD question, not the same gap.
- Do not speak `weakness_id`. Do not ask the operator to name the weakness.
- Still: no `MEMORY.md` writes; propose-only YAML unchanged.

Do not change the three demo question strings (`tests/source_packs.sh:32–33` greps them).

### 5. `tests/practice_session_stub.sh`

Keep `:75` `opening_target_source=MEMORY.md` on session two (attribution honesty). **Add:** session-two `question=` / `tts_text=` is the **fresh JD stub** (Praetor advisory line), **not** `crossfire_stub_opener_question` (no “what action did you take and what measurable result”, no “technical gap around”, no “product decision gap”).

### 6. Out of scope

No second memory store, competency picker, persist-rule change, or `live-two-session.sh` rewrite (it only WARNs if attribution is missing — still valid).

## Evidence (verified)

- Addendum vs S5 opener: `practice-weave-addendum.md:9–18`, `:20–29`
- Memory vs fresh start: `practice_session.sh:116–141`, `:162`
- Stub drill: `practice_session.sh:126–127`; `crossfire_lib.sh:599–618`
- Skill Q1 target: `SKILL.md:196`; Session-two / return-session: `SKILL.md:146–148`, `:173`
- Answer has no MEMORY bias: `practice_session.sh:233–236`
- Stub test checks attribution only: `tests/practice_session_stub.sh:69–75`
- Demo left alone: packet `:5`; addendum `:7`, `:33–34`

## Dead ends

- Softening the memory-opener `-q` while listing `missing_elements` — still a drill prompt.
- Relying on skill-only while Hermes can see `MEMORY.md` + return-session opener.
- Changing `crossfire_stub_opener_question` globally — that is demo session two.
- Treating `opening_target_source=MEMORY.md` as proof Q1 is a JD question — kv is honesty, not the spoken subject.

## Open questions (non-blocking)

1. Family-fit filter: start today selects newest weakness with no JD-family check (`practice_session.sh:116–121`). Addendum “newest gap that fits this JD” can stay as “inject only if family is plausible”; do not block Q1 on fit.
2. Live Luna proof of spoken Q1 is **human_needed** (do not hit real `~/.hermes` in automated tests). Stub + static skill/harness checks are the implementer bar.
