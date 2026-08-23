"""Turn End-session weak/strong kv into a short prose close-out."""
from __future__ import annotations

from collections import Counter

ELEMENT_PHRASE = {
    "problem": "the problem",
    "approach": "the approach",
    "tradeoff": "the tradeoff",
    "verification": "how you would verify it",
    "situation": "the situation",
    "task": "the task",
    "action": "what you did",
    "result": "what changed",
    "user": "the user",
    "constraint": "the constraint",
    "decision": "the decision",
    "metric": "the metric",
}

_NUMBER = {1: "one", 2: "two", 3: "three", 4: "four", 5: "five", 6: "six", 7: "seven", 8: "eight"}


def format_session_report(weak: str, strong: str) -> str:
    weak_items = _parse_weak(weak)
    strong_fams = _parse_strong(strong)
    if not weak_items and not strong_fams:
        return "No answers were assessed this session."
    sentences: list[str] = []
    sentences.extend(_weak_sentences(weak_items))
    if strong_fams:
        sentences.append(_strong_sentence(strong_fams))
    return " ".join(sentences)


def apply_end_report(parsed: dict) -> dict:
    parsed["report_text"] = format_session_report(
        parsed.get("report_weak", ""),
        parsed.get("report_strong", ""),
    )
    return parsed


def _parse_weak(raw: str) -> list[tuple[str, list[str]]]:
    out: list[tuple[str, list[str]]] = []
    for part in _split_items(raw):
        if ":" in part:
            family, rest = part.split(":", 1)
            elems = [e.strip() for e in rest.strip().strip("[]").split(",") if e.strip()]
            out.append((family.strip(), elems))
        else:
            out.append((part, []))
    return out


def _parse_strong(raw: str) -> list[str]:
    return [part for part in _split_items(raw)]


def _split_items(raw: str) -> list[str]:
    text = (raw or "").strip()
    if not text or text.lower() == "none":
        return []
    return [part.strip() for part in text.split(";") if part.strip() and part.strip().lower() != "none"]


def _weak_sentences(items: list[tuple[str, list[str]]]) -> list[str]:
    seen: Counter[str] = Counter()
    sentences: list[str] = []
    for family, elems in items:
        seen[family] += 1
        article = "Another" if seen[family] > 1 else "A"
        missing = _join_phrases([_element_phrase(e) for e in elems]) or "required pieces"
        sentences.append(f"{article} {family} answer was missing {missing}.")
    return sentences


def _strong_sentence(families: list[str]) -> str:
    counts = Counter(families)
    bits = [f"{_number(n)} {_family_noun(fam, n)}" for fam, n in counts.items()]
    subject = _join_phrases(bits)
    subject = subject[0].upper() + subject[1:]
    verb = "was" if sum(counts.values()) == 1 else "were"
    return f"{subject} {verb} strong enough not to persist."


def _family_noun(family: str, n: int) -> str:
    name = family.strip() or "practice"
    return f"{name} answer" if n == 1 else f"{name} answers"


def _element_phrase(name: str) -> str:
    key = name.strip().lower()
    if key in ELEMENT_PHRASE:
        return ELEMENT_PHRASE[key]
    return name.strip().replace("_", " ")


def _join_phrases(items: list[str]) -> str:
    if not items:
        return ""
    if len(items) == 1:
        return items[0]
    if len(items) == 2:
        return f"{items[0]} and {items[1]}"
    return f"{', '.join(items[:-1])}, and {items[-1]}"


def _number(n: int) -> str:
    return _NUMBER.get(n, str(n))
