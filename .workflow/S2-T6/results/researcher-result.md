# S2-T6 researcher: Candidate skill authorship and exclusion

**Packet:** `01-research` · **Status:** done · **Date:** 2026-08-18  
**Scope:** isolated `HERMES_HOME=<repo>/.crossfire/profiles/test` only (Hermes Agent v0.20.2, WSL user `fish`). Spec `sparring-1.0.0` wins. Real `~/.hermes` was never used as `HERMES_HOME`.

## Verdict

Pick **harness-relocated** authorship, **never-write-live** exclusion, and staging root **`.crossfire/candidate-skills/`**.

Hermes *can* create `SKILL.md` into the live dir (`skill_manage` / `_create_skill` → `$HERMES_HOME/skills`), and anything there is loadable. The learning loop is **not verified** to fire on session-one persist, and when it writes it writes the wrong place with the wrong shape. Spec §8 already forbids Hermes from editing `.crossfire/candidate-skills/`. A file dropped there is **not** listed and **`--skills` rejects it**. Snapshot-then-move is a verified fallback, not the primary path.

```json
{
  "packet_id": "01-research",
  "status": "done",
  "chosen_paths": {
    "authorship": "harness-relocated",
    "exclusion": "never-write-live",
    "staging_root": ".crossfire/candidate-skills/"
  },
  "why": "Hermes skill writes land in live $HERMES_SKILLS_DIR (loadable); candidate-skills files are not listed and --skills rejects them — harness writes spec SKILL.md from spool/MEMORY.md there.",
  "opportunity_cost": [
    {"path": "hermes-authored", "rejected": true, "why": "Learning-loop trigger after persist unverified; _create_skill writes live dir; spec §8 forbids Hermes editing candidate-skills; output is a procedure skill, not §14 provenance/unverified follow-up."},
    {"path": "skill-authored", "rejected": true, "why": "Stable SKILL.md already forbids staging; --toolsets skills includes skill_manage which writes live and would collide with the S2-T5 crossfire-interviewer copy."},
    {"path": "snapshot-then-move", "rejected": true, "why": "Verified as fallback if a live write appears; primary path must never write live so session two does not race a move."},
    {"path": "degraded-disclosure", "rejected": true, "why": "Exclusion is possible: staging outside $HERMES_SKILLS_DIR is not loadable."},
    {"path": ".crossfire/runs/<run_id>/ extra SKILL.md copy", "rejected": true, "why": "Spec §14 staging dir is required; extra body copies optional. Record path in a run-scoped barrier flag instead."}
  ]
}
```

## Chosen paths (opportunity cost)

| Decision | Pick | Why | Rejected |
| --- | --- | --- | --- |
| Authorship | **harness-relocated** | Harness already owns spool + MEMORY.md + persist. Write §14 `SKILL.md` from those fields into `.crossfire/candidate-skills/`. | Hermes-authored (unverified persist trigger; live write). Skill-authored (`skill_manage` → live). |
| Exclusion | **never-write-live** | Probe: live-dir file is listed/preloadable; candidate-skills file is not. S2-T5 already occupies `$HERMES_SKILLS_DIR/crossfire-interviewer/`. | snapshot-then-move as default (keep as fallback). degraded-disclosure (exclusion works). |
| Staging root | **`.crossfire/candidate-skills/`** | Spec §8/§14 required location. Outside trusted skill roots so `--skills` cannot normalize the path. | Required extra run-scoped SKILL.md copy. Use `.crossfire/runs/<run_id>/candidate-excluded.flag` for rehearsal scoping (spec §6). |

## Evidence

### Spec / prior tasks (authoritative)

