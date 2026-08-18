# S2-T7 skeptic-verifier result

**Verdict: pass**

Task-scoped. Treated implementation claims as unevidenced. Did not use `implementer-result.md` as evidence. Ignored Task 9 (risk beat / candidate activation). Did not mark the queue done. Did not commit. Did not install packages. Did not write real `~/.hermes`.

`bats` is absent (`Get-Command bats` empty; WSL `command -v bats` empty). Re-ran Test-Path, `.workflow/S2-T7/bash-assertions.sh`, and independent WSL harness runs under disposable `HERMES_HOME=/tmp/crossfire-s2-verify.*`. Existence checks alone are not a pass.

---

## Claim restated

S2-T7 is done: session two targets the persisted newest weakness with no naming prompt, no loaded candidate (or disclosed degraded path), and no pre-opener search; distinct process and session IDs versus session one; opener prints `opening_target_source`, `weakness_id`, and `source_session_id` before the question; `scripts/demo_session_2.sh` and `tests/demo_session_2.bats` exist.

---

## 1. Existence (Test-Path)

Cwd: `C:\Users\oalan\interview-gee`

```
Test-Path -LiteralPath scripts\demo_session_2.sh -PathType Leaf
True
Test-Path -LiteralPath tests\demo_session_2.bats -PathType Leaf
True
```

Existence alone is not a pass.

---

## 2. Bash-equivalent (bats missing)

Command:

```
wsl.exe -e bash -lc 'cd /mnt/c/Users/oalan/interview-gee && bash .workflow/S2-T7/bash-assertions.sh; echo EXIT:$?'
```

Fresh output:

```
PASS: isolation_real_home
PASS: select_newest_three_fixture
PASS: print_before_question
PASS: candidate_in_live_dir
PASS: distinct_session_id
PASS: distinct_process_id
PASS: opener_cmdline_toolsets
PASS: integration_s1_s2
PASS: live_fail_closed
PASS: demo_session_2_exists
PASS: skill_session_two
PASS: runs_dir_override_preserved
PASS: runs_dir_default_repo
passed=13 failed=0
EXIT:0
```

Coverage mapped to required behaviors:

| Required | Check | Result |
| --- | --- | --- |
| Newest-weakness selection (§9 last_seen desc) | `select_newest_three_fixture` | PASS (`w-b2f32d5ee0be` / product / `sess_c`) |
| Print `opening_target_source` before `Question:` | `print_before_question` | PASS (weak: does not line-order `weakness_id` / `source_session_id`; see §3) |
| Candidate in live dir fails launch | `candidate_in_live_dir` | PASS |
| Isolation fail-closed | `isolation_real_home` | PASS |
| `CROSSFIRE_RUNS_DIR` override preserved | `runs_dir_override_preserved` | PASS |
| Distinct session IDs when equal stubs provided | `distinct_session_id` | PASS |
| Distinct process IDs | `distinct_process_id` | PASS in helper, **gamed** (see §4) |
| No `--resume`; `--toolsets skills`; no `session_search` | `opener_cmdline_toolsets` | PASS |
| `CROSSFIRE_LIVE=1` without Hermes fails closed | `live_fail_closed` | PASS |

Helper caveats (not counted as AC failures; independent runs cover the gaps):

- `print_before_question` only requires `opening_target_source=MEMORY.md` line-number `<` `Question:`, plus attribution text somewhere in the blob.
- `distinct_process_id` launches `bash -c 'export CROSSFIRE_SESSION_ONE_PID=$$; bash demo_session_2.sh'`. Bash execs the last command, so child PID equals parent PID and the harness fail-closes. That is not a session-one vs session-two collision.
- Setup exports `CROSSFIRE_STUB_SESSION_ID=sess_stub_s2`, which session one inherits; `CROSSFIRE_SESSION_ONE_ID=sess_stub` is then a fabricated compare, not a captured s1 id.

---

## 3. Independent print-before-question (manual check)

Disposable `HERMES_HOME` under `/tmp/crossfire-s2-verify.S8yqlK/.crossfire/profiles/test`. Fixture `tests/fixtures/memory-three-weaknesses.md`. Stub opener. Numbered combined stdout/stderr:

