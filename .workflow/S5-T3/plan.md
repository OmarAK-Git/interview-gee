# Workflow Plan — S5-T3

## Goal

New session cannot start without exactly one JD (pack or paste).

## Success Criteria

- [ ] start_session_args raises without jd_kind/pack/paste.
- [ ] GET /api/packs lists the four shipped packs.
- [ ] Wrapper start without JD fail-closes; start with pack prints source_id and temperature.
- [ ] Existing stub session and inference starts still pass when given pack env.

## Agent Plan

- Researcher: **skipped** — plan Task 3 specifies start_session_args, server wiring, wrapper fail-closed, stub env, and practice_jd.sh. No path fork.
- Implementer: required (`composer-2.5-fast`).
- Code reviewer: required after code-changing implementation.
- Skeptic verifier: required.
- Test runner: **skipped** — not a phase gate.

## Ruling

Sanitize `pack_id` in `require_session_jd` before path join (basename must equal pack_id; resolved path must stay under sources_dir). S5-T1 reviewer minor; T3 exposes this over HTTP. Cost if wrong: extra than plan transcription.

## Work Packets

| ID | Objective | Ownership | Status |
| --- | --- | --- | --- |
| 01-research | Path choices | researcher | skipped |
| 02-implementation | Require JD on start | implementer | pending |
| 03-review | Review | code-reviewer | pending |
| 04-verify | Verify | skeptic-verifier | pending |
