#!/usr/bin/env python3
"""End-session close-out is prose, not a tag dump."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "app"))

from report import apply_end_report, format_session_report  # noqa: E402


class FormatSessionReportTest(unittest.TestCase):
    def test_empty_session(self) -> None:
        expected = "No answers were assessed this session."
        self.assertEqual(format_session_report("", ""), expected)
        self.assertEqual(format_session_report("none", "none"), expected)

    def test_screenshot_session_is_prose(self) -> None:
        text = format_session_report(
            "technical:[problem, verification];behavioral:[situation, task, action, result]",
            "technical;technical",
        )
        self.assertNotIn(":[", text)
        self.assertNotIn("Weak:", text)
        self.assertNotIn("Strong:", text)
        self.assertNotIn("[", text)
        self.assertNotIn(";", text)
        self.assertIn("problem", text.lower())
        self.assertIn("verif", text.lower())
        self.assertIn("situation", text.lower())
        self.assertIn("technical", text.lower())
        self.assertIn("behavioral", text.lower())
        self.assertTrue(text.endswith("."))
        self.assertGreaterEqual(text.count("."), 2)

    def test_only_weak_omits_strong_clause(self) -> None:
        text = format_session_report("behavioral:[action, result]", "")
        self.assertIn("behavioral", text.lower())
        self.assertIn("what you did", text.lower())
        self.assertIn("what changed", text.lower())
        self.assertNotIn("strong", text.lower())
        self.assertNotIn(":[", text)

    def test_only_strong_omits_missing_clause(self) -> None:
        text = format_session_report("", "technical")
        self.assertIn("technical", text.lower())
        self.assertNotIn("missing", text.lower())
        self.assertTrue(text.endswith("."))

    def test_product_elements_are_named(self) -> None:
        text = format_session_report("product:[user, metric]", "product")
        self.assertIn("user", text.lower())
        self.assertIn("metric", text.lower())
        self.assertNotIn("[", text)

    def test_apply_end_report_overrides_tag_dump(self) -> None:
        parsed = {
            "report_weak": "behavioral:[action, result]",
            "report_strong": "",
            "report_text": "Weak: behavioral:[action, result]\nStrong: none",
        }
        out = apply_end_report(parsed)
        self.assertNotIn(":[", out["report_text"])
        self.assertIn("what you did", out["report_text"])


if __name__ == "__main__":
    unittest.main()
