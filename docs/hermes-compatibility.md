# Hermes compatibility (Task 1)

Machine-local contract recorded **2026-08-16**. Status labels:

| Label | Meaning |
| --- | --- |
| **verified** | Observed on this machine |
| **unsupported** | Looked for; absent or not runnable on this machine |
| **documented-fallback** | Primary capability not proven here; spec or public docs name an alternative path |

Spec §15 capability **Status** cells use only the three labels above. Evidence/Notes columns may cite *public-doc (not checked against install)* where Hermes docs were not exercised against a binary.

Public Hermes documentation is never treated as **verified** unless a row says so explicitly.

## Locked product choices (this repo)

| Decision | Choice | Evidence |
| --- | --- | --- |
| MEMORY.md writer | **agent-direct** (harness writes delimited block) | Spec §8 / decisions.md #8; Hermes `memory` tool disabled on demo profiles (config probe pending) |
| Persistence branch (live) | **probe-pending** (first post-install attempt: **memory-md-block**) | Spec §9 #1; no throwaway probe yet — do not assume YAML block survives |
| Curator strategy | **isolated** via disposable `HERMES_HOME` | Spec §15 fallback; no `hermes curator pause` run on this machine |
| Isolation mechanism | **`HERMES_HOME`** → repo `.crossfire/profiles/test` (tests never default to real `~/.hermes`) | Spec §6; shared vars in `scripts/demo_common.sh`; harness boundary proven in Task 1b |

## MEMORY.md delimited YAML round-trip

Target markers (harness-owned):

```markdown
<!-- CROSSFIRE-WEAKNESSES:START -->
<!-- YAML block -->
<!-- CROSSFIRE-WEAKNESSES:END -->
```