- Spec §8: harness exclusively owns `.crossfire/candidate-skills/`; Hermes must not edit it (`docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md:101-106`).
- Spec §13: session two must not launch until harness asserts candidate is outside the live skill dir; lock/flag; degraded path only if move cannot be guaranteed (`spec.md:235`).
- Spec §14: created/patched on finalize; `status: unverified`; `weakness_id`, `source_session_id`, `answer_ref`, `observation_count`; one candidate per `target_family`; must not treat the bad answer as a model answer (`spec.md:237-268`).
- Plan Task 6: prefer verified learning-loop; else snapshot-then-move; document authorship (`plan.md:77-87`).
- S2-T5: `--skills <repo>/skills/crossfire-interviewer` → `Error: Unknown skill(s): …`; runtime copy into `$HERMES_SKILLS_DIR/crossfire-interviewer/` (`demo_common.sh:315-323`; implementer-result). Candidates must not use that path.
- Skill already: do not stage candidates (`skills/crossfire-interviewer/SKILL.md:10,70,76`).
- Persist source already exists: spool `answer_ref` / `source_session_id` / `missing_elements` (`scripts/demo_session_1.sh`; example spool `q_behavioral_01.yaml`).

### Hermes install-tree (not public-doc; not executed as HERMES_HOME)

- `_create_skill` writes `_skills_dir() / name` = `get_hermes_home() / "skills"` (`tools/skill_manager_tool.py:160-172,638-642,908-942`).
- `--toolsets skills` includes `skill_manage` (`toolsets.py:52,201`).
- `--skills` preload uses `normalize_skill_lookup_name`: absolute paths outside `$HERMES_HOME/skills` (and `skills.external_dirs`) pass through; `skill_view` rejects them → `Unknown skill(s)` (`agent/skill_utils.py:616-670`; `cli.py:8010-8017`). Isolated `config.yaml` has no `external_dirs`.
- Background review default **enabled** (`agent/background_review.py:75-87`). `/refine` exists (`commands.py:209`) — session one does not call it.
- Learning-loop **trigger after persist: unverified** (no `/refine`, no wait-for-review). After S2-T5 live `-Q` assessor, `hermes skills list --source local` showed only harness-copied `crossfire-interviewer`.

### Commands actually run (isolated `HERMES_HOME`)

Prefix:

`wsl.exe -e bash -lc 'export HOME=/home/fish PATH="/home/fish/.local/bin:$PATH" HERMES_HOME=/mnt/c/Users/oalan/interview-gee/.crossfire/profiles/test; …'`

Confirmed `HERMES_HOME != /home/fish/.hermes` on every invoke.

| Command | Result |
| --- | --- |
| `hermes --version` | v0.20.2 (2026.8.16) |
| `ls $HERMES_HOME/skills` | Bundled categories + **`crossfire-interviewer/`** (S2-T5 runtime copy) |
| `hermes skills list --source local` (baseline) | `crossfire-interviewer` local/enabled only |
| Drop `$HERMES_SKILLS_DIR/s2t6-probe-live/SKILL.md` then `list --source local` | **`s2t6-probe-live` listed local/enabled** |
| Drop `.crossfire/candidate-skills/s2t6-probe-candidate/SKILL.md` then same list | **candidate name absent** |
| `hermes chat -Q -q ping --max-turns 0 --toolsets skills --skills s2t6-probe-candidate --source tool` | `Error: Unknown skill(s): s2t6-probe-candidate` exit 1 |
| `--skills /mnt/c/…/.crossfire/candidate-skills/s2t6-probe-candidate` | `Error: Unknown skill(s): <path>` exit 1 |
| Python `build_preloaded_skills_prompt` (venv, same `HERMES_HOME`) | live name **and** live path: `loaded=['s2t6-probe-live']`; candidate name **and** path: `missing`; `crossfire-interviewer` loaded |
| `mv` live probe out of `$HERMES_SKILLS_DIR` then `list --source local` | probe gone; only `crossfire-interviewer` |
| `--skills s2t6-probe-live` after move | `Error: Unknown skill(s): s2t6-probe-live` exit 1 |
| `hermes skills inspect s2t6-probe-live` | `No skill named … found in any source` (inspect ≠ local catalog; do not use inspect as the barrier) |
| `hermes tools list --platform cli` | `skills` toolset **enabled** (contains `skill_manage`) |

