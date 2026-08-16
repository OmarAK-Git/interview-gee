# Skeptic verification — S1-T3 (packet 04-verify)

**packet_id:** `04-verify`  
**verdict:** `survives`  
**strongest_reason:** Plan-path artifacts exist; independent label hygiene shows `expected_persist == (n_missing >= 2)` on all 9 cases with no STAR-on-technical labels; SKILL + bats encode skip≠N=5-pass and forced-live fail-closed; WSL probes exited 77 / 1 accordingly. Live Hermes N=5 was not run and is not claimed passed.

Implementer transcripts were not used as evidence (`implementer-result.md` not read).

---

## Claim restated

S1-T3 is done on this machine under path 3: assessment contract + fixture suite + bats static/hygiene checks. Hermes is unsupported here, so live §10 N=5 is skip / fail-closed — **not** a tolerance-eval pass. Skip must not be treated as pass.

---

## Evidence gathered

### Official Test-Path (queue verification commands)

| Path | Result |
| --- | --- |
| `skills\crossfire-interviewer\SKILL.md` | `True` |
| `tests\fixtures\assessment-cases.md` | `True` |
| `tests\assessment_eval.bats` | `True` |

(`skills\crossfire-interviewer\assessment-cases.md` is `False` — cases live under `tests/fixtures/` per plan/queue `files_allowed`.)

### Fixture label hygiene (independent PowerShell; bats not installed)

9 cases, **0** persist-rule errors; `star_on_tech=False` on all technical cases:

| id | family | n_missing | expected_persist | ok |
| --- | --- | --- | --- | --- |
| behavioral_strong_01 | behavioral | 0 | false | True |
| behavioral_one_missing_01 | behavioral | 1 | false | True |
| behavioral_weak_demo_01 | behavioral | 2 | true | True |
| technical_strong_01 | technical | 0 | false | True |
| technical_one_missing_01 | technical | 1 | false | True |
| technical_weak_01 | technical | 3 | true | True |
| product_strong_01 | product | 0 | false | True |
| product_one_missing_01 | product | 1 | false | True |
| product_weak_01 | product | 3 | true | True |

Per-family coverage: each of behavioral / technical / product has strong, one-missing, and weak. Demo `q_behavioral_01` → `missing_elements: [action, result]`, `expected_persist: true`.

### Contract reads (not implementer narrative)

**SKILL.md**

- Families + required elements; mixed-family forbidden; technical **never** scored with STAR (lines 22–30, 74–75).
- Persist iff ≥2 missing; one missing does not persist; empty → no persist (lines 32–36, 68).
- Output: `family`, `missing_elements` (may be `[]`), quote/byte_offset evidence (lines 42–53).
- Live N=5 described; **Skip is not proof that N = 5 passed**; forced live without binary must **fail closed** (lines 98–102).

**assessment_eval.bats**

- Static greps for persist / STAR / families / demo IDs / skip≠pass.
- `assessment_assert_case_hygiene`: `persist_bool` from `count >= 2`; rejects STAR elems on technical; family allow-list.
- Live skip test requires **status 77** only (does not accept 0); fail-closed test requires nonzero + FAIL CLOSED / not discoverable.
- No direct `hermes` exec in non-comment lines; uses `discover_hermes_bin` under `CROSSFIRE_HERMES_DISCOVERY=0`.

**demo_common.sh:** `CROSSFIRE_HERMES_DISCOVERY=0` → `discover_hermes_bin` returns 1 immediately (no hermes invoke).

### Live skip / fail-closed probe (WSL; no bats install; no hermes exec)

```
DISCOVER_PROBE failed_as_expected
SKIP_PROBE status=77  out=SKIP: ... N=5 live eval unsupported
FAILCLOSED_PROBE status=1  out=FAIL CLOSED: CROSSFIRE_LIVE_ASSESSMENT=1 but Hermes binary not discoverable
BATS_skip_requires_77=yes
BATS_skip_accepts_0=no
```

### AC map

