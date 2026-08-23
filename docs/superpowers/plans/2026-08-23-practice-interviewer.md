# Practice Interviewer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Live practice sessions require exactly one JD (pack or paste), interview from that JD with temperature and Skip, and end with a strong/weak report plus family-bucket weaknesses — not a transcript.

**Architecture:** Hermes remains the runtime. We add source packs and interviewer procedure in the skill, inject the session JD/persona/temperature into the Hermes prompt (practice already strips `--toolsets`, so the model cannot read pack files at runtime), and keep the practice wrapper as a thin pipe: validate JD, Skip without persist, aggregate the End report. Persist still writes the existing `MEMORY.md` delimited block.

**Tech Stack:** Hermes Agent CLI, bash practice wrapper, Python 3 stdlib UI server (`app/server.py`), vanilla JS/CSS, `unittest` + bash assertion scripts. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md`

## Global Constraints

- Practice path only. Do not change `sparring-1.0.0` demo: three questions, isolation, memory-only opener, no packs/temp/Skip/paste.
- Hermes is the harness. Do not add a competency picker or a second memory store.
- Every new session requires exactly one JD (pick pack or paste). Missing JD must not start.
- Interviewer persona is optional free text. Empty persona is allowed.
- Temperature is 1–5, default 2. Mid-session change applies to the next question only.
- Persist rule unchanged: `persist_recommended` iff `≥ 2` missing elements of one family.
- Practice invokes stay `--max-turns 1`, `--reasoning low`, Codex default `gpt-5.6-luna` via `crossfire_practice_speed_tune`.
- Live path is acceptance. Stub is not proof. Static/no-Hermes contract tests are allowed.
- Do not auto-save a paste into `sources/`.
- Do not invent employer facts beyond the session JD. Shipped packs stay inside spec §4.
- One writer for the weakness block: existing persist path. Skill remains propose-only.

## File structure

| File | Responsibility |
| --- | --- |
| `skills/crossfire-interviewer/sources/*.md` | Four shipped JD packs (facts + competencies). Library only. |
| `app/packs.py` | Parse packs, list packs, slug a paste, normalize temperature, require a session JD. |
| `skills/crossfire-interviewer/SKILL.md` | Add practice interviewer procedure. Leave demo contracts verbatim. |
| `scripts/practice_session.sh` | Inject JD/persona/temp into prompts; `skip` command; persist topic `{source_label} · {family}`; End report kv. Copy `sources/` when installing the skill. |
| `app/server.py` | `GET /api/packs`; start requires JD; skip + temperature on later turns. |
| `app/static/index.html` `app.js` `app.css` | Pick-or-paste, persona, temperature, visible context, Skip, End report. |
| `tests/test_packs.py` | Parser + JD require + temperature. |
| `tests/source_packs.sh` | Four packs parse; cross-pack leak check. |
| `tests/practice_jd.sh` | Wrapper env: no JD fail-closed; skip does not persist. |
| `docs/sparring-1.1.0-practice.md` `README.md` | Practice chrome + live demo notes. |

Do not split `practice_session.sh` in this plan. Do not add a new persist engine.

---

### Task 1: Source packs and parser

**Files:**
- Create: `skills/crossfire-interviewer/sources/mccain-cyber-defense.md`
- Create: `skills/crossfire-interviewer/sources/mastercard-r-281517.md`
- Create: `skills/crossfire-interviewer/sources/praetor.md`
- Create: `skills/crossfire-interviewer/sources/alter-ego.md`
- Create: `app/packs.py`
- Test: `tests/test_packs.py`
- Test: `tests/source_packs.sh`

**Interfaces:**
- Consumes: spec §4 source bullets (McCain / Mastercard R-281517 / Praetor / ALTER_EGO).
- Produces:
  - `PACKS_DIR` default `Path(repo) / "skills/crossfire-interviewer/sources"`
  - `parse_pack_file(path: Path) -> dict` with keys `id`, `employer`, `role`, `requisition`, `families` (`list[str]`), `facts` (`list[str]`), `competencies` (`list[dict]` with `id`, `family`, `band`, `competency`), `context_text` (`str`)
  - `list_source_packs(sources_dir: Path) -> list[dict]`
  - `normalize_temperature(value: str | int | None) -> int` (1–5, default 2; invalid → `ValueError`)
  - `slug_paste(text: str) -> str` (`pasted-<slug>` or `pasted-jd`)
  - `require_session_jd(kind: str | None, pack_id: str | None, paste: str | None, *, sources_dir: Path) -> dict` with `kind`, `source_id`, `source_label`, `context_text`

- [ ] **Step 1: Write the failing Python tests**

Create `tests/test_packs.py`:

```python
#!/usr/bin/env python3
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "app"))

from packs import (  # noqa: E402
    list_source_packs,
    normalize_temperature,
    parse_pack_file,
    require_session_jd,
    slug_paste,
)

SOURCES = ROOT / "skills" / "crossfire-interviewer" / "sources"


class PackFilesTest(unittest.TestCase):
    def test_four_required_packs_exist(self) -> None:
        ids = {p["id"] for p in list_source_packs(SOURCES)}
        self.assertEqual(
            ids,
            {"mccain-cyber-defense", "mastercard-r-281517", "praetor", "alter-ego"},
        )

    def test_mastercard_shape(self) -> None:
        pack = parse_pack_file(SOURCES / "mastercard-r-281517.md")
        self.assertEqual(pack["employer"], "Mastercard")
        self.assertEqual(pack["role"], "Agent Suite PM")
        self.assertEqual(pack["requisition"], "R-281517")
        self.assertIn("product", pack["families"])
        self.assertGreaterEqual(len(pack["competencies"]), 4)
        self.assertLessEqual(len(pack["competencies"]), 6)
        bands = {c["band"] for c in pack["competencies"]}
        self.assertIn("core", bands)
        self.assertIn("edge", bands)
        for c in pack["competencies"]:
            self.assertIn(c["family"], ("behavioral", "technical", "product"))
            self.assertIn(c["band"], ("core", "edge"))
        self.assertTrue(any("R-281517" in f or "Agent Suite" in f for f in pack["facts"]))
        self.assertNotIn("advisory-only", " ".join(pack["facts"]).lower())
        self.assertNotIn("Praetor", pack["context_text"])


class TemperatureAndJdTest(unittest.TestCase):
    def test_temperature_default_and_range(self) -> None:
        self.assertEqual(normalize_temperature(None), 2)
        self.assertEqual(normalize_temperature(""), 2)
        self.assertEqual(normalize_temperature("4"), 4)
        with self.assertRaises(ValueError):
            normalize_temperature("0")
        with self.assertRaises(ValueError):
            normalize_temperature("6")

    def test_require_jd_rejects_missing(self) -> None:
        with self.assertRaises(ValueError):
            require_session_jd(None, None, None, sources_dir=SOURCES)
        with self.assertRaises(ValueError):
            require_session_jd("pack", None, None, sources_dir=SOURCES)
        with self.assertRaises(ValueError):
            require_session_jd("paste", None, "   ", sources_dir=SOURCES)

    def test_require_pack(self) -> None:
        got = require_session_jd("pack", "praetor", None, sources_dir=SOURCES)
        self.assertEqual(got["kind"], "pack")
        self.assertEqual(got["source_id"], "praetor")
        self.assertIn("Praetor", got["source_label"])
        self.assertIn("never-contain", got["context_text"])

    def test_require_paste_slugs_first_line(self) -> None:
        text = "Acme SWE\nBuild the payments API.\n"
        self.assertEqual(slug_paste(text), "pasted-acme-swe")
        got = require_session_jd("paste", None, text, sources_dir=SOURCES)
        self.assertEqual(got["source_id"], "pasted-acme-swe")
        self.assertEqual(got["context_text"], text.strip())
        self.assertEqual(slug_paste(""), "pasted-jd")


if __name__ == "__main__":
    unittest.main()
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python -m unittest tests.test_packs -v`

Expected: FAIL (`ModuleNotFoundError: No module named 'packs'` or missing pack files).

- [ ] **Step 3: Write pack files**

`skills/crossfire-interviewer/sources/mccain-cyber-defense.md`:

```markdown
---
id: mccain-cyber-defense
employer: McCain Foods
role: Cyber Defense Engineer
requisition:
families: behavioral
---

# Allowed facts
- McCain Foods
- Cyber Defense Engineer
- late-stage rounds

# Competencies
| id | family | band | competency |
| --- | --- | --- | --- |
| late-stage-story | behavioral | core | Tell a late-stage McCain Foods Cyber Defense Engineer story with situation, task, action, and result |
| detection-miss | behavioral | core | Own a detection that was wrong: what you did and what changed |
| stakeholder-pressure | behavioral | core | Handle pressure from operators or leadership during a late-stage loop |
| handoff | behavioral | edge | Hand off an unresolved detection at the end of a shift without dropping the ball |
| career-tradeoff | behavioral | edge | Choose to stay in or leave a late-stage process and what that cost |
```

`skills/crossfire-interviewer/sources/mastercard-r-281517.md`:

```markdown
---
id: mastercard-r-281517
employer: Mastercard
role: Agent Suite PM
requisition: R-281517
families: product
---

# Allowed facts
- Mastercard
- Agent Suite
- R-281517
- merchant false-positive freeze risk

# Competencies
| id | family | band | competency |
| --- | --- | --- | --- |
| rollout-sequencing | product | core | Sequence rollout when a false positive could freeze a merchant |
| success-metric | product | core | Define rollout success with user, constraint, decision, and metric |
| user-owner | product | core | Name the primary user and who is on the hook for a freeze |
| canary-vs-ga | product | edge | Choose canary tenants versus general availability under that constraint |
| rollback | product | edge | Decide when to roll back Agent Suite after a false-freeze event |
```

`skills/crossfire-interviewer/sources/praetor.md`:

```markdown
---
id: praetor
employer: Project Praetor
role: LangGraph SOAR disposition engine
requisition:
families: technical
---

# Allowed facts
- Project Praetor
- LangGraph
- SOAR disposition engine
- advisory-only output
- hash-chained audit ledger
- never-contain list

# Competencies
| id | family | band | competency |
| --- | --- | --- | --- |
| advisory-boundary | technical | core | Walk through how Praetor decides not to contain and where the advisory boundary is |
| never-contain | technical | core | Explain how the never-contain list interacts with advisory-only output |
| ledger-verify | technical | core | Verify a disposition using the hash-chained audit ledger |
| tradeoff-downtime | technical | edge | Trade containment speed against downtime risk while staying advisory-only |
| wrong-call | technical | edge | Know a Praetor decision was wrong after the fact |
```

`skills/crossfire-interviewer/sources/alter-ego.md`:

```markdown
---
id: alter-ego
employer: Project ALTER_EGO
role: UEBA behavioral drift detection
requisition:
families: technical,behavioral
---

# Allowed facts
- Project ALTER_EGO
- UEBA
- behavioral drift
- cumulative KL-divergence
- shadow profiles
- freeze-under-suspicion

# Competencies
| id | family | band | competency |
| --- | --- | --- | --- |
| drift-detect | technical | core | Explain how ALTER_EGO uses cumulative KL-divergence and shadow profiles to detect drift |
| freeze-call | technical | core | Walk a freeze-under-suspicion call: problem, approach, tradeoff, verification |
| sensitivity | technical | edge | Trade sensitivity against analyst load on a freeze-under-suspicion decision |
| owned-freeze | behavioral | core | Tell about a freeze-under-suspicion you owned: situation, task, action, result |
| missed-drift | behavioral | edge | A time shadow-profile drift was missed and what changed afterward |
```

- [ ] **Step 4: Write `app/packs.py`**

```python
"""Session JD packs. Stdlib only. Practice UI and tests import this."""
from __future__ import annotations

import re
from pathlib import Path

FAMILIES = frozenset({"behavioral", "technical", "product"})
BANDS = frozenset({"core", "edge"})
REQUIRED_IDS = frozenset(
    {"mccain-cyber-defense", "mastercard-r-281517", "praetor", "alter-ego"}
)


def normalize_temperature(value: str | int | None) -> int:
    if value is None or value == "":
        return 2
    try:
        n = int(value)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"temperature must be 1-5 (got {value!r})") from exc
    if n < 1 or n > 5:
        raise ValueError(f"temperature must be 1-5 (got {value!r})")
    return n


def slug_paste(text: str) -> str:
    first = (text or "").strip().splitlines()[0] if (text or "").strip() else ""
    slug = re.sub(r"[^a-z0-9]+", "-", first.lower()).strip("-")
    if not slug:
        return "pasted-jd"
    return f"pasted-{slug}"[:48].rstrip("-")


def parse_pack_file(path: Path) -> dict:
    raw = path.read_text(encoding="utf-8")
    if not raw.startswith("---"):
        raise ValueError(f"pack missing front matter: {path}")
    parts = raw.split("---", 2)
    if len(parts) < 3:
        raise ValueError(f"pack front matter not closed: {path}")
    meta: dict[str, str] = {}
    for line in parts[1].splitlines():
        if ":" not in line:
            continue
        key, val = line.split(":", 1)
        meta[key.strip()] = val.strip()
    body = parts[2]
    facts: list[str] = []
    competencies: list[dict] = []
    section = ""
    for line in body.splitlines():
        if line.startswith("# Allowed facts"):
            section = "facts"
            continue
        if line.startswith("# Competencies"):
            section = "comp"
            continue
        if section == "facts" and line.startswith("- "):
            facts.append(line[2:].strip())
        if section == "comp" and line.startswith("|") and "family" not in line.lower() and "---" not in line:
            cols = [c.strip() for c in line.strip("|").split("|")]
            if len(cols) >= 4 and cols[0] and cols[0] != "id":
                competencies.append(
                    {
                        "id": cols[0],
                        "family": cols[1],
                        "band": cols[2],
                        "competency": cols[3],
                    }
                )
    families = [f.strip() for f in meta.get("families", "").split(",") if f.strip()]
    for c in competencies:
        if c["family"] not in FAMILIES or c["band"] not in BANDS:
            raise ValueError(f"bad competency in {path}: {c}")
    pack = {
        "id": meta.get("id", ""),
        "employer": meta.get("employer", ""),
        "role": meta.get("role", ""),
        "requisition": meta.get("requisition", ""),
        "families": families,
        "facts": facts,
        "competencies": competencies,
        "context_text": raw.strip(),
    }
    if not pack["id"] or not pack["employer"] or len(competencies) < 4 or len(competencies) > 6:
        raise ValueError(f"invalid pack shape: {path}")
    return pack


def list_source_packs(sources_dir: Path) -> list[dict]:
    packs = [parse_pack_file(p) for p in sorted(sources_dir.glob("*.md"))]
    return packs


def require_session_jd(
    kind: str | None,
    pack_id: str | None,
    paste: str | None,
    *,
    sources_dir: Path,
) -> dict:
    k = (kind or "").strip().lower()
    if k == "pack":
        if not pack_id:
            raise ValueError("pack_id required")
        path = sources_dir / f"{pack_id}.md"
        if not path.is_file():
            raise ValueError(f"unknown pack {pack_id!r}")
        pack = parse_pack_file(path)
        label = pack["employer"]
        if pack["role"]:
            label = f"{pack['employer']} · {pack['role']}"
        return {
            "kind": "pack",
            "source_id": pack["id"],
            "source_label": label,
            "context_text": pack["context_text"],
        }
    if k == "paste":
        text = (paste or "").strip()
        if not text:
            raise ValueError("paste text required")
        sid = slug_paste(text)
        first = text.splitlines()[0].strip()
        return {
            "kind": "paste",
            "source_id": sid,
            "source_label": first or "Pasted JD",
            "context_text": text,
        }
    raise ValueError("jd kind must be pack or paste")
```

- [ ] **Step 5: Write `tests/source_packs.sh` leak check**

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
SRC="$REPO_ROOT/skills/crossfire-interviewer/sources"
pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

for id in mccain-cyber-defense mastercard-r-281517 praetor alter-ego; do
  [ -f "$SRC/$id.md" ] && ok "exists $id" || bad "exists $id"
done

mccain=$(cat "$SRC/mccain-cyber-defense.md")
printf '%s' "$mccain" | grep -qiE 'Praetor|ALTER_EGO|Agent Suite|R-281517|advisory-only|never-contain' \
  && bad "mccain leak" || ok "mccain leak"

mc=$(cat "$SRC/mastercard-r-281517.md")
printf '%s' "$mc" | grep -qiE 'Praetor|ALTER_EGO|McCain|advisory-only|never-contain|KL-divergence' \
  && bad "mastercard leak" || ok "mastercard leak"

pr=$(cat "$SRC/praetor.md")
printf '%s' "$pr" | grep -qiE 'McCain|ALTER_EGO|Agent Suite|R-281517|KL-divergence|shadow profile' \
  && bad "praetor leak" || ok "praetor leak"

ae=$(cat "$SRC/alter-ego.md")
printf '%s' "$ae" | grep -qiE 'McCain|Praetor|Agent Suite|R-281517|advisory-only|never-contain' \
  && bad "alter-ego leak" || ok "alter-ego leak"

echo "source_packs: passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
```

- [ ] **Step 6: Run tests to verify they pass**

Run:

```
python -m unittest tests.test_packs -v
bash tests/source_packs.sh
```

Expected: all PASS, `source_packs: passed=8 failed=0` (4 exists + 4 leak).

- [ ] **Step 7: Commit**

```bash
git add skills/crossfire-interviewer/sources app/packs.py tests/test_packs.py tests/source_packs.sh
git commit -m "Add session JD source packs and a stdlib parser."
```

---

### Task 2: Practice interviewer procedure in the skill

**Files:**
- Modify: `skills/crossfire-interviewer/SKILL.md` (append after Free-form Monday mode; do not edit the demo question table)
- Modify: `scripts/practice_session.sh` `crossfire_practice_ensure_skill` (copy `sources/`)
- Test: `tests/question_bank.bats` already asserts demo IDs in `SKILL.md` — keep those passing
- Test: add assertions to `tests/source_packs.sh` for skill headings

**Interfaces:**
- Consumes: pack files from Task 1 (documentation only; runtime JD is injected in Task 4).
- Produces: skill section titled `## Practice interviewer (session JD)` that Hermes reads when the skill is copied.

- [ ] **Step 1: Write failing skill-heading checks**

Append to `tests/source_packs.sh` before the final echo:

```bash
SKILL="$REPO_ROOT/skills/crossfire-interviewer/SKILL.md"
grep -q '## Practice interviewer (session JD)' "$SKILL" && ok "skill procedure heading" || bad "skill procedure heading"
grep -q 'q_technical_01' "$SKILL" && ok "demo q_technical_01 remains" || bad "demo q_technical_01 remains"
grep -Fq 'Walk through how Praetor decides not to contain' "$SKILL" && ok "demo question verbatim" || bad "demo question verbatim"
grep -q 'temperature' "$SKILL" && ok "skill mentions temperature" || bad "skill mentions temperature"
grep -q 'Skip' "$SKILL" && ok "skill mentions Skip" || bad "skill mentions Skip"
```

- [ ] **Step 2: Run the script to verify new checks fail**

Run: `bash tests/source_packs.sh`

Expected: FAIL `skill procedure heading` (and possibly temperature/Skip). Exists/leak checks still PASS.

- [ ] **Step 3: Append the procedure to `SKILL.md`**

Add this block at the **end** of `skills/crossfire-interviewer/SKILL.md`. Do not edit lines above Free-form Monday mode. Do not change the three demo question strings.

```markdown
## Practice interviewer (session JD)

Use for the practice UI (`sparring-1.1.x`). Demo session-one/two contracts above stay in force when the demo harness is driving. Practice already strips Hermes `--toolsets`; the session JD is in the operator prompt, not read from disk at runtime.

### Session context

The wrapper names exactly one JD for this session (a shipped pack or pasted text), an optional interviewer persona, and a temperature 1–5 (default 2). Interview only that JD. Do not mix facts from another employer or pack. Do not invent systems, metrics, or employers that are not in the session JD.

If `MEMORY.md` has a weakness whose family fits this JD, the first question may target those missing elements. Do not speak `weakness_id`. Do not ask the operator to pick a topic.

Optional persona (job title, what they do, how long they have been there) flavors voice only. Empty persona = default Crossfire interviewer.

### Asking

Ask one question at a time.

- Temperature 1: core competency only; prefer staying on the current story (probe).
- Temperature 2 (default): core competency, typical angle; may open a new core competency after a complete answer.
- Temperature 3–5: edge competency or a rarer in-role angle. Still fact-bound. Not trivia. Not a question that would never appear for this role.

Force a recent real story when the family is behavioral: last time, I not we, a number, what changed. For technical: problem, approach, tradeoff, verification. For product: user, constraint, decision, metric.

### After a real answer

1. Declare exactly one family.
2. `missing_elements` is what was actually absent — not the full checklist.
3. Emit the same propose-only YAML as session one. `persist_recommended: true` only when `count(missing_elements) >= 2`.
4. Then probe the gaps or ask the next question per temperature. Prefer a probe when the answer was thin.

Do not write `MEMORY.md`. Do not ask the operator to confirm persist.

### Skip

If the wrapper says the last question was skipped, do not emit assessment YAML. Ask a different question from the same JD. If they skipped because it sounded invented, stay inside allowed facts.

### End

If the wrapper asks for a closer, one short spoken line is enough. The wrapper owns the strong/weak report. Still do not write `MEMORY.md`.
```

- [ ] **Step 4: Copy `sources/` in `crossfire_practice_ensure_skill`**

In `scripts/practice_session.sh`, replace the body of `crossfire_practice_ensure_skill` with:

```bash
crossfire_practice_ensure_skill() {
  local dest="${HERMES_SKILLS_DIR}/crossfire-interviewer"
  mkdir -p "$dest" "${HERMES_HOME}/memories"
  cp "${CROSSFIRE_SKILL_PATH}/SKILL.md" "${dest}/SKILL.md"
  if [ -f "${CROSSFIRE_SKILL_PATH}/questions.md" ]; then
    cp "${CROSSFIRE_SKILL_PATH}/questions.md" "${dest}/questions.md"
  fi
  if [ -d "${CROSSFIRE_SKILL_PATH}/sources" ]; then
    mkdir -p "${dest}/sources"
    cp "${CROSSFIRE_SKILL_PATH}/sources/"*.md "${dest}/sources/" 2>/dev/null || true
  fi
}
```

- [ ] **Step 5: Run tests**

Run:

```
bash tests/source_packs.sh
python -m unittest tests.test_packs -v
```

If `bats` is installed: `bats tests/question_bank.bats`

Expected: source_packs all PASS including skill headings; question_bank demo tests still PASS.

- [ ] **Step 6: Commit**

```bash
git add skills/crossfire-interviewer/SKILL.md scripts/practice_session.sh tests/source_packs.sh
git commit -m "Teach the practice skill how to interview from one session JD."
```

---

### Task 3: Require one JD on session start

**Files:**
- Modify: `app/server.py` (`do_GET` add `/api/packs`; `do_POST` `/api/session/start` require JD)
- Modify: `scripts/practice_session.sh` `crossfire_practice_start` fail-closed without JD env; persist JD fields in `practice.state`
- Modify: `tests/practice_session_stub.sh` and `tests/practice_inference.sh` so existing stub starts pass a pack
- Test: `tests/test_packs.py` (`start_session_args`); `tests/practice_jd.sh` (wrapper fail-closed)

**Interfaces:**
- Consumes: `require_session_jd`, `normalize_temperature`, `list_source_packs` from `app/packs.py`
- Produces:
  - `GET /api/packs` → `{"packs": [ {id, employer, role, requisition, families} ]}`
  - `POST /api/session/start` JSON: `inference`, `jd_kind` (`pack`|`paste`), `pack_id`, `paste`, `persona`, `temperature`
  - Env into the wrapper: `CROSSFIRE_JD_KIND`, `CROSSFIRE_JD_SOURCE_ID`, `CROSSFIRE_JD_SOURCE_LABEL`, `CROSSFIRE_JD_CONTEXT`, `CROSSFIRE_PERSONA`, `CROSSFIRE_TEMPERATURE`
  - Wrapper start kv: `source_id=`, `source_label=`, `jd_kind=`, `temperature=`
  - Server start JSON: those kv fields plus `context_text` and `persona` from `start_session_args` (do not put the full paste through `kv_parse`)
  - Start without JD: HTTP 400 `{error: ...}` and wrapper `fail_closed` if env missing

- [ ] **Step 1: Write the failing start-args test**

Add `start_session_args(payload: dict, *, sources_dir: Path) -> dict` to `app/packs.py` (Step 3) and test it from `tests/test_packs.py`:

```python
    def test_start_session_args_requires_jd(self) -> None:
        from packs import start_session_args
        with self.assertRaises(ValueError):
            start_session_args({"inference": "nous"}, sources_dir=SOURCES)
        got = start_session_args(
            {"inference": "codex", "jd_kind": "pack", "pack_id": "praetor", "temperature": "3"},
            sources_dir=SOURCES,
        )
        self.assertEqual(got["inference"], "codex")
        self.assertEqual(got["temperature"], 3)
        self.assertEqual(got["source_id"], "praetor")
        self.assertEqual(got["persona"], "")
```

- [ ] **Step 2: Run the new test to verify it fails**

Run: `python -m unittest tests.test_packs.TemperatureAndJdTest.test_start_session_args_requires_jd -v`

Expected: FAIL `ImportError` or `AttributeError: start_session_args`.

- [ ] **Step 3: Implement `start_session_args` and wire the server + wrapper**

Add to `app/packs.py`:

```python
def start_session_args(payload: dict, *, sources_dir: Path) -> dict:
    from inference import normalize_inference

    jd = require_session_jd(
        payload.get("jd_kind"),
        payload.get("pack_id"),
        payload.get("paste"),
        sources_dir=sources_dir,
    )
    return {
        "inference": normalize_inference(payload.get("inference")),
        "temperature": normalize_temperature(payload.get("temperature")),
        "persona": (payload.get("persona") or "").strip(),
        **jd,
    }
```

In `app/server.py`:

- Import `list_source_packs`, `start_session_args` from `packs`.
- `PACKS = REPO_ROOT / "skills" / "crossfire-interviewer" / "sources"`
- In `do_GET`, if `path == "/api/packs"`: return `{"packs": [{k: p[k] for k in ("id","employer","role","requisition","families")} for p in list_source_packs(PACKS)]}`
- In `/api/session/start`, call `start_session_args(payload, sources_dir=PACKS)`. On `ValueError`, HTTP 400. Pass env:

```python
extra_env={
    "CROSSFIRE_INFERENCE": args["inference"],
    "CROSSFIRE_JD_KIND": args["kind"],
    "CROSSFIRE_JD_SOURCE_ID": args["source_id"],
    "CROSSFIRE_JD_SOURCE_LABEL": args["source_label"],
    "CROSSFIRE_JD_CONTEXT": args["context_text"],
    "CROSSFIRE_PERSONA": args["persona"],
    "CROSSFIRE_TEMPERATURE": str(args["temperature"]),
}
```

After a successful start, merge into the JSON response (not only kv): `source_id`, `source_label`, `jd_kind`, `temperature`, `persona`, `context_text`.

In `scripts/practice_session.sh` `crossfire_practice_start`, immediately after `crossfire_require_monday_home`:

```bash
  if [ -z "${CROSSFIRE_JD_KIND:-}" ] || [ -z "${CROSSFIRE_JD_CONTEXT:-}" ]; then
    fail_closed "practice start requires a session JD (pack or paste)"
  fi
  CROSSFIRE_TEMPERATURE="${CROSSFIRE_TEMPERATURE:-2}"
  CROSSFIRE_PERSONA="${CROSSFIRE_PERSONA:-}"
```

Extend `crossfire_practice_save_state` to persist:

```bash
CROSSFIRE_JD_KIND=${CROSSFIRE_JD_KIND:-}
CROSSFIRE_JD_SOURCE_ID=${CROSSFIRE_JD_SOURCE_ID:-}
CROSSFIRE_JD_SOURCE_LABEL=${CROSSFIRE_JD_SOURCE_LABEL:-}
CROSSFIRE_TEMPERATURE=${CROSSFIRE_TEMPERATURE:-2}
CROSSFIRE_PERSONA=${CROSSFIRE_PERSONA:-}
```

Write `"${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/jd-context.md"` from `CROSSFIRE_JD_CONTEXT`.

Emit kv: `source_id`, `source_label`, `jd_kind`, `temperature`.

Update stub starts in `tests/practice_session_stub.sh` and `tests/practice_inference.sh` by adding:

```bash
CROSSFIRE_JD_KIND=pack \
CROSSFIRE_JD_SOURCE_ID=praetor \
CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only never-contain' \
```

to every `practice_session.sh start` invocation.

- [ ] **Step 4: Add a bash fail-closed check**

Create `tests/practice_jd.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

home=$(mktemp -d /tmp/crossfire-practice-jd.XXXXXX)
trap 'rm -rf "$home"' EXIT
export HOME="$home"
mkdir -p "$HOME/.hermes"
export HERMES_HOME="$HOME/.hermes"
export CROSSFIRE_PRACTICE_STUB=1
export CROSSFIRE_RUNS_DIR="$home/runs"

if HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  bash "$REPO_ROOT/scripts/practice_session.sh" start >/tmp/jd-start.out 2>/tmp/jd-start.err; then
  bad "start without JD should fail"
else
  ok "start without JD fail-closed"
fi

start_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  CROSSFIRE_JD_KIND=pack \
  CROSSFIRE_JD_SOURCE_ID=praetor \
  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only' \
  CROSSFIRE_TEMPERATURE=2 \
  bash "$REPO_ROOT/scripts/practice_session.sh" start) || {
  bad "start with pack failed"
  echo "$start_out"
  echo "practice_jd: passed=$pass failed=$fail"
  exit 1
}
echo "$start_out" | grep -q 'source_id=praetor' && ok "source_id printed" || bad "source_id printed"
echo "$start_out" | grep -q 'temperature=2' && ok "temperature printed" || bad "temperature printed"

echo "practice_jd: passed=$pass failed=$fail"
[ "$fail" -eq 0 ]
```

- [ ] **Step 5: Run tests**

Run:

```
python -m unittest tests.test_packs tests.test_memory_view -v
bash tests/practice_jd.sh
bash tests/practice_session_stub.sh
bash tests/practice_inference.sh
```

Expected: all PASS. Start without JD fail-closed. Stub starts still work with pack env.

- [ ] **Step 6: Commit**

```bash
git add app/packs.py app/server.py scripts/practice_session.sh tests/test_packs.py tests/practice_jd.sh tests/practice_session_stub.sh tests/practice_inference.sh
git commit -m "Require exactly one job description before a practice session starts."
```

---

### Task 4: Prompt injection, temperature on later turns, Skip

**Files:**
- Modify: `scripts/practice_session.sh` (start/answer prompts; add `skip` command)
- Modify: `app/server.py` (`POST /api/session/skip`; pass `CROSSFIRE_TEMPERATURE` on answer/skip)
- Test: `tests/practice_jd.sh` (extend)

**Interfaces:**
- Consumes: `CROSSFIRE_JD_CONTEXT`, `CROSSFIRE_PERSONA`, `CROSSFIRE_TEMPERATURE`, `CROSSFIRE_JD_SOURCE_LABEL` from Task 3; `crossfire_practice_speed_tune` already forces `--max-turns 1` and `--reasoning low`.
- Produces:
  - `crossfire_practice_interviewer_preamble` — text block injected into every `-q`
  - `practice_session.sh skip` — no spool write, no persist; asks another question
  - `POST /api/session/skip` body `{temperature?: int}` → same kv as answer (`question`, `tts_text`) plus `assessment_status=skipped` and `skipped=true`
  - Answer POST may include `temperature`; server exports `CROSSFIRE_TEMPERATURE` and updates `practice.state`

- [ ] **Step 1: Write failing Skip/preamble checks**

Append to `tests/practice_jd.sh` after a successful start (reuse `run_id` from `start_out`):

```bash
run_id=$(echo "$start_out" | awk -F= '/^run_id=/{print $2; exit}')

grep -q 'crossfire_practice_interviewer_preamble' "$REPO_ROOT/scripts/practice_session.sh" \
  && ok "preamble helper exists" || bad "preamble helper exists"
grep -q 'Practice session JD' "$REPO_ROOT/scripts/practice_session.sh" \
  && ok "prompt names session JD" || bad "prompt names session JD"

skip_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run_id" \
  CROSSFIRE_TEMPERATURE=4 \
  bash "$REPO_ROOT/scripts/practice_session.sh" skip) || {
  bad "skip command failed: $skip_out"
}
echo "$skip_out" | grep -q 'skipped=true' && ok "skip kv" || bad "skip kv: $skip_out"
echo "$skip_out" | grep -q 'persist_recommended=false' && ok "skip no persist" || bad "skip persist"
spool_count=$(find "$CROSSFIRE_RUNS_DIR/$run_id/spool" -name '*.yaml' 2>/dev/null | wc -l | tr -d ' ')
[ "$spool_count" = "0" ] && ok "skip wrote no spool" || bad "skip wrote spool ($spool_count)"
```

- [ ] **Step 2: Run `bash tests/practice_jd.sh`**

Expected: FAIL `preamble helper exists` / `skip command failed`.

- [ ] **Step 3: Implement preamble, rewrite prompts, add skip**

Add to `scripts/practice_session.sh`:

```bash
crossfire_practice_interviewer_preamble() {
  cat <<EOF
You are the Crossfire interviewer for a practice session.
Practice session JD (only allowed facts):
${CROSSFIRE_JD_CONTEXT}

Source: ${CROSSFIRE_JD_SOURCE_LABEL} (${CROSSFIRE_JD_SOURCE_ID})
Temperature: ${CROSSFIRE_TEMPERATURE:-2} (1=stay on story/core; 2=typical core; 3-5=rarer in-role, still in this JD).
Interviewer persona (optional, flavor only): ${CROSSFIRE_PERSONA:-}
Follow the Practice interviewer (session JD) section of the crossfire-interviewer skill.
Do not invent employers or systems that are not in the session JD.
Do not write MEMORY.md.
EOF
}
```

Replace the start `-q` string (non-stub, non-memory-opener branch) with:

```bash
      prompt="$(crossfire_practice_interviewer_preamble)
Ask ONE interview question from this JD only. Reply with the question only."
      cmdline="hermes chat -Q --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "${HERMES_SKILLS_DIR}/crossfire-interviewer") --source tool -q $(printf '%q' "$prompt")"
```

(`crossfire_practice_inject_inference` will force `--max-turns 1` and `--reasoning low` and strip toolsets.)

Memory-opener branch (`target_source=MEMORY.md`): do **not** call `crossfire_build_opener_cmdline` as-is (it does not know about the session JD). Build the same `hermes chat -Q` command as the fresh-start branch, with `-q` set to:

```bash
      prompt="$(crossfire_practice_interviewer_preamble)
Session-two style opener. opening_target_source=MEMORY.md weakness_id=${CROSSFIRE_OPENER_WEAKNESS_ID} family=${CROSSFIRE_OPENER_FAMILY} missing_elements=[${CROSSFIRE_OPENER_MISSING_CSV}]. Ask ONE question that targets those missing elements and stays inside this session JD. Do not name weakness_id. Reply with the question only."
```

Keep printing opener attribution kv as today.

Replace the answer `-q` with:

```bash
    prompt="$(crossfire_practice_interviewer_preamble)
Operator answer: ${answer}

Assess against exactly one family checklist. missing_elements = what was actually absent, not the full checklist. Emit propose-only YAML (family, missing_elements, evidence, persist_recommended) then ask ONE follow-up interview question per temperature. One model pass. Do not ask the operator to confirm persistence. Do not write MEMORY.md."
    cmdline="hermes chat -Q --resume $(printf '%q' "$CROSSFIRE_SESSION_ID") --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "$skill") --source tool -q $(printf '%q' "$prompt")"
```

Add `crossfire_practice_skip`:

```bash
crossfire_practice_skip() {
  local stdout stderr question
  : "${CROSSFIRE_RUN_ID:?}"
  crossfire_practice_load_state
  CROSSFIRE_INFERENCE=$(crossfire_practice_resolve_inference)
  export CROSSFIRE_INFERENCE
  CROSSFIRE_TEMPERATURE="${CROSSFIRE_TEMPERATURE:-2}"
  crossfire_require_monday_home
  [ -n "${CROSSFIRE_JD_CONTEXT:-}" ] || fail_closed "skip requires a session JD"

  if [ "${CROSSFIRE_PRACTICE_STUB:-0}" = "1" ]; then
    question="Different question from the same JD — what tradeoff did you accept?"
  else
    stdout=$(mktemp)
    stderr=$(mktemp)
    prompt="$(crossfire_practice_interviewer_preamble)
The operator skipped the last question (it may have sounded invented). Do not emit assessment YAML. Ask ONE different interview question from the same JD only. Reply with the question only."
    cmdline="hermes chat -Q --resume $(printf '%q' "$CROSSFIRE_SESSION_ID") --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "${HERMES_SKILLS_DIR}/crossfire-interviewer") --source tool -q $(printf '%q' "$prompt")"
    cmdline=$(crossfire_practice_inject_inference "$cmdline")
    if ! crossfire_hermes_invoke "$cmdline" "$stdout" "$stderr"; then
      question="I will stay inside this job description. What problem were you solving, and how did you verify it?"
    else
      question=$(crossfire_extract_spoken_question "$(cat "$stdout")")
      [ -n "$question" ] || question="Same JD, different angle: what would make this decision wrong?"
    fi
    rm -f "$stdout" "$stderr"
  fi
  crossfire_practice_save_state
  crossfire_practice_append_transcript "interviewer" "(skipped previous) $question"
  crossfire_practice_kv event skip
  crossfire_practice_kv skipped true
  crossfire_practice_kv assessment_status skipped
  crossfire_practice_kv persist_recommended false
  crossfire_practice_kv question "$question"
  crossfire_practice_kv tts_text "$question"
}
```

Add `skip)` to the `case` at the bottom.

In `app/server.py` `/api/session/answer`, read `temperature` from payload if present, `normalize_temperature`, export `CROSSFIRE_TEMPERATURE`.

Add `/api/session/skip` mirroring answer (requires `SESSION["run_id"]`), calling `run_practice(["skip"], extra_env={..., CROSSFIRE_TEMPERATURE})`.

On answer/skip, update saved state temperature by exporting it before the script `save_state`.

- [ ] **Step 4: Run tests**

```
bash tests/practice_jd.sh
bash tests/practice_session_stub.sh
```

Expected: PASS including skip kv and no spool file.

- [ ] **Step 5: Commit**

```bash
git add scripts/practice_session.sh app/server.py tests/practice_jd.sh
git commit -m "Inject the session JD into Hermes turns and add Skip without persist."
```

---

### Task 5: Practice UI chrome

**Files:**
- Modify: `app/static/index.html`
- Modify: `app/static/app.js`
- Modify: `app/static/app.css`
- Test: `tests/test_memory_view.py` `UiContractTest` / `HttpSmokeTest`

**Interfaces:**
- Consumes: `GET /api/packs`, `POST /api/session/start` body from Task 3, `POST /api/session/skip` from Task 4
- Produces: operator can pick a pack or paste a JD, optional persona, temperature 1–5 (default 2), see context before/after start, Skip next to Send, mid-session temperature used on the next Send/Skip

- [ ] **Step 1: Extend UI contract tests (fail first)**

In `tests/test_memory_view.py` `UiContractTest.test_enter_sends_and_mic_exists`, add:

```python
        self.assertIn('id="jd-kind"', html)
        self.assertIn('id="pack-id"', html)
        self.assertIn('id="jd-paste"', html)
        self.assertIn('id="persona"', html)
        self.assertIn('id="temperature"', html)
        self.assertIn('id="jd-context"', html)
        self.assertIn('id="skip"', html)
        self.assertIn("/api/packs", js)
        self.assertIn("jd_kind", js)
        self.assertIn("/api/session/skip", js)
```

- [ ] **Step 2: Run `python -m unittest tests.test_memory_view.UiContractTest -v`**

Expected: FAIL on `id="jd-kind"`.

- [ ] **Step 3: Update HTML**

In `app/static/index.html`, inside `<header>` after `#meta`, add:

```html
    <div id="session-setup" class="setup">
      <label>JD
        <select id="jd-kind">
          <option value="pack">Shipped pack</option>
          <option value="paste">Paste</option>
        </select>
      </label>
      <label id="pack-wrap">Pack
        <select id="pack-id"></select>
      </label>
      <label id="paste-wrap" hidden>Paste JD
        <textarea id="jd-paste" rows="4" placeholder="Paste one job description for this session"></textarea>
      </label>
      <label>Persona (optional)
        <input id="persona" type="text" placeholder="e.g. Staff detection engineer, 8 years, late-stage loop" />
      </label>
      <label>Temperature
        <input id="temperature" type="range" min="1" max="5" value="2" />
        <span id="temperature-val">2</span>
      </label>
    </div>
    <div id="jd-context" class="context" hidden></div>
```

In the composer row, after Send:

```html
        <button type="button" id="skip">Skip</button>
```

- [ ] **Step 4: Update JS**

In `app/static/app.js`:

- On load, `api("/api/packs")` and fill `#pack-id` options with `p.id` / `${p.employer} · ${p.role}`.
- Toggle `#pack-wrap` / `#paste-wrap` from `#jd-kind`.
- `#temperature` input updates `#temperature-val`.
- `start` body:

```javascript
{
  inference: selectedInference(),
  jd_kind: document.getElementById("jd-kind").value,
  pack_id: document.getElementById("pack-id").value,
  paste: document.getElementById("jd-paste").value,
  persona: document.getElementById("persona").value,
  temperature: document.getElementById("temperature").value,
}
```

- After start, show `#jd-context` with `data.context_text` (textContent, scrollable). Show `source_label` and temperature in `showMeta`.
- `setBusy` also disables `#skip`.
- Skip button: `api("/api/session/skip", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ temperature: document.getElementById("temperature").value }) })` then bubble the new question with class `skipped`. Do not send the textarea.
- Answer POST includes `temperature` from the live slider.
- If start returns 400, `bubble("interviewer", data.error || "Need a job description")` — wrap `api()` errors so the operator sees the message.

- [ ] **Step 5: Minimal CSS**

Append to `app/static/app.css`:

```css
.setup { display: flex; flex-wrap: wrap; gap: 0.75rem; margin-top: 0.75rem; align-items: flex-end; }
.setup label { color: var(--muted); font-size: 0.85rem; display: flex; flex-direction: column; gap: 0.25rem; }
.setup input, .setup select, .setup textarea {
  background: var(--panel); color: var(--ink); border: 1px solid #2a3140; border-radius: 8px; padding: 0.3rem 0.45rem;
}
.context {
  max-height: 8rem; overflow: auto; white-space: pre-wrap;
  background: var(--panel); border-radius: 8px; padding: 0.6rem; margin-top: 0.6rem; font-size: 0.85rem; color: var(--muted);
}
```

- [ ] **Step 6: Run UI tests**

```
python -m unittest tests.test_memory_view -v
```

Expected: PASS, including `id="skip"` and `/api/packs`.

- [ ] **Step 7: Commit**

```bash
git add app/static/index.html app/static/app.js app/static/app.css tests/test_memory_view.py
git commit -m "Add pick-or-paste JD, persona, temperature, and Skip to the practice UI."
```

---

### Task 6: Close-out report and family buckets

**Files:**
- Modify: `scripts/practice_session.sh` `crossfire_practice_end` (topic, short quote, report kv)
- Modify: `app/server.py` end response passthrough
- Modify: `app/static/app.js` End bubble
- Test: `tests/practice_jd.sh` (extend with dashboard answer + end)

**Interfaces:**
- Consumes: `CROSSFIRE_JD_SOURCE_ID`, `CROSSFIRE_JD_SOURCE_LABEL` from Task 3; spool YAML already written on answer.
- Produces:
  - Persist `topic` = `${CROSSFIRE_JD_SOURCE_LABEL} · ${family}` (never `q_live_01 practice gap`)
  - `topic_key` via existing `crossfire_normalize_topic_key` so the same source+family merges
  - Evidence value truncated to 180 characters (do not persist the full `submitted_answer` as the quote)
  - End kv: `report_weak=` and `report_strong=` as semicolon-separated `family:missing` / `family` items, plus `report_text=` a two-block plain report
  - UI shows `report_text` instead of only `Persisted N`

- [ ] **Step 1: Write failing close-out checks**

Append to `tests/practice_jd.sh` (new start+dashboard+end, or continue after skip with a dashboard answer):

```bash
dash_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run_id" \
  bash "$REPO_ROOT/scripts/practice_session.sh" answer "I just kind of watched the dashboard.")
echo "$dash_out" | grep -q 'persist_recommended=true' && ok "dash persist rec" || bad "dash persist rec"

end_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run_id" \
  bash "$REPO_ROOT/scripts/practice_session.sh" end) || {
  bad "end failed: $end_out"
}
echo "$end_out" | grep -q 'report_weak=' && ok "report_weak kv" || bad "report_weak kv: $end_out"
echo "$end_out" | grep -q 'report_strong=' && ok "report_strong kv" || bad "report_strong"
echo "$end_out" | grep -q 'Weak:' && ok "report_text Weak" || bad "report_text Weak: $end_out"
echo "$end_out" | grep -q 'Strong:' && ok "report_text Strong" || bad "report_text Strong"
if grep -q 'q_live_01 practice gap' "$HERMES_HOME/memories/MEMORY.md"; then
  bad "old practice-gap topic"
else
  ok "no q_live practice-gap topic"
fi
if grep -q 'Project Praetor' "$HERMES_HOME/memories/MEMORY.md" || grep -q 'praetor' "$HERMES_HOME/memories/MEMORY.md"; then
  ok "topic uses source label"
else
  bad "topic missing source label"
fi
```

Also add to `UiContractTest`:

```python
        self.assertIn("report_text", js)
        self.assertNotIn("Persisted ${data.persisted_count", js)
```

- [ ] **Step 2: Run tests to verify they fail**

```
bash tests/practice_jd.sh
python -m unittest tests.test_memory_view.UiContractTest -v
```

Expected: FAIL `report_weak kv` and/or `Persisted ${data.persisted_count`.

- [ ] **Step 3: Change persist topic + evidence + report**

In `crossfire_practice_end`, replace topic assignment:

```bash
    family=$(crossfire_spool_field "$f" family)
    topic="${CROSSFIRE_JD_SOURCE_LABEL:-practice} · ${family}"
```

Do **not** use `question_id` or append `practice gap`.

Truncate evidence:

```bash
    ev_val=$(awk '/^evidence:/{getline; getline; if ($0 ~ /value:/) {sub(/^  value: /,""); gsub(/^"/,""); gsub(/"$/,""); print; exit}}' "$f")
    if [ ${#ev_val} -gt 180 ]; then
      ev_val="${ev_val:0:177}..."
    fi
```

Pass that `ev_val` into `crossfire_persist_weakness`. Do not pass the full submitted answer as `evidence_value`. `submitted_answer` may still be the 10th arg for schema, but evidence.value must stay short.

Before emitting `ack=ok`, scan spool:

```bash
  weak=""
  strong=""
  for f in "${spool_dir}"/*.yaml; do
    [ -f "$f" ] || continue
    fam=$(crossfire_spool_field "$f" family)
    miss=$(crossfire_spool_field "$f" missing_elements)
    if crossfire_spool_should_persist "$f"; then
      weak="${weak};${fam}:${miss}"
    else
      strong="${strong};${fam}"
    fi
  done
  weak="${weak#;}"
  strong="${strong#;}"
  report_text="Weak: ${weak:-none}
Strong: ${strong:-none}"
  crossfire_practice_kv report_weak "$weak"
  crossfire_practice_kv report_strong "$strong"
  printf '%s\n' "$report_text" | sed 's/^/report_line=/'
```

Replace `kv_parse` in `app/server.py` with:

```python
def kv_parse(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    attr_lines: list[str] = []
    report_lines: list[str] = []
    for line in text.splitlines():
        if "=" not in line:
            continue
        key, val = line.split("=", 1)
        if key == "attribution_line":
            attr_lines.append(val)
        elif key == "report_line":
            report_lines.append(val)
        else:
            out[key] = val
    if attr_lines:
        out["attribution"] = "\n".join(attr_lines)
    if report_lines:
        out["report_text"] = "\n".join(report_lines)
    return out
```

In `app/static/app.js` End handler:

```javascript
  const report = data.report_text || "No assessments this session.";
  bubble("interviewer", report);
```

Remove the `Persisted ${data.persisted_count}` sentence (count may appear inside the report if you want: do not make it the only line).

- [ ] **Step 4: Run tests**

```
bash tests/practice_jd.sh
bash tests/practice_session_stub.sh
python -m unittest tests.test_memory_view tests.test_packs -v
```

Expected: PASS. MEMORY.md topic is `{label} · {family}`. End JSON has `report_text` with Weak and Strong.

- [ ] **Step 5: Commit**

```bash
git add scripts/practice_session.sh app/server.py app/static/app.js tests/practice_jd.sh tests/test_memory_view.py
git commit -m "Replace practice-gap transcripts with family buckets and an end report."
```

---

### Task 7: Docs and live demo pass

**Files:**
- Modify: `docs/sparring-1.1.0-practice.md`
- Modify: `README.md` (practice UI section)
- Modify: `docs/superpowers/specs/2026-08-23-practice-interviewer-design.md` status line to `implemented` only after the live pass
- Test: live session (no stub)

**Interfaces:**
- Consumes: Tasks 1–6 working on Monday `HERMES_HOME` with Codex/Luna.
- Produces: operator-facing notes; recorded live checklist.

- [ ] **Step 1: Update `docs/sparring-1.1.0-practice.md`**

Add a section **Session JD (required)**:

```markdown
## Session JD (required)

Every New session needs exactly one job description: pick a shipped pack under `skills/crossfire-interviewer/sources/` or paste JD text. Optional persona flavors interviewer voice. Temperature 1–5 (default 2) changes the next question only. Skip asks again without assessing.

End session shows Weak and Strong for this session. The right panel shows merged family buckets (`{source} · {family}`), not `q_live_N practice gap` transcripts.

Practice invokes remain `--max-turns 1`, `--reasoning low`, Codex default `gpt-5.6-luna`.
```

Remove any implication that start can run with no JD.

- [ ] **Step 2: Update README practice UI bullets**

Add: required JD (pack or paste), optional persona, temperature, Skip, End report. Point at the design spec.

- [ ] **Step 3: Run static + contract suite**

```
python -m unittest tests.test_packs tests.test_memory_view -v
bash tests/source_packs.sh
bash tests/practice_jd.sh
bash tests/practice_session_stub.sh
bash tests/practice_inference.sh
```

Expected: all PASS.

- [ ] **Step 4: Live demo (acceptance)**

On the practice UI, Codex / Luna:

1. New session with pack `praetor`, empty persona, temperature 2. Context visible. First question stays in Praetor facts.
2. Answer thinly. Next question probes or stays in-role.
3. Move temperature to 4. Next question is a rarer Praetor angle, not Mastercard/ALTER_EGO.
4. Skip once. No new weakness from the skipped question.
5. Answer well on one family (strong) and poorly on another (weak).
6. End. Report lists Weak and Strong. Panel title is `Project Praetor · …`, tags are only missing elements, quote is short.
7. New session, **paste** a different JD. Questions do not leak Praetor tokens. Persona optional fill once to confirm voice flavor.

If a live turn is slow, do not raise `--max-turns`. The wait is one `hermes chat -Q`. Record outcomes in `tests/interactive_smoke.md` (append a dated “practice JD” section).

- [ ] **Step 5: Commit**

```bash
git add docs/sparring-1.1.0-practice.md README.md tests/interactive_smoke.md docs/superpowers/specs/2026-08-23-practice-interviewer-design.md
git commit -m "Document one-JD practice sessions and record the live close-out pass."
```

---

## Self-review (plan vs spec)

| Spec section | Task |
| --- | --- |
| §2 Runtime / no second memory | Global + Tasks 3–6 pipe only |
| §2 Session JD required / paste in scope | Tasks 1, 3, 5 |
| §2 Persona optional | Tasks 3, 5 |
| §2 Temperature 1–5 default 2, next question | Tasks 3, 4, 5 |
| §2 Skip | Task 4, 5 |
| §2 Close-out report + buckets | Task 6 |
| §2 Demo 1.0.0 untouched | Task 2 append-only; no demo script edits |
| §2 Persist ≥2 | Unchanged; Task 6 only changes topic/quote/report |
| §2 Luna / max-turns 1 / reasoning low | Already injected; Task 4 keeps `inject_inference` |
| §2 Live acceptance | Task 7 |
| §4 Packs + no tail scripts | Task 1 |
| §5 Visible context | Tasks 3, 5 |
| §6 Procedure | Task 2 |
| §8 UI chrome | Task 5 |
| §9 Missing JD / skip invention | Tasks 3, 4 |
| §11 No auto-save paste | No save-pack task |
