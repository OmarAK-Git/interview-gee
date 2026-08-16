# Packet 04-verify: S1-T1b

## Claim

S1-T1b is done: an automated run leaves real Hermes state unchanged; scripts/tests source isolation env; Hermes-invoking automation is recorded stopped until a binary proves HERMES_HOME.

## ACs

1. An automated run provably leaves real Hermes state unchanged.
2. Subsequent scripts/tests are documented to source the isolation env.
3. If isolation cannot be achieved, a recorded decision stops automation against Hermes (hand-script only).

## Manual check

Confirm isolation.bats would fail if a marker in real ~/.hermes were touched (read the test; do not run against the real profile).

## Extra skeptic check

T1 research found `/home/fish/.hermes` **absent**. A later review noted it now exists as an empty directory (born ~14:59). Independently check (read-only: `ls -la`, `stat`, do not write/delete) whether Win `%USERPROFILE%\.hermes` or WSL `/home/fish/.hermes` exists and whether product scripts mkdir those paths. If this run created the operator profile, refute AC1.

## Commands

```
Test-Path -LiteralPath tests\isolation.bats -PathType Leaf
Test-Path -LiteralPath scripts\demo_common.sh -PathType Leaf
```

Read tests/isolation.bats, scripts/demo_common.sh, scripts/start-wsl-isolated.sh, docs/hermes-compatibility.md 1b section.

Do not install bats. Do not mutate ~/.hermes. Do not delete the WSL dir if present.