| AC | Assessment |
| --- | --- |
| Fixture suite encodes family, missing-element, persist (persist iff ≥2; one-missing does not) | **Met** — 9 labeled cases; hygiene 0 errors |
| Technical answers not scored with STAR (skill + cases) | **Met** — SKILL prose + forbidden list; technical fixtures use only problem/approach/tradeoff/verification |
| One missing does not persist; ≥2 does | **Met** — SKILL + all one-missing `false` / weak `true` |
| SKILL.md, assessment-cases.md, assessment_eval.bats exist | **Met** at plan paths |
| Live N=5 skip/fail-closed; skip ≠ pass | **Met** — encoded + probed; **not** claimed as N=5 passed |

### Attack angles checked (did not refute)

- Missing live N=5 → **not grounds to refute** under this packet when contract + skip≠pass hold.
- Skip treated as pass → **no** (exit 77 required; SKILL anti-claim; bats reject status 0).
- Forced live soft-skips → **no** (status 1 + FAIL CLOSED).
- Label/persist mismatch or STAR-on-tech fixtures → **no** (independent parse).
- Wrong cases path under skills/ → **no** (plan/queue place cases in `tests/fixtures/`).

### Residual uncertainty (not blocking)

- Full `bats` suite not executed (packet: do not install bats). Hygiene + skip/fail-closed were checked independently of bats runner.
- Live assessor tolerance (≥4/5) remains **unproven** until Hermes exists — correctly recorded as unsupported/skip, not pass.

---

## Commands run

```text
Test-Path -LiteralPath skills\crossfire-interviewer\SKILL.md -PathType Leaf   # True
Test-Path -LiteralPath tests\fixtures\assessment-cases.md -PathType Leaf     # True
Test-Path -LiteralPath tests\assessment_eval.bats -PathType Leaf             # True
# Independent PowerShell fixture parse: cases=9 errors=0
# WSL probe: CROSSFIRE_HERMES_DISCOVERY=0 discover → fail; skip snippet → 77; forced live → 1 FAIL CLOSED
# bats: not installed (skipped per packet)
# hermes: not executed; ~/.hermes not mutated
```

Files read: `skills/crossfire-interviewer/SKILL.md`, `tests/fixtures/assessment-cases.md`, `tests/assessment_eval.bats`, `.workflow/S1-T3/plan.md`, queue S1-T3 entry, `scripts/demo_common.sh` (`discover_hermes_bin` only).

---

## Machine-readable

```json
{
  "packet_id": "04-verify",
  "verdict": "survives",
  "strongest_reason": "Plan-path artifacts exist; independent hygiene expected_persist==(n_missing>=2) on 9/9 with no STAR-on-technical; SKILL+bats encode skip≠N=5-pass and forced-live fail-closed; WSL probes 77/1. Live N=5 not run and not claimed passed.",
  "evidence": [
    "Test-Path SKILL.md / tests/fixtures/assessment-cases.md / tests/assessment_eval.bats all True",
    "Independent parse: 9 cases, 0 persist mismatches; per-family strong/one/weak; q_behavioral_01 [action,result] expected_persist true; technical elems non-STAR",
    "SKILL.md: never STAR on technical; persist >=2; one missing no persist; Skip is not proof N=5 passed; fail closed if forced without binary",
    "assessment_eval.bats: hygiene assert count>=2; skip test status eq 77 only; fail-closed nonzero; no direct hermes exec",
    "WSL: DISCOVERY=0 discover fails; skip snippet status 77; CROSSFIRE_LIVE_ASSESSMENT=1 without binary status 1 FAIL CLOSED",
    "demo_common.sh: CROSSFIRE_HERMES_DISCOVERY=0 returns 1 before any hermes lookup",
    "bats not installed — suite not executed (packet forbids install); hermes not exec'd; ~/.hermes not mutated"
  ],
  "commands_run": [
    "Test-Path -LiteralPath skills\\crossfire-interviewer\\SKILL.md -PathType Leaf",
    "Test-Path -LiteralPath tests\\fixtures\\assessment-cases.md -PathType Leaf",
    "Test-Path -LiteralPath tests\\assessment_eval.bats -PathType Leaf",
    "PowerShell independent fixture hygiene parse (cases=9 errors=0)",
    "wsl bash probe: discover under DISCOVERY=0; skip exit 77; forced-live FAIL CLOSED exit 1"
  ]
}
```
