#!/usr/bin/env python3
"""Localhost practice UI server. Binds 127.0.0.1 only. Shells to practice_session.sh."""
from __future__ import annotations

import json
import os
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

from inference import normalize_inference
from memory_view import parse_weaknesses
from packs import list_source_packs, start_session_args

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPT = REPO_ROOT / "scripts" / "practice_session.sh"
STATIC = Path(__file__).resolve().parent / "static"
PACKS = REPO_ROOT / "skills" / "crossfire-interviewer" / "sources"
HOST = os.environ.get("CROSSFIRE_UI_HOST", "127.0.0.1")
PORT = int(os.environ.get("CROSSFIRE_UI_PORT", "8787"))

SESSION = {
    "run_id": None,
    "session_id": None,
    "inference": "nous",
}


def kv_parse(text: str) -> dict[str, str]:
    out: dict[str, str] = {}
    attr_lines: list[str] = []
    for line in text.splitlines():
        if "=" not in line:
            continue
        key, val = line.split("=", 1)
        if key == "attribution_line":
            attr_lines.append(val)
        else:
            out[key] = val
    if attr_lines:
        out["attribution"] = "\n".join(attr_lines)
    return out


def run_practice(args: list[str], extra_env: dict[str, str] | None = None) -> tuple[int, str, str]:
    env = os.environ.copy()
    env.setdefault("HOME", str(Path.home()))
    if extra_env:
        env.update(extra_env)
    proc = subprocess.run(
        ["bash", str(SCRIPT), *args],
        cwd=str(REPO_ROOT),
        env=env,
        capture_output=True,
        text=True,
    )
    return proc.returncode, proc.stdout, proc.stderr


def memory_payload() -> dict:
    home = os.environ.get("HERMES_HOME") or str(Path.home() / ".hermes")
    path = Path(home) / "memories" / "MEMORY.md"
    if not path.is_file():
        return {"exists": False, "text": "", "weaknesses": [], "path": str(path)}
    text = path.read_text(encoding="utf-8")
    return {
        "exists": True,
        "text": text,
        "weaknesses": parse_weaknesses(text),
        "path": str(path),
    }


class Handler(BaseHTTPRequestHandler):
    def _send(self, code: int, body: bytes, content_type: str = "application/json") -> None:
        self.send_response(code)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _json(self, code: int, obj: dict) -> None:
        self._send(code, json.dumps(obj).encode("utf-8"))

    def do_GET(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        if path in ("/", "/index.html"):
            target = STATIC / "index.html"
            self._send(200, target.read_bytes(), "text/html; charset=utf-8")
            return
        if path.startswith("/static/"):
            rel = path[len("/static/") :]
            target = (STATIC / rel).resolve()
            if not str(target).startswith(str(STATIC.resolve())):
                self._json(403, {"error": "forbidden"})
                return
            if not target.is_file():
                self._json(404, {"error": "not found"})
                return
            ctype = "text/javascript" if target.suffix == ".js" else "text/css" if target.suffix == ".css" else "text/plain"
            self._send(200, target.read_bytes(), ctype)
            return
        if path == "/api/memory":
            self._json(200, memory_payload())
            return
        if path == "/api/packs":
            packs = list_source_packs(PACKS)
            self._json(
                200,
                {
                    "packs": [
                        {k: p[k] for k in ("id", "employer", "role", "requisition", "families")}
                        for p in packs
                    ]
                },
            )
            return
        if path == "/api/health":
            self._json(
                200,
                {
                    "ok": True,
                    "run_id": SESSION["run_id"],
                    "inference": SESSION["inference"],
                    "inference_choices": ["nous", "codex"],
                },
            )
            return
        self._json(404, {"error": "not found"})

    def do_POST(self) -> None:  # noqa: N802
        path = urlparse(self.path).path
        length = int(self.headers.get("Content-Length", "0") or 0)
        raw = self.rfile.read(length) if length else b"{}"
        try:
            payload = json.loads(raw.decode("utf-8") or "{}")
        except json.JSONDecodeError:
            self._json(400, {"error": "invalid json"})
            return

        if path == "/api/session/start":
            try:
                args = start_session_args(payload, sources_dir=PACKS)
            except ValueError as exc:
                self._json(400, {"error": str(exc)})
                return
            code, out, err = run_practice(
                ["start"],
                extra_env={
                    "CROSSFIRE_INFERENCE": args["inference"],
                    "CROSSFIRE_JD_KIND": args["kind"],
                    "CROSSFIRE_JD_SOURCE_ID": args["source_id"],
                    "CROSSFIRE_JD_SOURCE_LABEL": args["source_label"],
                    "CROSSFIRE_JD_CONTEXT": args["context_text"],
                    "CROSSFIRE_PERSONA": args["persona"],
                    "CROSSFIRE_TEMPERATURE": str(args["temperature"]),
                },
            )
            parsed = kv_parse(out)
            if code != 0:
                self._json(500, {"error": err or out, "stdout": out})
                return
            SESSION["run_id"] = parsed.get("run_id")
            SESSION["session_id"] = parsed.get("session_id")
            SESSION["inference"] = parsed.get("inference") or args["inference"]
            parsed["inference"] = SESSION["inference"]
            parsed["source_id"] = args["source_id"]
            parsed["source_label"] = args["source_label"]
            parsed["jd_kind"] = args["kind"]
            parsed["temperature"] = str(args["temperature"])
            parsed["persona"] = args["persona"]
            parsed["context_text"] = args["context_text"]
            self._json(200, parsed)
            return

        if path == "/api/session/answer":
            text = (payload.get("text") or "").strip()
            if not text:
                self._json(400, {"error": "empty answer"})
                return
            if not SESSION["run_id"]:
                self._json(409, {"error": "no active session"})
                return
            code, out, err = run_practice(
                ["answer", text],
                extra_env={"CROSSFIRE_RUN_ID": SESSION["run_id"]},
            )
            parsed = kv_parse(out)
            if code != 0 and parsed.get("assessment_status") != "skipped":
                self._json(500, {"error": err or out, "stdout": out, **parsed})
                return
            self._json(200, parsed)
            return

        if path == "/api/session/end":
            if not SESSION["run_id"]:
                self._json(409, {"error": "no active session"})
                return
            code, out, err = run_practice(
                ["end"],
                extra_env={"CROSSFIRE_RUN_ID": SESSION["run_id"]},
            )
            parsed = kv_parse(out)
            SESSION["run_id"] = None
            SESSION["session_id"] = None
            if code != 0:
                self._json(500, {"error": err or out, "stdout": out, **parsed})
                return
            self._json(200, parsed)
            return

        self._json(404, {"error": "not found"})

    def log_message(self, fmt: str, *args: object) -> None:
        sys.stderr.write("%s - %s\n" % (self.address_string(), fmt % args))


def main() -> None:
    if not SCRIPT.is_file():
        sys.exit(f"missing {SCRIPT}")
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Crossfire practice UI http://{HOST}:{PORT}", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
