# S4-GE skeptic-verifier result (in-session Grok gate)

**Verdict: pass**

`gate_model: cursor-grok-4.6-high-fast`

Verify-only. Did not implement. Did not mark the queue done (`S4-GE` remains `in_progress`). Did not commit. Did not install packages (including `bats`). Did not write real `~/.hermes`. Did not treat `implementer-result.md` or `code-reviewer-result.md` as proof. Test-runner `Test-Path` existence is necessary but not sufficient.

---

## Claim restated

Final plan gate (S4-GE): demo-blocking acceptance criteria have recorded evidence and the demo is operable from a clean terminal. Two gate ACs:

1. `docs/acceptance-checklist.md` exists and covers demo-blocking criteria.
2. Isolation and two-process opener evidence still exist.

Known limitations for cuttable polish are **not** a fail. Fail if the checklist is missing or omits spec §17 items 1–7, or if isolation / two-process opener evidence has been deleted or reduced to empty filenames.

---

## Independent evidence (this gate)

### Existence (test-runner re-checked)

Cwd: `C:\Users\oalan\interview-gee`

Packet commands (this run):

```
Test-Path -LiteralPath docs\acceptance-checklist.md -PathType Leaf   True
Test-Path -LiteralPath tests\demo_session_2.bats -PathType Leaf      True
Test-Path -LiteralPath tests\isolation.bats -PathType Leaf           True
```

Matches `.workflow/S4-GE/results/test-runner-result.md` (3 exist, 0 failed). Independently re-confirmed the same three leaves.

Also this run:

| Path | Exists |
| --- | --- |
| `README.md` | True |
| `scripts/demo.sh` | True |
| `docs/demo-script.md` | True |
| `.workflow/S4-T12/results/verifier-result.md` | True |
| `.workflow/S2-GE/results/verifier-result.md` | True |
| `.workflow/S2-GE/results/test-runner-result.md` | True |
| `.workflow/S1-T1b/results/verifier-result.md` | True |
| `.workflow/S2-T5/results/verifier-result.md` | True |
| `.workflow/S2-T6/results/verifier-result.md` | True |
| `.workflow/S2-T7/results/verifier-result.md` | True |
| `.workflow/S3-GE/results/verifier-result.md` | True |
| `.workflow/S3-T8/results/verifier-result.md` | True |
| `.workflow/S3-T10/results/verifier-result.md` | True |
| `.workflow/S4-T11/results/verifier-result.md` | True |
| `%USERPROFILE%\.hermes` | **False** (`USERPROFILE=C:\Users\oalan`) |

`bats` **NOT FOUND**. Did not execute `tests/isolation.bats` or `tests/demo_session_2.bats` against real home.

Queue: `S4-GE` status is still `in_progress` (read this session; not mutated).

---

## AC1 — checklist exists and covers demo-blocking criteria

Read `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md:299-309` and `docs/acceptance-checklist.md:32-42`.

| # | Spec §17 demo-blocking | Checklist row | Covers? |
| --- | --- | --- | --- |
| 1 | Session two targets the weak area with no operator prompt that names it | row 1 **held** | **yes** |
| 2 | Weakness visible on disk; candidate `SKILL.md` visible in staging | row 2 **held** | **yes** |
| 3 | Reviewer can state: target from prompt memory; wording from stable interviewer; candidate did not select opener | row 3 **held** | **yes** |
| 4 | Session one and two different processes and session IDs | row 4 **held** | **yes** |
| 5 | Tests never mutate real `~/.hermes` | row 5 **held** | **yes** |
| 6 | Three questions asked; none dropped for time | row 6 **held** | **yes** |
| 7 | `/done` / harness finalize produced artifacts; raw quit/SIGKILL documented as not guaranteed | row 7 **held** | **yes** |

Cited sibling files for those rows still exist (Test-Path table above). S4-T12 verifier **pass** already token-audited the “held” cells (not filename-only). This gate did not re-execute sibling bash-assertions.

Clean-terminal path is in the same checklist (`:9-16`): `bash scripts/demo.sh --prepare` then `bash scripts/demo.sh`. Product implements `--prepare` at `scripts/demo.sh:275-278` (handles flag then `exit 0`). Not an undocumented extra step.

Should-pass / cuttable polish is logged (`:65-79`): `bats` missing, T11 `human_needed`, YAML probe-pending, live 90s not re-measured, Monday manual merge, honesty beat, question-bank breadth. Packet: these are **not** a fail.

---

## AC2 — isolation and two-process opener evidence still exist

### Isolation (not filename-only)

`tests/isolation.bats` still contains load-bearing tests (this read):

- defaults `HERMES_HOME` to `.crossfire/profiles/test` (`:7-12`)
- `preflight_check_paths` rejects real-profile `HERMES_HOME` (`:14-30`, `:116-120`)
- no-create tripwire for Win/WSL operator homes (`:32-75`)
- fake-home marker stays `UNTOUCHED` after harness write (`:77-95`)
- `crossfire_require_isolated_hermes_home` enforces disposable profile (`:110-114`)

Sibling: `.workflow/S1-T1b/results/verifier-result.md` **survives** (isolation contract; first-run leak anti-claim). `.workflow/S2-GE/results/verifier-result.md` AC4 **held**: fail-closed `HERMES_HOME=/home/fish/.hermes`; fingerprint `a4a59ff1...` unchanged vs S2-T5; Windows home absent.

This run: `%USERPROFILE%\.hermes` still **False**. Did not point checks at real `~/.hermes`. Did not run isolation.bats.

