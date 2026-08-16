# Packet 01-research: Isolation mechanism

## Objective

Pick one isolation strategy that can be proven on this machine, or record STOP/hand-script for Hermes-invoking automation.

## Context

S1-T1 done: Hermes binary **unsupported**. `HERMES_HOME` chosen but **unsupported** (no binary to prove write scope). Real `~/.hermes` absent on Win and WSL. `/home/fish/crossfire/scripts/start-wsl-isolated.sh` is a different product — dead end.

Spec §6 / §15: if tests cannot be isolated from real `~/.hermes`, stop automating against Hermes and hand-script.

## Do

Compare:
1. HERMES_HOME → `.crossfire/profiles/test` (T1 pick)
2. Copied throwaway profile (never the real one)
3. STOP Hermes-invoking automation until install + proof

Can script-level tests prove that sourcing isolation env never writes real ~/.hermes **without** invoking Hermes? If yes, that may satisfy "automated run leaves real Hermes state unchanged" for harness scripts, while Hermes-invoking tasks stay stopped.

## Do Not

Write product files except `.workflow/S1-T1b/results/researcher-result.md`. Do not mutate real ~/.hermes. Do not install Hermes.

## Expected Output

Chosen path, rejected paths, what 1b can prove without a binary, and whether later Hermes-touching queue items should be blocked.
