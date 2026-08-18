# Packet 04-verify: S4-T12

Goal: Record demo-blocking acceptance evidence and known limitations for anything cut.

ACs: Demo-blocking tests pass. The checklist is complete. The demo runs from a clean terminal without undocumented manual steps. Should-pass items are logged as known limitations if cut.

Commands:
```
Test-Path -LiteralPath docs\acceptance-checklist.md -PathType Leaf
Test-Path -LiteralPath README.md -PathType Leaf
```

Treat implementation claims as unevidenced. Read checklist against spec §17. Confirm evidence paths exist. Isolation: never real ~/.hermes.

Write `.workflow/S4-T12/results/verifier-result.md`.