### Two-process opener (not filename-only)

`tests/demo_session_2.bats` still contains load-bearing tests (this read):

- prints `opening_target_source=MEMORY.md` before `Question:` (`:172-185`)
- stub opener does not name `weakness_id` (`:249-258`)
- equal session IDs fail-closed (`:202-209`); distinct IDs pass (`:211-219`)
- equal process IDs fail-closed (`:221-234`)
- integration s1 persist then s2 targets behavioral weakness (`:260-270`)
- fail-closed on real `HERMES_HOME` (`:102-112`)

Sibling: `.workflow/S2-GE/results/verifier-result.md` **pass** still records independent parent-continues PIDs **3265 / 3266**, sessions **`sess_stub` / `sess_stub_s2`**, `opening_target_source=MEMORY.md` before `Question:`, and AC1/AC3 **held**.

---

## Refutations attempted (did not stick)

| Attack | Result |
| --- | --- |
| Test-runner existence-only pass | **Rejected as sufficient** — independently re-ran Test-Path and read bats + spec + checklist contents. Existence matched; contents are not empty stubs. |
| Checklist exists but omits a spec §17 demo-blocking item | **Refuted** — all seven items mapped at `:36-42`. |
| Isolation evidence deleted or gamed to a stub | **Refuted** — `tests/isolation.bats` still has fail-closed + marker + no-create tests; S1-T1b **survives**; S2-GE AC4 tokens still present. |
| Two-process opener evidence gone | **Refuted** — `tests/demo_session_2.bats` still asserts distinct PID/session IDs; S2-GE still records 3265/3266 and `sess_stub`/`sess_stub_s2`. |
| Missing bats / no live e2e vs real `~/.hermes` is a gate fail | **Rejected** — packet + spec §17 should-pass: cuttable polish and logged limitations are not a fail. Checklist does not invent a live e2e pass. |
| Plan Task 12 full-suite + real-`MEMORY.md` audit not re-run | **Not a fail** — logged as `bats` known limitation; packet forbids pointing checks at real `~/.hermes`. |

---

## AC mapping

| # | AC | Result | Evidence |
| --- | --- | --- | --- |
| 1 | `docs/acceptance-checklist.md` exists and covers demo-blocking criteria | **held** | Test-Path True; spec §17 items 1–7 all present as checklist rows with sibling citations; should-pass table logs cuttable polish |
| 2 | Isolation and two-process opener evidence still exist | **held** | `tests/isolation.bats` + S1-T1b + S2-GE AC4 still present; `tests/demo_session_2.bats` + S2-GE PIDs 3265/3266 and distinct session IDs still present |

Failed ACs: **none**.

---

## Isolation (this gate)

Did not write `~/.hermes`. Did not set `HERMES_HOME` to a real profile. Windows `%USERPROFILE%\.hermes` absent this run. Did not execute `tests/isolation.bats`. Did not invoke Hermes. S1-T1b first-run leak remains documented; this gate does not claim that historical run never mutated.

---

## Commands run

```
Test-Path docs\acceptance-checklist.md tests\demo_session_2.bats tests\isolation.bats   # all True
Test-Path cited sibling verifier leaves + scripts\demo.sh + README.md                   # all True
Test-Path %USERPROFILE%\.hermes                                                          # False
Get-Command bats                                                                         # NOT FOUND
# read spec §17, checklist, isolation.bats, demo_session_2.bats, S4-T12, S2-GE, S1-T1b
# grep scripts/demo.sh --prepare  → :275-278
# did not run bats, demo.sh, or Hermes
# did not commit; did not mark queue done
```

Files read: `.workflow/S4-GE/packets/01-gate.md`, `.workflow/S4-GE/results/test-runner-result.md`, `docs/acceptance-checklist.md`, `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` §17, `.workflow/S4-T12/results/verifier-result.md`, `.workflow/S2-GE/results/verifier-result.md`, `.workflow/S1-T1b/results/verifier-result.md`, `tests/isolation.bats`, `tests/demo_session_2.bats`, `scripts/demo.sh` `--prepare`, `.workflow/autopilot-queue.json` S4-GE item.

---

## Strongest reason it survives

The checklist file exists and maps every spec §17 demo-blocking item to sibling verifier evidence that still exists; isolation and two-process opener contracts still exist as non-empty bats plus S2-GE recorded PIDs/session IDs and isolation fail-closed evidence. Logged cuttable polish (`bats`, live transcript) is not a fail.

---

## Machine-readable

```json
{
  "packet_id": "01-gate",
  "task": "S4-GE",
  "verdict": "pass",
  "claim": "survives",
  "gate_model": "cursor-grok-4.6-high-fast",
  "acs_held": [
    "docs/acceptance-checklist.md exists and covers demo-blocking criteria",
    "isolation and two-process opener evidence still exist"
  ],
  "acs_failed": [],
  "evidence_path": ".workflow/S4-GE/results/verifier-result.md",
  "sibling_evidence": [
    ".workflow/S4-T12/results/verifier-result.md",
    ".workflow/S2-GE/results/verifier-result.md",
    ".workflow/S1-T1b/results/verifier-result.md"
  ],
  "test_path": {
    "acceptance_checklist": true,
    "demo_session_2_bats": true,
    "isolation_bats": true,
    "userprofile_hermes": false
  },
  "bats_installed": false,
  "isolation": "pass_real_hermes_absent",
  "queue_marked_done": false,
  "committed": false
}
```
