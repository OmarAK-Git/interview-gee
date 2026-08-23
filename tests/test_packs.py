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

    def test_require_pack_rejects_path_traversal(self) -> None:
        with self.assertRaises(ValueError):
            require_session_jd("pack", "../SKILL", None, sources_dir=SOURCES)

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

    def test_start_session_args_paste_only(self) -> None:
        from packs import start_session_args

        got = start_session_args(
            {"inference": "nous", "paste": "Acme SWE\nBuild the payments API."},
            sources_dir=SOURCES,
        )
        self.assertEqual(got["kind"], "paste")
        self.assertEqual(got["source_id"], "pasted-acme-swe")
        self.assertIn("payments API", got["context_text"])


if __name__ == "__main__":
    unittest.main()
