# S5-GE skeptic-verifier result (in-session Grok gate)

**Verdict: pass**

`gate_model: cursor-grok-4.6-high-fast`

Verify-only. Did not implement this sprint. Did not mark the queue done (`S5-GE` remains `verifying`). Did not commit. Did not install packages. Did not write real `~/.hermes`. Did not treat implementer or code-reviewer transcripts as proof. Did not treat stub session output as proof of the live Luna bar.

---

## Claim restated

Sprint 5 close-out gate: practice interviewer meets the 2026-08-23 design (one JD, skill-steered questions, Skip, strong/weak report, family buckets) and the 1.0.0 demo three questions are untouched. Four ACs:

1. S5-T1 through S5-T7 are done with verifier evidence.
2. Four packs and skill procedure exist; demo three questions still verbatim.
3. Start requires a JD; Skip and End report exist in code.
4. Automated tests do not target real `~/.hermes`.

Manual: operator live pass recorded **or** explicitly left `human_needed`. Isolation fail-closed still required. Stub is not the live bar.

---

## Independent evidence (this gate)

### Test-runner re-run (this session)

Cwd: `C:\Users\oalan\interview-gee`

```
py -3 -m unittest tests.test_packs tests.test_memory_view
  → Ran 14 tests in 0.594s  OK  UNITTEST_EXIT=0

Test-Path skills\crossfire-interviewer\sources\mastercard-r-281517.md
  → True

Select-String SKILL.md q_technical_01 | Measure-Object Count
  → 3

Test-Path $env:USERPROFILE\.hermes
  → False (before and after; USERPROFILE=C:\Users\oalan)
```

Matches `.workflow/S5-GE/results/test-runner-result.md` (14 passed, mastercard leaf True, count 3). Re-executed here; not trusted from that file alone.

### Isolation fail-closed (this session)

Git Bash, `HERMES_HOME=/tmp/evil/.hermes`, source `scripts/demo_common.sh`:

```
PREFLIGHT FAIL: HERMES_HOME points at real profile: /tmp/evil/.hermes
```

Process exit 1. Real `%USERPROFILE%\.hermes` still absent after.

### Queue + task verdicts (read this session)

| Item | Queue status | Evidence path | Verdict line |
| --- | --- | --- | --- |
| S5-T1 | `done` | `.workflow/S5-T1/results/verifier-result.md` | **survives** (`:3`) |
| S5-T2 | `done` | `.workflow/S5-T2/results/verifier-result.md` | **survives** (`:3`) |
| S5-T3 | `done` | `.workflow/S5-T3/results/verifier-result.md` | **survives** (`:3`) |
| S5-T4 | `done` | `.workflow/S5-T4/results/verifier-result.md` | **survives** (`:3`) |
| S5-T5 | `done` | `.workflow/S5-T5/results/verifier-result.md` | **survives** (`:3`) |
| S5-T6 | `done` | `.workflow/S5-T6/results/verifier-result.md` | **survives** (`:3`) |
| S5-T7 | `done` | `.workflow/S5-T7/results/verifier-result.md` | **survives** (`:3`) |

`S5-GE` is `verifying` with empty `evidence` (expected mid-gate). `S6-T1` / `S6-GE` remain `pending`.

---

## AC1 — S5-T1 through S5-T7 done with verifier evidence

**Result: held**

Queue statuses are `done` for all seven. Each listed evidence file exists and records skeptic verdict **survives** (not missing, not `refuted`). Task ACs were already independently probed by those verifiers; this gate re-checked existence and the verdict line, then re-probed the gate ACs below.

Not used as a fail: S5-T3 stub persist / `Python was not found`, S5-T6 missing `MEMORY.md` on this Windows host. Those were scoped host/persist gaps, not missing JD / Skip / report / isolation.

---

## AC2 — Four packs and skill procedure; demo three questions verbatim

**Result: held**

Independent `list_source_packs` + `parse_pack_file` this session:

| Pack | comps | families | bands |
| --- | --- | --- | --- |
| `alter-ego` | 5 | behavioral, technical | core, edge |
| `mastercard-r-281517` | 5 | product | core, edge |
| `mccain-cyber-defense` | 5 | behavioral | core, edge |
| `praetor` | 5 | technical | core, edge |

Leaf files: `skills/crossfire-interviewer/sources/{alter-ego,mastercard-r-281517,mccain-cyber-defense,praetor}.md`.

Skill procedure: `skills/crossfire-interviewer/SKILL.md:188` `## Practice interviewer (session JD)`; temperature `:200-206`; dedicated `### Skip` `:219-221`. `HAS_PRACTICE_HEADING True`, `HAS_SKIP_HEADING True`.

Demo three questions, exact string vs spec `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md:195-197` and `SKILL.md:86-88` (count 1 in each file this run):

- `Walk through how Praetor decides not to contain. What is the advisory boundary, and how would you know the decision was wrong?`
- `Tell me about a time a detection you owned was wrong. What did you do, and what changed afterward?`
- `For Mastercard Agent Suite (R-281517), how would you sequence rollout when a false positive could freeze a merchant?`

`q_technical_01` appears 3 times in `SKILL.md` (table, fixture row, harness order) — a weak packet grep; the verbatim bar is the three full strings above, not the ID count.

---

## AC3 — Start requires a JD; Skip and End report exist in code

