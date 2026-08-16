# S1-T3 researcher: Family-specific assessment contract

**Packet:** S1-T3 research · **Status:** done · **Date:** 2026-08-16  
**Scope:** read-only except this file. Hermes binary **unsupported**. Do not install. Do not mutate `~/.hermes`. Do not implement.

Frame: replace unrunnable spec §10 live fixture eval (N=5, ≥4 persist-decision match) with the strongest contract proof this machine can ship without a binary — without redefining that eval as “passed.”

## Verdict

**Chosen path: 3** — `SKILL.md` + `tests/fixtures/assessment-cases.md` + `tests/assessment_eval.bats` encode spec §10; live N=5 eval **skips** when Hermes is missing and **fails closed** if live mode is forced without a binary.

Path 1 cannot run. Path 2 as *the* test oracle would launder a tautological (or keyword) checklist as the spec’s tolerance eval. Path 3 keeps the live oracle for after install and still proves the contract + fixture labels now.

## Chosen path (JSON)

```json
{
  "task_id": "S1-T3",
  "status": "done",
  "chosen_path": 3,
  "chosen_path_name": "skill_cases_bats_fail_closed_skip_live",
  "why": "Hermes is unsupported and Hermes-invoking automation is stopped (S1-T1 / S1-T1b). Spec §10 N=5 live eval cannot run. Path 2 as the oracle either tautologically recounts human labels or invents a keyword scorer that is not the live assessor and is outside files_allowed. Path 3 matches plan files, encodes the persist/family/STAR contract so S1-GE has testable artifacts, and preserves live N=5 as skip-now / un-skip-after-install instead of claiming tolerance eval passed.",
  "what_can_be_proven_without_binary": [
    "SKILL.md states the §10 family element lists, persist iff >=2 missing, one-missing does not persist, mixed-family forbidden, technical never STAR, output names family + missing_elements + quote/byte_offset evidence, propose-only (no MEMORY.md write)",
    "assessment-cases.md has strong/weak (and one-missing) fixtures per family including q_behavioral_01 bad answer (action+result missing -> persist)",
    "Fixture labels are internally consistent: expected_persist iff missing_elements count >= 2; missing_elements subset of that family's required set; technical cases never list STAR names",
    "bats never exec hermes, source isolation env, never write operator ~/.hermes",
    "Live N=5 block skips with an explicit reason when Hermes is undiscoverable; CROSSFIRE_LIVE_ASSESSMENT=1 without Hermes fails closed (nonzero, not skip, not pass)"
  ],
  "what_cannot_be_proven_without_binary": [
    "An assessor selects the correct family from free-text",
    "An assessor detects missing elements in free-text (N=5, pass if >=4 persist-decision matches)",
    "Flakiness of a live model (spec: flag, do not hard-fail a single off-run)",
    "Live demo gate K=3 persist of the scripted bad answer (Task 5 / spec §10 live demo gate, out of S1-T3 scope)"
  ],
  "tests_must_encode": {
    "static_must_pass_now": [
      "SKILL.md contains family required elements: behavioral=situation,task,action,result; technical=problem,approach,tradeoff,verification; product=user,constraint,decision,metric",
      "SKILL.md states persist automatically when >=2 required elements of that family are missing; one missing element does not persist; no operator confirmation",
      "SKILL.md states exactly one family per question; mixed-family scoring forbidden",
      "SKILL.md states a technical answer is never scored with STAR (never apply situation/task/action/result to technical)",
      "SKILL.md states assessment output names family, missing_elements, and evidence (quote substring or byte_offset start:end of the submitted answer)",
      "SKILL.md states propose-only: stdout or run-scoped spool; do not write MEMORY.md or candidate staging (S1-T3 scope; spec §8)",
      "assessment-cases.md: at least one strong and one weak (>=2 missing) case per family; plus at least one one-missing case per family (expected_persist=false)",
      "Include spec §11 q_behavioral_01 bad answer: omits action and result (example quote 'I just kind of watched the dashboard.'); expected_persist=true; family=behavioral",
      "Each case fields: id, family, question_id, answer, missing_elements[], expected_persist, evidence_kind, evidence_value (substring of answer or start:end)",
      "Deterministic label-consistency checks (NOT the §10 N=5 oracle): expected_persist == (count(missing_elements) >= 2); missing_elements subset of family required set; no STAR names on technical cases; no technical names on behavioral cases; no mixed-family missing_elements",
      "Isolation: source scripts/demo_common.sh; HERMES_HOME under .crossfire/profiles/; do not exec hermes; do not mkdir/write REAL_HERMES_WIN or REAL_HERMES_WSL"
    ],
    "live_n5_skip_or_fail_closed": [
      "Default when HERMES_BIN empty or CROSSFIRE_HERMES_DISCOVERY=0: skip live eval tests with reason that Hermes is unsupported; static tests still run",
      "If CROSSFIRE_LIVE_ASSESSMENT=1 (or equivalent force flag) and Hermes undiscoverable: fail closed nonzero — do not skip, do not pass",
      "Never treat skip as proof that N=5 >=4 persist-decision match passed",
      "Future un-skip (post-install, not this task): each case N=5; pass if >=4 runs match expected persist decision; flag 4/5 flakiness; do not hard-fail a single off-run; still propose-only (no MEMORY.md write); isolated HERMES_HOME only"
    ],
    "must_not_encode": [
      "A keyword/regex free-text scorer as a stand-in for the live assessor",
      "A new scripts/ assessment engine (S1-T3 files_allowed is SKILL.md, assessment-cases.md, assessment_eval.bats only)",
      "Calling crossfire_persist_weakness / writing MEMORY.md (that is S1-T2; T3 proposes assessments)",
      "Live demo K=3 session-one persist gate (S2-T5)",
      "Installing Hermes or touching ~/.hermes"
    ]
  },
  "files_allowed": [
    "skills/crossfire-interviewer/SKILL.md",
    "tests/fixtures/assessment-cases.md",
    "tests/assessment_eval.bats"
  ],
  "open_questions": [
    "After approval-first Hermes install, un-skip live N=5 under throwaway HERMES_HOME; do not claim S1-T3 live eval passed before that.",
    "S1-GE Test-Path of assessment_eval.bats must not be narrated as spec §10 tolerance eval passed."
  ]
}
```

