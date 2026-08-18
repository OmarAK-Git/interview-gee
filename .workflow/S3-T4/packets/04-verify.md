# Packet 04-verify: S3-T4

Goal: Add a statically validated broader question bank without inventing employer facts.

ACs:
- Static tests pass.
- Three demo questions remain complete within the measured session-one budget.
- No invented employer facts.

Product: `skills/crossfire-interviewer/questions.md`, `tests/question_bank.bats`

Commands:
```
Test-Path -LiteralPath skills\crossfire-interviewer\questions.md -PathType Leaf
Test-Path -LiteralPath tests\question_bank.bats -PathType Leaf
```

Treat implementation claims as unevidenced. Check questions.md against spec §4. Re-run bash-equivalent. Write `.workflow/S3-T4/results/verifier-result.md`.
