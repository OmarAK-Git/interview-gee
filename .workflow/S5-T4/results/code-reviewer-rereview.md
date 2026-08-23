# S5-T4 code re-review — mid-session temperature after fix

**Packet:** `.workflow/S5-T4/packets/03-review.md` (scoped re-review of Important 1 only)
**Prior review:** `.workflow/S5-T4/results/code-reviewer-result.md`
**Reviewer:** code-reviewer (did not author this code)
**Date:** 2026-08-23
**Scope:** `scripts/practice_session.sh` answer/skip, `tests/practice_jd.sh`
**Constraint:** no real `~/.hermes`; no implementation edits

**Verdict:** `approve`

| Priority | Count |
| --- | --- |
| Critical | 0 |
| Important | 0 |
| Open finding | ADDRESSED |
| Blocking | 0 |

---

## Open finding status

### Important 1 — `load_state` clobbers mid-session temperature — **ADDRESSED**

Prior evidence: start `CROSSFIRE_TEMPERATURE=2` then skip with `CROSSFIRE_TEMPERATURE=4` left `practice.state` at `CROSSFIRE_TEMPERATURE=2`.

Current code captures inbound env before `crossfire_practice_load_state` and restores it after, in both `crossfire_practice_answer` (`practice_session.sh:181-193`) and `crossfire_practice_skip` (`:295-307`). `save_state` then writes the restored value (`:61`).

`tests/practice_jd.sh:58-59` now greps `CROSSFIRE_TEMPERATURE=4` on `$CROSSFIRE_RUNS_DIR/$run_id/practice.state` after the temp=4 skip.

Independent reproduction (Git Bash, stub, `mktemp` HOME / `HERMES_HOME`; real `C:/Users/oalan/.hermes` did not exist before or after):

```
START_TEMP_STATE=CROSSFIRE_TEMPERATURE=2
AFTER_SKIP_UNSET_TEMP_STATE=CROSSFIRE_TEMPERATURE=2
AFTER_SKIP_TEMP_STATE=CROSSFIRE_TEMPERATURE=4
AFTER_SKIP_KEEP4_TEMP_STATE=CROSSFIRE_TEMPERATURE=4
ANSWER_START_TEMP_STATE=CROSSFIRE_TEMPERATURE=2
AFTER_ANSWER_TEMP_STATE=CROSSFIRE_TEMPERATURE=4
SPOOL_YAML_COUNT=0
ANY_YAML_UNDER_RUN=0
REAL_HERMES_EXISTS_BEFORE=no
REAL_HERMES_EXISTS_AFTER=no
HERMES_HOME_IS_ISOLATED=yes
```

Same isolated start (temp=2) then skip (`CROSSFIRE_TEMPERATURE=4`) now leaves `practice.state` at `4`. Skip with inbound unset keeps the saved value (2, then 4). Answer with inbound 4 also persists 4.

---

## New Critical / Important breakage

None.

The preserve/restore does not change skip kv, spool, or isolation. Unset inbound still uses sourced state (not forced default 2 after a later-turn 4).

Unchanged Minors from the first review (header still `start | answer | end` at `:2`; live skip still has no `session_id` guard; preamble checks remain source greps) are not new and do not block this re-review.

---

## Independent checks (not implementer claims)

### Temperature clobber (the open finding)

Isolated stub start (pack praetor, `CROSSFIRE_TEMPERATURE=2`) then:

| Step | Inbound `CROSSFIRE_TEMPERATURE` | `practice.state` |
| --- | --- | --- |
| after start | 2 | `CROSSFIRE_TEMPERATURE=2` |
| skip, `env -u` | unset | `CROSSFIRE_TEMPERATURE=2` |
| skip | 4 | `CROSSFIRE_TEMPERATURE=4` |
| skip, `env -u` | unset | `CROSSFIRE_TEMPERATURE=4` |

Fresh start (temp=2) then answer `"hash-chained ledger"` with inbound 4: `AFTER_ANSWER_TEMP_STATE=CROSSFIRE_TEMPERATURE=4`.

### Skip contract still holds on that run

- `event=skip` `skipped=true` `persist_recommended=false`
- `SPOOL_YAML_COUNT=0` `ANY_YAML_UNDER_RUN=0`

### `practice_jd.sh` this re-review

```
"C:\Program Files\Git\bin\bash.exe" tests/practice_jd.sh
# PASS: skip saved temperature 4
# practice_jd: passed=9 failed=0
```

Suite now fails if the clobber returns (grep is on `practice.state`, not stdout).

### Isolation

`HOME` / `HERMES_HOME` were under `/tmp/crossfire-s5t4-rereview.*`. Real `~/.hermes` was not created.

---

## Verdict

**approve** — Important 1 is ADDRESSED; no new Critical or Important findings.
