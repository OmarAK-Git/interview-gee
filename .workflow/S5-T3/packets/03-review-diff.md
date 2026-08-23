diff --git a/app/packs.py b/app/packs.py
index d2bd136..9e98dca 100644
--- a/app/packs.py
+++ b/app/packs.py
@@ -2,20 +2,21 @@
 from __future__ import annotations
 
 import re
 from pathlib import Path
 
 FAMILIES = frozenset({"behavioral", "technical", "product"})
 BANDS = frozenset({"core", "edge"})
 REQUIRED_IDS = frozenset(
     {"mccain-cyber-defense", "mastercard-r-281517", "praetor", "alter-ego"}
 )
+_SAFE_PACK_ID = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
 
 
 def normalize_temperature(value: str | int | None) -> int:
     if value is None or value == "":
         return 2
     try:
         n = int(value)
     except (TypeError, ValueError) as exc:
         raise ValueError(f"temperature must be 1-5 (got {value!r})") from exc
     if n < 1 or n > 5:
@@ -85,32 +86,42 @@ def parse_pack_file(path: Path) -> dict:
     if not pack["id"] or not pack["employer"] or len(competencies) < 4 or len(competencies) > 6:
         raise ValueError(f"invalid pack shape: {path}")
     return pack
 
 
 def list_source_packs(sources_dir: Path) -> list[dict]:
     packs = [parse_pack_file(p) for p in sorted(sources_dir.glob("*.md"))]
     return packs
 
 
+def _resolve_pack_path(pack_id: str, sources_dir: Path) -> Path:
+    if not pack_id or not _SAFE_PACK_ID.match(pack_id):
+        raise ValueError(f"invalid pack_id {pack_id!r}")
+    base = sources_dir.resolve()
+    path = (sources_dir / f"{pack_id}.md").resolve()
+    if not path.is_relative_to(base):
+        raise ValueError(f"invalid pack_id {pack_id!r}")
+    return path
+
+
 def require_session_jd(
     kind: str | None,
     pack_id: str | None,
     paste: str | None,
     *,
     sources_dir: Path,
 ) -> dict:
     k = (kind or "").strip().lower()
     if k == "pack":
         if not pack_id:
             raise ValueError("pack_id required")