Probes deleted afterward. Isolated local list restored to **`crossfire-interviewer` only**.

Snapshot/move feasibility: **verified** entirely under the repo (`.crossfire/runs/_s2t6-research/live-snapshot/`, then removed). No real `~/.hermes` touch as `HERMES_HOME`.

## Implementer contract

**Files:** `scripts/stage_candidate_skill.sh` (source `demo_common.sh` + `weakness_memory.sh` as needed), `.crossfire/candidate-skills/.gitkeep`, `tests/candidate_skill.bats`, keep skill forbid-staging; update `docs/hermes-compatibility.md` exclude-candidate row to **verified** (harness staging).

**Layout:** `.crossfire/candidate-skills/unverified-<family>-followup/SKILL.md` (spec `name:` / `id: crossfire.candidate.<family>`). Never `crossfire-interviewer/`.

**Functions (suggested):**

- `crossfire_candidate_skills_root` → `${REPO_ROOT}/.crossfire/candidate-skills`
- `crossfire_stage_candidate_skill` — on finalize, from spool + persisted MEMORY record: write/patch one SKILL.md per `target_family`; frontmatter `status: unverified`, `weakness_id`, `source_session_id`, `answer_ref`, `observation_count`, `missing_elements`; body = corrective checklist + follow-up template; **do not** praise/imitate `submitted_answer`.
- `crossfire_assert_candidates_excluded_from_live` — fail-closed unless `HERMES_HOME` under `.crossfire/profiles/`.
- `crossfire_write_candidate_barrier_flag` → `.crossfire/runs/<run_id>/candidate-excluded.flag` with staged path(s). Task 7 reads this; do not implement opener.
- `crossfire_snapshot_live_candidates_if_any` — **fallback only**: if a `id: crossfire.candidate.*` / `unverified-*-followup` SKILL.md appears under `$HERMES_SKILLS_DIR`, `mv` reversibly under `.crossfire/runs/<run_id>/live-skill-snapshot/` then re-assert. Do not `hermes tools disable` into any profile.

**Tests that must fail** if a candidate exists under `$HERMES_SKILLS_DIR` (allow only the stable **`crossfire-interviewer`** copy, plus Hermes bundled category dirs):

- Any `$HERMES_SKILLS_DIR/**/SKILL.md` with `id: crossfire.candidate.` or `name: unverified-` or `status: unverified` (except none should).
- Directory `$HERMES_SKILLS_DIR/unverified-*` or `$HERMES_SKILLS_DIR/crossfire.candidate.*`.
- Stage script writing into `$HERMES_SKILLS_DIR` or `$HERMES_SKILLS_DIR/crossfire-interviewer/`.
- Missing §14 fields; treating `submitted_answer` as a model answer; more than one candidate per family; missing `.gitkeep`.
- Isolation: fail-closed if `HERMES_HOME` is real `~/.hermes`.
- Optional live (Hermes discoverable): `hermes skills list --source local` must not contain `unverified-` names; `--skills` on the staged path must error `Unknown skill(s)`.

Hook staging from session-one **finalize** (same function as `/done`). Do not activate the candidate (Task 9) or implement session-two opener (Task 7).

## Dead ends

- `--skills` filesystem path outside `$HERMES_HOME/skills` (repo skill, candidate-skills) → Unknown skill. S2-T5 already locked the stable-skill copy.
- `hermes skills inspect` does not prove local loadability.
- Interactive `hermes skills config`; `hermes tools disable` (persists).
- Waiting on background review / `/refine` to author the candidate (unverified, would write live, costs tokens).

## Open questions

1. Should `demo_prepare` wipe `.crossfire/candidate-skills/` between rehearsals (spec §6: other `run_id`s not selectable)? Recommend yes, keyed by barrier flag.
2. Exact live install name for Task 9 (namespaced path) — out of scope; keep staging name `unverified-<family>-followup`.
3. Background-review write after a future longer session: still unverified; keep snapshot fallback in the stage script.
