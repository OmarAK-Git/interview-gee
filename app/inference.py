"""Practice inference toggle. Hermes stays the harness; only the provider changes."""
from __future__ import annotations

ALLOWED = ("nous", "codex")


def normalize_inference(value: str | None) -> str:
    raw = (value or "nous").strip().lower()
    if raw in ("", "nous"):
        return "nous"
    if raw in ("codex", "openai-codex"):
        return "codex"
    raise ValueError(f"inference must be nous or codex (got {value!r})")
