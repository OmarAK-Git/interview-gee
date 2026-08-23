# S5-T1 review package

Untracked implementation files (no prior BASE commit for this task).



===== app/packs.py =====

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
            label = f"{pack['employer']} Â· {pack['role']}"
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



===== tests/test_packs.py =====

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



===== tests/source_packs.sh =====

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



===== skills/crossfire-interviewer/sources/mccain-cyber-defense.md =====

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



===== skills/crossfire-interviewer/sources/mastercard-r-281517.md =====

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



===== skills/crossfire-interviewer/sources/praetor.md =====

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



===== skills/crossfire-interviewer/sources/alter-ego.md =====

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

