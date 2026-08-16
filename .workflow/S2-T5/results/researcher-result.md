# S2-T5 researcher: Session-one buffer, driver, tests

**Packet:** `01-research` · **Status:** done · **Date:** 2026-08-16  
**Scope:** this machine (Hermes Agent v0.20.2, WSL user `fish`, isolated `HERMES_HOME`). Spec `sparring-1.0.0` wins over the plan.

## Verdict

Pick **harness-spool + hybrid driver + deterministic-plus-live tests**. Finalize is a **harness `/done` equivalent** (not a Hermes slash command). Guard MEMORY.md by **disabling the `memory` toolset** on assessor invocations (`--toolsets` allowlist). Skill-only is already locked and is not enough.

Hermes **can** resume sessions and print session IDs. That is conversation state, not a structured assessment buffer. Spec §8 already names the spool. `/done` is absent from Hermes `COMMAND_REGISTRY`. The CLI `memory` toolset is enabled by default.

```json
{
  "packet_id": "01-research",
  "status": "done",
  "chosen_paths": {
    "buffer": "harness-spool",
    "driver": "hybrid",
    "tests": "deterministic-plus-live",
    "finalize": "harness-finalize-equivalent",
    "memory_guard": "disable-memory-tool"
  },
  "why": "Resume holds chat not assessments; /done is not a Hermes command; memory tool is on by default — spool + hybrid finalize + --toolsets without memory + deterministic-plus-live.",
  "opportunity_cost": [
    {"path": "hermes-native buffer", "rejected": true, "why": "Resume/session APIs exist but store unstructured chat; spec §8 requires propose-to-stdout-or-spool; no schema-preserving extract."},
    {"path": "live-chat driver", "rejected": true, "why": "No Hermes /done; --max-turns is tool iterations not Q count; piping three fixture answers into the REPL is fragile on free-tier."},
    {"path": "harness-orchestrated (no explicit finalize)", "rejected": true, "why": "Same assessor loop, but spec §12 requires a single /done==finalize path with ack; hybrid names that."},
    {"path": "live-e2e only", "rejected": true, "why": "Free-tier flake; plan risk table already splits deterministic vs live."},
    {"path": "skip-as-pass", "rejected": true, "why": "Does not prove session one ran against installed Hermes; matches assessment_eval fail-closed rule."},
    {"path": "hermes-/done finalize", "rejected": true, "why": "/done is not in COMMAND_REGISTRY; /quit is the Exit command and spec forbids saying quit."},
    {"path": "skill-only memory guard", "rejected": true, "why": "cli memory toolset is enabled; file tool is also enabled — second-writer risk."}
  ],
  "hermes_cli": {
    "chat_flags": ["-Q", "-q", "--max-turns 1", "--toolsets skills", "--skills <repo>/skills/crossfire-interviewer", "--source tool", "--resume <session_id>"],
    "resume": "verified",
    "done_command": "harness /done (not a Hermes slash command); same function as auto-finalize after answer 3",
    "session_id_how": "parse 'session_id: <id>' on hermes chat -Q stderr; fallback hermes sessions list --limit 1"
  },
  "tests_must_encode": [
    "exactly three spec §11 questions in order from fixtures, not operator typing",
    "answers read from tests/fixtures/demo-answers.txt",
    "each assessment lands under .crossfire/runs/<run_id>/spool/ before finalize",
    "MEMORY.md missing or fingerprint unchanged until finalize",
    "/done and post-Q3 auto-finalize are the same function and wait for ack",
    "q_behavioral_01 scripted bad answer persists via crossfire_persist_weakness (no confirm)",
    "strong answers (missing < 2) do not persist",
    "isolation fail-closed unless HERMES_HOME is under .crossfire/profiles",
    "live skip when Hermes missing is not an E2E pass; CROSSFIRE_LIVE=1 fails closed",
    "when Hermes+model present, at least one isolated -Q assessor writes a spool proposal",
    "assessor invocations omit memory (and file/terminal) from --toolsets",
    "source_session_id captured and passed into persist",
    "live assessor retries the bad answer up to K=3 then abort"
  ],
  "implementer_notes": [
    "Spec artifact root is .crossfire/runs/<run_id>/ (plan .crossfire/run/ is superseded).",
    "Do not use --safe-mode or --ignore-user-config: they drop the isolated Nous config (stepfun/step-3.7-flash:free).",
    "Do not use --ignore-rules if you need -s skill preload / SOUL.md.",
    "--max-turns is tool-calling iterations per turn, not the three-question count.",
    "Invoke via WSL: HOME=/home/fish PATH=/home/fish/.local/bin:$PATH HERMES_HOME=<repo>/.crossfire/profiles/test; source scripts/demo_common.sh first.",
    "Persist API: crossfire_persist_weakness memory_md family topic missing_csv last_seen source_session_id answer_ref evidence_kind evidence_value submitted_answer (scripts/weakness_memory.sh:553).",
    "YAML CROSSFIRE round-trip can wait: harness is sole writer during session one if memory+file are off. Probe belongs after finalize / session two.",
    "Record session_id for S2-T7 only; do not implement session-two opener or candidate staging.",
    "-s path vs installed name is unverified; repo skill is not in hermes skills list. Try repo path; if rejected, load the stable skill into the isolated profile skills dir (not .crossfire/candidate-skills/).",
    "A live --resume chat was not executed (ping budget). Resume API + listed IDs + -Q stderr format are verified."
  ],
  "open_questions": [
    "Does --skills accept a filesystem path to skills/crossfire-interviewer or only an installed name?",
    "What minimal --toolsets string still preloads the skill with no file/memory/terminal?",
    "Does default bats on this machine run the live assessor (Hermes is discoverable) or only when CROSSFIRE_LIVE=1?"
  ]
}
```

