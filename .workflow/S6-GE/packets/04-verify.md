# Packet 04-verify: S6-GE

Verify-only. Gate model cursor-grok-4.6-high-fast. Never Opus.

ACs:
1. S6-T1 done with verifier evidence.
2. Practice first-question path is JD-owned; MEMORY.md is follow-up bias only.
3. demo.sh and demo_session_2.sh were not rewritten.
4. Automated tests do not target real ~/.hermes.

Commands:
```
Select-String -Path scripts\practice_session.sh -Pattern 'targets those missing elements' | Measure-Object | Select-Object -ExpandProperty Count
Select-String -Path scripts\demo_session_2.sh -Pattern 'MEMORY.md' | Measure-Object | Select-Object -ExpandProperty Count
```

First count must be 0. Second must be >0. Isolation fail-closed still required. Live pass may stay human_needed.

Test-runner writes results/test-runner-result.md. Gate writes results/verifier-result.md.
