# S1-T1b researcher: Isolation mechanism

**Packet:** `01-research` · **Status:** done · **Date:** 2026-08-16  
**Scope:** this machine only. Hermes binary **unsupported** (S1-T1). Real `~/.hermes` absent on Windows and WSL. Do not install packages. Do not mutate real `~/.hermes`.

Frame: replace the unproven “invoke Hermes and hope `HERMES_HOME` holds” claim with a split that this machine can actually prove — harness isolation now; Hermes write-scope later.

## Verdict

**Chosen path: (d) hybrid.**

- **Isolation mechanism:** `HERMES_HOME` → repo `.crossfire/profiles/test` (same T1 pick). Implement script-level isolation and prove it without a binary.
- **Hermes-invoking automation:** **stopped** until a discoverable binary proves write scope on a throwaway `HERMES_HOME`.

Spec §6 / §15 hard stop is “stop automating **against Hermes**,” not “stop all harness work.” Script-level tests **can** prove that sourcing the isolation env never writes real `~/.hermes` without invoking Hermes. That satisfies Task 1b “automated run leaves real Hermes state unchanged” for **harness scripts**. It does **not** satisfy “Hermes read/write a disposable directory.” Record that split; do not relabel isolation **verified**.

## Chosen paths (JSON)

```json
{
  "packet_id": "01-research",
  "status": "done",
  "chosen_paths": {
    "isolation_mechanism": "hybrid",
    "hermes_invoking_automation": "stopped"
  },
  "open_questions": [
    "After install, does HERMES_HOME=.crossfire/profiles/test bind writes without hermes profile create?",
    "Does Hermes still write $HOME/.hermes unless terminal.home_mode: profile?",
    "Approval-first: install Hermes on WSL before any Hermes-invoking task is unblocked."
  ]
}
```

(`isolation_mechanism` is hybrid rather than `HERMES_HOME` alone: the env override is the mechanism, but proof is split — harness now, binary later.)

## Opportunity cost

| Path | Pick? | Why | Opportunity cost |
| --- | --- | --- | --- |
| **(a) `HERMES_HOME` only** | Reject as *sufficient proof* | T1 already set default `HERMES_HOME` to `.crossfire/profiles/test`. Compatibility row 9 / §15 isolation is still **unsupported**: no binary to prove write scope. Claiming 1b done under (a) would treat public-doc as verified. | Lose honesty on the hard-stop capability. Later S2 E2E would look “isolated” while Hermes might still write `$HOME/.hermes` (`terminal.home_mode` caveat from T1). |
| **(b) copied throwaway `~/.hermes`** | Reject | Plan fallback is only “if no override exists.” Override **exists**. Real profile is **absent**; copying into `$USERPROFILE/.hermes` or `/home/fish/.hermes` **creates** the Monday profile — that is mutating real `~/.hermes`. A copy under `/tmp` or `.crossfire` is just (a) with a worse name. | Risk of creating the operator profile “for a marker.” Confuses Monday vs test. No extra proof vs `HERMES_HOME` until a binary exists. |
| **(c) STOP / hand-script only** | Reject as *total* stop | Spec §6: if tests **cannot** be isolated from real `~/.hermes`. Harness **can**. Full stop would freeze S1-T2 (deterministic merge) and fixture-only S1-T3, which never need a Hermes process. | Waste the 4-hour window on a demo that still cannot run without install, while skipping shippable harness tests. Over-reads “against Hermes” as “against the repo.” |
| **(d) hybrid** | **Choose** | Packet’s own split: prove sourcing isolation never writes real `~/.hermes` **without** invoking Hermes; keep Hermes-invoking tasks stopped until install + proof. Matches T1: “automation against Hermes is not.” Matches queue S1-T1b: if isolation of **Hermes** cannot be achieved, do not implement later Hermes-touching tasks. | S2 E2E (T5–T7) stays blocked; 90s demo cannot ship. Isolation.bats cannot assert “Hermes wrote only under `HERMES_HOME`.” Implementer must document harness-proven vs Hermes-unproven so S1-GE does not inflate the claim. |

**Dead end (not a path):** `/home/fish/crossfire/scripts/start-wsl-isolated.sh` is a different product (`COUNCIL_DATABASE_PATH` / `pnpm start`). Do **not** copy it. This repo **may still add** a Hermes-specific `scripts/start-wsl-isolated.sh` on the allow-list: source `demo_common.sh`, export isolation env, refuse real `~/.hermes`, fail closed if `HERMES_HOME` is the operator profile, **do not** exec `hermes` while the binary is missing.

## What 1b can prove without a binary

Already partly encoded in `tests/preflight.bats` (defaults, path layout, `preflight_check_paths` reject of `*/.hermes`). `isolation.bats` should own the **write-boundary** claims:

