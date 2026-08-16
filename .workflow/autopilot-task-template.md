# Autopilot Task Template

Copy and adapt this object under `.workflow/autopilot-queue.json` → `items`.

```json
{
  "id": "S1-T0",
  "title": "Short title",
  "status": "pending",
  "tier": "T2",
  "type": "task",
  "priority": "must",
  "depends_on": [],
  "goal": "One observable task goal.",
  "scope": "The allowed boundary for this item.",
  "description": "Plan-derived implementation detail.",
  "code_changing": true,
  "needs_research": false,
  "researcher_policy": "multi_path_opportunity_cost",
  "code_review_policy": "frequent_after_implement",
  "files_allowed": ["scripts/", "tests/"],
  "acceptance_criteria": ["Observable outcome."],
  "verification": {
    "scope": "task",
    "commands": ["PowerShell command from repo root"],
    "manual_checks": []
  },
  "implementation_agent": "implementer",
  "verification_agent": "skeptic-verifier",
  "run_dir": ".workflow/S1-T0",
  "attempts": 0,
  "max_retries": 1,
  "evidence": []
}
```

Rules:

- Keep IDs unique and preserve `depends_on` ordering from `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-plan.md`.
- Use `phase_exit` only for explicit sprint/phase gate items; set their `run_mode` to `in_session_grok`.
- Keep normal verification task-scoped.
- Run researcher when `needs_research` is true or the researcher policy fires.
- Run code-reviewer after every `code_changing` implementation.
- Never set `done` without fresh verifier evidence.
