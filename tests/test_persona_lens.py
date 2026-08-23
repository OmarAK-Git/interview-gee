#!/usr/bin/env python3
"""Persona is a lens on the session JD, not voice-only flavor."""
from __future__ import annotations

import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILL = ROOT / "skills" / "crossfire-interviewer" / "SKILL.md"
PREAMBLE = ROOT / "scripts" / "practice_session.sh"
HTML = ROOT / "app" / "static" / "index.html"
SPEC = ROOT / "docs" / "superpowers" / "specs" / "2026-08-23-practice-interviewer-design.md"
ADDENDUM = ROOT / "docs" / "sparring-1.1.0-practice.md"
README = ROOT / "README.md"


class PersonaLensContractTest(unittest.TestCase):
    def test_skill_persona_is_lens_not_voice_only(self) -> None:
        skill = SKILL.read_text(encoding="utf-8")
        self.assertNotIn("flavors voice only", skill)
        self.assertNotIn("that are not in the session JD", skill)
        self.assertIn("lens", skill.lower())
        self.assertIn("domain knowledge implied by the persona is allowed", skill.lower())
        self.assertIn("do not invent this employer's", skill.lower())
        self.assertIn("not a second JD", skill)

    def test_preamble_persona_is_lens_not_flavor_only(self) -> None:
        text = PREAMBLE.read_text(encoding="utf-8")
        self.assertNotIn("flavor only", text)
        self.assertNotIn("only allowed facts", text)
        self.assertNotIn("that are not in the session JD", text)
        self.assertIn("lens on this JD", text)
        self.assertIn("domain knowledge implied by the persona is allowed", text.lower())
        self.assertIn("do not invent this employer's", text.lower())

    def test_ui_placeholder_hints_lens_not_title_only(self) -> None:
        html = HTML.read_text(encoding="utf-8")
        self.assertIn('id="persona"', html)
        self.assertIn("OT plant engineer", html)

    def test_docs_lock_persona_as_lens(self) -> None:
        spec = SPEC.read_text(encoding="utf-8")
        addendum = ADDENDUM.read_text(encoding="utf-8")
        readme = README.read_text(encoding="utf-8")
        self.assertIn("lens", spec.lower())
        self.assertNotIn("flavors voice if present", spec)
        self.assertIn("lens", addendum.lower())
        self.assertNotIn("Optional persona flavors interviewer voice.", addendum)
        self.assertIn("lens", readme.lower())
        self.assertNotIn("interviewer voice flavor", readme)


if __name__ == "__main__":
    unittest.main()
