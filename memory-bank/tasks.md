# Tasks

Projected from the plan into `.workflow/autopilot-queue.json`.

## Sprint 1 — GATED

- `S1-T1` … `S1-GE` done

## Sprint 2 — Cross-session learning (must) — GATED

- `S2-T5` … `S2-GE` done (pass, Grok 4.6-high)

## Sprint 3 — Evidence + risk beat (nice) — GATED

- `S3-T4` done
- `S3-T8` done
- `S3-T9` done
- `S3-T10` done
- `S3-GE` done (pass, Grok 4.6-high)

## Sprint 4 — Acceptance (must) — GATED

- `S4-T11` done — live transcript **human_needed** (not demo blocker)
- `S4-T12` done
- `S4-GE` done (pass, Grok 4.6-high)

## Sprint 5 — Practice interviewer (must) — GATED

Plan: `docs/superpowers/plans/2026-08-23-practice-interviewer.md`
Spec: `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md`

- `S5-T1` done — four source packs + stdlib parser (verifier survives)
- `S5-T2` done — practice interviewer skill procedure (verifier survives)
- `S5-T3` done — one JD required on start (verifier survives)
- `S5-T4` done — preamble + Skip + mid-session temperature (verifier survives)
- `S5-T5` done — JD/persona/temp/Skip UI (verifier survives; no browser MCP, HTTP+contract used)
- `S5-T6` done — End Weak/Strong report; topic `{source} · {family}` (verifier survives; MEMORY write host-gapped on Windows python3)
- `S5-T7` done — docs; live Luna pass **human_needed**
- `S5-GE` done (pass, Grok 4.6-high-fast) — live Luna **human_needed**

Next runnable: none (queue drained).

## Sprint 6 — Practice weave (must) — GATED

- `S6-T1` done — JD owns Q1; MEMORY seasons follow-ups (verifier survives)
- `S6-GE` done (pass, Grok 4.6-high-fast) — live JD-first New session **human_needed**

Parked for S5-T3: sanitize `pack_id` before joining to a filesystem path (`app/packs.py` `require_session_jd`). Reviewer minor; local-only until HTTP.

## Sprint 6 — Practice weave (must) — QUEUED AFTER S5-GE

Addendum: `docs/superpowers/specs/2026-08-23-practice-weave-addendum.md`

Do not start while Sprint 5 is in progress. The other chat owns S5-T2…S5-GE.

- `S6-T1` pending — JD owns the first question; MEMORY.md biases follow-ups only (depends S5-GE; needs research)
- `S6-GE` pending — phase exit, Grok in-session (depends T1)

Supersedes practice design §5 “opener may target the newest gap” and plan Task 4 “Ask ONE question that targets those missing elements.” This is the live UI you run and show. Unused `demo.sh` theater is left alone, not the Monday path.