## Chosen paths (opportunity cost)

| Decision | Pick | Why | Rejected |
| --- | --- | --- | --- |
| Buffer | **harness-spool** under `.crossfire/runs/<run_id>/spool/` | Spec §8: Hermes proposes to stdout or that spool; harness owns MEMORY.md. Skill is propose-only. | Hermes-native: resume exists but is chat history, not assessment YAML. |
| Driver | **hybrid** | Harness prints §11 questions, reads `demo-answers.txt`, calls `hermes chat -Q` as assessor, writes spool, finalizes. Meets “runs against installed Hermes” without a 3-Q REPL. | live-chat: no `/done`, `--max-turns` ≠ Q count. |
| Tests | **deterministic-plus-live** | Buffer/persist/no-confirm are harness-owned and must be TDD’d without the model. Live isolated `-Q` when Hermes+model present; force-live fails closed. | Full live E2E (flake). skip-as-pass (does not meet AC). |
| Finalize | **harness-finalize-equivalent** | Spec §7/§12: harness invokes the same path as typing `/done`. Hermes has `/quit`, not `/done`. | Treating `/done` as a Hermes slash command. |
| Memory guard | **disable-memory-tool** | `hermes tools list` shows `memory` **enabled** on cli. `-t/--toolsets` is an enable-allowlist. Also omit `file`/`terminal`. | skill-only (already locked; insufficient). |

## Evidence

### Spec / skill / persist (authoritative)

- Spec §8: Hermes “proposes assessments on stdout / run-scoped spool”; “may emit structured records to stdout or `.crossfire/runs/<run_id>/spool/`”; harness exclusively owns the MEMORY.md block (`docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md:91-106`).
- Spec §10 live demo gate: persist at least one qualifying weakness for the scripted bad answer; retry assessment **K = 3** (`spec.md:187`).
- Spec §11 three questions: `q_technical_01`, `q_behavioral_01` (bad), `q_product_01` (`spec.md:193-197`).
- Spec §12: `/done` is the only normal completion; harness finalize after answer 3 is the same operation; assessments buffered; MEMORY.md unchanged until finalize (`spec.md:203-215`).
- Spec §7 spoken script: harness invokes `/done` (same finalize as typing it) (`spec.md:75`).
- Plan Task 5: “Hermes-native if verified, else session-ID-scoped buffer”; plan path `.crossfire/run/` is superseded by spec `.crossfire/runs/<run_id>/` (`plan.md:65-75`; packet).
- Skill propose-only + buffer-until-finalize (`skills/crossfire-interviewer/SKILL.md:10-18,38-70`).
- Persist API already exists: `crossfire_persist_weakness` (`scripts/weakness_memory.sh:553-563`).

### Hermes CLI (commands actually run)

Isolation prefix used for all Hermes invocations:

`wsl.exe -e bash -lc 'export HOME=/home/fish PATH="/home/fish/.local/bin:$PATH" HERMES_HOME=/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test; …'`

| Command | Result |
| --- | --- |
| `hermes --version` | Hermes Agent v0.20.2 (2026.8.16); `/home/fish/.local/bin/hermes` |
| `hermes --help` | `--resume SESSION`, `-t/--toolsets`, `--pass-session-id`, `--safe-mode` (implies ignore-user-config + ignore-rules), `sessions` subcommand |
| `hermes chat --help` | `-q` single query; `-Q` quiet (“final response and session info”); `--resume SESSION_ID` or `latest`; `--max-turns N` = **tool-calling iterations per turn** (default 500); `-t` “toolsets to enable”; `-s/--skills` preload; `--source` (default `cli`) |
| `hermes sessions --help` / `list --help` | SQLite session store; `list`, `export`, `rename` |
| `hermes sessions list --limit 10` | IDs like `20260816_161838_05db3e` (workspace `interview-gee`) |
| `hermes tools --help` / `list --platform cli` | `memory` **enabled**; `file` **enabled**; `session_search` **enabled**; `hermes tools disable NAME` persists per platform |
| `hermes skills list` | many builtins; **no** `crossfire-interviewer` |
| `hermes memory --help` | not needed after tools list |

