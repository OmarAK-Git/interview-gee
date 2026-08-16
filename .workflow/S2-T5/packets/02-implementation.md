# Packet 02-implementation: Three-question demo session one

## Objective

Ship session-one harness with deferred automatic persistence: exactly three spec §11 questions, answers from the fixture file, assessments buffered, MEMORY.md unchanged until harness `/done` finalize.

## Context

Research: `.workflow/S2-T5/results/researcher-result.md` ([researcher](332e4435-694e-4149-858a-08a4a5c40781)).
Spec: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` §8, §10 live demo gate, §11, §12.
Plan Task 5: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-plan.md` lines 65–75.

### Locked paths (do not reopen)

| Decision | Choice |
| --- | --- |
| Buffer | harness-spool under `.crossfire/runs/<run_id>/spool/` (spec wins over plan `.crossfire/run/`) |
| Driver | **hybrid**: harness prints the three questions, reads `tests/fixtures/demo-answers.txt`, calls isolated `hermes chat -Q` as assessor (or stub when `CROSSFIRE_ASSESSOR=stub`), writes spool, does **not** persist until finalize |
| Tests | **deterministic-plus-live**: always-on harness tests; live `-Q` only when `CROSSFIRE_LIVE=1`; skip-when-missing is not an E2E pass; `CROSSFIRE_LIVE=1` without Hermes **fails closed** |
| Finalize | harness `/done` equivalent — same function as auto-finalize after answer 3; print ack. Hermes has `/quit` not `/done`; do not send `/quit` |
| Memory guard | `--toolsets skills` allowlist (omit `memory`, `file`, `terminal`). Do **not** use `--safe-mode` or `--ignore-user-config` (they drop isolated Nous config) |

Controller resolutions of researcher open questions:

1. Try `--skills` with filesystem path `skills/crossfire-interviewer`. If rejected, copy the stable skill into isolated `$HERMES_SKILLS_DIR/crossfire-interviewer/` at **runtime** (not `.crossfire/candidate-skills/`).
2. Use `--toolsets skills`.
3. Default bats/harness tests are **stub/deterministic**. Live assessor is opt-in `CROSSFIRE_LIVE=1`. You MUST still attempt one isolated live `-Q` (or `demo_session_1.sh` live) during this task and record stdout/stderr as evidence. If live fails (credits/network), record the command+error; do not fake a pass.

Workspace: `C:\Users\oalan\interview-gee`. **No worktree.** Do not create one. **Do not commit.** Do not edit `memory-bank/` (controller projects after verifier).

Hermes: WSL Ubuntu user `fish`, v0.20.2, isolated `HERMES_HOME=<repo>/.crossfire/profiles/test`, model `stepfun/step-3.7-flash:free`.

Persist API (already exists — source it, do not copy):

```
crossfire_persist_weakness memory_md family topic missing_csv last_seen source_session_id answer_ref evidence_kind evidence_value submitted_answer
```

See `scripts/weakness_memory.sh` and `tests/weakness_memory.bats:43-53`.

## Files or Sources

Write **only**:

- `skills/crossfire-interviewer/SKILL.md`
- `scripts/demo_session_1.sh`
- `scripts/demo_common.sh`
- `tests/demo_session_1.bats`
- `tests/fixtures/demo-answers.txt`

Do not write candidate staging, session-two scripts, docs/hermes-compatibility.md, or memory-bank.

## Ownership

implementer (`composer-2.5`)

## Do

TDD. `bats` is likely **not installed** — do not install it. Write the bats file anyway. Run bash-equivalent assertions (WSL `bash`) covering the same cases and record `passed=N failed=0` like S1-T2.

### 1. Fixture `tests/fixtures/demo-answers.txt`

Exactly three answers, order matching spec §11:

| Order | ID | Kind | Content |
| --- | --- | --- | --- |
| 1 | `q_technical_01` | strong | Must include never-contain / hash-chained ledger / verification (see `tests/fixtures/assessment-cases.md` `technical_strong_01`) |
| 2 | `q_behavioral_01` | **bad** | Exactly or including `I just kind of watched the dashboard.` (omits action+result) |
| 3 | `q_product_01` | strong | Names user, constraint, decision, metric |

Answers are read by the harness; not typed by the operator.