| Question | Status | Evidence |
| --- | --- | --- |
| Who writes `MEMORY.md` in production? | **agent-direct** (chosen) | Harness exclusive writer; Hermes-mediated `memory` tool is a second-writer risk (*public-doc (not checked against install)*) |
| Do HTML-comment delimiters survive a Hermes write round-trip? | **documented-fallback** — **not proven to survive** | No throwaway probe run (no binary). *Public-doc (not checked against install):* Hermes renders `§`-delimited memory entries, 2,200-char cap, consolidate/remove — likely strips or rewrites raw markdown with HTML comments. If probe fails: session archive + `opening_target_source=SESSION_SEARCH` (spec §9 #2) |
| Effective path | **unsupported** (no profile tree) | *Public-doc (not checked against install):* `$HERMES_HOME/memories/MEMORY.md` — not `$HERMES_HOME/MEMORY.md` |

If the probe fails after install: **documented-fallback** → session archive + `opening_target_source=SESSION_SEARCH` (spec §9 #2). If neither layer is writable: **STOP** (spec §9 #3).

## Curator

| Approach | Status | Notes |
| --- | --- | --- |
| **`hermes curator pause` / snapshot** | **documented-fallback** | *Public-doc (not checked against install):* pause, resume, backup, rollback ([curator docs](https://hermes-agent.nousresearch.com/docs/user-guide/features/curator)) — not executed here |
| **Isolated profile (`HERMES_HOME`)** | **documented-fallback** (strategy chosen) | Disposable profile keeps default Curator off demo skills; Task 1b harness scripts do not mkdir operator paths (see Task 1b incident + restore) |

**Chosen strategy for MVP:** **isolated** (one strategy only).

## session_search observability

| Item | Status | Evidence |
| --- | --- | --- |
| Tool present / callable | **unsupported** | No install; *public-doc (not checked against install):* `session_search` toolset, FTS in `state.db` |
| Disable for opener or log tool calls | **unsupported** | No binary to exercise `--toolsets`; not measured here |
| Spec fallback if unsupported | **documented-fallback** | Drop search-detection; prove memory-only opener via disk artifact + distinct process/session ID (spec §13, §15) |

## Spec §15 capability table (MVP)

| Capability | Required | Status | Evidence | If unsupported (spec) |
| --- | --- | --- | --- | --- |
| Disposable `HERMES_HOME` isolation | Hard stop | **verified** (profile data) | `hermes doctor` with `HERMES_HOME=<repo>/.crossfire/profiles/test` created `memories/`, `sessions/`, `logs/`, `skills/`, `SOUL.md`, `state.db` only under that tree. Real `/home/fish/.hermes` has install-only top-level dirs (`bin`, `hermes-agent`, `node`) — no `memories/`, `sessions/`, `state.db`, `config.yaml`, `SOUL.md`. Running the binary updates `__pycache__` under the install checkout `~/.hermes/hermes-agent/` (code tree, not profile data). Windows `%USERPROFILE%\.hermes` still absent. | Stop automating; hand-script |
| Distinct process + session ID (session two) | Hard stop | **documented-fallback** | Binary exists; two-process session IDs not yet measured (no live chat). Prove in S2-T7. | Stop demo build |
| Durable weakness store (`MEMORY.md` block **or** archive) | Hard stop | **documented-fallback** | Throwaway profile has `memories/` + `state.db`. `MEMORY.md` is created on first memory write. Harness merge (`weakness_memory.sh`) is the durable store. YAML round-trip still unprobed. | Hand-script |
| `MEMORY.md` delimited block survives round-trip | Preferred | **documented-fallback** | **Not proven to survive** — no Hermes rewrite of a CROSSFIRE block yet. Doctor did not create `MEMORY.md`. | Archive + `SESSION_SEARCH` |
| Pause / isolate Curator | Required | **documented-fallback** | Chosen strategy: **isolated** profile via `HERMES_HOME`; `hermes curator pause` not run | Isolate profile (chosen) |
| Disable `session_search` for opener **or** log calls | Preferred | **documented-fallback** | Tool is present (`hermes doctor`). Disable-for-opener / logging not yet exercised. Spec fallback: disk artifact + distinct process | Disk artifact + distinct process |
| Learning-loop write ≤ 8s | Preferred | **documented-fallback** | Not measured; would write profile. Spec: pre-persist before timed run | Pre-persist before timed run |
| Exclude candidate from live dir before session two | Required | **verified** | S2-T6 researcher probe (isolated `HERMES_HOME`): file under `.crossfire/candidate-skills/` absent from `hermes skills list --source local`; `--skills` on staged path → `Unknown skill(s)`; live-dir drop is listed. Harness: `scripts/stage_candidate_skill.sh` never-write-live + snapshot-before-assert + `crossfire_assert_candidates_excluded_from_live` fail-closed | Degraded path + disclosure |
| Skill reload without new process | Optional | **documented-fallback** | Treat as startup-only until reload proven; *public-doc (not checked against install):* memory injection startup-frozen | Start new process after opener |

## Task 1 discovery inventory (read-only)

| # | Check | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Hermes executable + version | **verified** | WSL Ubuntu user `fish`: Hermes Agent **v0.20.2** (2026.8.16) at `/home/fish/.local/bin/hermes` → `~/.hermes/hermes-agent/venv/bin/hermes`. Windows PATH still has no `hermes`. |
| 2 | Effective `MEMORY.md` path | **verified** (convention) | `hermes doctor` under throwaway `HERMES_HOME`: `$HERMES_HOME/memories/MEMORY.md` — "will be created when the agent first writes a memory". Not `$HERMES_HOME/MEMORY.md`. |
| 3 | Effective skill-dir path | **verified** | `$HERMES_HOME/skills` created by doctor on the throwaway profile. |
| 4 | New invocation → distinct session/process ID | **unsupported** | No binary; preflight records `state_db` path only; no session started |
| 5 | Skill loading timing | **documented-fallback** | Recorded as **startup-only** until reload proven (`SKILL_LOADING_TIMING` in `demo_common.sh`); start new process if reload needed |
| 6 | Learning-loop trigger + latency | **documented-fallback** | Not measured; ≤8s not assumed; spec pre-persist fallback |
| 7 | Curator pause / isolate / snapshot | **documented-fallback** | Strategy **isolated** via `HERMES_HOME`; pause CLIs not run |
| 8 | `session_search` observability | **verified** (tool present) | `hermes doctor` lists `session_search` as available. Disable-for-opener / tool-call logging still unprobed — keep spec fallback until `--toolsets` is exercised. |
| 9 | Isolation env (`HERMES_HOME`) | **verified** | Harness boundary (Task 1b) plus Hermes process profile-data write-scope (2026-08-16 probe). |
| 10 | Who writes `MEMORY.md` | **agent-direct** (product choice) | Runtime gate pending config probe after install |
| 11 | CROSSFIRE-WEAKNESSES markers survive write | **documented-fallback** | **Not proven to survive**; throwaway probe pending; archive fallback if probe fails |
| 12 | Persistence-layer branch | **documented-fallback** | Live: **probe-pending**; first post-install attempt: **memory-md-block**; archive if probe fails |

## Shared variables (`scripts/demo_common.sh`)

| Variable | Value / discovery |
| --- | --- |
| `HERMES_BIN` | `command -v hermes`; else `wsl -e bash -c 'command -v hermes'` (absolute path only, `test -x` in WSL); skip when `CROSSFIRE_HERMES_DISCOVERY=0` |
| `HERMES_VERSION` | `"$HERMES_BIN" --version` (via WSL `bash -c` when bin is WSL-only; fails closed on ambiguous output) |
| `HERMES_HOME` | Default `<repo>/.crossfire/profiles/test` |
| `HERMES_MEMORY_MD` | `${HERMES_HOME}/memories/MEMORY.md` |
| `HERMES_SKILLS_DIR` | `${HERMES_HOME}/skills` |
| `HERMES_STATE_DB` | `${HERMES_HOME}/state.db` |
| `HERMES_CONFIG` | `${HERMES_HOME}/config.yaml` |
| `PERSISTENCE_BRANCH` | `probe-pending` (first post-install attempt: `memory-md-block`) |
| `WSL_DISTRO` | `Ubuntu` (verified via `wsl -l -v`) |
| `WSL_USER` | `fish` |
| `REAL_HERMES_WIN` | `$USERPROFILE/.hermes` (absent after restore; see Task 1b incident) |
| `REAL_HERMES_WSL` | `/home/fish/.hermes` (install tree after 2026-08-16 approved install: `bin/`, `hermes-agent/`, `node/`) |

## Preflight behavior (this machine)

`scripts/preflight.sh` sources `demo_common.sh`, validates isolated paths, attempts binary discovery (PATH then WSL), prints the capability summary, and **exits nonzero** when Hermes is missing. It does **not** start a Hermes session or write under real `~/.hermes`.

## Task 1b — Hybrid isolation decision (2026-08-16)

**Mechanism:** `HERMES_HOME` → `<repo>/.crossfire/profiles/test` via `scripts/demo_common.sh`.

### Operator-profile incident (first S1-T1b run)

During the first S1-T1b run, real Hermes state changed on this machine:

| Event | Detail |
| --- | --- |
| Prior baseline (S1-T1) | `/home/fish/.hermes` **absent** (~14:49); Windows `%USERPROFILE%\.hermes` absent |
| Leak | Empty `/home/fish/.hermes` born **2026-08-16 14:59:15** during S1-T1b (after product files at ~14:57) |
| Creator | **Uncertain** — product scripts as written have no `mkdir` of `REAL_HERMES_WSL` / `REAL_HERMES_WIN` |
| Restore | Operator approved removal; controller ran `wsl.exe -e bash -c "rmdir /home/fish/.hermes"` after confirming empty |
| Post-restore | Both real homes **absent** (`Test-Path` False on Win; WSL `WSL_ABSENT`) |

**Do not claim** the first S1-T1b run never mutated real `~/.hermes`. The WSL operator profile appeared mid-task; attribution is unproven.

### Going-forward harness boundary

Product isolation scripts (`demo_common.sh`, `start-wsl-isolated.sh`) **do not mkdir operator paths** — the sole `mkdir -p` in product code is under disposable `HERMES_HOME` in `crossfire_harness_write_probe`. Harness writes stay under the disposable profile.

`tests/isolation.bats` no-create tests snapshot `REAL_HERMES_WIN` / `REAL_HERMES_WSL` absence in the **same process** before sourcing or running isolation entrypoints; they **fail closed** if a previously absent path appears. A temp fake real-home marker test fails if harness writes touch operator-profile paths keyed off `REAL_HERMES_WSL`.

**Hermes write-scope (verified for profile data, 2026-08-16):** Official WSL install (operator-approved) created `/home/fish/.hermes/{bin,hermes-agent,node}`. A throwaway `HERMES_HOME` probe (`hermes doctor`) wrote profile dirs only under `<repo>/.crossfire/profiles/test`. Real home gained no `memories/`, `sessions/`, `state.db`, or `SOUL.md`. Install-tree `__pycache__` updates under `hermes-agent/` are expected when running the venv binary. Copied throwaway trees into real `~/.hermes` remain forbidden.

**Contract:** Every subsequent script and test must source `scripts/demo_common.sh` or `scripts/start-wsl-isolated.sh` before any write under `HERMES_HOME`.

| Layer | Status | Evidence |
| --- | --- | --- |
| Harness script isolation | **verified** (post-restore) | `tests/isolation.bats`, `crossfire_require_isolated_hermes_home`, `is_real_hermes_home`; both real homes absent after restore |
| Hermes process honors `HERMES_HOME` | **verified** (profile data) | Doctor created throwaway `memories/sessions/logs/skills/state.db/SOUL.md`; real home has install-only top-level dirs |
| Hermes-invoking automation | **unblocked for isolated `HERMES_HOME`** | Still needs a configured model (`hermes setup` / API keys) before a live chat |

## Install record (2026-08-16, operator-approved)

- Command: `curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --skip-browser --skip-computer-use --skip-setup --non-interactive` (WSL Ubuntu, user `fish`).
- Optional apt packages (`ripgrep`, `ffmpeg`) skipped (no passwordless sudo). Browser/Playwright skipped. `npm install` for Node browser tools failed or timed out; CLI still runs.
- Binary: Hermes Agent v0.20.2. Code: `/home/fish/.hermes/hermes-agent`. Launcher: `/home/fish/.local/bin/hermes`.
- `hermes doctor` lists tools including `memory` and `session_search`. No Nous/OpenRouter auth yet.

## Open items (post-install)

1. Configure a model (`hermes setup` / `hermes model`) before live session scripts can chat — approval-first if it needs keys or Portal OAuth.
2. Throwaway `HERMES_HOME` only: YAML round-trip probe, session-id uniqueness, `--toolsets` without `session_search`, `memory` tool disablement.
3. Confirm whether `HERMES_HOME=.crossfire/profiles/test` works without `hermes profile create`.
4. ~~Task 1b: marker in real `~/.hermes` must remain untouched during isolated runs.~~ Harness-proven via fake-home marker in `tests/isolation.bats`; Hermes-invoking probe still pending install.
