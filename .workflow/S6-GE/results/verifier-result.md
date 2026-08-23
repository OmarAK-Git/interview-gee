# S6-GE skeptic-verifier result (in-session Grok gate)

**Verdict: pass**

`gate_model: cursor-grok-4.6-high-fast`

Verify-only. Did not implement. Did not mark the queue done (`S6-GE` remains `verifying`). Did not commit. Did not write real `~/.hermes`. Did not treat implementer, reviewer, or test-runner transcripts as sole proof.

---

## Claim restated

Sprint 6 close-out gate: live practice New session is JD-first; unused demo.sh theater is left alone. Four ACs:

1. S6-T1 is done with verifier evidence.
2. Practice first-question path is JD-owned; MEMORY.md is follow-up bias only.
3. `scripts/demo.sh` and `demo_session_2.sh` were not rewritten.
4. Automated tests do not target real `~/.hermes`.

Packet commands: `targets those missing elements` count in `practice_session.sh` must be 0; `MEMORY.md` count in `demo_session_2.sh` must be >0. Isolation fail-closed still required. Live pass may stay `human_needed`.

---

## Independent evidence (this gate)

### Packet commands (this session)

Cwd: `C:\Users\oalan\interview-gee`

```
Select-String -Path scripts\practice_session.sh -Pattern 'targets those missing elements'
  → Count = 0  (required 0)

Select-String -Path scripts\demo_session_2.sh -Pattern 'MEMORY.md'
  → Count = 1  (required >0)
```

Matches `.workflow/S6-GE/results/test-runner-result.md` (0 and 1). Re-executed here; not trusted from that file alone.

### Demo not rewritten this sprint (this session)

```
git log --since=2026-08-20 --oneline -- scripts/demo.sh scripts/demo_session_2.sh
  → empty (no commits this sprint)

git log -3 --format='%h %ad %s' --date=short -- scripts/demo.sh scripts/demo_session_2.sh
  → f6a2112 2026-08-18 Ship the Crossfire demo through final acceptance.

git diff --stat -- scripts/demo.sh scripts/demo_session_2.sh
  → empty

git status --porcelain -- scripts/demo.sh scripts/demo_session_2.sh
  → empty

git blame -L 25,25 -- scripts/demo_session_2.sh
  → f6a2112d 2026-08-18  opening_target_source="${4:-MEMORY.md}"

git blame -L 172,172 -- scripts/demo.sh
  → f6a2112d 2026-08-18  layer_attribution: opening_target=MEMORY.md
```

### Isolation fail-closed (this session)

Git Bash, `HERMES_HOME=/tmp/evil/.hermes`, source `scripts/demo_common.sh`:

```
PREFLIGHT FAIL: HERMES_HOME points at real profile: /tmp/evil/.hermes
EXIT=1
```

`Test-Path C:\Users\oalan\.hermes` → **False** before and after. `USERPROFILE=C:\Users\oalan`.

### Queue + T1 verdict (read this session)

| Item | Queue status | Evidence path | Verdict line |
| --- | --- | --- | --- |
| S6-T1 | `done` | `.workflow/S6-T1/results/verifier-result.md` | **survives** (`:3`) |
| S6-GE | `verifying` | this file | mid-gate |

S6-T1 reviewer file exists (`code-reviewer-result.md`) with `Verdict: pass`, 0 blocking. Not used as AC1 proof; the skeptic file is.

---

## AC1 — S6-T1 done with verifier evidence

**Result: held**

Queue `S6-T1.status` is `done` (`.workflow/autopilot-queue.json:1259`). Evidence file `.workflow/S6-T1/results/verifier-result.md` exists and records skeptic verdict **survives**, not missing, not `refuted`. All six T1 ACs marked **confirmed** with first-party commands and an isolated MEMORY-present fixture.

Not used as a fail: T1 residual that `tests/practice_jd.sh` exited 2 on this Windows host (`Python was not found` so persist never wrote MEMORY.md). T1 covered that with an isolated fixture; not an S6-GE AC.

---

## AC2 — Practice first-question path is JD-owned; MEMORY.md is follow-up bias only

**Result: held (code + stub). Live Luna not used as proof.**

