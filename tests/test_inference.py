#!/usr/bin/env python3
"""Inference toggle: Nous vs Codex, still Hermes."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "app"))

from inference import normalize_inference  # noqa: E402


class NormalizeInferenceTest(unittest.TestCase):
    def test_default_nous(self) -> None:
        self.assertEqual(normalize_inference(None), "nous")
        self.assertEqual(normalize_inference(""), "nous")
        self.assertEqual(normalize_inference("  NOUS  "), "nous")

    def test_codex_aliases(self) -> None:
        self.assertEqual(normalize_inference("codex"), "codex")
        self.assertEqual(normalize_inference("openai-codex"), "codex")

    def test_rejects_unknown(self) -> None:
        with self.assertRaises(ValueError):
            normalize_inference("cursor")
        with self.assertRaises(ValueError):
            normalize_inference("xai")


class UiInferenceContractTest(unittest.TestCase):
    def test_toggle_exists_and_is_sent_on_start(self) -> None:
        html = (ROOT / "app" / "static" / "index.html").read_text(encoding="utf-8")
        js = (ROOT / "app" / "static" / "app.js").read_text(encoding="utf-8")
        self.assertIn('id="inference"', html)
        self.assertIn('value="nous"', html)
        self.assertIn('value="codex"', html)
        self.assertIn("inference", js)
        self.assertIn("/api/session/start", js)
        self.assertIn("JSON.stringify", js)


class StartInferenceHttpTest(unittest.TestCase):
    def test_unknown_inference_is_400(self) -> None:
        import json
        import threading
        import urllib.error
        import urllib.request
        from http.server import ThreadingHTTPServer

        import server

        httpd = ThreadingHTTPServer(("127.0.0.1", 0), server.Handler)
        thread = threading.Thread(target=httpd.serve_forever, daemon=True)
        thread.start()
        try:
            port = httpd.server_address[1]
            req = urllib.request.Request(
                f"http://127.0.0.1:{port}/api/session/start",
                data=b'{"inference":"cursor"}',
                method="POST",
                headers={"Content-Type": "application/json"},
            )
            with self.assertRaises(urllib.error.HTTPError) as ctx:
                urllib.request.urlopen(req, timeout=3)
            self.assertEqual(ctx.exception.code, 400)
            body = json.loads(ctx.exception.read().decode())
            self.assertIn("nous or codex", body.get("error", ""))
        finally:
            httpd.shutdown()
            httpd.server_close()


if __name__ == "__main__":
    unittest.main()
