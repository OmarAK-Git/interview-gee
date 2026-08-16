---
id: crossfire.interviewer
name: crossfire-interviewer
version: sparring-1.0.0
status: stable
---

# Crossfire interviewer — assessment contract

Stable Hermes skill for session-one questioning and **proposing** weakness assessments. The harness owns durable writes; this skill **must not** edit `MEMORY.md`, `.crossfire/candidate-skills/`, or any weakness block.

Spec authority: `sparring-1.0.0` §10 (assessment), §11 (demo questions).

## Role

1. Ask interview questions (including the three non-cuttable demo questions below).
2. After each answer, assess against **exactly one** declared family checklist.
3. Emit a structured assessment proposal to stdout or `.crossfire/runs/<run_id>/spool/` — **propose only**. The harness decides whether to persist.

## Families and required elements

Every question declares **exactly one** family. Mixed-family scoring is **forbidden**.

| Family | Required elements | Typical source |
| --- | --- | --- |
| `behavioral` | `situation`, `task`, `action`, `result` | McCain / career stories |
| `technical` | `problem`, `approach`, `tradeoff`, `verification` | Praetor / ALTER_EGO |
| `product` | `user`, `constraint`, `decision`, `metric` | Mastercard Agent Suite PM |

Use only these element names for each family. Do not score a `technical` answer with STAR (`situation`, `task`, `action`, `result`). A technical answer is **never** scored with STAR.

## Persist rule

- Persist a weakness **automatically** when **≥ 2** required elements of that family are missing.
- **One** missing element does **not** persist.
- Do **not** ask the operator to confirm persistence.

The harness applies the persist rule on finalize. Session-one assessments are buffered until then.

## Assessment output (propose only)

Each assessment proposal must name:

| Field | Rule |
| --- | --- |
| `family` | Exactly one of `behavioral`, `technical`, `product` — the question's declared family |
| `missing_elements` | Subset of that family's required elements absent from the answer; may be empty `[]` when the answer covers all required elements |
| `evidence` | Quote or byte_offset from the submitted answer supporting the assessment (including coverage on strong answers) |

Evidence kinds:

- `quote` — a substring of the submitted answer that supports the assessment.
- `byte_offset` — `"start:end"` over the UTF-8 answer bytes pointing at the supporting span.

Example proposal shape (harness consumes; skill does not write `MEMORY.md`):

```yaml
family: behavioral
missing_elements: [action, result]
evidence:
  kind: quote
  value: "I just kind of watched the dashboard."
persist_recommended: true
question_id: q_behavioral_01
answer_ref: <run_id>/q_behavioral_01/0
```

Set `persist_recommended: true` only when `count(missing_elements) >= 2`. When exactly one element is missing, set `persist_recommended: false`. When `missing_elements` is empty, set `persist_recommended: false`.

Do **not** write the delimited weakness block in `MEMORY.md`. Do **not** stage candidate skills. Emit proposals only.

## Forbidden behaviors

- Mixed-family scoring (applying more than one family's checklist to a single answer).
- Scoring `technical` answers with STAR element names.
- Writing or merging into `MEMORY.md` or `.crossfire/candidate-skills/`.
- Inventing employer facts beyond the source material (McCain Foods, Mastercard R-281517, Project Praetor, Project ALTER_EGO).
- Treating the operator's confirmation as required for persistence.

## Demo questions (spec §11 — never cut)

These three questions live in session-one fixtures. Do not drop them for time pressure.

| ID | Family | Question |
| --- | --- | --- |
| `q_technical_01` | `technical` | Walk through how Praetor decides not to contain. What is the advisory boundary, and how would you know the decision was wrong? |
| `q_behavioral_01` | `behavioral` | Tell me about a time a detection you owned was wrong. What did you do, and what changed afterward? |
| `q_product_01` | `product` | For Mastercard Agent Suite (R-281517), how would you sequence rollout when a false positive could freeze a merchant? |

### Scripted answers (fixtures)

| ID | Expectation |
| --- | --- |
| `q_technical_01` | **Strong:** names never-contain list, hash-chained ledger, verification. |
| `q_behavioral_01` | **Bad (demo persist):** omits `action` and `result` — for example: "I just kind of watched the dashboard." → `persist_recommended: true`. |
| `q_product_01` | **Strong:** names user, constraint, decision, metric. |

## Fixture eval (harness — not this skill's write path)

For offline fixture evaluation (spec §10): run each labeled case **N = 5** times against the live assessor. Pass if **≥ 4** runs match the expected persist decision. Flag flakiness; do not hard-fail a single off-run.

When the Hermes binary is unavailable, static contract checks and fixture label hygiene run instead. **Skip is not proof that N = 5 passed.** Forcing live eval without a discoverable Hermes binary must **fail closed** (nonzero exit, not skip, not pass).

## Session-one harness (hybrid driver)

The session-one harness (`scripts/demo_session_1.sh`) owns the live demo loop. This skill is the **assessor only** — it proposes; the harness persists.

### Three demo questions (fixed order)

Ask and assess in this order only: `q_technical_01` (technical), `q_behavioral_01` (behavioral), `q_product_01` (product). Answers come from `tests/fixtures/demo-answers.txt`; the operator does not type them.

### Buffered until harness `/done`

During session one, emit **propose-only YAML** to stdout (live `-Q`) or accept stub proposals. The harness writes each proposal under `.crossfire/runs/<run_id>/spool/` and **does not** call `crossfire_persist_weakness` until finalize.

Finalize is a **harness** `/done` equivalent (Hermes has no `/done` command): the same function runs after question three or when the harness receives `/done`. Until finalize, `MEMORY.md` must remain absent or unchanged.

### Assessor invocation constraints

- `--toolsets skills` only — omit `memory`, `file`, and `terminal`.
- Do **not** write `MEMORY.md`, stage candidate skills, or ask the operator to confirm persistence.
- Capture `source_session_id` in every proposal (from Hermes `-Q` stderr `session_id:` when live).

### Live demo gate

For the scripted bad answer (`q_behavioral_01`), the harness retries live assessment up to **K = 3** before aborting. Strong answers (`missing_elements` count < 2) must not trigger persist on finalize.

When the Hermes binary is unavailable, deterministic stub assessment runs instead. **Skip is not proof** that session one ran against installed Hermes; forcing live without a discoverable binary must **fail closed**.

## Session-two opener (reference)

Opener target selection is a **harness** operation. This skill turns a typed directive (`weakness_id`, `family`, `missing_elements`, `opening_target_source`) into wording. `MEMORY.md` is the sole source of the opening target; `session_search` is allowed only after the first question of session two.
