# Practice weave (addendum)

**Date:** 2026-08-23  
**Status:** queued after Sprint 5 close-out. Do not implement during S5-T2…S5-GE.  
**Authority:** practice UI only. Amends `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md` §5 opener sentence. `sparring-1.0.0` §13 memory-only opener is unchanged.

## Spec conflict (resolved)

| Doc | Rule |
| --- | --- |
| `sparring-1.0.0` §5 / §13 | Demo session two **opens on** the persisted weak area. Never cut. |
| Practice design §5 (as written for S5) | If `MEMORY.md` has a fitting gap, the opener **may target** that gap. |
| Practice plan Task 4 | Memory branch `-q` still says “Ask ONE question that **targets those missing elements**.” |
| This addendum (after S5-GE) | Practice New session is a **mock for one JD**. The first spoken question is a normal in-role question. Weaknesses **bias follow-ups**, they do not become the session subject. |

S5 may still ship the Task 4 memory-opener wording. **S6 replaces that practice behavior.** Demo scripts stay on §13.

## Product rule

Every new practice session will usually already have a weakness. That is the point. The interviewer knows what the operator is bad at and still interviews them **as prep for a role they have soon**.

- **JD owns the question stream** (pack or paste from S5).
- **MEMORY.md seasons follow-ups:** at most one probe that listens for a known missing element *inside the current story*, then move on.
- Do not restating the same Praetor/tradeoff/verification drill for the rest of the session.
- Honor Skip and “I don’t want this topic” as a new JD question, not as hesitation about the same gap.
- Do not speak `weakness_id`. Do not ask the operator to name the weakness.
- Attribution kv (`opening_target_source=MEMORY.md`, …) may still print for honesty. It must **not** force the first spoken question to be the drill.

## Out of scope

- Changing `demo_session_2.sh` or the 90s memory-only opener.
- A second memory store, promotion gate, or competency picker.
- Reopening the persist rule (`≥ 2` missing).
