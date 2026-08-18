# S2-GE skeptic-verifier result (in-session Grok gate)

**Verdict: pass**

`gate_model: cursor-grok-4.6-high-fast`

Verify-only. Did not implement. Did not mark the queue done. Did not commit. Did not install packages. Did not run `tests/isolation.bats` against real `~/.hermes`. Did not treat `implementer-result.md` as evidence. Test-runner `Test-Path` existence is necessary but not sufficient.

---

## Claim restated

Sprint 2 phase exit (S2-GE): the memory-only opener works across separate processes with candidate exclusion (or a recorded degraded path). All four gate ACs hold:

1. Session two targets the weak area with no operator prompt that names it.
2. Candidate skill is not in the live dir at opener (or degraded path is recorded).
3. Session one and two are different processes and session IDs.
4. Tests never mutate real `~/.hermes`.

Fail if isolation is unproven or the opener does not print `opening_target_source` before the question.

---

## Independent evidence (this gate)

### Existence (test-runner re-checked)

Cwd: `C:\Users\oalan\interview-gee`

```
Test-Path tests\demo_session_1.bats   True
Test-Path tests\demo_session_2.bats   True
Test-Path tests\candidate_skill.bats  True
Test-Path tests\isolation.bats        True
Test-Path %USERPROFILE%\.hermes       False
```

WSL read-only: `/home/fish/.hermes` **EXISTS** (install tree, `drwx------` 2026-08-16; not created this run). Windows home **ABSENT**.

### S2-T7 bash-equivalent (fresh)

```
wsl.exe -e bash -lc 'cd /mnt/c/Users/oalan/interview-gee && bash .workflow/S2-T7/bash-assertions.sh'
```

`passed=13 failed=0` `ASSERT_EXIT:0` including `print_before_question`, `candidate_in_live_dir`, `isolation_real_home`, `integration_s1_s2`. Helper `distinct_process_id` is known-gamed (exec-last); not used as AC3 proof.

### Numbered opener (fixture MEMORY.md, disposable HERMES_HOME)

```
     1	opening_target_source=MEMORY.md
     2	weakness_id=w-b2f32d5ee0be
     3	family=product
     4	source_session_id=sess_c
     5	target selected by prompt memory; wording generated under stable interviewer procedure
     8	Question: For the product decision gap (metric,decision), ...
```

`opening_target_source` on line 1 **before** `Question:` on line 8. Question does not quote `w-b2f32d5ee0be`.

### Clean session-one then session-two (disposable `/tmp/crossfire-s2ge-s1s2.*`)

Session one: `S1_RC:0`, `1 weakness(es) persisted.`, `family: behavioral`, `source_session_id: sess_stub`.

Live skills at opener: **empty** (`LIVE_SKILLS:` blank). Isolation fail-closed: `ISO_RC:1` `PREFLIGHT FAIL: HERMES_HOME points at real profile: /home/fish/.hermes`.

Session two:

```
opening_target_source=MEMORY.md
weakness_id=w-847d45c82e2b
family=behavioral
source_session_id=sess_stub
...
CROSSFIRE_SESSION_TWO_PID=3266
CROSSFIRE_SESSION_TWO_ID=sess_stub_s2
Question: Tell me about a time a detection you owned was wrong — specifically, what action did you take and what measurable result followed?
session_identifiability: distinct process=3266 session=sess_stub_s2 (session_one=3265/sess_stub)
PARENT_STILL_HERE pid=3265
```

Parent continues after child (not exec-last). Distinct PIDs `3265` / `3266`. Distinct session IDs `sess_stub` / `sess_stub_s2`. No naming prompt. Question does not contain `w-847d45c82e2b`.

### Real-home fingerprint (this run vs S2-T5)

| Check | Value |
| --- | --- |
| This gate `STAT_AFTER` | `a4a59ff1362c37eebef70c5d42ffc1996762dccec7033d7aed0b97ed93e71142` |
| S2-T5 verifier sha256 of `find /home/fish/.hermes` | **same** |
| Windows `%USERPROFILE%\.hermes` | absent before and after |

Temp trees removed (`CLEANED=yes`). Writes stayed under `/tmp/crossfire-s2ge*`.

---

## Sibling verifier evidence (task-scoped)

