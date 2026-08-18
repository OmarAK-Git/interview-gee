# Packet 01-research: Candidate skill authorship and exclusion

## Objective

Choose how a poor session-one answer produces a provenance-linked candidate `SKILL.md` that is **not loadable** before session two. Record authorship (Hermes / skill / harness-relocated) and the exclusion mechanism.

## Context

Workspace: `C:\Users\oalan\interview-gee`. Spec `sparring-1.0.0` wins.

- Spec §14: created/patched on finalize; lives in `.crossfire/candidate-skills/` until after the opener; `status: unverified`; contains `weakness_id`, `source_session_id`, `answer_ref`, `observation_count`; one candidate per `target_family`; must not treat the bad answer as a model answer.
- Spec §8: harness exclusively owns `.crossfire/candidate-skills/`. Hermes must not edit it.
- Spec §13 candidate barrier: session two must not launch until harness asserts candidate is outside the live skill dir. Lock/flag file. If move cannot be guaranteed, degraded path + disclosure.
- Plan Task 6: prefer verified learning-loop mechanism; if Hermes writes into the live dir, snapshot immediately then disable/move the live copy reversibly.
- S2-T5 already copies the **stable** skill into `$HERMES_SKILLS_DIR/crossfire-interviewer/` at runtime because Hermes rejects repo `--skills` paths. Candidates must not collide with that path.
- Isolated profile: `HERMES_HOME=<repo>/.crossfire/profiles/test`. Hermes v0.20.2 WSL user `fish`. Do not use real `~/.hermes` as HERMES_HOME.

## Paths with opportunity cost (must pick one of each)

1. **Authorship:** Hermes-authored learning-loop vs skill-authored vs harness-relocated (harness writes the candidate SKILL.md from spool/MEMORY.md).
2. **Exclusion:** never write into live `$HERMES_SKILLS_DIR` vs snapshot-then-move if Hermes writes live vs degraded disclosure if exclusion is impossible.
3. **Staging root:** spec `.crossfire/candidate-skills/` vs also run-scoped `.crossfire/runs/<run_id>/` copy. Spec staging dir is required; extra copies are optional.

## Ownership

researcher (read-only product files). Write only `.workflow/S2-T6/results/researcher-result.md`.

## Do

Probe on the **isolated** profile only. Record:

- Whether Hermes has a learning-loop / skill-write that would create a SKILL.md after persist (commands actually run, or explicitly unverified).
- Live skill dir path: `$HERMES_HOME/skills`.
- How `hermes skills list` treats a file dropped into `$HERMES_SKILLS_DIR/<name>/SKILL.md` vs `.crossfire/candidate-skills/`.
- Whether `--skills` / startup load would pick up a candidate if it were in the live dir.
- Snapshot/move feasibility without touching real `~/.hermes`.

Recommend implementer contract: function names, file layout, tests that must fail if a candidate exists under `$HERMES_SKILLS_DIR` (except the stable `crossfire-interviewer` copy).

## Do Not

- Write product files (`stage_candidate_skill.sh`, bats, SKILL.md, compatibility doc) — implementer does that.
- Implement session-two opener or activate the candidate (Task 7 / Task 9).
- Point probes at real `~/.hermes` as HERMES_HOME.
- Install packages. Do not `hermes tools disable` into the real profile.
- Commit.

## Expected Output

`.workflow/S2-T6/results/researcher-result.md` with chosen paths, rejected alternatives + why, command evidence, implementer notes, open questions, and JSON:

```json
{
  "packet_id": "01-research",
  "status": "done",
  "chosen_paths": {
    "authorship": "hermes-authored | skill-authored | harness-relocated",
    "exclusion": "never-write-live | snapshot-then-move | degraded-disclosure",
    "staging_root": ".crossfire/candidate-skills/"
  },
  "why": "string",
  "opportunity_cost": [{"path": "string", "rejected": true, "why": "string"}]
}
```
