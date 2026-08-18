# Crossfire Question Bank (cuttable)

Broader interview coverage beyond spec §11 demo questions. The three session-one demo questions live in session-one fixtures and `SKILL.md` — **never cut**.

Source material only: McCain Foods, Mastercard R-281517, Project Praetor, Project ALTER_EGO.

| ID | Family | Source | Question |
| --- | --- | --- | --- |
| `q_behavioral_mccain_01` | `behavioral` | McCain Foods | Tell me about your McCain Foods Cyber Defense Engineer experience during late-stage rounds. What was the situation, your task, what you did, and what changed afterward? |
| `q_behavioral_alterego_01` | `behavioral` | Project ALTER_EGO | Describe a time Project ALTER_EGO UEBA shadow-profile drift triggered a freeze-under-suspicion decision. Walk through situation, task, action, and result. |
| `q_technical_praetor_02` | `technical` | Project Praetor | How does Project Praetor's never-contain list interact with the hash-chained audit ledger when disposition stays advisory-only? What problem does that solve, what tradeoff do you accept, and how do you verify the decision was correct? |
| `q_technical_alterego_01` | `technical` | Project ALTER_EGO | Explain how Project ALTER_EGO uses cumulative KL-divergence and shadow profiles to detect behavioral drift. What tradeoff do you accept between sensitivity and analyst load, and how do you verify a freeze-under-suspicion call after the fact? |
| `q_product_mastercard_02` | `product` | Mastercard R-281517 | For Mastercard Agent Suite (R-281517), how would you define rollout success when a false positive could freeze a merchant? Name user, constraint, decision, and metric. |
| `q_product_mastercard_03` | `product` | Mastercard Agent Suite | Who is the primary user for Agent Suite rollout at Mastercard (R-281517), and how would you sequence canary tenants versus general availability under a false-positive constraint? Name user, constraint, decision, and metric. |
