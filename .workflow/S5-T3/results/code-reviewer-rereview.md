# S5-T3 code re-review — inference-before-JD fix

**Packet:** `.workflow/S5-T3/packets/03-rereview-diff.md`
**Prior review:** `.workflow/S5-T3/results/code-reviewer-result.md` (verdict `block`)
**Reviewer:** code-reviewer (did not author this code)
**Date:** 2026-08-23
**Kind:** scoped re-review of the Important 1 fix only
**Scope:** current `app/packs.py` `start_session_args` vs prior Important finding; no implementation edits this review

**Verdict:** `approve`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 0 |
| New Critical/Important breakage | 0 |

**Retry:** no

---

## Open findings

### Important 1 — `start_session_args` validated JD before inference — **ADDRESSED**

**Prior claim:** `start_session_args` called `require_session_jd` before `normalize_inference`, so `StartInferenceHttpTest` (`{"inference":"cursor"}`) returned `"jd kind must be pack or paste"` instead of `"nous or codex"`.

**Current code** (`app/packs.py:145-160`):

```python
def start_session_args(payload: dict, *, sources_dir: Path) -> dict:
    from inference import normalize_inference

    inference = normalize_inference(payload.get("inference"))
    jd = require_session_jd(...)
    return {
        "inference": inference,
        "temperature": normalize_temperature(payload.get("temperature")),
        ...
    }
```

`normalize_inference` now runs first. Unknown `"cursor"` raises `ValueError: inference must be nous or codex (got 'cursor')` (`app/inference.py:13`) before JD is touched. Server maps that to HTTP 400 (`app/server.py:144-147`).

**Independent evidence this review:**

```
py -3 -m unittest tests.test_inference.StartInferenceHttpTest tests.test_packs -v
# Ran 9 tests in 0.552s
# OK
# StartInferenceHttpTest.test_unknown_inference_is_400 ... ok
# test_start_session_args_requires_jd ... ok
```

`StartInferenceHttpTest` still POSTs only `{"inference":"cursor"}` and still asserts the error contains `"nous or codex"` (`tests/test_inference.py:61-69`). That test is now green. JD-required start is unchanged: `start_session_args({"inference":"nous"})` still raises (unit test ok).

Deviation from the prior suggested snippet: temperature/persona still run after JD. That does not affect the open finding (payload has no temperature; inference fails first). Not new Important breakage.

---

## New Critical / Important breakage

None.

Checked in the fix:

- Inference-unknown without JD now 400s with `"nous or codex"` (the open regression).
- Valid inference without JD still fail-closes on JD (`test_start_session_args_requires_jd`).
- Valid inference + pack still returns `inference`, `temperature`, `source_id`.
- Pack sanitize / `require_session_jd` / HTTP start mapping were not changed by this reorder.

Not re-opened as blockers (still track from prior review, out of this re-review's open set): Minor 1 traversal assertion uniqueness, Minor 2 missing GET `/api/packs` HTTP test, Minor 3 `practice_jd.sh` CRLF.

---

## Verdict

**approve** — Important 1 ADDRESSED; no new Critical/Important breakage.
