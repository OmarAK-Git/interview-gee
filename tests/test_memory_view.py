#!/usr/bin/env python3
"""Unit tests for user-facing weakness parsing (MEMORY.md YAML stays on disk)."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "app"))

from memory_view import parse_weaknesses  # noqa: E402

FIXTURE = ROOT / "tests" / "fixtures" / "memory-three-weaknesses.md"


class ParseWeaknessesTest(unittest.TestCase):
    def test_fixture_yields_three_readable_records(self) -> None:
        text = FIXTURE.read_text(encoding="utf-8")
        records = parse_weaknesses(text)
        self.assertEqual(len(records), 3)
        first = records[0]
        self.assertEqual(first["family"], "behavioral")
        self.assertEqual(first["topic"], "alpha story")
        self.assertEqual(first["missing_elements"], ["action", "result"])
        self.assertEqual(first["observation_count"], 1)
        self.assertEqual(first["evidence"]["kind"], "quote")
        self.assertEqual(first["evidence"]["value"], "watched the dashboard")
        self.assertEqual(first["last_seen"], "2026-08-10T10:00:00Z")
        self.assertEqual(records[1]["family"], "technical")
        self.assertEqual(records[1]["missing_elements"], ["tradeoff", "verification"])
        self.assertNotIn("topic_key", first)
        self.assertNotIn("weakness_id", first)
        self.assertNotIn("answer_ref", first)
        self.assertNotIn("source_session_id", first)

    def test_missing_file_content_is_empty(self) -> None:
        self.assertEqual(parse_weaknesses(""), [])
        self.assertEqual(parse_weaknesses("# Personal Memory\n\nNo block here.\n"), [])

    def test_empty_block_is_empty_list(self) -> None:
        text = (
            "<!-- CROSSFIRE-WEAKNESSES:START -->\n"
            "```yaml\n"
            "version: 1\n"
            "weaknesses: []\n"
            "```\n"
            "<!-- CROSSFIRE-WEAKNESSES:END -->\n"
        )
        self.assertEqual(parse_weaknesses(text), [])


class MemoryPayloadTest(unittest.TestCase):
    def test_payload_includes_parsed_cards(self) -> None:
        import os
        import shutil
        import tempfile

        tmp = Path(tempfile.mkdtemp())
        old = os.environ.get("HERMES_HOME")
        try:
            (tmp / "memories").mkdir()
            shutil.copyfile(FIXTURE, tmp / "memories" / "MEMORY.md")
            os.environ["HERMES_HOME"] = str(tmp)
            import server

            data = server.memory_payload()
            self.assertTrue(data["exists"])
            self.assertEqual(len(data["weaknesses"]), 3)
            self.assertEqual(data["weaknesses"][0]["topic"], "alpha story")
            self.assertNotIn("weakness_id", data["weaknesses"][0])
        finally:
            if old is None:
                os.environ.pop("HERMES_HOME", None)
            else:
                os.environ["HERMES_HOME"] = old
            shutil.rmtree(tmp, ignore_errors=True)


class UiContractTest(unittest.TestCase):
    def test_enter_sends_and_mic_exists(self) -> None:
        html = (ROOT / "app" / "static" / "index.html").read_text(encoding="utf-8")
        js = (ROOT / "app" / "static" / "app.js").read_text(encoding="utf-8")
        self.assertIn('id="mic"', html)
        self.assertIn(">Speak</button>", html)
        self.assertIn("stt.js", js)
        self.assertTrue((ROOT / "app" / "static" / "stt.js").is_file())
        self.assertIn('id="memory"', html)
        self.assertNotIn("<pre", html)
        self.assertIn('e.key !== "Enter"', js)
        self.assertIn("finishVoiceAndSend", js)
        self.assertIn("renderWeaknesses", js)


class HttpSmokeTest(unittest.TestCase):
    def test_memory_endpoint_and_static(self) -> None:
        import json
        import os
        import shutil
        import tempfile
        import threading
        import urllib.request
        from http.server import ThreadingHTTPServer

        tmp = Path(tempfile.mkdtemp())
        old = os.environ.get("HERMES_HOME")
        httpd = None
        try:
            (tmp / "memories").mkdir()
            shutil.copyfile(FIXTURE, tmp / "memories" / "MEMORY.md")
            os.environ["HERMES_HOME"] = str(tmp)
            import server

            httpd = ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)
            thread = threading.Thread(target=httpd.serve_forever, daemon=True)
            thread.start()
            port = httpd.server_address[1]
            base = f"http://127.0.0.1:{port}"
            mem = json.loads(urllib.request.urlopen(f"{base}/api/memory", timeout=3).read())
            home = urllib.request.urlopen(f"{base}/", timeout=3).read().decode()
            stt = urllib.request.urlopen(f"{base}/static/stt.js", timeout=3).read().decode()
            self.assertEqual(len(mem["weaknesses"]), 3)
            self.assertEqual(mem["weaknesses"][0]["topic"], "alpha story")
            self.assertIn('id="mic"', home)
            self.assertNotIn("<pre", home)
            self.assertIn("SpeechRecognition", stt)
        finally:
            if httpd is not None:
                httpd.shutdown()
                httpd.server_close()
            if old is None:
                os.environ.pop("HERMES_HOME", None)
            else:
                os.environ["HERMES_HOME"] = old
            shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