-        path = sources_dir / f"{pack_id}.md"
+        path = _resolve_pack_path(pack_id, sources_dir)
         if not path.is_file():
             raise ValueError(f"unknown pack {pack_id!r}")
         pack = parse_pack_file(path)
         label = pack["employer"]
         if pack["role"]:
             label = f"{pack['employer']} ┬╖ {pack['role']}"
         return {
             "kind": "pack",
             "source_id": pack["id"],
             "source_label": label,
@@ -122,10 +133,27 @@ def require_session_jd(
             raise ValueError("paste text required")
         sid = slug_paste(text)
         first = text.splitlines()[0].strip()
         return {
             "kind": "paste",
             "source_id": sid,
             "source_label": first or "Pasted JD",
             "context_text": text,
         }
     raise ValueError("jd kind must be pack or paste")
+
+
+def start_session_args(payload: dict, *, sources_dir: Path) -> dict:
+    from inference import normalize_inference
+
+    jd = require_session_jd(
+        payload.get("jd_kind"),
+        payload.get("pack_id"),
+        payload.get("paste"),
+        sources_dir=sources_dir,
+    )
+    return {
+        "inference": normalize_inference(payload.get("inference")),
+        "temperature": normalize_temperature(payload.get("temperature")),
+        "persona": (payload.get("persona") or "").strip(),
+        **jd,
+    }
diff --git a/app/server.py b/app/server.py
index 0b6aca8..1da5dcd 100644
--- a/app/server.py
+++ b/app/server.py
@@ -5,24 +5,26 @@ from __future__ import annotations
 import json
 import os
 import subprocess
 import sys
 from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
 from pathlib import Path
 from urllib.parse import urlparse
 
 from inference import normalize_inference
 from memory_view import parse_weaknesses
+from packs import list_source_packs, start_session_args
 
 REPO_ROOT = Path(__file__).resolve().parent.parent
 SCRIPT = REPO_ROOT / "scripts" / "practice_session.sh"
 STATIC = Path(__file__).resolve().parent / "static"
+PACKS = REPO_ROOT / "skills" / "crossfire-interviewer" / "sources"
 HOST = os.environ.get("CROSSFIRE_UI_HOST", "127.0.0.1")
 PORT = int(os.environ.get("CROSSFIRE_UI_PORT", "8787"))
 
 SESSION = {
     "run_id": None,
     "session_id": None,
     "inference": "nous",
 }
 
 
@@ -96,20 +98,32 @@ class Handler(BaseHTTPRequestHandler):
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
+        if path == "/api/packs":
+            packs = list_source_packs(PACKS)
+            self._json(
+                200,
+                {
+                    "packs": [
+                        {k: p[k] for k in ("id", "employer", "role", "requisition", "families")}
+                        for p in packs
+                    ]
+                },
+            )
+            return
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
@@ -121,36 +135,50 @@ class Handler(BaseHTTPRequestHandler):
         length = int(self.headers.get("Content-Length", "0") or 0)
         raw = self.rfile.read(length) if length else b"{}"
         try:
             payload = json.loads(raw.decode("utf-8") or "{}")
         except json.JSONDecodeError:
             self._json(400, {"error": "invalid json"})
             return
 
         if path == "/api/session/start":
             try:
-                inference = normalize_inference(payload.get("inference"))
+                args = start_session_args(payload, sources_dir=PACKS)
             except ValueError as exc:
                 self._json(400, {"error": str(exc)})
                 return
             code, out, err = run_practice(
                 ["start"],
-                extra_env={"CROSSFIRE_INFERENCE": inference},
+                extra_env={
+                    "CROSSFIRE_INFERENCE": args["inference"],
+                    "CROSSFIRE_JD_KIND": args["kind"],
+                    "CROSSFIRE_JD_SOURCE_ID": args["source_id"],
+                    "CROSSFIRE_JD_SOURCE_LABEL": args["source_label"],
+                    "CROSSFIRE_JD_CONTEXT": args["context_text"],
+                    "CROSSFIRE_PERSONA": args["persona"],
+                    "CROSSFIRE_TEMPERATURE": str(args["temperature"]),
+                },
             )
             parsed = kv_parse(out)
             if code != 0:
                 self._json(500, {"error": err or out, "stdout": out})
                 return
             SESSION["run_id"] = parsed.get("run_id")
             SESSION["session_id"] = parsed.get("session_id")
-            SESSION["inference"] = parsed.get("inference") or inference
+            SESSION["inference"] = parsed.get("inference") or args["inference"]
             parsed["inference"] = SESSION["inference"]
+            parsed["source_id"] = args["source_id"]
+            parsed["source_label"] = args["source_label"]
+            parsed["jd_kind"] = args["kind"]
+            parsed["temperature"] = str(args["temperature"])
+            parsed["persona"] = args["persona"]
+            parsed["context_text"] = args["context_text"]
             self._json(200, parsed)
             return
 
         if path == "/api/session/answer":
             text = (payload.get("text") or "").strip()
             if not text:
                 self._json(400, {"error": "empty answer"})
                 return
             if not SESSION["run_id"]:
                 self._json(409, {"error": "no active session"})
diff --git a/scripts/practice_session.sh b/scripts/practice_session.sh
index dcf1646..8f8da39 100644
--- a/scripts/practice_session.sh
+++ b/scripts/practice_session.sh
@@ -26,21 +26,29 @@ crossfire_practice_save_state() {
   local f dir
   dir="${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}"
   mkdir -p "$dir/spool" "$dir/transcript" "$dir/skipped"
   f="${dir}/practice.state"
   cat >"$f" <<EOF
 CROSSFIRE_RUN_ID=${CROSSFIRE_RUN_ID}
 CROSSFIRE_SESSION_ID=${CROSSFIRE_SESSION_ID:-}
 CROSSFIRE_TURN=${CROSSFIRE_TURN:-0}
 HERMES_HOME=${HERMES_HOME}
 CROSSFIRE_INFERENCE=${CROSSFIRE_INFERENCE:-nous}
+CROSSFIRE_JD_KIND=${CROSSFIRE_JD_KIND:-}
+CROSSFIRE_JD_SOURCE_ID=${CROSSFIRE_JD_SOURCE_ID:-}
+CROSSFIRE_JD_SOURCE_LABEL=$(printf '%q' "${CROSSFIRE_JD_SOURCE_LABEL:-}")
+CROSSFIRE_TEMPERATURE=${CROSSFIRE_TEMPERATURE:-2}
+CROSSFIRE_PERSONA=$(printf '%q' "${CROSSFIRE_PERSONA:-}")
 EOF
+  if [ -n "${CROSSFIRE_JD_CONTEXT:-}" ]; then
+    printf '%s\n' "$CROSSFIRE_JD_CONTEXT" >"${dir}/jd-context.md"
+  fi
 }
 
 crossfire_practice_ensure_skill() {
   local dest="${HERMES_SKILLS_DIR}/crossfire-interviewer"
   mkdir -p "$dest" "${HERMES_HOME}/memories"
   cp "${CROSSFIRE_SKILL_PATH}/SKILL.md" "${dest}/SKILL.md"
   if [ -f "${CROSSFIRE_SKILL_PATH}/questions.md" ]; then
     cp "${CROSSFIRE_SKILL_PATH}/questions.md" "${dest}/questions.md"
   fi
   if [ -d "${CROSSFIRE_SKILL_PATH}/sources" ]; then
@@ -60,20 +68,27 @@ crossfire_practice_append_transcript() {
     printf '%s\n' "--- ${role} ---"
     printf '%s\n' "$text"
   } >>"$f"
 }
 
 crossfire_practice_start() {
   local question attribution="none" target_source="none"
   local stdout stderr sid
 
   crossfire_require_monday_home
+  if [ -z "${CROSSFIRE_JD_KIND:-}" ] || [ -z "${CROSSFIRE_JD_CONTEXT:-}" ]; then
+    fail_closed "practice start requires a session JD (pack or paste)"
+  fi
+  CROSSFIRE_TEMPERATURE="${CROSSFIRE_TEMPERATURE:-2}"
+  CROSSFIRE_PERSONA="${CROSSFIRE_PERSONA:-}"
+  export CROSSFIRE_JD_KIND CROSSFIRE_JD_CONTEXT CROSSFIRE_JD_SOURCE_ID CROSSFIRE_JD_SOURCE_LABEL
+  export CROSSFIRE_TEMPERATURE CROSSFIRE_PERSONA
   CROSSFIRE_INFERENCE=$(crossfire_practice_resolve_inference)
   export CROSSFIRE_INFERENCE
   CROSSFIRE_RUN_ID=$(crossfire_allocate_run_id)
   CROSSFIRE_TURN=0
   CROSSFIRE_SESSION_ID=""
   export CROSSFIRE_RUN_ID
   mkdir -p "${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/spool"
   crossfire_practice_ensure_skill
 
   if [ -f "$HERMES_MEMORY_MD" ] && grep -q 'CROSSFIRE-WEAKNESSES:START' "$HERMES_MEMORY_MD" \
@@ -116,20 +131,24 @@ crossfire_practice_start() {
     rm -f "$stdout" "$stderr"
   fi
 
   crossfire_practice_save_state
   crossfire_practice_append_transcript "interviewer" "$question"
   crossfire_practice_kv event start
   crossfire_practice_kv run_id "$CROSSFIRE_RUN_ID"
   crossfire_practice_kv session_id "$CROSSFIRE_SESSION_ID"
   crossfire_practice_kv opening_target_source "$target_source"
   crossfire_practice_kv inference "$CROSSFIRE_INFERENCE"
+  crossfire_practice_kv source_id "${CROSSFIRE_JD_SOURCE_ID:-}"
+  crossfire_practice_kv source_label "${CROSSFIRE_JD_SOURCE_LABEL:-}"
+  crossfire_practice_kv jd_kind "${CROSSFIRE_JD_KIND:-}"
+  crossfire_practice_kv temperature "${CROSSFIRE_TEMPERATURE:-2}"
   printf '%s\n' "$attribution" | sed 's/^/attribution_line=/'
   crossfire_practice_kv question "$question"
   crossfire_practice_kv tts_text "$question"
 }
 
 crossfire_practice_answer() {
   local answer="${1:-}"
   local stdout stderr proposal qid status="ok" persist="false" question=""
   local spool_file skip_file cmdline skill
 
diff --git a/tests/practice_inference.sh b/tests/practice_inference.sh
index d592a67..dab9320 100644
--- a/tests/practice_inference.sh
+++ b/tests/practice_inference.sh
@@ -48,20 +48,24 @@ fi
 home=$(mktemp -d /tmp/crossfire-practice-inf.XXXXXX)
 trap 'rm -rf "$home"' EXIT
 export HOME="$home"
 mkdir -p "$HOME/.hermes"
 export HERMES_HOME="$HOME/.hermes"
 export CROSSFIRE_PRACTICE_STUB=1
 export CROSSFIRE_RUNS_DIR="$home/runs"
 
 start_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
   CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_INFERENCE=codex \
+  CROSSFIRE_JD_KIND=pack \
+  CROSSFIRE_JD_SOURCE_ID=praetor \
+  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
+  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only never-contain' \
   bash "$REPO_ROOT/scripts/practice_session.sh" start) || {
   bad "codex stub start failed"
   echo "$start_out"
   echo "practice_inference: passed=$pass failed=$fail"
   exit 1
 }
 echo "$start_out" | grep -q 'inference=codex' && ok "start prints inference=codex" || bad "start inference: $start_out"
 
 echo "practice_inference: passed=$pass failed=$fail"
 [ "$fail" -eq 0 ]
diff --git a/tests/practice_session_stub.sh b/tests/practice_session_stub.sh
index 54c6844..256e86f 100644
--- a/tests/practice_session_stub.sh
+++ b/tests/practice_session_stub.sh
@@ -10,20 +10,24 @@ bad() { echo "FAIL: $1"; fail=$((fail + 1)); }
 home=$(mktemp -d /tmp/crossfire-practice-sess.XXXXXX)
 trap 'rm -rf "$home"' EXIT
 export HOME="$home"
 mkdir -p "$HOME/.hermes"
 export HERMES_HOME="$HOME/.hermes"
 export CROSSFIRE_PRACTICE_STUB=1
 export CROSSFIRE_RUNS_DIR="$home/runs"
 export PATH="/usr/bin:/bin:${PATH:-}"
 
 start_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
+  CROSSFIRE_JD_KIND=pack \
+  CROSSFIRE_JD_SOURCE_ID=praetor \
+  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
+  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only never-contain' \
   bash "$REPO_ROOT/scripts/practice_session.sh" start) || {
   echo "$start_out"
   bad "start failed"
   echo "practice_session: passed=$pass failed=$fail"
   exit 1
 }
 echo "$start_out" | grep -q 'event=start' && ok "start event" || bad "start event"
 run_id=$(echo "$start_out" | awk -F= '/^run_id=/{print $2; exit}')
 [ -n "$run_id" ] && ok "run_id printed" || bad "run_id printed"
 
@@ -56,24 +60,32 @@ end_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
   bad "end failed: $end_out"
 }
 echo "$end_out" | grep -q 'ack=ok' && ok "end ack" || bad "end ack: $end_out"
 if grep -q 'CROSSFIRE-WEAKNESSES:START' "$HERMES_HOME/memories/MEMORY.md"; then
   ok "weakness persisted to Monday-shaped home"
 else
   bad "MEMORY.md missing weakness block"
 fi
 
 start2=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
+  CROSSFIRE_JD_KIND=pack \
+  CROSSFIRE_JD_SOURCE_ID=praetor \
+  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
+  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only never-contain' \
   bash "$REPO_ROOT/scripts/practice_session.sh" start)
 echo "$start2" | grep -q 'opening_target_source=MEMORY.md' && ok "session two memory opener" || bad "session two opener: $start2"
 
 # Strong answer should not require retry / not force persist
 start3=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
+  CROSSFIRE_JD_KIND=pack \
+  CROSSFIRE_JD_SOURCE_ID=praetor \
+  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
+  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only never-contain' \
   bash "$REPO_ROOT/scripts/practice_session.sh" start) || true
 run2=$(printf '%s\n' "$start3" | awk -F= '/^run_id=/{print $2; exit}')
 strong=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
   CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run2" \
   bash "$REPO_ROOT/scripts/practice_session.sh" answer "Praetor never-contain list plus hash-chained ledger verification.")
 echo "$strong" | grep -q 'persist_recommended=false' && ok "strong answer no weakness" || bad "strong: $strong"
 
 echo "practice_session: passed=$pass failed=$fail"
 [ "$fail" -eq 0 ]
diff --git a/tests/test_packs.py b/tests/test_packs.py
index 88587e8..241bf99 100644
--- a/tests/test_packs.py
+++ b/tests/test_packs.py
@@ -72,13 +72,31 @@ class TemperatureAndJdTest(unittest.TestCase):
         self.assertIn("never-contain", got["context_text"])
 
     def test_require_paste_slugs_first_line(self) -> None:
         text = "Acme SWE\nBuild the payments API.\n"
         self.assertEqual(slug_paste(text), "pasted-acme-swe")
         got = require_session_jd("paste", None, text, sources_dir=SOURCES)
         self.assertEqual(got["source_id"], "pasted-acme-swe")
         self.assertEqual(got["context_text"], text.strip())
         self.assertEqual(slug_paste(""), "pasted-jd")
 
+    def test_require_pack_rejects_path_traversal(self) -> None:
+        with self.assertRaises(ValueError):
+            require_session_jd("pack", "../SKILL", None, sources_dir=SOURCES)
+
+    def test_start_session_args_requires_jd(self) -> None:
+        from packs import start_session_args
+
+        with self.assertRaises(ValueError):
+            start_session_args({"inference": "nous"}, sources_dir=SOURCES)
+        got = start_session_args(
+            {"inference": "codex", "jd_kind": "pack", "pack_id": "praetor", "temperature": "3"},
+            sources_dir=SOURCES,
+        )
+        self.assertEqual(got["inference"], "codex")
+        self.assertEqual(got["temperature"], 3)
+        self.assertEqual(got["source_id"], "praetor")
+        self.assertEqual(got["persona"], "")
+
 
 if __name__ == "__main__":
     unittest.main()


===== tests/practice_jd.sh (new) =====

#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
pass=0
fail=0
ok() { echo "PASS: $1"; pass=$((pass + 1)); }
bad() { echo "FAIL: $1"; fail=$((fail + 1)); }

home=$(mktemp -d /tmp/crossfire-practice-jd.XXXXXX)
trap 'rm -rf "$home"' EXIT
export HOME="$home"
mkdir -p "$HOME/.hermes"
export HERMES_HOME="$HOME/.hermes"
export CROSSFIRE_PRACTICE_STUB=1
export CROSSFIRE_RUNS_DIR="$home/runs"

if HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  bash "$REPO_ROOT/scripts/practice_session.sh" start >/tmp/jd-start.out 2>/tmp/jd-start.err; then
  bad "start without JD should fail"
else
  ok "start without JD fail-closed"
fi

start_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" \
  CROSSFIRE_JD_KIND=pack \
  CROSSFIRE_JD_SOURCE_ID=praetor \
  CROSSFIRE_JD_SOURCE_LABEL='Project Praetor' \
  CROSSFIRE_JD_CONTEXT='Project Praetor advisory-only' \
  CROSSFIRE_TEMPERATURE=2 \
  bash "$REPO_ROOT/scripts/practice_session.sh" start) || {
  bad "start with pack failed"
  echo "$start_out"
  echo "practice_jd: passed=$pass failed=$fail"
  exit 1
}
echo "$start_out" | grep -q 'source_id=praetor' && ok "source_id printed" || bad "source_id printed"
echo "$start_out" | grep -q 'temperature=2' && ok "temperature printed" || bad "temperature printed"

echo "practice_jd: passed=$pass failed=$fail"
[ "$fail" -eq 0 ]

