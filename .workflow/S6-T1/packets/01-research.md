# Packet 01-research: S6-T1 practice weave path

Bounded question: which implementation path should S6-T1 take so the live practice UI New session first spoken question is a JD competency question, not a restatement of the newest MEMORY.md gap?

## Authority

`docs/superpowers/specs/2026-08-23-practice-weave-addendum.md` wins for the live UI. `sparring-1.0.0` demo session two opener is untouched (do not rewrite demo.sh / demo_session_2.sh).

## Paths to compare

1. **Skill-only:** keep the practice memory-opener branch; rewrite the first `-q` so it does not say “targets those missing elements.”
2. **Harness + skill:** stop using the practice memory-opener branch for the first question; inject MEMORY.md only as follow-up bias. Attribution kv may still print.

Return: chosen path, rejected path, opportunity cost, evidence (`file:line`), and the exact files/edits for the implementer.

Write `.workflow/S6-T1/results/researcher-result.md`.
