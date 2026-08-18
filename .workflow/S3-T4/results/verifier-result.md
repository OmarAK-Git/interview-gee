# S3-T4 skeptic-verifier result

**Verdict: pass**

Task-scoped. Treated implementation and review claims as unevidenced. Did not use `implementer-result.md` or `code-reviewer-result.md` as proof. Did not mark the queue done. Did not commit. Did not install packages (including `bats`). Did not write real `~/.hermes`.

---

## Claim restated

S3-T4 is done: a statically validated broader question bank exists at `skills/crossfire-interviewer/questions.md` with tests at `tests/question_bank.bats`; static tests pass; the three never-cut demo questions remain complete within the session-one set; questions invent no employer facts beyond spec §4.

Vague parts of the claim: “measured session-one budget” (no wall-clock command in this packet). Held only if session-one still asks exactly the three spec §11 questions and the extra bank cannot displace them.

---

## 1. Existence (Test-Path)

Cwd: `C:\Users\oalan\interview-gee`

```
Test-Path -LiteralPath skills\crossfire-interviewer\questions.md -PathType Leaf
True
Test-Path -LiteralPath tests\question_bank.bats -PathType Leaf
True
```

`Test-Path` `%USERPROFILE%\.hermes` → `False` (before bash-equivalent; no product write in this run).

Existence alone is not a pass.

---

## 2. Bash-equivalent (bats missing)

`Get-Command bats` empty. Did not install bats.

Command (fresh this run, Git Bash):

```
"C:\Program Files\Git\bin\bash.exe" .workflow/S3-T4/bash-assertions.sh
```

Output:

```
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
EXIT:0
```

`tests/question_bank.bats` has 13 `@test` blocks; bash-equivalent names map 1:1. `demo_ids_verbatim` is vacuous on the current bank (demo IDs omitted, which spec §11 allows). Coverage for never-cut demo text is `demo_question_entry`, `demo_answers_fixture`, and `skill_demo_authoritative`, independently re-checked in §4 below.

Negative control is not a FAANG denylist: `source_binding_negative` uses the three known §4 inventions (plant ops on McCain; ALTER_EGO-at-McCain; advisory-only on Mastercard). `source_binding` walks live rows. Both passed together, so the helper is not stuck-open or stuck-closed.

---

## 3. Independent spec §4 / §11 read (not the helper)

Spec `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md`:

- §4 allowlist: McCain Foods / Cyber Defense Engineer / late-stage rounds; Mastercard / Agent Suite PM role / R-281517; Project Praetor / LangGraph SOAR disposition engine / advisory-only / hash-chained audit ledger / never-contain list; Project ALTER_EGO / UEBA behavioral drift / cumulative KL-divergence / shadow profiles / freeze-under-suspicion.
- §3 / §4: do not invent employer facts beyond that list.
- §11: three demo questions live in session-one fixtures, not the cuttable bank; broader coverage may live in `questions.md`.

Read `skills/crossfire-interviewer/questions.md` lines 9–14 against the matching §4 bullet only.

| ID | Source | Employer/project tokens | §4 bullet | Invented employer fact? |
| --- | --- | --- | --- | --- |
| `q_behavioral_mccain_01` | McCain Foods | McCain Foods; Cyber Defense Engineer; late-stage rounds | McCain Foods. Cyber Defense Engineer. Late-stage rounds. | No. STAR ask is interview method. No plant ops. |
| `q_behavioral_alterego_01` | Project ALTER_EGO | ALTER_EGO; UEBA; shadow-profile drift; freeze-under-suspicion | ALTER_EGO. UEBA behavioral drift. Shadow profiles. Freeze-under-suspicion. | No. No McCain employment/deployment claim. |
| `q_technical_praetor_02` | Project Praetor | never-contain list; hash-chained audit ledger; advisory-only; disposition | Praetor. Advisory-only output, hash-chained audit ledger, never-contain list. | No. `advisory-only` only on this Praetor row. |
| `q_technical_alterego_01` | Project ALTER_EGO | cumulative KL-divergence; shadow profiles; behavioral drift; freeze-under-suspicion | ALTER_EGO. Cumulative KL-divergence, shadow profiles, freeze-under-suspicion. | No. Sensitivity/analyst-load is a family tradeoff ask, not an asserted employer fact. |
| `q_product_mastercard_02` | Mastercard R-281517 | Mastercard Agent Suite (R-281517); false positive could freeze a merchant | Mastercard. Agent Suite PM role, R-281517. Merchant false-freeze is spec §11 `q_product_01`, not a new employer. | No. No Praetor `advisory-only` leakage. |
| `q_product_mastercard_03` | Mastercard Agent Suite | Agent Suite; Mastercard (R-281517); canary vs GA as a sequencing ask; false-positive constraint | Same Mastercard bullet. Canary/GA is a hypothetical product prompt (“how would you sequence”), not an asserted Mastercard tenancy fact. | No. |

