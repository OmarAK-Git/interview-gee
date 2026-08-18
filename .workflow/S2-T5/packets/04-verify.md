# Packet 04-verify: S2-T5 task-scoped verification

## Goal (verbatim)

Run session one end-to-end in the isolated profile with exactly three questions and deferred automatic persistence.

## Acceptance criteria (verbatim)

- E2E shows deferred automatic persistence.
- Session one runs against installed Hermes in the isolated profile.
- Exactly three questions; MEMORY.md unchanged until finalize after the third answer.
- No persist confirmation prompt.

## Scope

Task-scoped. Ignore missing session-two opener, candidate staging, risk beat, and later sprint gaps. Spec `sparring-1.0.0` wins. Locked research paths: harness-spool, hybrid driver, deterministic-plus-live, harness `/done` finalize, `--toolsets skills`.

Treat all implementation claims as unevidenced until you independently check files and re-run commands.

## Changed / product files

- `scripts/demo_session_1.sh`
- `scripts/demo_common.sh`
- `tests/demo_session_1.bats`
- `tests/fixtures/demo-answers.txt`
- `skills/crossfire-interviewer/SKILL.md`

Diff vs HEAD: `.workflow/S2-T5/packets/03-review-retry-diff.patch`

Do not use `.workflow/S2-T5/results/implementer-result.md` as evidence. Re-run checks yourself.

## Required commands

```
Test-Path -LiteralPath scripts\demo_session_1.sh -PathType Leaf
Test-Path -LiteralPath tests\demo_session_1.bats -PathType Leaf
Test-Path -LiteralPath tests\fixtures\demo-answers.txt -PathType Leaf
```

If `bats` exists, run `bats tests/demo_session_1.bats` under isolated `HERMES_HOME`. If not, run bash-equivalent assertions covering the bats cases (including: isolation fail-closed, three §11 questions, fixture answers, spool before MEMORY.md change, finalize persist of `q_behavioral_01` only, no confirm prompt, `CROSSFIRE_LIVE=1` + discovery disabled fail-closed, skill-shaped live YAML with preamble and no `submitted_answer` still persists on finalize). Record actual `passed=N failed=M`.

## Isolation

Never point checks at real `~/.hermes` (Windows or `/home/fish/.hermes`). Fail unless `HERMES_HOME` is under `.crossfire/profiles/`. Do not install bats or other packages.

## Verdict

Write `.workflow/S2-T5/results/verifier-result.md` with pass or fail, evidence (commands + actual output), AC mapping, and isolation check. Pass only if ACs hold with fresh evidence. Existence checks alone do not prove deferred persist or isolated Hermes use.