### 2. `tests/demo_session_1.bats` (write first)

Must encode:

- Sources `scripts/demo_common.sh`; fail-closed unless `HERMES_HOME` is under `.crossfire/profiles/`
- Exactly three spec §11 questions in order; answers from `demo-answers.txt`
- Each assessment lands under `.crossfire/runs/<run_id>/spool/` **before** finalize
- MEMORY.md missing or fingerprint unchanged until finalize
- `/done` and post-Q3 auto-finalize are the **same function** and print an ack
- Stub assessor: `q_behavioral_01` persists via `crossfire_persist_weakness`; strong answers (`missing < 2`) do not persist
- No confirmation prompt in output
- Assessor invocations omit `memory`/`file`/`terminal` from `--toolsets` (assert the command line the harness would use, or a `CROSSFIRE_HERMES_CMDLINE` log)
- `source_session_id` captured into persist (stub may use `sess_stub`)
- Live skip when Hermes missing is **not** documented as E2E pass
- `CROSSFIRE_LIVE=1` with `CROSSFIRE_HERMES_DISCOVERY=0` fails closed
- Isolation: never mkdir/write `REAL_HERMES_*`

Use `CROSSFIRE_ASSESSOR=stub` for deterministic runs so tests do not need the model.

### 3. `scripts/demo_session_1.sh`

Hybrid loop:

1. Source `demo_common.sh`; `crossfire_require_isolated_hermes_home`
2. Allocate `run_id`; mkdir `.crossfire/runs/<run_id>/spool/`
3. For each of three questions: print the question; read next answer from fixture; assess (stub or live `-Q`); write spool; **do not persist yet**
4. After Q3 (or stdin `/done`): same finalize function → persist qualifying spool rows (`persist_recommended` or `count(missing_elements)>=2`) via `crossfire_persist_weakness` → print ack
5. Concise output. No “please confirm persist”

Live assessor (when not stub):

```
hermes chat -Q -q "<assess this Q+A; emit propose-only YAML>" \
  --max-turns 1 \
  --toolsets skills \
  --skills <repo>/skills/crossfire-interviewer \
  --source tool
```

Parse `session_id:` from stderr. `--max-turns` is tool iterations, not question count. Invoke via WSL when the binary is WSL-only (`HOME=/home/fish`, `PATH` includes `/home/fish/.local/bin`, `HERMES_HOME` = isolated profile).

Live demo gate: retry the bad-answer assessment up to **K = 3**, then abort with a clear message if no qualifying persist.

Candidate staging is **out of scope**. Record session_id for later S2-T7; do not start session two.

### 4. `scripts/demo_common.sh`

Add only what session one needs (e.g. `CROSSFIRE_RUNS_DIR`, run_id helper, MEMORY.md fingerprint helper, WSL hermes invoke helper). Keep isolation contract. Never default `HERMES_HOME` to real `~/.hermes`.

### 5. `skills/crossfire-interviewer/SKILL.md`

Add session-one harness notes: three demo questions in order; propose-only YAML; buffered until harness `/done`; do not write MEMORY.md; do not ask for persist confirmation. Do not implement session-two opener behavior beyond the existing reference section.

## Do Not

- Install bats, packages, or Hermes extras (approval-first)
- Mutate real `~/.hermes` (Windows or `/home/fish/.hermes`)
- Use `--safe-mode`, `--ignore-user-config`, or send `/quit`
- Stage candidate skills or write `demo_session_2.sh`
- Widen beyond files_allowed
- Mark the queue item done
- Commit

## Expected Output

Changed files + rationale, commands run with **actual** results (including stub assertions and any live `-Q` attempt). Write `.workflow/S2-T5/results/implementer-result.md`.

## Verification (run these; do not invent pass)

```powershell
Test-Path -LiteralPath scripts\demo_session_1.sh -PathType Leaf
Test-Path -LiteralPath tests\demo_session_1.bats -PathType Leaf
Test-Path -LiteralPath tests\fixtures\demo-answers.txt -PathType Leaf
```

If `bats` exists, run `bats tests/demo_session_1.bats` under isolation. If not, run bash-equivalent assertions and record `BATS_MISSING`.

Attempt one isolated live assessor call **or** `CROSSFIRE_LIVE=1` only if Hermes is discoverable; never against real `~/.hermes`.
