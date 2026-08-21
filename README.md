# Hermes Interview Sparring Partner (Crossfire)

Stable Hermes skill + harness for interview sparring with weakness tracking.

- Demo CLI: spec `sparring-1.0.0` (`docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md`)
- Live practice UI: addendum `sparring-1.1.0` (`docs/sparring-1.1.0-practice.md`)

## Live practice (WSL)

Hermes interviews you in a localhost UI. Weaknesses persist to **WSL `$HOME/.hermes` only**. Windows `%USERPROFILE%\.hermes` is refused. Tests and `demo.sh` still fail-closed on any real home.

```bash
export HOME=/home/fish   # WSL user that has Hermes
# Once: copy Nous auth from the working isolated profile if Monday has no keys
#   cp .crossfire/profiles/test/config.yaml "$HOME/.hermes/"
#   cp .crossfire/profiles/test/auth.json "$HOME/.hermes/"   # gitignored
bash scripts/practice_ui.sh
# open http://127.0.0.1:8787
# Enter sends; Shift+Enter for a new line. Speak (Chrome/Edge) for voice replies.
# Weaknesses panel shows cards, not the on-disk YAML.
```

Stub harness (no live model) for tests: `CROSSFIRE_PRACTICE_STUB=1` with `HOME` pointing at a throwaway dir that owns `.hermes`.

## Profiles

| Profile | `HERMES_HOME` | Use |
| --- | --- | --- |
| **Test / stage** | `<repo>/.crossfire/profiles/test` or `stage` | Automated tests and the 90s demo |
| **Monday** | Real `~/.hermes` (WSL: `/home/<user>/.hermes`) | Free-form practice after the event |

**Hard rule:** automated tests and demo scripts never write real `~/.hermes`. Demo weaknesses under `.crossfire/profiles/stage` do **not** auto-copy to the Monday profile.

## Install the stable skill (once per profile)

From WSL (Hermes is installed there on this project’s reference machine):

```bash
export REPO_ROOT="/mnt/c/Users/oalan/interview-gee"   # adjust to your checkout
export HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"     # Monday profile

mkdir -p "${HERMES_HOME}/skills/crossfire-interviewer"
cp "${REPO_ROOT}/skills/crossfire-interviewer/SKILL.md" \
   "${HERMES_HOME}/skills/crossfire-interviewer/SKILL.md"
cp "${REPO_ROOT}/skills/crossfire-interviewer/questions.md" \
   "${HERMES_HOME}/skills/crossfire-interviewer/questions.md" 2>/dev/null || true

hermes doctor   # creates memories/, sessions/, state.db if missing
```

No prompt or `SOUL.md` edits are required. The skill contract is self-contained in `SKILL.md`.

## 90-second demo (disposable profile)

Pre-warm, then run the full scripted sequence — **no undocumented manual steps** between prepare and the timed run. See `docs/demo-script.md` for the spoken beat sheet and `docs/acceptance-checklist.md` for demo-blocking criteria with verifier evidence.

```bash
export REPO_ROOT="/mnt/c/Users/oalan/interview-gee"   # adjust to your checkout
export HERMES_HOME="${REPO_ROOT}/.crossfire/profiles/stage"
bash scripts/demo.sh --prepare
bash scripts/demo.sh
```

Live assessor/opener (after pre-warm):

```bash
export HERMES_HOME="${REPO_ROOT}/.crossfire/profiles/stage"
export CROSSFIRE_LIVE=1
export CROSSFIRE_ASSESSOR=live CROSSFIRE_OPENER=live
bash scripts/demo.sh
```

## Monday free-form (no prompt edits)

Use the **Monday profile** for open-ended practice. You type answers; the agent asks follow-ups beyond the three demo questions.

### Start a session

```bash
export REPO_ROOT="/mnt/c/Users/oalan/interview-gee"
export HERMES_HOME="$HOME/.hermes"

# Skill must already be copied (see Install above).
hermes chat \
  --skills crossfire-interviewer \
  --toolsets skills,memory \
  --source cli
```

**First question of a return session:** the skill reads weaknesses from in-context `MEMORY.md` and targets the newest gap (behavioral `action`/`result`, technical tradeoff/verification, product user/metric, etc.). It does **not** ask you to name the weakness or use demo-only fixture chatter.

**After the first question:** you may add `session_search` to `--toolsets` if your Hermes build supports it (`skills,memory,session_search`). If `session_search` is unavailable, continue without it — disk-backed `MEMORY.md` remains the opener source.

**Strong answers:** when fewer than two required family elements are missing, the skill recommends no persist (`persist_recommended: false`). That is expected.

**Beyond three questions:** keep the conversation going. Optional extra coverage lives in `skills/crossfire-interviewer/questions.md` (cuttable bank; demo three in `SKILL.md` are unchanged).

### End a session

Use Hermes’s normal exit path (for example `/quit` in the REPL). The skill emits propose-only assessment YAML during the session; durable weakness writes are harness-owned in demo mode. For Monday free-form, review proposals in the session transcript and merge qualifying observations into `MEMORY.md` manually until a Monday finalize helper ships — or run a future harness wrapper pointed at `$HOME/.hermes`.

Do **not** copy `.crossfire/profiles/stage/memories/MEMORY.md` into real `~/.hermes`. Build Monday weakness history from your own answers.

### Isolated rehearsal (safe smoke)

To rehearse free-form behavior without touching real `~/.hermes`:

```bash
export HERMES_HOME="${REPO_ROOT}/.crossfire/profiles/test"
mkdir -p "${HERMES_HOME}/memories"
cp tests/fixtures/memory-three-weaknesses.md "${HERMES_HOME}/memories/MEMORY.md"
cp -r skills/crossfire-interviewer "${HERMES_HOME}/skills/"

hermes chat --skills crossfire-interviewer --toolsets skills,memory --source cli
```

Record outcomes in `tests/interactive_smoke.md`.

## Tests

```bash
export REPO_ROOT="/mnt/c/Users/oalan/interview-gee"   # adjust to your checkout
export HERMES_HOME="${REPO_ROOT}/.crossfire/profiles/test"
bats tests/
```

Isolation tests fail closed if `HERMES_HOME` resolves to real `~/.hermes`.

**Known limitation:** `bats` may not be installed on the reference machine. Task verifiers used `.workflow/*/bash-assertions.sh` substitutes; install `bats` to replay the full suite. See `docs/acceptance-checklist.md` § Should-pass / known limitations.

## Key paths

| Path | Role |
| --- | --- |
| `skills/crossfire-interviewer/SKILL.md` | Stable assessor + interviewer contract |
| `scripts/demo.sh` | Full demo orchestrator |
| `scripts/demo_common.sh` | Isolation guards and Hermes discovery |
| `.crossfire/profiles/` | Disposable Hermes profiles |
| `.crossfire/runs/<run_id>/` | Run-scoped spool and artifacts |
| `docs/demo-script.md` | Spoken demo script |
| `docs/acceptance-checklist.md` | Demo-blocking ACs with verifier evidence |
| `docs/hermes-compatibility.md` | Machine-local Hermes capability matrix |
| `tests/interactive_smoke.md` | Manual free-form smoke record (live transcript **human_needed**) |

## Documentation map

- **Spec / plan:** `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md`, `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-plan.md`
- **Durable task state:** `memory-bank/`
- **Workflow evidence:** `.workflow/`
