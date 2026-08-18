# Packet 03-review: S2-T7 memory-only opener

Review full current `scripts/demo_session_2.sh`, `scripts/demo_common.sh`, `tests/demo_session_2.bats`, `skills/crossfire-interviewer/SKILL.md`.

New untracked: `scripts/demo_session_2.sh`, `tests/demo_session_2.bats`.

Spec §9 selection + §13 opener. Researcher skipped (spec-locked). session_search detection omitted is documented-fallback, not a defect if MEMORY.md + candidate exclusion + distinct IDs are proven.

**Also check:** S2-T5 helpers still present in `demo_common.sh` (`crossfire_extract_yaml_from_live_stdout`, `crossfire_normalize_live_proposal`, `CROSSFIRE_RUNS_DIR` override). Implementer reported a checkout mishap.

Blocking if: selection order wrong; prints after question; candidate in live dir can still launch; session two resumes session one; isolation not fail-closed; naming prompt.

Write `.workflow/S2-T7/results/code-reviewer-result.md`. Verdict `approve` or `blocking_retry`.
