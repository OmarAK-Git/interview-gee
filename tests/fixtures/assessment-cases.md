# Assessment fixture cases

Machine-readable cases for **static label-consistency checks** in `tests/assessment_eval.bats`.
These labels encode the spec §10 persist rule (`expected_persist` iff `count(missing_elements) >= 2`).
They are **not** the live §10 N = 5 tolerance eval oracle.

Source material only: McCain Foods, Mastercard R-281517, Project Praetor, Project ALTER_EGO.

---

<!-- CASE START -->
id: behavioral_strong_01
family: behavioral
question_id: q_behavioral_custom
answer: |
  At McCain Foods during late-stage cyber-defense rounds, our ALTER_EGO shadow profile flagged a service account for drift (situation). My task was to validate whether the KL-divergence spike was a true positive before escalation (task). I pulled cumulative divergence baselines, compared peer cohort behavior, and opened a ticket with the owning team to freeze-under-suspicion only after corroborating host telemetry (action). The alert was downgraded to monitoring; we tightened the threshold and documented the false-positive path in the runbook (result).
missing_elements: []
expected_persist: false
evidence_kind: quote
evidence_value: documented the false-positive path in the runbook
<!-- CASE END -->

<!-- CASE START -->
id: behavioral_one_missing_01
family: behavioral
question_id: q_behavioral_custom
answer: |
  Situation: ALTER_EGO flagged unusual login timing on a contractor account. Task: decide whether to freeze the account. Action: I compared the session against the shadow profile and escalated to IR with the divergence chart attached. I did not summarize what changed afterward for the control owners.
missing_elements: [result]
expected_persist: false
evidence_kind: quote
evidence_value: did not summarize what changed afterward
<!-- CASE END -->

<!-- CASE START -->
id: behavioral_weak_demo_01
family: behavioral
question_id: q_behavioral_01
answer: |
  I just kind of watched the dashboard.
missing_elements: [action, result]
expected_persist: true
evidence_kind: quote
evidence_value: I just kind of watched the dashboard.
<!-- CASE END -->

<!-- CASE START -->
id: technical_strong_01
family: technical
question_id: q_technical_01
answer: |
  Problem: Praetor must recommend disposition without auto-containing production assets. Approach: the SOAR engine evaluates each alert against a never-contain list and emits advisory-only output with a hash-chained audit ledger entry for every decision. Tradeoff: we accept slower human approval instead of risky automated containment when classification confidence is borderline. Verification: replay the ledger hash chain and compare the advisory boundary flag to post-incident review—if containment would have been wrong, the never-contain match or ledger gap shows up in the verification pass.
missing_elements: []
expected_persist: false
evidence_kind: quote
evidence_value: hash-chained audit ledger entry
<!-- CASE END -->

<!-- CASE START -->
id: technical_one_missing_01
family: technical
question_id: q_technical_custom
answer: |
  Problem: ALTER_EGO needs to detect behavioral drift without freezing legitimate admins. Approach: maintain cumulative KL-divergence against shadow profiles and freeze-under-suspicion only on sustained divergence. Tradeoff: higher sensitivity catches insiders sooner but increases analyst load. I did not describe how we verify a freeze decision after the fact.
missing_elements: [verification]
expected_persist: false
evidence_kind: quote
evidence_value: did not describe how we verify
<!-- CASE END -->

<!-- CASE START -->
id: technical_weak_01
family: technical
question_id: q_technical_custom
answer: |
  Praetor just sends alerts somewhere and we trust it.
missing_elements: [approach, tradeoff, verification]
expected_persist: true
evidence_kind: quote
evidence_value: just sends alerts somewhere
<!-- CASE END -->

<!-- CASE START -->
id: product_strong_01
family: product
question_id: q_product_01
answer: |
  User: merchants and their payment ops teams on Agent Suite (R-281517). Constraint: a false positive must not freeze checkout during rollout. Decision: stage by merchant segment—shadow mode first, then limited actuation with human approval before any automated freeze. Metric: track false-freeze rate per thousand sessions and rollback if it exceeds our agreed SLO.
missing_elements: []
expected_persist: false
evidence_kind: quote
evidence_value: false-freeze rate per thousand sessions
<!-- CASE END -->

<!-- CASE START -->
id: product_one_missing_01
family: product
question_id: q_product_custom
answer: |
  User: fraud analysts using Agent Suite. Constraint: advisory-only automations cannot block settlements without review. Decision: ship rules to a canary tenant before general availability. I skipped naming a metric to know rollout succeeded.
missing_elements: [metric]
expected_persist: false
evidence_kind: quote
evidence_value: skipped naming a metric
<!-- CASE END -->

<!-- CASE START -->
id: product_weak_01
family: product
question_id: q_product_custom
answer: |
  Roll out Agent Suite everywhere at once and fix problems later.
missing_elements: [user, constraint, metric]
expected_persist: true
evidence_kind: quote
evidence_value: Roll out Agent Suite everywhere at once
<!-- CASE END -->
