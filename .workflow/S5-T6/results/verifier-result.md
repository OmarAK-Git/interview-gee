# S5-T6 verifier result

Verdict: **survives**

Claim checked: S5-T6 is done — End session shows Weak and Strong; MEMORY.md topics are `{source} · {family}`, not `q_live` practice gap.

Implementer report was not read. Implementation claims were treated as unevidenced until reproduced from source, Git Bash `tests/practice_jd.sh`, isolated start→answer→end, `kv_parse`, and `UiContractTest`.

## Strongest reason

Independent isolated Git Bash `start` → dashboard `answer` → `end` (temp `HOME` / `HERMES_HOME`, `CROSSFIRE_PRACTICE_STUB=1`, not real `~/.hermes`) emitted `report_weak=behavioral:[action, result]`, `report_strong=`, `report_line=Weak: behavioral:[action, result]`, `report_line=Strong: none`. `kv_parse` of that stdout produced `report_text` containing `Weak:` and `Strong:`. Persist topic in `end()` is `${CROSSFIRE_JD_SOURCE_LABEL:-practice} · ${family}` (`scripts/practice_session.sh:353`); `practice_session.sh` contains no `q_live_01` / `practice gap` string. Missing `MEMORY.md` is the Windows `python3`/fsync host gap, which the verify packet says must not solely refute.

## Acceptance criteria independently confirmed

| AC | Result | Evidence |
| --- | --- | --- |
| 1. End kv includes report_weak, report_strong, and report_text with Weak: and Strong: | **confirmed** | Isolated end stdout (below). Shell emits `report_weak` / `report_strong` / `report_line`; `app/server.py:41-48` joins `report_line` into `report_text`. Independent `kv_parse` of the captured stdout → `report_text="Weak: behavioral:[action, result]\nStrong: none"`. `practice_jd.sh` also PASS on the four report greps. |
| 2. MEMORY.md topic is not q_live_01 practice gap | **confirmed (code; disk unwritten on this host)** | Topic assignment `practice_session.sh:353` is `{label} · {family}`. Loaded state had `CROSSFIRE_JD_SOURCE_LABEL=Project\ Praetor`, family `behavioral` → would persist `Project Praetor · behavioral`. No `practice gap` / `q_live_01` remains in `practice_session.sh`. `MEMORY.md` was not created: persist fsync calls Store-stub `python3` (`Python was not found`); a `py -3` shim still failed `os.fsync` (`OSError: [Errno 9] Bad file descriptor`). Packet: do not fail solely for that host gap when topic code and report kv are proven. Product does not write `q_live_01 practice gap`. |
| 3. UI shows report_text on End | **confirmed** | `app/static/app.js:262-263` `const report = data.report_text \|\| "No assessments this session."; bubble("interviewer", report);`. No `Persisted ${data.persisted_count` in `app.js`. Select-String `report_text` count **1**. `UiContractTest` PASS (`assertIn("report_text")`, `assertNotIn` Persisted template). End JSON field the UI reads is the `kv_parse` join proven in AC1. |

## Commands run (this verifier)

```
Select-String practice_session.sh report_weak → count 1  (line 400)
Select-String app/static/app.js report_text → count 1  (line 262)

Git Bash: command -v python3
  → /c/Users/oalan/AppData/Local/Microsoft/WindowsApps/python3
  → "Python was not found; … Microsoft Store …"

Git Bash: bash tests/practice_jd.sh
  → PASS report_weak / report_strong / report_text Weak / report_text Strong
  → FAIL topic missing source label  (MEMORY.md absent)
  → practice_jd: passed=15 failed=1

Isolated Git Bash start/answer/end (HOME=/tmp/s5t6-verify.*, HERMES_HOME=…/.hermes)
  USING_REAL vs C:\Users\oalan\.hermes: no
  dash: persist_recommended=true
  end rc=0:
    report_weak=behavioral:[action, result]
    report_strong=
    report_line=Weak: behavioral:[action, result]
    report_line=Strong: none
    persisted_count=0
  stderr: Store python3 stub
  MEMORY.md: missing (memories/ dir empty)
  spool q_live_01.yaml exists (question_id only; not used as topic)

py -3 kv_parse(captured end stdout)
  → report_text = "Weak: behavioral:[action, result]\nStrong: none"
  → KV_PARSE_OK

py -3 -m unittest tests.test_memory_view.UiContractTest tests.test_memory_view -v
  → Ran 7 tests in 0.575s  OK

Persist retry with PATH python3 shim → py -3
  → python3 --version Python 3.12.10
  → persist still failed: OSError [Errno 9] Bad file descriptor (fsync)
  → MEMORY.md still missing; persisted_count=0
```

Windows `py -3` HTTP `/api/session/start` used WSL `bash` and mangled the script path (`C:Usersoalaninterview-geescriptspractice_session.sh`). That is a host runner gap, not an End-report defect. AC3 is source-proven; AC1 was proven via Git Bash + `kv_parse`.

## file:line reads

- `scripts/practice_session.sh:17-29` — `end` loads `practice.state` (includes quoted `CROSSFIRE_JD_SOURCE_LABEL`).
- `scripts/practice_session.sh:60` — state writes `CROSSFIRE_JD_SOURCE_LABEL=$(printf '%q' …)`.
- `scripts/practice_session.sh:352-353` — persist topic `${CROSSFIRE_JD_SOURCE_LABEL:-practice} · ${family}` (not question_id, not `practice gap`).
- `scripts/practice_session.sh:384-402` — spool scan → `report_weak` / `report_strong` / `report_line=Weak:` / `report_line=Strong:`.
- `scripts/weakness_memory.sh:179-190` — fsync via `python3` if `command -v python3` (Store stub on this host).
- `scripts/weakness_memory.sh:552-556` — fsync failure deletes tmp and returns 1 (no MEMORY.md).
- `app/server.py:31-48` — `report_line` joined to `report_text`.
- `app/server.py:235-249` — `/api/session/end` returns `kv_parse(out)`.
- `app/static/app.js:256-264` — End click bubbles `data.report_text`.
- `tests/practice_jd.sh:61-84` — dashboard answer + end report greps + MEMORY.md topic checks.
- `tests/test_memory_view.py:103-104` — UI contract `report_text` / not Persisted template.

## Isolation

No command used real `~/.hermes`. Probes set `HOME`/`HERMES_HOME` under `/tmp/s5t6-verify.*`, `/tmp/s5t6-persist.*`, and `C:\Users\oalan\AppData\Local\Temp\s5t6-http-*`. HTTP probe printed `USING_REAL False` vs `C:\Users\oalan\.hermes`.

## What would have refuted (not found)

- `end()` still assigning `topic` from `question_id` or appending `practice gap`.
- End stdout missing `report_weak=` / `report_strong=` / `Weak:` / `Strong:`.
- `kv_parse` dropping `report_line` so UI `data.report_text` is empty.
- End handler still showing only `Persisted ${data.persisted_count}`.
- Product writing `q_live_01 practice gap` into MEMORY.md (cannot hide behind a missing file if the write path still used that string).

## Notes (not used to refute)

- Official `practice_jd.sh` failed 1 check (`topic missing source label`) because MEMORY.md was never written. Packet exception applies.
- The test’s `grep q_live_01 practice gap` on a missing file is vacuous PASS. This verifier did not treat that as proof; topic was checked in source plus loaded label/family.
- Evidence truncate uses `${ev_val:0:180}` (no `...`). Not an AC in the verify packet.
- `report_strong` was empty in the one-weak-answer fixture; `Strong: none` still present.
