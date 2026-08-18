# S2-T5 skeptic-verifier result

**Verdict: pass**

Task-scoped. Ignored phase-level gaps (session two, candidate staging). Did not mark the queue done. Did not commit. Did not install packages. Did not treat `implementer-result.md` as evidence.

`bats` is absent (`command -v bats` → `bats-absent`). Ran `.workflow/S2-T5/bash-assertions.sh` plus an independent WSL evidence script. Hermes binary exists at `/home/fish/.local/bin/hermes` but was **not** invoked (stub assessor; live invoke would export `HOME=/home/fish` and risk the real profile).

---

## 1. Existence (Test-Path)

Cwd: `C:\Users\oalan\interview-gee`

```
Test-Path -LiteralPath scripts\demo_session_1.sh -PathType Leaf
True
Test-Path -LiteralPath tests\demo_session_1.bats -PathType Leaf
True
Test-Path -LiteralPath tests\fixtures\demo-answers.txt -PathType Leaf
True
```

Existence alone is not a pass.

---

## 2. Isolation fail-closed (`HERMES_HOME=/home/fish/.hermes`)

Independent re-run (not from implementer notes):

```
isolation_exit=1
isolation_output<<
PREFLIGHT FAIL: HERMES_HOME points at real profile: /home/fish/.hermes
>>isolation_output
```

Held. Source of `scripts/demo_common.sh` fail-closes before any write.

---

## 3. Bash-equivalent covering `tests/demo_session_1.bats`

`bats`: absent. Command:

```
wsl.exe bash /mnt/c/Users/oalan/interview-gee/.workflow/S2-T5/bash-assertions.sh
```

Actual output:

```
PASS: isolation_real_home
PASS: defer_finalize_exit
PASS: spool_before_finalize
PASS: fp_unchanged_before_finalize
PASS: manual_finalize_exit
PASS: manual_finalize_ack
PASS: fp_changed_after_finalize
PASS: harness_exit_0
PASS: three_questions_order
PASS: fixture_answers
PASS: auto_finalize_ack
PASS: spool_under_test_root
PASS: source_session_id
PASS: one_behavioral_weakness
PASS: strong_technical_not_persisted
PASS: strong_product_not_persisted
PASS: no_confirm_prompt
PASS: done_same_finalize_fn
PASS: live_yaml_extract_overlay
PASS: live_shaped_finalize_persist
PASS: toolsets_skills
PASS: toolsets_no_memory
PASS: product_uses_discover
PASS: live_fail_closed
PASS: skill_live_notes
passed=25 failed=0
```

`passed=25 failed=0`

Independent disposable home: `HERMES_HOME=/tmp/crossfire-s1-verify.t6bHOm/.crossfire/profiles/test` (`hermes_home_under_profiles=True`).

### Three §11 questions + fixture answers (defer stdout, `defer_rc=0`)

```
CROSSFIRE_RUN_ID=20260818_134613_0cc7fa
CROSSFIRE q_technical_01 (technical)
Walk through how Praetor decides not to contain. What is the advisory boundary, and how would you know the decision was wrong?
Answer: ... never-contain ... hash-chained audit ledger ...
Assessment buffered for q_technical_01
CROSSFIRE q_behavioral_01 (behavioral)
Tell me about a time a detection you owned was wrong. What did you do, and what changed afterward?
Answer: I just kind of watched the dashboard.
Assessment buffered for q_behavioral_01
CROSSFIRE q_product_01 (product)
For Mastercard Agent Suite (R-281517), how would you sequence rollout when a false positive could freeze a merchant?
Answer: ... false-freeze rate per thousand sessions ...
Assessment buffered for q_product_01
CROSSFIRE: session one buffered (finalize deferred).
```

`q_technical_text=True` `q_behavioral_text=True` `q_product_text=True`

### Spool before MEMORY.md change

```
fp_before=absent:0
fp_mid=absent:0
memory_exists_mid=False
```

Spool files present: `q_technical_01.yaml`, `q_behavioral_01.yaml`, `q_product_01.yaml`.

Behavioral spool: `persist_recommended: true`, `missing_elements: [action, result]`. Technical and product: `persist_recommended: false`, `missing_elements: []`.

### Finalize persists only the bad behavioral answer

```
fin_rc=0
CROSSFIRE: session one finalized; 1 weakness(es) persisted.
fp_after=1787060773:549
weakness_blocks=1
bad_behavioral_in_memory=True
strong_technical_in_memory=False
strong_product_in_memory=False
```

MEMORY.md after finalize contained one `family: behavioral` record, evidence quote `I just kind of watched the dashboard.`, `answer_ref: 20260818_134613_0cc7fa/q_behavioral_01/0`. No never-contain / false-freeze text.