```
     1	opening_target_source=MEMORY.md
     2	weakness_id=w-b2f32d5ee0be
     3	family=product
     4	source_session_id=sess_c
     5	target selected by prompt memory; wording generated under stable interviewer procedure
     6	CROSSFIRE_SESSION_TWO_PID=873
     7	CROSSFIRE_SESSION_TWO_ID=sess_stub_s2
     8	Question: For the product decision gap (metric,decision), who is the user, what constraint bound you, what did you decide, and which metric would prove it worked?
    10	session_identifiability: distinct process=873 session=sess_stub_s2 (session_one=unset/sess_one_distinct)
```

Line positions: `pos_src=1 pos_wid=2 pos_sid=4 pos_q=8` → all three required fields **before** `Question:`.

`INDEPENDENT_PRINT_BEFORE_QUESTION: PASS`

Question line does not quote `w-b2f32d5ee0be`. No operator naming prompt (`which weakness` / `name the weakness`).

Spec §13 attribution line is present on line 5.

---

## 4. Independent selection, barrier, isolation, override, distinct IDs

### Newest-weakness total order (§9)

| Case | Selected | Expected |
| --- | --- | --- |
| Three-weakness fixture (last_seen desc) | `w-b2f32d5ee0be` family=product `sess_c` | held |
| Same last_seen, higher `observation_count` | `w-aaaaaaaaaaaa` `sess_tie_b` | held |
| Same last_seen and obs, `weakness_id` asc | `w-aaaaaaaaaaaa` `sess_id_win` | held |

`cat -A` on select output showed real newlines (`MEMORY.md$`), not a collapsed blob.

### Isolation fail-closed

```
iso_status=1
PREFLIGHT FAIL: HERMES_HOME points at real profile: /home/fish/.hermes
```

Held. No write under the real profile.

### Candidate in live dir

Planted `unverified-behavioral-followup/SKILL.md` with `id: crossfire.candidate.behavioral` under isolated live skills.

```
cand_status=1
PREFLIGHT FAIL: candidate skill material found under live skills dir: .../skills/unverified-behavioral-followup/SKILL.md ...
```

Held. Session two did not launch the question path after the barrier.

Flag file: launcher prints if `.crossfire/runs/<run_id>/candidate-excluded.flag` exists; it does not require the flag. Packet: check flag **if present**. Live-dir assert is the blocking barrier.

### `CROSSFIRE_RUNS_DIR` override

```
sourced_CROSSFIRE_RUNS_DIR=/tmp/crossfire-s2-verify.S8yqlK/custom-runs-override
expected=/tmp/crossfire-s2-verify.S8yqlK/custom-runs-override
runs_harness_status=0
```

`demo_common.sh:232` keeps a pre-set value (`${CROSSFIRE_RUNS_DIR:-${REPO_ROOT}/.crossfire/runs}`). Unset default is `${REPO_ROOT}/.crossfire/runs` (`runs_dir_default_repo`). Session two still launched with the override. S2-T5 helpers still present: `crossfire_extract_yaml_from_live_stdout`, `crossfire_normalize_live_proposal`.

### Clean s1 then s2 (no inherited stub id)

`unset CROSSFIRE_STUB_SESSION_ID`. Session one default `sess_stub`; session two default `sess_stub_s2`.

MEMORY.md after s1: `source_session_id: sess_stub`. Session two:

```
opening_target_source=MEMORY.md
weakness_id=w-847d45c82e2b
family=behavioral
source_session_id=sess_stub
...
CROSSFIRE_SESSION_TWO_ID=sess_stub_s2
Question: Tell me about a time a detection you owned was wrong — specifically, what action did you take and what measurable result followed?
session_identifiability: distinct process=954 session=sess_stub_s2 (session_one=unset/sess_stub)
```

Persisted behavioral weakness targeted. Session IDs differ.

Equal IDs fail-closed:

```
equal_ids_status=1
PREFLIGHT FAIL: session two session ID must differ from session one (sess_stub)
```