Independent greps on `questions.md`: `plant` absent; `google` / `acme` / `faang` absent; `advisory-only` count = 1 (Praetor row only); demo IDs `q_technical_01` / `q_behavioral_01` / `q_product_01` absent from the cuttable bank (allowed).

Stable IDs: six unique `q_[a-z0-9_]+`. Families present: `behavioral`, `technical`, `product`. Sources present: McCain Foods, Mastercard (R-281517 / Agent Suite), Project Praetor, Project ALTER_EGO.

---

## 4. Session-one completeness (budget AC)

Packet/plan AC: “Three demo questions remain complete within the measured session-one budget.”

No wall-clock command in this packet; Task 10 owns the timed ~90s demo. This task can still break the AC by cutting, rewriting, or injecting extra bank questions into session one.

Independent string compare vs spec §11:

| Location | Result |
| --- | --- |
| `skills/crossfire-interviewer/SKILL.md:86-88` | spec §11 texts present verbatim |
| `scripts/demo_common.sh:263-265` `crossfire_demo_question_entry` | spec §11 strings present verbatim |
| `tests/fixtures/demo-answers.txt` | `# q_technical_01`, `# q_behavioral_01`, `# q_product_01` present |
| `scripts/demo_session_1.sh` | `for i in 0 1 2` only; `questions.md` not referenced |
| `skills/crossfire-interviewer/SKILL.md` | `questions.md` not referenced |
| `scripts/` | no `questions.md` references |

Session one still asks exactly the three never-cut questions. The extra bank cannot lengthen or replace that set. Budget AC held as completeness, not as a fresh 90s timing.

---

## AC mapping

| AC | Status | Evidence |
| --- | --- | --- |
| Static tests pass | **held** | `Test-Path` both True; bash-equivalent `passed=13 failed=0 EXIT:0`; bats absent and not installed |
| Three demo questions remain complete within the measured session-one budget | **held** | spec §11 strings verbatim in `SKILL.md:86-88` and `demo_common.sh:263-265`; fixture IDs present; session-one loop still `0 1 2`; extra bank not wired into harness or skill |
| No invented employer facts | **held** | independent line-by-line §4 read of `questions.md:9-14`; prior inventions (plant ops, ALTER_EGO-at-McCain, advisory-only on Mastercard) absent; `source_binding` + `source_binding_negative` both PASS |

---

## Residuals (non-blocking)

- `question_bank_source_binding_ok` is still a keyword bind/deny, not a complete §3 invention scanner (third-party employers; some hyphen/token spellings). Current bank rows do not hit those gaps.
- `demo_ids_verbatim` is a no-op while the bank omits demo IDs (spec-allowed). Fixture tests cover the never-cut texts.
- `tests/question_bank.bats:3` comment still says “spec §11 bank”; the file is the cuttable extra bank.
- No live session-one wall-clock was collected (out of this packet’s commands).

---

## Isolation

Windows `%USERPROFILE%\.hermes` absent. Bash-equivalent is grep/parse only against repo files; it sources `scripts/demo_common.sh` then `set +e`. No `HERMES_HOME` write in this run.

---

## Verdict JSON

```json
{
  "packet_id": "04-verify",
  "status": "done",
  "verdict": "pass",
  "retry_required": false,
  "acs": {
    "static_tests_pass": "held",
    "demo_questions_complete_in_session_one": "held",
    "no_invented_employer_facts": "held"
  },
  "evidence_path": ".workflow/S3-T4/results/verifier-result.md",
  "commands": {
    "test_path_questions_md": true,
    "test_path_question_bank_bats": true,
    "bash_assertions": "passed=13 failed=0 EXIT:0",
    "bats": "absent_not_installed"
  },
  "isolation": "pass_real_hermes_absent",
  "queue": "not_marked_done",
  "commit": "not_made"
}
```
