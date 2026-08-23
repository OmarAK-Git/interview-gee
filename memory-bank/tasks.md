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

## Sprint 5 — Practice interviewer (must) — IN PROGRESS

Plan: `docs/superpowers/plans/2026-08-23-practice-interviewer.md`
Spec: `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md`

- `S5-T1` done — four source packs + stdlib parser (verifier survives)
- `S5-T2` pending — skill procedure (depends T1)
- `S5-T3` pending — require one JD on start (depends T1, T2)
- `S5-T4` pending — prompt injection + Skip (depends T3)
- `S5-T5` pending — UI chrome (depends T3, T4)
- `S5-T6` pending — End report + family buckets (depends T4, T5)
- `S5-T7` pending — docs; live Luna pass is a manual check (depends T6)
- `S5-GE` pending — phase exit, Grok in-session (depends T7)

Next runnable: `S5-T2`.

Parked for S5-T3: sanitize `pack_id` before joining to a filesystem path (`app/packs.py` `require_session_jd`). Reviewer minor; local-only until HTTP.
