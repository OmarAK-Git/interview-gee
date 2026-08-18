# S3-T4 code review (retry)

**Packet:** `03-review` (re-review after `blocking_retry`)
**Reviewer:** code-reviewer (did not author the fix; did not implement, commit, or mark the queue done)
**Date:** 2026-08-18
**Prior:** `.workflow/S3-T4/results/code-reviewer-result.md` (`blocking_retry`, Critical 1 + Important 1)
**Scope:** Independent re-read of `skills/crossfire-interviewer/questions.md` against spec §4; `tests/question_bank.bats`; `.workflow/S3-T4/bash-assertions.sh` as test evidence. Spec `sparring-1.0.0` §3, §4, §11; plan Task 4; packet `02-implementation.md`.
**Blocking list (unchanged):** invented employer facts; missing family/ID; three demo questions cut/changed in session-one fixtures.

**Verdict:** `approve`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 0 |
| Minor | 1 |
| Blocking | 0 |

**Retry:** no

---

## Prior findings

### Critical 1 — Invented employer facts beyond spec §4 — **ADDRESSED**

**Was:** three bank rows invented facts outside the matching §4 bullet: McCain “plant operations”; ALTER_EGO “at McCain Foods”; Praetor “advisory-only” applied to Mastercard Agent Suite.

**Now:** those three rows are rewritten. Independent §4 audit of every current bank question (allow only the matching bullet, plus §11 merchant false-freeze on Mastercard product as previously ruled):

| ID | Source | Employer/project tokens in the question | §4 (and allowed §11) | Invented? |
| --- | --- | --- | --- | --- |
| `q_behavioral_mccain_01` `:9` | McCain Foods | McCain Foods; Cyber Defense Engineer; late-stage rounds; STAR prompt | McCain Foods. Cyber Defense Engineer. Late-stage rounds. | No. Plant ops gone. |
| `q_behavioral_alterego_01` `:10` | Project ALTER_EGO | ALTER_EGO; UEBA; shadow-profile drift; freeze-under-suspicion; STAR prompt | ALTER_EGO. UEBA behavioral drift. Shadow profiles. Freeze-under-suspicion. | No. No McCain employment/deployment claim. |
| `q_technical_praetor_02` `:11` | Project Praetor | never-contain list; hash-chained audit ledger; advisory-only; technical prompt | Praetor. Advisory-only output, hash-chained audit ledger, never-contain list. | No. Unchanged and still inside the Praetor bullet. |
| `q_technical_alterego_01` `:12` | Project ALTER_EGO | cumulative KL-divergence; shadow profiles; behavioral drift; freeze-under-suspicion; hypothetical sensitivity/analyst-load tradeoff | ALTER_EGO. Cumulative KL-divergence, shadow profiles, freeze-under-suspicion. | No. Tradeoff is the family ask, not an asserted employer fact. |
| `q_product_mastercard_02` `:13` | Mastercard R-281517 | Mastercard Agent Suite (R-281517); false positive could freeze a merchant; product prompt | Mastercard. Agent Suite PM role, R-281517. Merchant false-freeze from §11 `q_product_01`. | No. “advisory-only” gone. |
| `q_product_mastercard_03` `:14` | Mastercard Agent Suite | Agent Suite; Mastercard (R-281517); hypothetical canary vs GA; false-positive constraint | Same Mastercard bullet + §11 false-freeze. Canary/GA remains hypothetical (prior pass, text unchanged). | No. |

Grep: `plant ops` / `plant operations` / `at McCain Foods` / `advisory-only automations` absent from `questions.md`. `advisory-only` remains only on the Praetor row. `McCain` appears only in the header allowlist and `q_behavioral_mccain_01`.

Missing family/ID: still not a defect. Six unique `q_[a-z0-9_]+` IDs; families are `behavioral` \| `technical` \| `product`.

---

### Important 1 — Invented-fact tests cannot fail — **ADDRESSED**

**Was:** `no_invented_employers` was a FAANG/Acme denylist. `bash .workflow/S3-T4/bash-assertions.sh` reported `passed=10 failed=0` **with** the three invented §4 facts still in `questions.md`. Source-column allowlist did not inspect question text.

**Now:**

- FAANG denylist replaced by `question_bank_source_binding_ok` (`tests/question_bank.bats:33-67`, mirrored `.workflow/S3-T4/bash-assertions.sh:37-70`): each row’s question text must contain a token from the Source’s §4 bullet **and** must not contain the named cross-bullet inventions (plant ops; ALTER_EGO/Praetor/Mastercard leakage including `advisory-only` on Mastercard and `McCain` on ALTER_EGO).
- Positive check walks live bank rows (`question_bank.bats:120-125`, bash-assertions `:128-133` `source_binding`).
- Negative control uses the three prior Critical 1 strings (`question_bank.bats:127-134`, bash-assertions `:135-143` `source_binding_negative`). If the helper always returned 0, this test fails; if it always returned 1, `source_binding` fails on the current bank. Both passed together.

