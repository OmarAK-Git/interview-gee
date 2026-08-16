# S2-T5 / drain handoff (2026-08-16, operator going offline)

Controller launched a **cloud** continuation. Do not wait for the operator.

## Queue

- Sprint 1 (`S1-T1` … `S1-GE`) is **done**.
- **Current item:** `S2-T5` status `in_progress`, attempts=1.
- Next after T5: `S2-T6` → `S2-T7` → `S2-GE` (must-ship). Then nice items / `S4-T12`.

## S2-T5 state

Research **done**: `.workflow/S2-T5/results/researcher-result.md` ([researcher](332e4435-694e-4149-858a-08a4a5c40781)).

Locked paths: harness-spool, hybrid driver, deterministic-plus-live, harness `/done` finalize, `--toolsets skills` (no memory/file/terminal).

Implementer (`composer-2.5`) was **aborted** mid-flight. Product files exist but are unfinished:

- `scripts/demo_session_1.sh` — truncated locals (`submitted_answe`, `answe`); `set +e` scattered; persist may ignore `crossfire_persist_weakness` exit status
- `scripts/demo_common.sh` — run/spool/assessor helpers added
- `tests/demo_session_1.bats`, `tests/fixtures/demo-answers.txt` exist
- `skills/crossfire-interviewer/SKILL.md` — **corrupted** (many `r` letters stripped: Hemes/haness/poposing). Restore from git/spec language; keep the new session-one harness notes
- **Missing:** `.workflow/S2-T5/results/implementer-result.md`
- `.workflow/S2-T5/run_assertions.sh` is a scratch assertion harness (not files_allowed; do not treat as product)

Packet: `.workflow/S2-T5/packets/02-implementation.md`

## Protocol (GSD)

Controller orchestrates; do not mark `done` without skeptic-verifier evidence.

1. Finish implementer (model `composer-2.5-fast` — slug is not `composer-2.5`) within `files_allowed`. TDD. Do not install bats. Do not commit unless needed for cloud; **never** commit `.crossfire/shared/nous_auth.json` or profile secrets.
2. Code-reviewer after code changes. Blocking findings → retry.
3. Status `verifying`, then skeptic-verifier with `cursor-grok-4.6-high-fast`. Packet: goal, ACs, diff, commands — **no** implementer reasoning dump.
4. On pass: queue `done`, project memory-bank, continue drain (`S2-T6` needs_research true, then T7, then `S2-GE` in-session Grok gate).

## Hard stops

- Never point tests at real `~/.hermes` (Windows or `/home/fish/.hermes`).
- Ask before dependency installs, harness config, clones, writes outside workspace.
- Do not implement candidate staging (T6) or session-two opener (T7) inside T5.
- Spec wins: `.crossfire/runs/<run_id>/`. Three demo questions never cut. Automatic persist, no confirm.

## Environment

- Hermes v0.20.2 on WSL user `fish`. Isolated `HERMES_HOME=<repo>/.crossfire/profiles/test`.
- Free model `stepfun/step-3.7-flash:free`. Portal auth is gitignored under `.crossfire/`.
- This git repo has **no remote** at handoff time; if cloud clone is bootstrap-only (`d3f7041`), **stop** and report missing S1 working tree — do not reinvent Sprint 1 from the spec alone.
