# Personal Memory

Session notes preserved outside the weakness block.

<!-- CROSSFIRE-WEAKNESSES:START -->
```yaml
version: 1
weaknesses:
  - weakness_id: w-e00e42cd5216
    family: behavioral
    topic: "alpha story"
    topic_key: alpha-story
    missing_elements: [action, result]
    first_seen: 2026-08-10T10:00:00Z
    last_seen: 2026-08-10T10:00:00Z
    observation_count: 1
    source_session_id: sess_a
    answer_ref: run_a/q_behavioral_01/0
    evidence:
      kind: quote
      value: "watched the dashboard"
  - weakness_id: w-1ee6d6febe17
    family: technical
    topic: "beta tradeoff"
    topic_key: beta-tradeoff
    missing_elements: [tradeoff, verification]
    first_seen: 2026-08-11T11:00:00Z
    last_seen: 2026-08-12T12:00:00Z
    observation_count: 2
    source_session_id: sess_b
    answer_ref: run_b/q_technical_01/0
    evidence:
      kind: quote
      value: "skipped verification"
  - weakness_id: w-b2f32d5ee0be
    family: product
    topic: "gamma metric"
    topic_key: gamma-metric
    missing_elements: [metric, decision]
    first_seen: 2026-08-13T13:00:00Z
    last_seen: 2026-08-14T14:00:00Z
    observation_count: 1
    source_session_id: sess_c
    answer_ref: run_c/q_product_01/0
    evidence:
      kind: byte_offset
      value: "0:6"
```
<!-- CROSSFIRE-WEAKNESSES:END -->

Footer content must survive updates.