| Check | Evidence |
| --- | --- |
| Packet grep | `targets those missing elements` count in `scripts/practice_session.sh` = **0** this session. |
| Live start `-q` | `scripts/practice_session.sh:143-144` is `Ask ONE interview question from this JD only. Reply with the question only.` No missing-elements list. |
| Stub start | `:137-139` always the Praetor advisory JD line. Does not call `crossfire_stub_opener_question` or `crossfire_build_opener_cmdline`. |
| Preamble | `:42` first spoken question is a normal in-role JD competency question; MEMORY.md may season follow-ups only. |
| MEMORY selection | `:126-135` still selects newest weakness for **attribution / follow-up state** (`CROSSFIRE_OPENING_TARGET_SOURCE`, `CROSSFIRE_MEMORY_PROBE_USED=0`). Not interpolated into start `-q`. |
| Follow-up bias only | `:236-242` injects `memory_bias` on the first live **answer** turn, then sets `CROSSFIRE_MEMORY_PROBE_USED=1`. Subsequent answers see `!= "1"` fail. |
| Skill | `skills/crossfire-interviewer/SKILL.md:188-200` Practice section wins; first question is this JD, not the newest gap; weaknesses season follow-ups at most once. |
| Design §5 | `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md:95` same JD-first rule. |

Letter-not-intent that did not refute: start still prints `opening_target_source=MEMORY.md` when a weakness exists. Addendum allows attribution kv; the spoken `-q` / stub `question=` is the JD line.

---

## AC3 — demo.sh and demo_session_2.sh were not rewritten

**Result: held**

No working-tree diff. No commits to either file since 2026-08-20 (Sprint 6 window). Last touch remains `f6a2112` (2026-08-18), before this sprint. `demo_session_2.sh:25` still defaults `opening_target_source` to `MEMORY.md` (count 1). `demo.sh:172` still prints `opening_target=MEMORY.md`. Blame on both MEMORY.md lines is `f6a2112d`.

---

## AC4 — Automated tests do not target real ~/.hermes

**Result: held. Isolation fail-closed still present.**

| Check | Evidence |
| --- | --- |
| Practice shell tests | `tests/practice_jd.sh:9-13`, `practice_session_stub.sh` / `practice_inference.sh` remap `HOME=$(mktemp /tmp/crossfire-…)` **then** `mkdir -p "$HOME/.hermes"`. That `.hermes` is under `/tmp`, not `%USERPROFILE%`. |
| Refuse-real test | `tests/practice_home.sh:47-55` exports `HERMES_HOME='/mnt/c/Users/oalan/.hermes'` only to **assert reject**. HOME is already `$tmpdir/wsl-home`. |
| Demo isolation contract | `scripts/demo_common.sh:20-25` still fail-closes `is_real_hermes_home`. Independently reproduced this session (`/tmp/evil/.hermes`, exit 1). `tests/isolation.bats:14-18`, `:116-119` still encode the landmine. |
| Practice Monday allowlist | `scripts/practice_common.sh:65-81` refuses Windows-mounted `.hermes` and any path that is not remapped WSL `$HOME/.hermes`. Product Monday path is not an automated-test target. |
| Real home after this gate | `Test-Path C:\Users\oalan\.hermes` → **False**. |

---

## Attacks that did not refute

- **Stale test-runner file.** Re-ran both packet greps this session; same 0 and 1.
- **T1 “survives” ≠ gate “pass”.** Queue `done` plus non-`refuted` T1 verifier file satisfy AC1. Gate ACs 2–4 were re-probed in current tree and commands.
- **Demo rewritten then reverted.** `git log --since=2026-08-20` on those paths is empty; blame still 2026-08-18.
- **Treat stub Praetor line as live Luna bar.** Not done. Live New-session pass remains `human_needed`.
- **Attribution kv means Q1 is still MEMORY-owned.** Spoken start `-q` has no gap payload; MEMORY is injected on first answer only.
- **Isolation abandoned for practice Monday allowlist.** Fail-closed still fires on `demo_common.sh`. Automated tests override `HOME` first and do not write `%USERPROFILE%\.hermes`.

---

## human_needed residuals

Operator live pass from queue `S6-GE.verification.manual_checks` and packet: **New session with an existing weakness opens on the JD, not the gap.** Not recorded in this sprint. Explicitly allowed to stay `human_needed`.

Also carried, not used as fail:

- `tests/practice_jd.sh` host gap (no Store `python3` → persist does not write MEMORY.md). Isolated fixture covered T1 MEMORY-present start/skip.
- Live Codex / Luna wording is prompt + one-shot env flag, not a gold transcript.

---

## Verdict

**pass.** Strongest reason: this session re-ran the packet greps (0 and 1), confirmed demo.sh / demo_session_2.sh last commit 2026-08-18 with MEMORY.md still present and no sprint diff, reproduced isolation fail-closed without creating `C:\Users\oalan\.hermes`, and read JD-only start `-q` plus answer-turn MEMORY bias in current `practice_session.sh`; S6-T1 is `done` with a `survives` verifier file. Live New-session pass is an explicit `human_needed` residual.
