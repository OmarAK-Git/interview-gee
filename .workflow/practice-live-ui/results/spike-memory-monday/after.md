# Operator memory (spike; will be restored)

<!-- CROSSFIRE-WEAKNESSES:START -->
```yaml
version: 1
weaknesses:
  - weakness_id: w-mondayspike01
    family: product
    topic: "mastercard rollout sequencing"
    topic_key: mastercard-rollout-sequencing
    missing_elements: [metric, constraint]
    first_seen: 2026-08-21T19:30:00Z
    last_seen: 2026-08-21T19:30:00Z
    observation_count: 1
    source_session_id: sess_monday_spike
    answer_ref: spike-monday/q_product_01/0
    evidence:
      kind: quote
      value: "we would just ship it"
```
<!-- CROSSFIRE-WEAKNESSES:END -->
