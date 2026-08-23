diff --git a/app/packs.py b/app/packs.py
index d2bd136..6c04a8f 100644
--- a/app/packs.py
+++ b/app/packs.py
@@ -4,16 +4,17 @@ from __future__ import annotations
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
@@ -87,28 +88,38 @@ def parse_pack_file(path: Path) -> dict:
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
@@ -124,8 +135,26 @@ def require_session_jd(
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
+    inference = normalize_inference(payload.get("inference"))
+    jd = require_session_jd(
+        payload.get("jd_kind"),
+        payload.get("pack_id"),
+        payload.get("paste"),
+        sources_dir=sources_dir,
+    )
+    return {
+        "inference": inference,
+        "temperature": normalize_temperature(payload.get("temperature")),
+        "persona": (payload.get("persona") or "").strip(),
+        **jd,
+    }