## Opportunity cost

| Path | Pick? | Why | Opportunity cost |
| --- | --- | --- | --- |
| **1. Live Hermes fixture eval (N=5)** | Reject | Binary **unsupported** (`docs/hermes-compatibility.md` inventory #1; Windows PATH + WSL `fish` have no `hermes`). Hermes-invoking automation **stopped** until install + throwaway `HERMES_HOME` probe (`docs/hermes-compatibility.md` Task 1b). This task forbids install and `~/.hermes` mutation. Spec §10 eval *is* a live assessor loop: each case N=5, pass if ≥4 persist-decision matches. | S1-T3 and S1-GE stall for a binary that is out of scope. Burns the 4-hour window. Violates S1-T1b: “Do not spawn `hermes` for scoring.” |
| **2. Deterministic harness checklist as the test oracle** | Reject as *the oracle* | Two implementations, both bad as a spec substitute. (a) Count human `missing_elements` and assert `persist iff n≥2`: tautological label hygiene, not assessment. (b) Keyword-score free-text: a second scorer that will drift from the live skill; STAR/technical keyword matching is a known false friend; extra `scripts/` engine is **not** in `files_allowed`. Spec §10 explicitly uses N=5 / ≥4 because the assessor is non-deterministic; a checklist cannot flake, so it cannot *be* that eval. S1-T2 already encodes family element lists in `scripts/weakness_memory.sh` (`crossfire_weakness_family_elements`); duplicating a scorer in T3 spends budget on the wrong layer. | Looks like “fixture suite produces persist decisions” while never running an assessor. S1-GE and later S2-T5 would inherit a fake green. SKILL.md could rot relative to a bats-only oracle. |
| **3. SKILL.md + cases + bats; fail-closed/skip live** | **Choose** | Plan files (`docs/…-plan.md` Task 3) and queue `files_allowed` are exactly these three. S1-T1b already allowed T3 “if fixture/static eval of SKILL.md” and forbade spawning Hermes. Static tests prove the contract the live agent must follow; label-consistency checks (path 2’s *hygiene*, not its oracle claim) live inside `assessment_eval.bats`. Live N=5 remains a skip with a reason, or fail-closed if forced — same fail-closed culture as `tests/preflight.bats` (“fails closed when Hermes is missing”) without pretending skip ≡ pass. | Live family/missing-element/persist reliability is **unproven**. Queue AC “fixture suite reliably (within tolerance) produces expected decisions” is **not met as spec §10 eval**. Implementer/verifier must not claim N=5 ≥4. S2-T5 still blocked on install for the demo persist gate. |

**Steal from path 2, do not become path 2:** bats MAY assert fixture-label consistency (`expected_persist` ↔ `count(missing_elements)≥2`, family allow-list, no STAR on technical). That is contract encoding, not the spec oracle. Do not name those checks “N=5 eval.”

## Spec / prior evidence (verified)

| Claim | Evidence |
| --- | --- |
| Persist when ≥2 family elements missing; one missing does not; no confirm | `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md:175` |
| Families + required elements; technical not STAR; mixed-family forbidden | spec.md:173–181 |
| Output names family, missing elements, quote or byte-offset evidence | spec.md:183; evidence kinds spec.md:149–150 |
| Fixture eval N=5, pass if ≥4 persist-decision match; flag flakiness | spec.md:185 |
| Live demo K=3 is session-one persist, not this task | spec.md:187; plan Task 5; queue S2-T5 |
| Demo bad answer: `q_behavioral_01` omits `action` and `result` | spec.md:196 |
| Hermes proposes assessments; harness writes MEMORY.md | spec.md:90–92, 100–106 |
| Plan files for Task 3 | `docs/…-plan.md:51` — `SKILL.md`, `assessment-cases.md`, `assessment_eval.bats` |
| Hermes binary unsupported; invoking automation stopped | `docs/hermes-compatibility.md:77`, `:135`, `:143` |
| S1-T3 may proceed without spawning Hermes | `.workflow/S1-T1b/results/researcher-result.md:78` |
| Family element lists already in merge harness (do not reimplement persist) | `scripts/weakness_memory.sh:45–51` |
| S1-T3 `files_allowed` | `.workflow/autopilot-queue.json` S1-T3 item |
| S1-GE only existence-checks `assessment_eval.bats` | queue S1-GE `verification.commands` |

## What T3 can prove without a binary

| Can prove now | How |
| --- | --- |
| Interviewer skill states the same §10 contract the fixtures expect | Grep/assert `SKILL.md` |
| Strong / weak / one-missing fixtures exist per family; demo bad answer labeled persist | Parse `assessment-cases.md` |
| Labels are consistent with the persist rule and family element sets | Deterministic checks in bats (hygiene, not live scoring) |
| Technical fixtures are not annotated with STAR element names | Same |
| Tests do not invoke Hermes or touch operator `~/.hermes` | Source `demo_common.sh`; no `hermes` exec; absence snapshot optional |
| Live eval is not a silent pass | `skip` with reason, or fail-closed when forced |

| Cannot prove without a binary | Why |
| --- | --- |
| Correct family selected from an answer | Requires the live skill + model |
| Persist decision on free-text, N=5 ≥4 | Spec §10 fixture eval |
| Flakiness vs a single off-run | No stochastic assessor |
| K=3 demo persist into MEMORY.md | S2-T5; also writes durable state |

**Done-when mapping for this machine:** Task 3 “fixture suite reliably (within tolerance) produces expected family/missing-element/persist decisions” = **contract + labeled fixtures + skip/fail-closed live hook encoded**. It does **not** mean spec §10 N=5 ran. Do not relabel live eval **passed**.

## Implementer notes (read-only research)

- Allowed writes: `skills/crossfire-interviewer/SKILL.md`, `tests/fixtures/assessment-cases.md`, `tests/assessment_eval.bats` only. `skills/` does not exist yet.
- TDD: bats and fixtures first; SKILL.md must state the same rules the tests grep.
- Do not source `weakness_memory.sh` to persist; T3 proposes assessments. Reuse of family-element *names* in bats is fine if copied as literals matching spec §10 / SKILL.md — do not add a fourth file.
- Isolation: source `scripts/demo_common.sh` before any path use; default `HERMES_HOME` is repo `.crossfire/profiles/test`.
- Live hook: follow preflight’s fail-closed culture (`tests/preflight.bats:9-12`) for *forced* live eval; use bats `skip` only for the default-no-binary live block.
- S1-GE will see the bats file exist. Narrative must keep live scoring **unsupported**.

## Dead ends

1. Installing Hermes or probing a real/throwaway profile from this task — forbidden.
2. Keyword STAR detector as “N=5.”
3. Calling `crossfire_persist_weakness` from assessment tests (wrong layer; would write MEMORY.md).
4. Treating S1-GE `Test-Path tests\assessment_eval.bats` as tolerance-eval evidence.
5. Implementing S2-T5 K=3 demo persist here.

## Open questions

1. Approval-first Hermes install on WSL, then un-skip live N=5 under throwaway `HERMES_HOME` only.
2. Whether S1-GE notes should explicitly record “live assessment eval skipped (Hermes unsupported)” so the phase exit does not inflate the claim.