| Task | Path | Load-bearing for gate |
| --- | --- | --- |
| S2-T5 | `.workflow/S2-T5/results/verifier-result.md` | Session one persist of newest/only weakness; isolation fail-closed; fingerprint unchanged |
| S2-T6 | `.workflow/S2-T6/results/verifier-result.md` | Staging never-write-live; live assert fail-closed; exclusion possible so degraded path not required; `docs/hermes-compatibility.md` exclude-candidate row **verified** |
| S2-T7 | `.workflow/S2-T7/results/verifier-result.md` | Print-before-question; no naming; live-dir candidate blocks launch; distinct IDs; documented-fallback for `session_search` |
| S1-T1b | `.workflow/S1-T1b/results/verifier-result.md` | `tests/isolation.bats` contract; first-run leak recorded (do not claim first 1b never mutated); going-forward harness does not mkdir operator paths |

Product reads (not implementer notes): `scripts/demo_session_2.sh:96-100` assert-then-print-then-ask; `scripts/demo_common.sh:584-590` prints `opening_target_source`/`weakness_id`/`source_session_id` before `crossfire_session_two_ask_opener` (`Question:` at `demo_session_2.sh:81`); `scripts/demo_common.sh:228-229` source fail-closes on real `HERMES_HOME`; `tests/isolation.bats` (read only).

Spec: `docs/b83b4a6b-e9dc-4c74-9edc-2e0b9bf9de54-spec.md` §13 (219–235) and gate ACs matching §17.1 / §17.4 / §17.5 plus candidate-barrier §13.

---

## AC mapping

| # | AC | Result | Evidence |
| --- | --- | --- | --- |
| 1 | Session two targets the weak area with no operator prompt that names it | **held** | Clean s1→s2 targeted persisted `family=behavioral` / `w-847d45c82e2b`; question asks for missing action/result; no `which weakness` / `name the weakness`; `tests/demo_session_2.bats` `@test "stub opener question does not name weakness_id"`; S2-T7 sibling |
| 2 | Candidate skill is not in the live dir at opener (or degraded path is recorded) | **held** | Independent `LIVE_SKILLS` empty at opener; `crossfire_assert_candidates_excluded_from_live` before question (`demo_session_2.sh:97`); bash-assertions + S2-T7 plant fail-closes launch; S2-T6 never-write-live + independent stray removed from live. Exclusion is possible → degraded path not required (`hermes-compatibility.md` exclude-candidate **verified**) |
| 3 | Session one and two are different processes and session IDs | **held** | Independent parent-continues: PID `3265` vs `3266`, session `sess_stub` vs `sess_stub_s2`; equal IDs fail-closed (S2-T7 + `tests/demo_session_2.bats`). Spec §13 “not context carryover” fallback (MEMORY.md on disk + candidate absent + distinct IDs) used; `session_search` observability remains documented-fallback |
| 4 | Tests never mutate real `~/.hermes` | **held** | `tests/isolation.bats` (read): defaults to `.crossfire/profiles/test`, fail-closes real `HERMES_HOME`, no-create tripwire, fake-marker `UNTOUCHED`. Bats mkdir only under disposable `HERMES_HOME` / `TEST_ROOT` / fake `BATS_TMPDIR`. Product `mkdir` after `crossfire_require_isolated_hermes_home` (memory write, isolated skill copy, spool under `CROSSFIRE_RUNS_DIR`). This-run fingerprint of `/home/fish/.hermes` unchanged vs S2-T5; Windows home still absent. Isolation fail-closed `ISO_RC:1` with no write |

Failed ACs: **none**.

---

## Isolation (AC4 detail)

`/home/fish/.hermes` exists as the approved Hermes **install** tree (compatibility doc Task 1b install record). `tests/isolation.bats` no-create branches are **inert for WSL creation** while that path already exists; they would miss in-place mutation. In-place mutation is covered by fingerprint comparison (S2-T5 and this gate: identical sha256) plus source-path fail-closed before any write. Windows `%USERPROFILE%\.hermes` remains absent, so the Win no-create tripwire stays armed.

S1-T1b first-run leak is documented; this gate does **not** claim that historical run never mutated. Going-forward tests and this verification did not mutate real `~/.hermes`.

