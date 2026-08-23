# Practice weave (addendum)

**Date:** 2026-08-23  
**Status:** implemented in S6-T1 (2026-08-23). Live practice UI behavior below is authoritative.  
**Authority:** the live practice UI (`bash scripts/practice_ui.sh`, `http://127.0.0.1:8787`). That is the session you run and show. Amends `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md` §5 opener sentence.

The old scripted theater (`scripts/demo.sh`, `demo_session_2.sh`, `sparring-1.0.0` §13) is **legacy**. S6 does not spend time on it and does not rewrite it. It is not the Monday live path.

## Spec conflict (resolved)

| Doc | Rule |
| --- | --- |
| `sparring-1.0.0` §5 / §13 | Demo session two **opens on** the persisted weak area. Never cut. |
| Practice design §5 (as written for S5) | If `MEMORY.md` has a fitting gap, the opener **may target** that gap. |
| Practice plan Task 4 | Memory branch `-q` still says “Ask ONE question that **targets those missing elements**.” |
| This addendum (after S5-GE) | Practice New session is a **mock for one JD**. The first spoken question is a normal in-role question. Weaknesses **bias follow-ups**, they do not become the session subject. |

S5 may still ship the Task 4 memory-opener wording. **S6 replaces that live-UI behavior.** Leave `demo.sh` / `demo_session_2.sh` unread for this task.

## Product rule

Every new practice session will usually already have a weakness. That is the point. The interviewer knows what the operator is bad at and still interviews them **as prep for a role they have soon**.

- **JD owns the question stream** (pack or paste from S5).
- **MEMORY.md seasons follow-ups:** at most one probe that listens for a known missing element *inside the current story*, then move on.
- Do not restating the same Praetor/tradeoff/verification drill for the rest of the session.
- Honor Skip and “I don’t want this topic” as a new JD question, not as hesitation about the same gap.
- Do not speak `weakness_id`. Do not ask the operator to name the weakness.
- Attribution kv (`opening_target_source=MEMORY.md`, …) may still print for honesty. It must **not** force the first spoken question to be the drill.

## Out of scope

- Rewriting the unused 90s `demo.sh` theater (leave those scripts as-is; they are not the live demo).
- A second memory store, promotion gate, or competency picker.
- Reopening the persist rule (`≥ 2` missing).
