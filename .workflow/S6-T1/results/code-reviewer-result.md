# S6-T1 code review — Practice weave (JD owns Q1)

**Packet:** `.workflow/S6-T1/packets/03-review.md`  
**Reviewer:** code-reviewer (did not author this code)  
**Date:** 2026-08-23  
**Kind:** scoped review of path 2 (harness + skill)  
**Authority:** `docs/superpowers/specs/2026-08-23-practice-weave-addendum.md` + researcher path 2  
**Scope:** `scripts/practice_session.sh`, `skills/crossfire-interviewer/SKILL.md` Practice section, `tests/practice_jd.sh`, design §5  
**Not in scope as edits:** `scripts/demo.sh`, `scripts/demo_session_2.sh`, persist rule, Session-two / return-session skill body

Implementer report treated as unevidenced. Review is from the working-tree diff vs HEAD.

**Verdict:** `pass`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 0 |
| Minor | 3 |
| Blocking | 0 |

**Retry:** no

**Strongest issue:** `tests/practice_jd.sh` treats `grep 'season follow-ups'` as proof that answer `-q` injects MEMORY bias, but that string also lives in the start preamble, so the check stays green if the answer-turn injection is deleted.

---

## Confirmations (packet)

| Check | Result | Evidence |
| --- | --- | --- |
| First start `-q` is JD-only | **Yes** | Memory-opener `-q` and `crossfire_stub_opener_question` branch deleted. Live start always uses `Ask ONE interview question from this JD only.` (`practice_session.sh:143-145`). Stub start always uses the Praetor advisory line (`:139`). No `targets those missing elements` / `Session-two style opener` remain in the file. |
| MEMORY does not force Q1 to be the drill | **Yes** | Detection + `crossfire_print_opener_attribution` + `opening_target_source` kv kept (`:126-135`, `:165`). Selection is **not** interpolated into start `-q`. Practice skill section now says this section wins and Q1 is not a restatement of the newest gap (`SKILL.md:190`, `:198`). |
| `demo_session_2.sh` / `demo.sh` untouched | **Yes** | `git diff --name-only` does not list either file. `demo_session_2.sh` still references `MEMORY.md` (line 25). `crossfire_build_opener_cmdline` / `crossfire_stub_opener_question` unchanged in `crossfire_lib.sh`. |
| Persist `>= 2` unchanged | **Yes** | No diff to `crossfire_spool_should_persist` (`crossfire_lib.sh:408-423`). Practice skill still `persist_recommended: true` only when `count(missing_elements) >= 2` (`SKILL.md:218`). Demo persist sentence (`SKILL.md:68`) and the three demo question strings (`SKILL.md:86-88`) unchanged. |

---

## Spec compliance

| Requirement | Result | Evidence |
| --- | --- | --- |
| Path 2: stop memory-opener branch; always fresh JD `-q` | **Met** | Single start prompt path (`practice_session.sh:137-145`). |
| Keep attribution kv when a weakness exists | **Met** | `target_source` / `opening_target_source` still printed (`:165`). `practice_jd.sh` session-two start after persist still asserts `opening_target_source=MEMORY.md`. |
| Answer: MEMORY seasons at most one in-story follow-up | **Met (code)** | Live answer injects family + `missing_elements` bias and sets `CROSSFIRE_MEMORY_PROBE_USED=1` (`:236-243`). Persisted on `practice.state` (`:68-75`). |
| Skip: new JD question, not same-gap hesitation | **Met** | Skip live `-q` (`:328-329`); Practice Skip subsection (`SKILL.md:225`). |
| Practice section wins; do not apply Session-two / return-session opener | **Met** | `SKILL.md:190`. Session-two (`:132-148`) and return-session opener (`:173`) left intact for demo / free-form Monday. |
| Design §5 no longer says opener may target the gap | **Met** | §5 now: first spoken question is in-role from this JD; weaknesses season follow-ups (`design.md:95`). `opener may target` absent. |
| Plan Task 4 memory-opener wording amended | **Met** | Plan now: do not use Session-two memory-opener `-q`; MEMORY seasons answer turn. |
| Do not rewrite demo theater; no second memory store | **Met** | Demo scripts and persist helper not in the diff. |
| Tests: Q1 is JD stub, not `crossfire_stub_opener_question` | **Met** | `practice_jd.sh:104-124` rejects the three stub-drill phrases and requires the Praetor advisory line. Packet ruling correctly put this in `practice_jd.sh`, not `practice_session_stub.sh`. |

---

## Findings

### Critical

None.

### Important

None.

### Minor (track)

#### Minor 1 — `tests/practice_jd.sh:126` does not prove answer-turn bias

`grep -q 'season follow-ups'` matches the **start preamble** (`practice_session.sh:42`: `MEMORY.md may season follow-ups only`) as well as the answer bias (`:240`). Deleting the answer-turn `memory_bias` block would leave this check green.

**Fix:** grep a string unique to the answer prompt (e.g. `Known weakness from MEMORY.md` or `inside the current story`) or assert `practice.state` after a MEMORY start then a live-shaped answer path.

#### Minor 2 — `CROSSFIRE_MEMORY_PROBE_USED` is consumed on the first live answer, not when a probe is spoken

`practice_session.sh:241-242` sets the flag when the bias is **injected**, including the Hermes-fail path that then `save_state`s (`:260`). A first follow-up that is a new JD question (temperature 2) permanently drops harness seasoning. Later thin answers rely only on in-context `MEMORY.md` + skill text.

**Fix (if seasoning is missed in live use):** keep sending the bias with “already used / do not restart the drill” until a probe is observed, or only flip the flag on the fail-closed success path after a probe-shaped follow-up. Not required for path 2’s “at most one” cap.

#### Minor 3 — `practice.state` opener fields are unquoted

`practice_session.sh:70-74` writes `CROSSFIRE_OPENER_MISSING_CSV=${...}` without `printf %q` (unlike `CROSSFIRE_JD_SOURCE_LABEL` / `PERSONA`). Today’s parser strips spaces (`weakness_memory.sh:334`), so `action,result` sources cleanly. A future record with whitespace or shell metacharacters would break `source` under `set -e`.

**Fix:** write those five lines with `printf '%s=%q\n'`.

---

## Blast radius / non-findings

- Hermes may still see `MEMORY.md` plus Session-two / return-session text in the same skill file. Path 2’s mitigation is the Practice-section override + JD-only start `-q` + preamble. That is the approved structural guarantee; residual model drift is `human_needed` (researcher open question 2).
- `practice_session_stub.sh:75` still labels the check “session two memory opener” and only asserts attribution. Packet forbade editing that file.
- Family-fit filter still absent (researcher: non-blocking).
- Addendum status line now says “implemented in S6-T1” before skeptic-verify; docs-only, not a harness defect.

---

## Checks run (this review)

- `git diff` on `practice_session.sh`, `SKILL.md`, `practice_jd.sh`, design §5, plan Task 4, addendum status
- `git diff --name-only -- scripts/demo.sh scripts/demo_session_2.sh scripts/crossfire_lib.sh` → empty
- Grep: no `targets those missing elements` in `practice_session.sh`; no `opener may target` in design spec; `MEMORY.md` still in `demo_session_2.sh`; demo Q1–Q3 strings still at `SKILL.md:86-88`
- Read `crossfire_spool_should_persist` (unchanged `count >= 2`); Practice persist sentence unchanged
