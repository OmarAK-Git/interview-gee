# Packet 03-review: S1-T1 code review

## Objective

Review the S1-T1 diff for spec compliance, correctness, security, simplicity, and tests. Blocking findings force retry.

## Context

Task: Verify the installed Hermes contract. Hermes is not installed; documenting unsupported/unverified and fail-closed preflight is in scope.

Spec: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` §8, §9, §15.
Plan Task 1: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-plan.md` lines 9–19.
ACs in `.workflow/autopilot-queue.json` item S1-T1.

Do not treat implementer narrative as evidence. Run `git diff` yourself.

## Files or Sources

Changed product files:
- `docs/hermes-compatibility.md`
- `scripts/demo_common.sh`
- `scripts/preflight.sh`
- `tests/preflight.bats`

## Ownership

code-reviewer

## Do

Review in order: spec compliance, correctness, security (especially never writing real ~/.hermes), simplicity, tests (could they pass without the behavior working? are they environment-coupled?).

## Do Not

- Modify files except `.workflow/S1-T1/results/code-reviewer-result.md`
- Widen scope to Task 1b/2/3
- Praise-only review

## Expected Output

Findings by priority: Critical (blocks), Important (fix before proceeding), Minor (track). Each with file:line and a concrete fix. If none, say what you checked.

Write `.workflow/S1-T1/results/code-reviewer-result.md`.

Verdict: `approve` | `blocking_retry`

```json
{
  "packet_id": "03-review",
  "status": "done",
  "verdict": "approve | blocking_retry",
  "findings": [{"priority": "Critical | Important | Minor", "file": "path:line", "issue": "string", "fix": "string"}]
}
```
