#!/usr/bin/env python3
"""Isolated kv_parse + HTTP end probe. Never uses real ~/.hermes."""
from __future__ import annotations

import json
import os
import sys
import tempfile
import threading
from http.server import ThreadingHTTPServer
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "app"))

from server import Handler, kv_parse  # noqa: E402

SAMPLE = """report_weak=behavioral:[action, result]
report_strong=
report_line=Weak: behavioral:[action, result]
report_line=Strong: none
event=end
persisted_count=0
ack=ok
"""

parsed = kv_parse(SAMPLE)
print("KV_PARSE", json.dumps(parsed, indent=2))
assert "report_weak" in parsed, "missing report_weak"
assert "report_strong" in parsed, "missing report_strong"
assert "report_text" in parsed, "missing report_text"
assert "Weak:" in parsed["report_text"], parsed["report_text"]
assert "Strong:" in parsed["report_text"], parsed["report_text"]
print("KV_PARSE_OK")

tmp = Path(tempfile.mkdtemp(prefix="s5t6-http-"))
hermes = tmp / ".hermes"
hermes.mkdir()
real = Path.home() / ".hermes"
print("HERMES_HOME", hermes)
print("REAL", real)
print("USING_REAL", hermes.resolve() == real.resolve())
if hermes.resolve() == real.resolve():
    raise SystemExit("refusing real ~/.hermes")

os.environ["HOME"] = str(tmp)
os.environ["HERMES_HOME"] = str(hermes)
os.environ["CROSSFIRE_PRACTICE_STUB"] = "1"
os.environ["CROSSFIRE_RUNS_DIR"] = str(tmp / "runs")

httpd = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
thread = threading.Thread(target=httpd.serve_forever, daemon=True)
thread.start()
port = httpd.server_address[1]
base = f"http://127.0.0.1:{port}"


def post(path: str, body: dict) -> tuple[int, dict]:
    req = Request(
        base + path,
        data=json.dumps(body).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urlopen(req, timeout=60) as resp:
            return resp.status, json.loads(resp.read().decode())
    except Exception as exc:  # noqa: BLE001
        if hasattr(exc, "read"):
            raw = exc.read().decode()
            try:
                return getattr(exc, "code", 0), json.loads(raw)
            except json.JSONDecodeError:
                return getattr(exc, "code", 0), {"raw": raw}
        raise


try:
    js = urlopen(base + "/static/app.js", timeout=10).read().decode()
    print("JS_HAS_REPORT_TEXT", "report_text" in js)
    print("JS_HAS_PERSISTED_TMPL", "Persisted ${data.persisted_count" in js)
    print("JS_BUBBLE_REPORT", 'bubble("interviewer", report)' in js)

    code, start = post(
        "/api/session/start",
        {
            "jd_kind": "pack",
            "pack_id": "praetor",
            "inference": "nous",
            "temperature": 2,
        },
    )
    print("START", code, {k: start.get(k) for k in ("run_id", "error", "source_label")})
    if code != 200:
        raise SystemExit(f"start failed {code} {start}")

    code, ans = post(
        "/api/session/answer",
        {"text": "I just kind of watched the dashboard."},
    )
    print("ANSWER", code, {k: ans.get(k) for k in ("persist_recommended", "error")})

    code, end = post("/api/session/end", {})
    print("END_STATUS", code)
    print("END_KEYS", sorted(end.keys()))
    print("END_REPORT_WEAK", end.get("report_weak"))
    print("END_REPORT_STRONG", end.get("report_strong"))
    print("END_REPORT_TEXT", json.dumps(end.get("report_text")))
    mem = hermes / "memories" / "MEMORY.md"
    print("MEMORY_EXISTS", mem.is_file())
    if mem.is_file():
        text = mem.read_text(encoding="utf-8")
        print("MEMORY_HAS_QLIVE_GAP", "q_live_01 practice gap" in text)
        print("MEMORY_HAS_PRAETOR", "Project Praetor" in text or "praetor" in text.lower())
        print("MEMORY_SNIP", text[:800])
finally:
    httpd.shutdown()