| Can prove now | How (never write operator `~/.hermes`) |
| --- | --- |
| Default `HERMES_HOME` is `<repo>/.crossfire/profiles/test`, not Win/WSL real homes | Source `demo_common.sh` with `HERMES_HOME` unset |
| `is_real_hermes_home` / `preflight_check_paths` fail-closed on `$USERPROFILE/.hermes`, `/home/fish/.hermes`, and any `*/.hermes` outside `.crossfire/profiles/` | Env override in the test process only |
| Sourcing isolation env (`demo_common.sh` and Hermes-specific `start-wsl-isolated.sh`) does not **create** real Win or WSL `~/.hermes` | Read-only `test ! -e` before/after; both homes are currently absent |
| A harness write under `HERMES_HOME` does not change a marker in a **fake** “real” home | Plan risk row: fake home or read-only assertions — **not** the operator profile |
| Subsequent scripts that source the isolation helper inherit the disposable `HERMES_HOME` | Source chain in bats |
| `start-wsl-isolated.sh` is Hermes-scoped (no pnpm/council) and does not invoke `hermes` when undiscoverable | File content + fail-closed |

| Cannot prove without a binary | Why |
| --- | --- |
| Hermes reads/writes only the disposable directory | No process to honor or ignore `HERMES_HOME` |
| Marker in **real** `~/.hermes` survives a Hermes run | Creating that marker **is** mutating real `~/.hermes` (forbidden). Fake-home markers are not the operator profile. |
| `HERMES_HOME` works without `hermes profile create` | Open T1 question |
| Host tools stay off `$HOME/.hermes` | T1 public-doc caveat: `terminal.home_mode: profile` unverified |
| Distinct session/process IDs, YAML round-trip, Curator isolation as a running daemon | S1-T1 **unsupported** / documented-fallback |

**Done-when mapping:** “automated run leaves real Hermes state unchanged” = **harness automated run** (source isolation, optional write under `.crossfire/profiles/test`, assert real homes untouched/absent). Do **not** claim spec §15 “Disposable `HERMES_HOME` isolation” is **verified**. Leave it **unsupported** until a binary probe; record hybrid + STOP in `docs/hermes-compatibility.md`.

## Should S2 Hermes-touching tasks be blocked?

**Yes.** Keep **stopped** until install (approval-first) **and** a throwaway-`HERMES_HOME` probe shows Hermes did not touch real `~/.hermes`.

| Item | Block Hermes invoke? | Notes |
| --- | --- | --- |
| **S1-T2** | No | Deterministic shell merge; fixtures; no Hermes process. Must source isolation env; writes only under isolated / fixture paths. |
| **S1-T3** | No *if* fixture/static eval of `SKILL.md` | Do not spawn `hermes` for scoring. If eval would require a live agent, that invocation is stopped (hand-script or defer). |
| **S1-GE** | No | Artifact/existence gate. Must not treat isolation as Hermes-verified. |
| **S2-T5** | **Yes** | AC: “Session one runs against **installed Hermes** in the isolated profile.” |
| **S2-T6** | **Yes** for learning-loop / live skill dir | Harness staging scripts may be sketched without invoke; E2E that waits on Hermes-authored candidates is blocked. |
| **S2-T7 / S2-GE** | **Yes** | Fresh Hermes process + session ID. Demo minimum bar cannot be proven. |
| **S3–S4 Hermes E2E** | **Yes** until the same proof | Includes timed demo, risk beat against a live session, Monday free-form against a real profile (Monday still never written by tests). |

Revisit trigger: `hermes` discoverable on Windows PATH or WSL Ubuntu (`fish`); then one probe with `HERMES_HOME` under `.crossfire/profiles/test` (or another workspace throwaway), **never** the operator home. If the binary ignores `HERMES_HOME`, fall back to (b) only as a **copy of a fixture tree into a disposable directory that is not real `~/.hermes`**, or escalate to (c) for remaining Hermes automation.

## Implementer notes (read-only research)

- Files in scope: `scripts/start-wsl-isolated.sh` (create Hermes-specific; do not port `/home/fish/crossfire`), `scripts/demo_common.sh` (already has `HERMES_HOME`, `is_real_hermes_home`, `preflight_check_paths`), `tests/isolation.bats`, `docs/hermes-compatibility.md`, `memory-bank/`.
- Every later script/test should source the isolation env; 1b documents that contract.
- Never point tests at real `~/.hermes`. Never install Hermes from this task.
- Compatibility doc should state: mechanism = `HERMES_HOME`; harness boundary = to be proven in 1b; Hermes write-scope = still **unsupported**; Hermes-invoking automation = **stopped**.
