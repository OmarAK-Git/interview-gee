# Packet 02-implementation: Question bank

Researcher skipped: spec §11 demo questions already exist in session-one fixtures; this task is static extra coverage. No close path fork. Do not invent employer facts (McCain Foods, Mastercard R-281517, Project Praetor, Project ALTER_EGO only). Do not change the three demo questions.

## Files allowed

- `skills/crossfire-interviewer/questions.md`
- `tests/question_bank.bats`

Plus `.workflow/S3-T4/results/implementer-result.md` and optional bash-assertions.sh. Do not commit. Do not edit demo_session_1.sh or SKILL.md unless... SKILL.md is NOT in files_allowed. Stay strictly in the two files.

## Do (TDD)

Static validation tests:
- Covers McCain / Mastercard / Praetor / ALTER_EGO
- All three families (behavioral, technical, product)
- Every question has stable ID + declared family
- Demo questions (q_technical_01, q_behavioral_01, q_product_01) remain complete if referenced; they live in session-one fixtures and are never cut — questions.md may point at them or omit duplicates
- No invented employer facts

Do not install bats. Bash-equivalent passed=N failed=0.

Write `.workflow/S3-T4/results/implementer-result.md`.