No `hermes chat -Q` ping this packet: help + `sessions list` + install-tree source decided resume/session-id. Prior S2-T5 probe already showed `hermes chat -Q -q pong` → `pong` (`.workflow/S2-T5/results/install-probe.md:30`).

### Install-tree reads (not public-doc)

- Slash registry `/home/fish/.hermes/hermes-agent/hermes_cli/commands.py`: `COMMAND_REGISTRY` includes `quit` (“Exit the CLI”) at line 387; **no `done` entry** (CommandDef list 144–387).
- Quiet `-Q` path `/home/fish/.hermes/hermes-agent/cli.py:20070-20094`: stdout = final response; **stderr** = `session_id: {cli.session_id}`.
- Interactive/single-query summary `_print_exit_summary` (`cli.py:16192-16200`): `Resume this session with:` / `hermes --resume {id}` / `Session:        {id}`.

Resume status: **verified** for CLI flag + listable IDs + `-Q` stderr format. A live `--resume` round-trip was **not** run.

### Isolated profile (read-only)

- `HERMES_HOME=.../.crossfire/profiles/test/config.yaml`: `model.provider=nous`, `model.default=stepfun/step-3.7-flash:free`.
- `memories/` empty (no `MEMORY.md` yet). `state.db` present. Sessions exist from earlier pings.
- Real `/home/fish/.hermes` extra dirs (`SOUL.md`, `memories/`, `sessions/`, `skills/`, …) have mtime **16:06** — **before** this research (~16:21). Empty of MEMORY.md and session files. Windows `%USERPROFILE%\.hermes` absent. Treat 16:06 as pre-existing; still fail-closed in product tests.

## How the hybrid loop should work

1. `source scripts/demo_common.sh`; `crossfire_require_isolated_hermes_home`.
2. Allocate `run_id`; create `.crossfire/runs/<run_id>/spool/`.
3. For each of the three §11 questions: print question; read the next line/block from `tests/fixtures/demo-answers.txt`; invoke isolated:

```text
hermes chat -Q -q "<assess this Q+A; emit propose-only YAML>" \
  --max-turns 1 \
  --toolsets skills \
  --skills <repo>/skills/crossfire-interviewer \
  --source tool \
  [--resume "$SESSION_ID"]
```

4. Parse proposal from stdout; parse `session_id:` from stderr; write spool file; **do not** call `crossfire_persist_weakness` yet.
5. After Q3 (or stdin `/done`): same finalize function → persist qualifying rows → print ack. Candidate staging is Task 6 (out of scope).

`--toolsets skills` is an allowlist (chat help: “toolsets to **enable**”), so `memory` and `file` stay off for that process without writing `hermes tools disable` into the profile.

## Test strategy (TDD)

Mirror `tests/assessment_eval.bats` (skip when undiscoverable ≠ pass; `CROSSFIRE_LIVE=1` fails closed):

- **Always:** three questions, fixture answers, spool-before-MEMORY.md, fingerprint unchanged until finalize, `/done`==auto-finalize, persist rule, no confirm, isolation fail-closed.
- **Live (Hermes discoverable or `CROSSFIRE_LIVE=1`):** one isolated `-Q` assessor on the scripted bad answer (K=3); assert spool proposal + optional persist-on-finalize. Do **not** treat skip as “session one ran against installed Hermes”.
- Do **not** make default CI a full free-tier 3-Q interview.

## YAML round-trip

**Wait.** Session-one writer is the harness (`crossfire_persist_weakness`). If assessor `-t` omits `memory` and `file`, Hermes should not rewrite MEMORY.md during session one. Round-trip still **unproven** (`docs/hermes-compatibility.md:36-37`); first attempt remains `memory-md-block` after finalize / session two.

## Isolation / dead ends

- Did not write product files. Did not run a 3-question interview. Did not `hermes tools disable` (would persist config).
- Did not point commands at real `~/.hermes` as `HERMES_HOME`.
- **Dead end:** interactive `hermes chat` + typed `/done` — `/done` is unknown to Hermes; `/quit` deletes-or-exits and is forbidden in the spoken script.
- **Dead end:** `--safe-mode` as memory guard — drops isolated Nous `config.yaml`.
- **Dead end:** using Hermes session export (`jsonl`/`md`) as the assessment buffer — transcript, not §10 YAML.

## Open questions

1. Does `-s` accept a filesystem path to `skills/crossfire-interviewer`, or only an installed skill name?
2. Minimal `--toolsets` that still preloads the skill with no `file`/`memory`/`terminal`.
3. Whether default `bats tests/demo_session_1.bats` should auto-run the live assessor on this machine (binary is discoverable via WSL).