Did not execute `tests/isolation.bats` (packet: read; do not run against real `~/.hermes`). `bats` is still absent; bash-equivalent + independent disposable-home runs substitute.

---

## Refutations attempted (did not stick)

- Existence-only pass from test-runner `Test-Path`: rejected; independent numbered opener + s1→s2 required and run.
- Opener does not print `opening_target_source` before the question: **refuted** — line 1 then line 8 (fixture) and s1→s2 stdout starts with `opening_target_source=MEMORY.md` before `Question:`.
- Isolation unproven because WSL home exists: **refuted** — existence is the install tree; tests fail-close rather than write; fingerprint unchanged.
- AC3 only from gamed `distinct_process_id` helper: **refuted** — independent parent-continues PIDs 3265/3266.
- Candidate exclusion only vacuously true: **partial** — this s1 run did not stage a SKILL.md (`demo_session_1.sh` has no `stage_candidate` call), but S2-T6/T7 prove assert fail-closed when a live candidate **is** planted, and opener still asserts before ask. Vacuous absence still satisfies “not in the live dir.” Non-blocking: session-one finalize does not invoke `scripts/stage_candidate_skill.sh` (S2-T6 noted hook out of its `files_allowed`). Spec §17.2 staging visibility is **not** one of the four S2-GE gate ACs.

---

## Commands run

```
Test-Path tests\demo_session_{1,2}.bats tests\candidate_skill.bats tests\isolation.bats
Test-Path %USERPROFILE%\.hermes                                          # False
wsl: test -e /home/fish/.hermes                                          # EXISTS (install)
wsl: bash .workflow/S2-T7/bash-assertions.sh                             # passed=13 failed=0
wsl: numbered demo_session_2.sh under /tmp/crossfire-s2ge.*              # opening_target_source line 1 < Question line 8
wsl: demo_session_1.sh then demo_session_2.sh under /tmp/crossfire-s2ge-s1s2.*
  # PIDs 3265/3266; sess_stub/sess_stub_s2; family=behavioral; LIVE_SKILLS empty
wsl: HERMES_HOME=/home/fish/.hermes source demo_common.sh                 # ISO_RC:1 fail-closed
find /home/fish/.hermes fingerprint                                      # a4a59ff1... unchanged vs S2-T5
# bats not installed; isolation.bats not executed
```

Files read: `.workflow/S2-GE/packets/01-gate.md`, `.workflow/S2-GE/results/test-runner-result.md`, spec §13 / §17, sibling verifier results (S2-T5, S2-T6, S2-T7, S1-T1b), `tests/isolation.bats`, `tests/demo_session_2.bats`, `scripts/demo_session_2.sh`, `scripts/demo_common.sh`, `scripts/stage_candidate_skill.sh`, `docs/hermes-compatibility.md`.

---

## Strongest reason it survives

Independent disposable-home s1→s2 printed `opening_target_source=MEMORY.md` **before** `Question:`, targeted the persisted behavioral weakness with distinct PIDs and session IDs, asserted an empty live skill dir, and left `/home/fish/.hermes` fingerprint identical to S2-T5 while fail-closing `HERMES_HOME=/home/fish/.hermes`.

---

## Machine-readable

```json
{
  "packet_id": "01-gate",
  "task": "S2-GE",
  "verdict": "pass",
  "claim": "survives",
  "gate_model": "cursor-grok-4.6-high-fast",
  "acs_held": [
    "session two targets weak area with no naming prompt",
    "candidate not in live dir at opener; degraded path not required",
    "distinct process and session IDs",
    "tests never mutate real ~/.hermes"
  ],
  "acs_failed": [],
  "evidence_path": ".workflow/S2-GE/results/verifier-result.md",
  "sibling_evidence": [
    ".workflow/S2-T5/results/verifier-result.md",
    ".workflow/S2-T6/results/verifier-result.md",
    ".workflow/S2-T7/results/verifier-result.md",
    ".workflow/S1-T1b/results/verifier-result.md"
  ],
  "opening_target_source_before_question": true,
  "isolation_proven": true,
  "real_hermes_fingerprint": "a4a59ff1362c37eebef70c5d42ffc1996762dccec7033d7aed0b97ed93e71142",
  "queue_marked_done": false,
  "committed": false
}
```