Independent run (Git Bash, no bats install, no `~/.hermes` write):

```text
$ "C:\Program Files\Git\bin\bash.exe" .workflow/S3-T4/bash-assertions.sh
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

A FAANG denylist is no longer the AC. The helper encodes the §4 bind + the three named cross-bullet inventions.

---

### Minor 1 — Demo-question guard does not inspect session-one fixtures — **ADDRESSED** (track residual vacuity)

**Was:** `demo_ids_verbatim` no-op when bank omits demo IDs; skill grep did not inspect `crossfire_demo_question_entry` / `demo-answers.txt`.

**Now:** non-vacuous fixture checks:

- `tests/question_bank.bats:152-156` / bash-assertions `:161-166` — `crossfire_demo_question_entry` 0/1/2 equal spec §11 strings.
- `tests/question_bank.bats:158-165` / bash-assertions `:168-176` — `# q_technical_01` / `# q_behavioral_01` / `# q_product_01` in `tests/fixtures/demo-answers.txt`; spec substrings in `scripts/demo_common.sh`.

Independent fixture read: `scripts/demo_common.sh:263-265` and `skills/crossfire-interviewer/SKILL.md:86-88` still match spec §11 verbatim. `questions.md` still omits demo IDs (allowed). `demo_ids_verbatim` itself remains a no-op; coverage now lives in the new tests.

---

## New Critical / Important in the fix

None. New blocking count: **0**.

---

## Minor 2 — Binding denylist is still keyword-incomplete — **track**

`question_bank_source_binding_ok` catches the three named inventions but is not a complete §3 “no invented employer facts” scanner. Residual gaps (current `questions.md` does not hit them):

- Third-party employers (Google, Acme, …) are no longer denied; a McCain row that also names Google would still bind.
- Token spelling: McCain deny lists `shadow profile` (space) not `shadow-profile`; McCain deny does not include the word `Mastercard` (only Agent Suite / R-281517).

Not blocking: live bank rows pass the independent §4 read; the Important 1 AC examples fail as required.

---

## Spec / plan / packet checks

| Requirement | Result |
| --- | --- |
| Broader bank in `questions.md`; demo questions stay in session-one fixtures (§11) | Met. Six extra rows; header says never-cut; demo IDs omitted (allowed). |
| Covers McCain / Mastercard / Praetor / ALTER_EGO and all three families | Met. |
| Every question has stable ID + declared family | Met. Unique IDs; families in `{behavioral,technical,product}`. |
| No invented employer facts (§3 / §4) | Met for current bank (Critical 1 ADDRESSED). |
| Demo questions never cut in session-one fixtures | Met. Independent string compare vs spec §11; new fixture tests. |
| Files allowed | Met. Product writes: `questions.md` + `question_bank.bats`. `demo_common.sh` / `SKILL.md` working-tree diffs are prior sprint work; §11 question texts unchanged. |
| Static tests exist | Met. Bats not installed; bash-equivalent `passed=13 failed=0`. |

---

## Isolation

No product write under real `~/.hermes`. Windows `%USERPROFILE%\.hermes` **absent**. Review ran Git Bash reads + assertions only. Did not install bats. Did not mutate git state or the queue.

---

## Checks run

- Independent line-by-line read of `questions.md` against spec §4 (and §11 merchant false-freeze for Mastercard product).
- Re-read prior Critical 1 / Important 1 text and packet `02-implementation.md`.
- Grep for plant ops, ALTER_EGO-at-McCain, advisory-only-on-Mastercard.
- Independent spec §11 compare vs `demo_common.sh:263-265` and `SKILL.md:86-88`; IDs in `tests/fixtures/demo-answers.txt`.
- `bash .workflow/S3-T4/bash-assertions.sh` → `passed=13 failed=0` (Git Bash).

```json
{
  "packet_id": "03-review",
  "status": "done",
  "verdict": "approve",
  "retry_required": false,
  "findings": {
    "critical": 0,
    "important": 0,
    "minor": 1
  },
  "blocking_count": 0,
  "prior": {
    "Critical 1": "ADDRESSED",
    "Important 1": "ADDRESSED",
    "Minor 1": "ADDRESSED"
  },
  "isolation": "pass_real_hermes",
  "blocking": "none",
  "items": [
    {
      "priority": "Minor",
      "file": "tests/question_bank.bats:33",
      "issue": "Source-binding denylist still keyword-incomplete (third-party employers; some hyphen/token spellings).",
      "fix": "Optionally extend deny tokens; not required for this packet once §4 bind + named inventions fail."
    }
  ]
}
```