**Result: held (code). Live Luna not used as proof.**

| Check | Evidence |
| --- | --- |
| Python start without JD | Independent `start_session_args({"inference":"nous"})` → `ValueError: jd kind must be pack or paste` (`app/packs.py:145-153` always calls `require_session_jd`; `:142` raise). Unittest `tests/test_packs.py:86-90` is the same path and passed in the 14-test run. |
| HTTP 400 mapping | `app/server.py:148-152` maps that `ValueError` to HTTP 400 before `run_practice`. |
| Wrapper fail-closed | `scripts/practice_session.sh:100-101` `fail_closed "practice start requires a session JD (pack or paste)"`. |
| Skip in wrapper | `scripts/practice_session.sh:291-336` `crossfire_practice_skip`; kv `skipped=true` `:331`, `persist_recommended=false` `:333`; no spool yaml write in skip. |
| Skip HTTP | `app/server.py:211-213` `POST /api/session/skip` requires `SESSION["run_id"]` else 409. UI posts it at `app/static/app.js:309`. |
| End report | `practice_session.sh:398-402` `report_weak` / `report_strong` / `report_line=Weak:` / `Strong:`. `app/server.py:41-48` joins `report_line` → `report_text`. UI `app/static/app.js:262-263` bubbles `data.report_text`. Topic is `{source} · {family}` at `practice_session.sh:353`. No `q_live_01` / `practice gap` string in `practice_session.sh`. |

Stub start still hardcodes the Praetor demo question (`practice_session.sh:129`). That is stub theater, not the live bar. Not treated as proof that Luna skill-steers from the session JD.

---

## AC4 — Automated tests do not target real ~/.hermes

**Result: held. Isolation fail-closed still present.**

| Check | Evidence |
| --- | --- |
| Gate unittests | `tests/test_packs.py` reads repo `sources/` only (no `HERMES_HOME`). `tests/test_memory_view.py:59-64,117-123` set `HERMES_HOME` to `tempfile.mkdtemp()` and rmtree. 14/14 OK this run. |
| Practice shell tests | `tests/practice_jd.sh:9-13`, `practice_session_stub.sh:10-14`, `practice_inference.sh:48-52` remap `HOME=$(mktemp …)` **then** `mkdir -p "$HOME/.hermes"`. That `.hermes` is under `/tmp/crossfire-*`, not the operator home. |
| Demo isolation contract | `scripts/demo_common.sh:20-25` still fail-closes `is_real_hermes_home`. Independently reproduced this session (`/tmp/evil/.hermes`). `tests/isolation.bats` still encodes the landmine (`:14-18`, `:116-119`). |
| Real home after this gate | `Test-Path C:\Users\oalan\.hermes` → **False**. |

Practice product path allowlists WSL `$HOME/.hermes` (`scripts/practice_common.sh:65-81`) for Monday/live use. That is not an automated-test target. Automated tests override `HOME` first.

---

## Manual / live bar

`tests/interactive_smoke.md:101-118` — **Practice JD — live Luna close-out (S5-T7)**. **Status: human_needed**. Checklist rows 1–7 all `pending`. Transcript placeholder empty (`:120-135`). Design spec not flipped to `implemented` (S5-T7 verifier; not re-opened here as a fail).

Packet: operator live pass recorded **or** explicitly left `human_needed`. Explicit. Stub passing is **not** this checklist.

---

## Attacks that did not refute

- **ID-count theater.** Packet `q_technical_01` count=3 would pass if the question text changed. Refuted by exact three-string compare to spec §11.
- **Stale test-runner file.** Re-ran the three commands this session; same 14/0/0 + leaf + count.
- **Task “survives” ≠ gate “pass”.** Queue `done` plus non-`refuted` verdict files satisfy AC1. Gate ACs 2–4 were re-probed in code and commands.
- **Windows persist host gap** (no `MEMORY.md` / Store `python3`). Not a gate AC. Packet forbids failing solely on that when topic/report code is present.
- **Treat stub as live bar.** Not done. Live Luna remains `human_needed`.
- **Isolation abandoned for practice Monday allowlist.** Fail-closed still fires on `demo_common.sh`. Automated tests do not point at `%USERPROFILE%\.hermes`.

---

## human_needed residuals

Live practice UI on Codex / `gpt-5.6-luna` (`bash scripts/practice_ui.sh`, http://127.0.0.1:8787), still pending in `tests/interactive_smoke.md`:

1. Pack session (`praetor`), empty persona, temperature 2; context visible; first question stays in Praetor facts.
2. Thin answer → probe / in-role next question.
3. Mid-session temperature 4 → rarer Praetor angle, no Mastercard/ALTER_EGO leak.
4. Skip once; no persist from the skipped question.
5. One strong family + one weak family.
6. End report lists Weak and Strong; panel title `{source} · {family}`.
7. Paste-JD new session; no Praetor leak.

Do not flip the 2026-08-23 design spec to `implemented` until that pass is recorded. Do not start S6 weave work from this residual.

---

## Verdict

**pass.** Strongest reason: this session re-ran the gate commands (14/14), reproduced isolation fail-closed, confirmed the three demo strings character-identical to spec §11, and read JD-required / Skip / End-report in product code; S5-T1..T7 are `done` with `survives` verifier files. Live Luna is an explicit `human_needed` residual, not a stub-proven close-out.
