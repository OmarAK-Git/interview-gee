# Packet 02-implementation: Isolation env + tests

## Objective

Prove harness automation leaves real Hermes state unchanged. Hybrid: HERMES_HOME = repo `.crossfire/profiles/test`; Hermes-invoking automation stopped until a binary proves write scope.

## Do

Write/update only:
- `scripts/start-wsl-isolated.sh` — Hermes-specific. Source isolation env. Do not invoke `hermes` while binary missing. Do not reuse /home/fish/crossfire council script.
- `scripts/demo_common.sh` — isolation helpers; subsequent scripts source this.
- `tests/isolation.bats` — TDD first.
- `docs/hermes-compatibility.md` — record hybrid decision + STOP Hermes-invoking automation.

Tests must (without writing the operator profile):
1. Default HERMES_HOME is repo `.crossfire/profiles/test`, not real ~/.hermes.
2. preflight_check_paths / isolation guard rejects real or `*/.hermes` paths (throwaway fake home OK).
3. Sourcing demo_common / start-wsl-isolated.sh does not create real ~/.hermes (Win or WSL).
4. A harness write under HERMES_HOME does not change a marker in a **fake** real-home (temp dir). Structure the test so it **would fail** if code wrote the marker path — read-the-test AC.
5. Document that later scripts/tests must source the isolation env.

Do not install Hermes/bats. Do not mutate real ~/.hermes. Do not implement weakness merge or demo sessions.

## Verification

```
Test-Path -LiteralPath tests\isolation.bats -PathType Leaf
Test-Path -LiteralPath scripts\demo_common.sh -PathType Leaf
```

If bash exists, run isolation-relevant helpers. Do not install bats.

Write `.workflow/S1-T1b/results/implementer-result.md`.
