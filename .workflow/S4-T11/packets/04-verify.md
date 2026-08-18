# Packet 04-verify: S4-T11

Goal: Record a manual free-form run that is useful without editing prompts or files.

ACs:
- A manual free-form run is recorded.
- The tool is useful without editing prompts or files.
- Demo weaknesses do not auto-copy into the Monday profile.

Commands:
```
Test-Path -LiteralPath tests\interactive_smoke.md -PathType Leaf
Test-Path -LiteralPath README.md -PathType Leaf
```

Manual: A recorded free-form run exists in tests/interactive_smoke.md.

Honest stub/procedure is allowed; do not require a faked live transcript. If the live Q&A block is still pending, note `human_needed` but do not fail solely for that if README+procedure+isolation hold and no auto-copy exists.

Write `.workflow/S4-T11/results/verifier-result.md`.
