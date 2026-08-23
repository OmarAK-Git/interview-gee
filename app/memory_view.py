"""Parse MEMORY.md weakness YAML into user-facing records. On-disk format is unchanged."""
from __future__ import annotations

import ast
import re
from typing import Any

from report import format_weakness_why

START = "<!-- CROSSFIRE-WEAKNESSES:START -->"
END = "<!-- CROSSFIRE-WEAKNESSES:END -->"

# Fields the UI should not dump as YAML.
_DROP = frozenset(
    {
        "weakness_id",
        "topic_key",
        "answer_ref",
        "source_session_id",
        "first_seen",
    }
)


def parse_weaknesses(text: str) -> list[dict[str, Any]]:
    block = _extract_block(text)
    if not block:
        return []
    records: list[dict[str, Any]] = []
    current: dict[str, Any] | None = None
    in_evidence = False
    for raw in block.splitlines():
        if re.match(r"^\s*-\s+\w", raw):
            if current:
                records.append(_public(current))
            current = {}
            in_evidence = False
            rest = raw.split("-", 1)[1].strip()
            _assign(current, rest)
            continue
        if current is None:
            continue
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        indent = len(raw) - len(raw.lstrip(" "))
        if stripped.startswith("evidence:"):
            current["evidence"] = {}
            in_evidence = True
            continue
        if in_evidence and indent >= 6 and ":" in stripped:
            key, val = stripped.split(":", 1)
            current.setdefault("evidence", {})[key.strip()] = _coerce(val)
            continue
        if indent <= 4:
            in_evidence = False
        if ":" in stripped:
            _assign(current, stripped)
    if current:
        records.append(_public(current))
    return records


def _extract_block(text: str) -> str:
    start = text.find(START)
    end = text.find(END)
    if start < 0 or end < 0 or end <= start:
        return ""
    inner = text[start + len(START) : end]
    inner = re.sub(r"^\s*```ya?ml\s*", "", inner, flags=re.IGNORECASE)
    inner = re.sub(r"```\s*$", "", inner)
    return inner


def _assign(record: dict[str, Any], line: str) -> None:
    if ":" not in line:
        return
    key, val = line.split(":", 1)
    record[key.strip()] = _coerce(val)


def _coerce(val: str) -> Any:
    s = val.strip()
    if not s:
        return ""
    if s.startswith("[") and s.endswith("]"):
        try:
            parsed = ast.literal_eval(s)
            if isinstance(parsed, list):
                return [str(x) for x in parsed]
        except (SyntaxError, ValueError):
            inner = s[1:-1].strip()
            if not inner:
                return []
            return [p.strip().strip("'\"") for p in inner.split(",") if p.strip()]
    if (s.startswith('"') and s.endswith('"')) or (s.startswith("'") and s.endswith("'")):
        return s[1:-1]
    if re.fullmatch(r"-?\d+", s):
        return int(s)
    return s


def _public(record: dict[str, Any]) -> dict[str, Any]:
    out = {k: v for k, v in record.items() if k not in _DROP}
    missing = out.get("missing_elements")
    if not isinstance(missing, list):
        missing = []
    out["why"] = format_weakness_why(str(out.get("family") or ""), missing)
    return out