### Distinct PIDs without exec-last

Parent continues after child (`echo PARENT_STILL_HERE` so bash cannot exec the last command):

```
CROSSFIRE_SESSION_TWO_PID=1308
session_identifiability: distinct process=1308 session=sess_stub_s2 (session_one=1307/sess_stub)
PARENT_STILL_HERE pid=1307
non_exec_status=0
```

Held.

### No pre-opener search (documented-fallback)

Opener cmdline (stub `CROSSFIRE_LOG_CMDLINE_ONLY=1`):

```
hermes chat -Q -q Session-two\ opener.\ ... --max-turns 1 --toolsets skills --skills .../skills/crossfire-interviewer --source tool
```

Contains `--toolsets skills`. Does not contain `session_search` or `--resume`. Packet: omit search-detection if MEMORY.md + candidate exclusion + distinct IDs are proven — those three are proven above. `SESSION_SEARCH_OBSERVABILITY=documented-fallback` in `demo_common.sh`.

### Live skip is not a pass

```
live_status=1
PREFLIGHT FAIL: CROSSFIRE_LIVE=1 but Hermes binary not discoverable (CROSSFIRE_HERMES_DISCOVERY=0)
```

Packet: live `-Q` opener is not required if stub proves selection+print+barrier.

### Real `~/.hermes` unchanged

WSL `/home/fish/.hermes` existed before this run (pre-existing hermes-agent tree). Windows `C:\Users\oalan\.hermes` absent. File fingerprint:

```
STAT_BEFORE=e8afb6ac3f2fa8058ceb2802e746e5ab96a921b882fb2a9804980f8ff7a96c3e  -
STAT_AFTER=e8afb6ac3f2fa8058ceb2802e746e5ab96a921b882fb2a9804980f8ff7a96c3e  -
REAL_HERMES_UNCHANGED: PASS
```

Harness writes stayed under `/tmp/crossfire-s2-verify*` and `/tmp/crossfire-s2-clean*`.

---

## 5. Product files vs spec §9 / §13 (read, not implementer notes)

- `scripts/demo_session_2.sh`: isolate → optional flag print → `crossfire_assert_candidates_excluded_from_live` → `crossfire_print_opener_attribution` → then `crossfire_session_two_ask_opener` (Question).
- `scripts/demo_common.sh`: `crossfire_select_newest_weakness` sorts `last_seen` desc, `observation_count` desc, `weakness_id` asc; prints the three fields; opener cmdline `--toolsets skills` without `--resume`.
- `skills/crossfire-interviewer/SKILL.md`: session-two section matches print-before-question, no naming, `--toolsets skills` only.
- `tests/demo_session_2.bats` exists and encodes the same cases; not executed (`bats` missing; not installed).

Task 9 (candidate activation / risk beat) not evaluated.

---

## Acceptance criteria

| AC | Status |
| --- | --- |
| Automated and manual runs both show session two targeting the persisted weakness | **held** (bash-assertions integration + independent s1→s2 numbered output) |
| No naming prompt, no loaded candidate (or disclosed degraded path), no pre-opener search | **held** |
| Distinct process and session IDs versus session one | **held** (independent clean run; helper process-id check is gamed but product behaves) |
| Opener prints `opening_target_source`, `weakness_id`, and `source_session_id` before the question | **held** (independent line-order: 1, 2, 4 before 8) |
| `scripts/demo_session_2.sh` and `tests/demo_session_2.bats` exist | **held** (not sufficient alone) |

ACs failed: **none**.

---

## Verdict

**pass** — claim survives independent re-runs. Strongest reason: numbered stub opener output prints `opening_target_source=MEMORY.md`, `weakness_id=...`, and `source_session_id=...` on lines 1–4 **before** `Question:` on line 8, and a clean s1→s2 run targets the persisted MEMORY.md weakness with distinct default session IDs (`sess_stub` / `sess_stub_s2`) and distinct PIDs (1307 / 1308), while a live-dir candidate fail-closes launch.

Evidence path: `.workflow/S2-T7/results/verifier-result.md`
