# Practice live-ui spikes (2026-08-21)

Isolated profile: `HERMES_HOME=<repo>/.crossfire/profiles/test` (Nous `auth.json` present).
Monday: `/home/fish/.hermes` (no `config.yaml` / `auth.json` — Hermes printed setup wizard).

## --resume

**Result: verified live.** Same `session_id` across two `-Q` turns; stderr `↻ Resumed session … (2 user messages, 5 total messages)`. Follow-up stayed on verification.

- IDs: `20260821_155613_95c208`
- Evidence: `.workflow/practice-live-ui/results/spike-resume/summary.txt`
- `--max-turns 1` dumps a huge reasoning box + “Reached maximum iterations” into stdout. `--reasoning none` still prints a reasoning box (smaller). Harness must extract YAML/question from noisy stdout; prefer `--max-turns 3` and `--reasoning none`.
- Fallback (transcript-in-prompt, no resume) **not needed**.

## MEMORY.md round-trip

**Isolated, live model: block survived.** `skills` only and `skills,memory` both `unchanged=yes`, markers intact.

**Monday: not a model round-trip.** Chat aborted (“no API keys”). File hash unchanged because Hermes never ran. Probe file restored to absent (`had_prior_memory=0`).

Monday live practice requires copying `config.yaml` + `auth.json` from the working test profile onto `/home/fish/.hermes` (gitignored). Persistence branch stays **memory-md-block**.
