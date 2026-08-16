# S1-T1 researcher: Installed Hermes contract

**Packet:** `01-research` · **Status:** done · **Date:** 2026-08-16  
**Scope:** this machine only. Public Hermes docs are cited as *unverified* (not checked against an install).

## Verdict

Hermes Agent is **not installed** on Windows or WSL. There is **no** real `~/.hermes` on either side. Isolation via `HERMES_HOME` remains the intended Task 1b mechanism (public-doc + spec), but it is **unverified** until a binary exists. Do **not** reuse `/home/fish/crossfire/scripts/start-wsl-isolated.sh`.

## Chosen paths (opportunity cost)

| Decision | Pick | Why | Opportunity cost |
| --- | --- | --- | --- |
| Memory writer | **agent-direct** (harness writes the delimited block) | Spec §8 / decisions.md #8: harness exclusively owns the weakness block. | Hermes-mediated `memory` tool (public-doc) uses `§`-delimited entries, 2,200-char cap, add/replace/remove — likely strips HTML comment markers and can consolidate away YAML. Violates one-writer rule. |
| Persistence branch | **memory-md-block** (pending throwaway probe) | Spec §9 prefers this if a write round-trip survives. Harness write + new-process frozen snapshot can work *if* Hermes does not rewrite the file. | If probe fails: session archive (`state.db` / `hermes sessions`, public-doc) + `opening_target_source=SESSION_SEARCH`. If neither writable after install: STOP / hand-script (spec §9 #3, §15). |
| Curator | **isolated** | Pause/snapshot CLIs are public-doc only; isolation is spec §15 fallback and already required for tests. A disposable `HERMES_HOME` keeps the default Curator off demo skills. | `hermes curator pause` (persists across sessions, [official curator docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/curator)) is cheaper *if* the binary matches docs, but does not replace profile isolation. Snapshot/rollback undoes damage; it does not prevent it. |
| Isolation | **HERMES_HOME** | Spec §6; official profiles: `HERMES_HOME` is the profile boundary ([profiles](https://hermes-agent.nousresearch.com/docs/user-guide/profiles)). | `start-wsl-isolated.sh` is a **dead end** (different product). Copied throwaway `~/.hermes` is Task 1b fallback only if `HERMES_HOME` is ignored. |

**Hard stop (current machine):** spec §15 isolation + durable store + distinct session IDs cannot be proven until Hermes is installed. Research is complete; automation against Hermes is not.

## Capability inventory

Statuses: **verified** = observed here · **unsupported** = looked and absent · **documented-fallback** = primary missing, spec/docs name an alternative · **unverified** = not safely measurable / public-doc only.

| # | Capability | Status | Evidence | Notes |
| --- | --- | --- | --- | --- |
| 1 | Hermes executable + version | **unsupported** | `Get-Command hermes` empty; `where.exe hermes` empty; `wsl -e bash -lic 'command -v hermes'` → `hermes: command not found` (login PATH includes `~/.local/bin` + nvm). Windows `python -c find_spec('hermes'/'hermes_agent')` → False. `uv tool list` has serena only. WSL npm globals: corepack/npm only. | WSL distro `Ubuntu` running, user `fish`, `$HOME=/home/fish`. No version string. |
| 2 | Effective MEMORY.md path | **unsupported** | `Test-Path $env:USERPROFILE\.hermes` = False. `wsl test -e /home/fish/.hermes` exit 1. Same for `/root/.hermes`. | *Unverified convention* (official memory.md): `$HERMES_HOME/memories/MEMORY.md` — **not** `$HERMES_HOME/MEMORY.md`. 2,200-char limit. Frozen snapshot at session start. |
| 3 | Effective skill-dir path | **unsupported** | No `.hermes` tree on Win or WSL. | *Unverified convention*: `$HERMES_HOME/skills/` (+ optional `skills.external_dirs` in `config.yaml`). |
| 4 | New invocation → distinct session/process ID | **unverified** | No binary; starting a chat against a real profile is forbidden. | *Unverified convention*: sessions in `$HERMES_HOME/state.db`; `hermes sessions list`. Spec §15 hard-stop if this stays unsupported after install. |
| 5 | Skill loading timing | **unverified** | No install. | Public-doc: memory injection is startup-frozen; `hermes bundles reload` exists for bundled skills only. Treat live skill load as **startup-only**; spec §15 optional reload → start a new process after opener. |
| 6 | Learning-loop trigger + latency | **unverified** | Measurement would write a profile. | Public-doc: post-turn background review can write memory/skills (`auxiliary.background_review`). Do not assume ≤8s. Spec fallback: pre-persist before timed run. |
| 7 | Curator pause / isolate / snapshot | **unverified** | Cannot run `hermes curator *`. | Public-doc: `pause`/`resume`, `backup`/`rollback`. **Chosen: isolated** via disposable `HERMES_HOME`. |
| 8 | session_search observability | **unverified** | No install. | Public-doc: `session_search` is a toolset; `--toolsets` can omit it; FTS in `state.db`. Spec §13/§15 fallback: drop search-detection; prove opener with disk artifact + distinct process. |
| 9 | Isolation env (`HERMES_HOME`) | **unverified** | `HERMES_HOME` unset on Win and WSL. No binary to prove writes stay inside the override. | Public-doc: `HERMES_HOME` scopes config, memory, skills, `state.db`. **Caveat:** host tools still use real `$HOME` unless `terminal.home_mode: profile`. Task 1b must prove a marker in real `~/.hermes` is untouched. |
| 10 | Who writes MEMORY.md | **unverified** | No write observed. | Public-doc: Hermes-mediated `memory` tool + optional `memory.write_approval`. **Product pick: agent-direct** (harness). Disable/gate the `memory` tool on demo profiles so Hermes does not become a second writer. |
| 11 | CROSSFIRE-WEAKNESSES markers survive Hermes write | **unverified** | Live probe forbidden (leave to implementer on workspace throwaway). | Public-doc implies **likely fail**: prompt rendering is `§` entries, not raw markdown-with-HTML-comments; overflow triggers consolidate/remove. Harness-only writes + no Hermes rewrite may still be readable at next session start. |
| 12 | Persistence-layer branch | **unverified** (branch chosen, not proven) | Spec §9 lines 163–169. | **Live branch to implement first:** `memory-md-block`. Probe on throwaway. Else archive. Else STOP. |

## `demo_common.sh` variable proposals

| Name | Value or discovery |
| --- | --- |
| `HERMES_BIN` | `Get-Command hermes`; else `wsl -e bash -lic 'command -v hermes'`; fail preflight if empty |
| `HERMES_VERSION` | `"$HERMES_BIN" --version` (or `wsl … hermes --version`) |
| `HERMES_HOME` | Override to repo profile: test=`<repo>/.crossfire/profiles/test`, stage=`<repo>/.crossfire/profiles/stage`. Never default to real `~/.hermes` in tests. |
| `HERMES_MEMORY_MD` | `${HERMES_HOME}/memories/MEMORY.md` (unverified convention; confirm after install) |
| `HERMES_SKILLS_DIR` | `${HERMES_HOME}/skills` |
| `HERMES_STATE_DB` | `${HERMES_HOME}/state.db` |
| `HERMES_CONFIG` | `${HERMES_HOME}/config.yaml` |
| `HERMES_SOUL` | `${HERMES_HOME}/SOUL.md` |
| `WSL_DISTRO` | `Ubuntu` (verified: `wsl -l -v`) |
| `WSL_USER` | `fish` (verified: WSL `$HOME=/home/fish`) |
| `REAL_HERMES_WIN` | `$env:USERPROFILE\.hermes` (absent today) |
| `REAL_HERMES_WSL` | `/home/fish/.hermes` (absent today) |

## Dead ends

1. **Windows PATH / pip / npm / uv / winget:** no Hermes package or shim.
2. **WSL `~/.hermes`:** does not exist; login shell still has no `hermes`.
3. **Plan path `/home/fish/crossfire`:** different app (pnpm “Crossfire” council). `scripts/start-wsl-isolated.sh` sets `COUNCIL_DATABASE_PATH` and `exec pnpm start` — **not** Hermes isolation. Plan line 27 (“exists — verify/adapt”) is false for this repo (no `scripts/` here).
4. **Provisional `$HERMES_HOME/MEMORY.md`:** official layout is `memories/MEMORY.md`.
5. **Marketing pages:** not used as verified.

## Open questions (for implementer / operator)

1. Install Hermes (WSL recommended: Linux-native CLI) before preflight can pass. Approval-first; do not install from this packet.
2. After install, on a **workspace throwaway** `HERMES_HOME` only: probe HTML-comment YAML round-trip; measure session-id uniqueness; confirm `--toolsets` can omit `session_search`; confirm `hermes curator pause` vs isolation.
3. Does setting `HERMES_HOME` to `.crossfire/profiles/test` work without `hermes profile create`, or must profiles live under `~/.hermes/profiles/<name>`?
4. How to disable the `memory` tool / background review so harness remains the only MEMORY.md writer (`memory_enabled`, toolsets, `write_approval`)?
5. Session-archive schema if the MEMORY.md probe fails (`state.db` vs `hermes sessions` export).
