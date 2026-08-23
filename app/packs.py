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
