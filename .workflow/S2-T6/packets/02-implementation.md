# Packet 02-implementation: Stage unverified candidate skill

## Objective

A poor answer produces a visible provenance-linked candidate `SKILL.md` that is not loadable before session two.

## Locked paths (do not reopen)

| Decision | Choice |
| --- | --- |
| Authorship | **harness-relocated** — harness writes §14 SKILL.md from spool/MEMORY.md |
| Exclusion | **never-write-live** — never write under `$HERMES_SKILLS_DIR`. Snapshot-then-move is fallback only |
| Staging root | **`.crossfire/candidate-skills/`** |

Research: `.workflow/S2-T6/results/researcher-result.md`. Spec §8, §13, §14.

**Ruling:** do **not** widen `files_allowed`. Do **not** edit `scripts/demo_session_1.sh`. Tests and `stage_candidate_skill.sh` must produce the candidate from spool + MEMORY fixtures (or by invoking persist then stage). Record that session-one finalize can call the stage function later; that hook is out of this packet's write set.

## Files allowed

- `scripts/stage_candidate_skill.sh`
- `.crossfire/candidate-skills/.gitkeep`
- `tests/candidate_skill.bats`
- `skills/crossfire-interviewer/SKILL.md`
- `docs/hermes-compatibility.md`

Plus `.workflow/S2-T6/results/implementer-result.md`. You may write a throwaway `.workflow/S2-T6/bash-assertions.sh`. Do not edit memory-bank or the queue. **Do not commit.**

## Implementer contract (from research)

Layout: `.crossfire/candidate-skills/unverified-<family>-followup/SKILL.md` (`id: crossfire.candidate.<family>`, `name: unverified-<family>-followup`). Never `crossfire-interviewer/`.

Functions:

- `crossfire_candidate_skills_root` → `${REPO_ROOT}/.crossfire/candidate-skills`
- `crossfire_stage_candidate_skill` — write/patch one SKILL.md per `target_family`; frontmatter `status: unverified`, `weakness_id`, `source_session_id`, `answer_ref`, `observation_count`, `missing_elements`; body = corrective checklist + follow-up template; **do not** praise/imitate `submitted_answer`. Reuse one provenance key (`weakness_id` from family+topic_key as persist already computes).
- `crossfire_assert_candidates_excluded_from_live` — fail-closed unless `HERMES_HOME` under `.crossfire/profiles/`
- `crossfire_write_candidate_barrier_flag` → `.crossfire/runs/<run_id>/candidate-excluded.flag`
- `crossfire_snapshot_live_candidates_if_any` — fallback only if `id: crossfire.candidate.*` appears under `$HERMES_SKILLS_DIR`; `mv` reversibly under `.crossfire/runs/<run_id>/live-skill-snapshot/` then re-assert. Do not `hermes tools disable`.

TDD. Do not install bats. Run bash-equivalent assertions; record `passed=N failed=0`. Isolation fail-closed. Tests must fail if a candidate exists under `$HERMES_SKILLS_DIR` (allow only stable `crossfire-interviewer` plus Hermes bundled dirs).

Update `docs/hermes-compatibility.md` exclude-candidate row: **verified** (harness staging; never-write-live). Keep skill forbid-staging.

Optional live: if Hermes discoverable, `hermes skills list --source local` must not contain `unverified-` names; `--skills` on staged path must error `Unknown skill(s)`. Skip-as-pass is not an AC pass; `CROSSFIRE_LIVE=1` without Hermes fails closed.

Do not implement session-two opener or candidate activation.

## Expected Output

`.workflow/S2-T6/results/implementer-result.md` with files, actual command results, JSON summary.
