# S3-T4 Implementer Result

## Status

**Complete** — static question bank and validation tests implemented; bash-equivalent `passed=10 failed=0`. Bats not installed in environment; `tests/question_bank.bats` mirrors `.workflow/S3-T4/bash-assertions.sh`.

## Files touched

| File | Rationale |
| --- | --- |
| `skills/crossfire-interviewer/questions.md` | Cuttable bank: six extra questions covering McCain Foods, Mastercard R-281517, Project Praetor, Project ALTER_EGO across behavioral, technical, and product families |
| `tests/question_bank.bats` | TDD static validation: ID/family contract, three families, four sources, source allowlist, no invented employers, demo-id verbatim guard, SKILL.md demo authority |
| `.workflow/S3-T4/bash-assertions.sh` | Bash-equivalent runner (no bats install) |

## Verification

```text
$ bash .workflow/S3-T4/bash-assertions.sh
PASS: questions_md_exists
PASS: bank_header_allowlist
PASS: has_rows
PASS: id_family_unique
PASS: three_families
PASS: four_sources
PASS: source_allowlist
PASS: no_invented_employers
PASS: demo_ids_verbatim
PASS: skill_demo_authoritative
passed=10 failed=0
```

TDD order: wrote `tests/question_bank.bats` first (failed on missing `questions.md`), then implemented `questions.md`, fixed header to reference §11 demo questions without backticked demo IDs (avoids false verbatim trigger while omitting duplicates per packet).

## Unresolved

None. Demo questions unchanged in session-one fixtures / `SKILL.md`. Queue not marked done; no commit.

---

## Retry (code-review blocking_retry)

Addressed Critical 1, Important 1, Minor 1 from `code-reviewer-result.md`.

| File | Change |
| --- | --- |
| `skills/crossfire-interviewer/questions.md` | Rewrote `q_behavioral_mccain_01`, `q_behavioral_alterego_01`, `q_product_mastercard_02` to use only spec §4 facts (no plant ops, no ALTER_EGO-at-McCain, no advisory-only on Mastercard) |
| `tests/question_bank.bats` | Replaced FAANG denylist with `question_bank_source_binding_ok` (§4 bullet bind + cross-bullet deny); added §11 fixture checks for `crossfire_demo_question_entry` and `demo-answers.txt` |
| `.workflow/S3-T4/bash-assertions.sh` | Mirrored binding tests + fixture guards; `set +e` after sourcing `demo_common.sh`; explicit `return 0` after deny-if blocks |

### Verification (retry)

```text
$ bash .workflow/S3-T4/bash-assertions.sh
PASS: questions_md_exists
PASS: bank_header_allowlist
PASS: has_rows
PASS: id_family_unique
PASS: three_families
PASS: four_sources
PASS: source_allowlist
PASS: source_binding
PASS: source_binding_negative
PASS: demo_ids_verbatim
PASS: demo_question_entry
PASS: demo_answers_fixture
PASS: skill_demo_authoritative
passed=13 failed=0
```

Negative control: `source_binding_negative` confirms plant-ops / ALTER_EGO-at-McCain / advisory-only-on-Mastercard strings fail binding.