### No confirm prompt

```
confirm_prompt=absent
```

No `[Pp]lease.*confirm` / `[Cc]onfirm.*persist` in defer or finalize stdout.

### `CROSSFIRE_LIVE=1` + `CROSSFIRE_HERMES_DISCOVERY=0` fail-closed

```
live_rc=1
live_output<<
PREFLIGHT FAIL: CROSSFIRE_LIVE=1 but Hermes binary not discoverable (CROSSFIRE_HERMES_DISCOVERY=0)
>>live_output
```

### Skill-shaped live YAML (preamble, no `submitted_answer`) still persists

Raw assessor text had reasoning preamble and a decoy `family:` line; no `submitted_answer`. Overlay injected `submitted_answer` and `source_session_id: sess_live_verify`.

```
liveyaml_rc=0
CROSSFIRE: session one finalized; 1 weakness(es) persisted.
overlay_submitted_answer=True
liveyaml_persisted_bad_answer=True
liveyaml_session_id=True
```

---

## 4. Assessor cmdline `--toolsets skills`; omit memory/file/terminal

Independent `crossfire_build_assessor_cmdline` output:

```
CMDLINE=hermes chat -Q -q Assess\ this\ interview\ Q+A\;\ emit\ propose-only\ YAML\ per\ crossfire-interviewer\ skill. question_id=q_behavioral_01\ family=behavioral\ question=Tell\ me\ about\ a\ time\ answer=I\ just\ kind\ of\ watched\ the\ dashboard. --max-turns 1 --toolsets skills --skills /mnt/c/Users/oalan/interview-gee/skills/crossfire-interviewer --source tool
toolsets_value=skills
has_toolsets_skills=True
has_toolsets_memory=False
has_toolsets_file=False
has_toolsets_terminal=False
```

`--skills` is the skill path flag, not a toolset. Product source: `scripts/demo_common.sh` `crossfire_build_assessor_cmdline` (`--toolsets skills` only).

---

## 5. Tests never mkdir/write real `~/.hermes`

Static (`tests/demo_session_1.bats`): `mkdir` only under disposable `HERMES_HOME` (`${TEST_ROOT}/.crossfire/profiles/test/memories`) and spool dir under `CROSSFIRE_RUNS_DIR`. `/home/fish/.hermes` appears only as a fail-closed `HERMES_HOME` export, not a mkdir target. No `hermes` exec in tests.

Runtime snapshot:

| Path | Before | After |
| --- | --- | --- |
| `C:\Users\oalan\.hermes` | False | False |
| `/home/fish/.hermes` | True (pre-existing) | True |
| sha256 of `find /home/fish/.hermes -printf '%p %s %T@\n' \| sort` | `a4a59ff1362c37eebef70c5d42ffc1996762dccec7033d7aed0b97ed93e71142` | same |

Note: the bats “never mkdir REAL_HERMES” test only fails if a previously **absent** real home appears. `/home/fish/.hermes` already exists, so that bats check would miss in-place mutation. Independent fingerprint comparison showed **no** mutation during this run.

---

## AC mapping

| AC | Result | Evidence |
| --- | --- | --- |
| E2E shows deferred automatic persistence | **held** | Spool written for all three Qs while `MEMORY.md` absent (`fp_before=fp_mid=absent:0`); finalize wrote one weakness with no confirm prompt (`1 weakness(es) persisted`) |
| Session one runs against installed Hermes in the isolated profile | **held** | Session one ran with `HERMES_HOME` under `.crossfire/profiles/` (mktemp tree). Real `/home/fish/.hermes` fail-closed. Live binary not invoked; stub assessor as in bats. `CROSSFIRE_LIVE=1` + discovery disabled fail-closed. Isolated profile use is behavioral, not existence-only |
| Exactly three questions; MEMORY.md unchanged until finalize after the third answer | **held** | Three §11 question strings in order; fixture answers; memory absent until finalize; then one behavioral block |
| No persist confirmation prompt | **held** | `confirm_prompt=absent`; no confirm language in harness stdout |

Failed ACs: **none**.

---

## Isolation check (summary)

- Fail-closed on `HERMES_HOME=/home/fish/.hermes`: exit 1, `PREFLIGHT FAIL: HERMES_HOME points at real profile`.
- Disposable home under `.crossfire/profiles/`.
- Real WSL home fingerprint unchanged; Windows `~\.hermes` still absent.
- Product `mkdir` paths: spool under `CROSSFIRE_RUNS_DIR`, `dirname "$HERMES_MEMORY_MD"` after isolation require, isolated skill dest under `HERMES_SKILLS_DIR`.
