# Packet 04-verify: S3-T9

Goal: Show the generated skill shaping a later turn without contaminating opener attribution.

ACs: The beat visibly uses the generated skill. It cannot contaminate opener attribution. It truthfully presents unverified status.

Product: `scripts/activate_candidate_skill.sh`, `scripts/demo_risk_beat.sh`, `tests/risk_beat.bats`, `docs/demo-script.md`

Commands:
```
Test-Path -LiteralPath scripts\demo_risk_beat.sh -PathType Leaf
Test-Path -LiteralPath tests\risk_beat.bats -PathType Leaf
```

Treat implementation claims as unevidenced. Re-run bash-equivalent. Confirm activation fails before opener; label+warning before influence; isolation fail-closed. Never real ~/.hermes.

Write `.workflow/S3-T9/results/verifier-result.md`.
