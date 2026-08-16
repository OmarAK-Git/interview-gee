# Packet 04-verify-restore: S1-T1b after operator rmdir

## Claim (precise)

After operator-approved removal of the leaked empty `/home/fish/.hermes`, the isolation harness leaves the restored baseline unchanged: Windows `%USERPROFILE%\.hermes` absent, WSL `/home/fish/.hermes` absent. Sourcing isolation / start-wsl-isolated does not recreate those paths. `tests/isolation.bats` would fail if a previously absent operator path appeared or if a fake-home marker were touched. Subsequent scripts must source the isolation env. Hermes-invoking automation is recorded stopped.

Do **not** accept a claim that the first 1b run never mutated real `~/.hermes`.

## ACs

1. An automated run (from the restored baseline) provably leaves real Hermes state unchanged.
2. Subsequent scripts/tests are documented to source the isolation env.
3. Hermes-invoking automation is recorded stopped until a binary proves HERMES_HOME (hybrid decision).

## Manual

Read isolation.bats: would fail if a marker in real ~/.hermes were touched — do not write the real profile. Confirm same-process snapshot of REAL_HERMES_* before source/start.

## Commands

```
Test-Path -LiteralPath tests\isolation.bats -PathType Leaf
Test-Path -LiteralPath scripts\demo_common.sh -PathType Leaf
Test-Path -LiteralPath $env:USERPROFILE\.hermes
```

WSL read-only: `test ! -e /home/fish/.hermes`. Optional: source demo_common / run start-wsl-isolated then re-check both homes still absent. Do not mkdir. Do not install bats.

## Do not

Mutate or recreate ~/.hermes. Trust implementer transcripts. Fail the task for missing demo sessions.
