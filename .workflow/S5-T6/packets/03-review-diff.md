diff --git a/app/server.py b/app/server.py
index 6f36576..f47adb5 100644
--- a/app/server.py
+++ b/app/server.py
@@ -26,26 +26,31 @@ SESSION = {
     "session_id": None,
     "inference": "nous",
 }
 
 
 def kv_parse(text: str) -> dict[str, str]:
     out: dict[str, str] = {}
     attr_lines: list[str] = []
+    report_lines: list[str] = []
     for line in text.splitlines():
         if "=" not in line:
             continue
         key, val = line.split("=", 1)
         if key == "attribution_line":
             attr_lines.append(val)
+        elif key == "report_line":
+            report_lines.append(val)
         else:
             out[key] = val
     if attr_lines:
         out["attribution"] = "\n".join(attr_lines)
+    if report_lines:
+        out["report_text"] = "\n".join(report_lines)
     return out
 
 
 def run_practice(args: list[str], extra_env: dict[str, str] | None = None) -> tuple[int, str, str]:
     env = os.environ.copy()
     env.setdefault("HOME", str(Path.home()))
     if extra_env:
         env.update(extra_env)
diff --git a/app/static/app.js b/app/static/app.js
index fc653a5..0b877ca 100644
--- a/app/static/app.js
+++ b/app/static/app.js
@@ -254,17 +254,18 @@ document.getElementById("start").addEventListener("click", async () => {
 });
 
 document.getElementById("end").addEventListener("click", async () => {
   tts.cancel();
   stopVoice();
   const data = await withWait("Wrapping upΓÇª", () =>
     api("/api/session/end", { method: "POST", body: "{}" }),
   );
-  bubble("interviewer", `Session ended. Persisted ${data.persisted_count || 0} weakness(es).`);
+  const report = data.report_text || "No assessments this session.";
+  bubble("interviewer", report);
   await refreshMemory();
 });
 
 composer.addEventListener("submit", async (e) => {
   e.preventDefault();
   stopVoice();
   const text = answer.value.trim();
   if (!text) return;
diff --git a/scripts/practice_session.sh b/scripts/practice_session.sh
index 1e654b4..a939bb3 100644
--- a/scripts/practice_session.sh
+++ b/scripts/practice_session.sh
@@ -345,27 +345,28 @@ crossfire_practice_end() {
 
   shopt -s nullglob
   for f in "${spool_dir}"/*.yaml; do
     [ -f "$f" ] || continue
     if ! crossfire_spool_should_persist "$f"; then
       continue
     fi
     family=$(crossfire_spool_field "$f" family)
-    topic=$(crossfire_spool_field "$f" question_id)
-    [ -n "$topic" ] || topic="$family"
-    topic="${topic} practice gap"
+    topic="${CROSSFIRE_JD_SOURCE_LABEL:-practice} ┬╖ ${family}"
     missing=$(crossfire_spool_field "$f" missing_elements)
     missing=${missing//[\[\]]/}
     missing=${missing// /}
     last_seen=$(date -u +%Y-%m-%dT%H:%M:%SZ)
     source_sid=$(crossfire_spool_field "$f" source_session_id)
     answer_ref=$(crossfire_spool_field "$f" answer_ref)
     ev_kind=$(awk '/^evidence:/{getline; if ($0 ~ /kind:/) {sub(/^  kind: /,""); print; exit}}' "$f")
     ev_val=$(awk '/^evidence:/{getline; getline; if ($0 ~ /value:/) {sub(/^  value: /,""); gsub(/^"/,""); gsub(/"$/,""); print; exit}}' "$f")
+    if [ ${#ev_val} -gt 180 ]; then
+      ev_val="${ev_val:0:177}..."
+    fi
     submitted=$(awk '/^submitted_answer:/{capture=1; next} capture && /^[^ ]/{exit} capture {sub(/^  /,""); print}' "$f")
     if crossfire_persist_weakness \
       "$HERMES_MEMORY_MD" "$family" "$topic" "$missing" "$last_seen" \
       "$source_sid" "$answer_ref" "${ev_kind:-quote}" "${ev_val:-}" "$submitted"; then
       persisted=$((persisted + 1))
       wid=$(crossfire_compute_weakness_id "$family" "$(crossfire_normalize_topic_key "$topic")")
       dest="${REPO_ROOT}/.crossfire/candidate-skills/unverified-${family}-followup/SKILL.md"
       mkdir -p "$(dirname "$dest")"
@@ -375,16 +376,36 @@ crossfire_practice_end() {
       fi
     else
       echo "practice_session: persist skipped/failed for ${topic}" >&2
     fi
     trap - RETURN 2>/dev/null || true
   done
   shopt -u nullglob
 
+  weak=""
+  strong=""
+  for f in "${spool_dir}"/*.yaml; do
+    [ -f "$f" ] || continue
+    fam=$(crossfire_spool_field "$f" family)
+    miss=$(crossfire_spool_field "$f" missing_elements)
+    if crossfire_spool_should_persist "$f"; then
+      weak="${weak};${fam}:${miss}"
+    else
+      strong="${strong};${fam}"
+    fi
+  done
+  weak="${weak#;}"
+  strong="${strong#;}"
+  report_text="Weak: ${weak:-none}
+Strong: ${strong:-none}"
+  crossfire_practice_kv report_weak "$weak"
+  crossfire_practice_kv report_strong "$strong"
+  printf '%s\n' "$report_text" | sed 's/^/report_line=/'
+
   crossfire_practice_kv event end
   crossfire_practice_kv persisted_count "$persisted"
   crossfire_practice_kv ack ok
 }
 
 usage() {
   echo "usage: $0 start | answer <text> | skip | end" >&2
   echo "  Requires CROSSFIRE_RUN_ID for answer/skip/end (printed by start)." >&2
diff --git a/tests/practice_jd.sh b/tests/practice_jd.sh
index e24c35e..29a82bf 100644
--- a/tests/practice_jd.sh
+++ b/tests/practice_jd.sh
@@ -53,10 +53,35 @@ skip_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
 }
 echo "$skip_out" | grep -q 'skipped=true' && ok "skip kv" || bad "skip kv: $skip_out"
 echo "$skip_out" | grep -q 'persist_recommended=false' && ok "skip no persist" || bad "skip persist"
 spool_count=$(find "$CROSSFIRE_RUNS_DIR/$run_id/spool" -name '*.yaml' 2>/dev/null | wc -l | tr -d ' ')
 [ "$spool_count" = "0" ] && ok "skip wrote no spool" || bad "skip wrote spool ($spool_count)"
 grep -q 'CROSSFIRE_TEMPERATURE=4' "$CROSSFIRE_RUNS_DIR/$run_id/practice.state" \
   && ok "skip saved temperature 4" || bad "skip saved temperature 4"
 
+dash_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
+  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run_id" \
+  bash "$REPO_ROOT/scripts/practice_session.sh" answer "I just kind of watched the dashboard.")
+echo "$dash_out" | grep -q 'persist_recommended=true' && ok "dash persist rec" || bad "dash persist rec"
+
+end_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
+  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run_id" \
+  bash "$REPO_ROOT/scripts/practice_session.sh" end) || {
+  bad "end failed: $end_out"
+}
+echo "$end_out" | grep -q 'report_weak=' && ok "report_weak kv" || bad "report_weak kv: $end_out"
+echo "$end_out" | grep -q 'report_strong=' && ok "report_strong kv" || bad "report_strong"
+echo "$end_out" | grep -q 'Weak:' && ok "report_text Weak" || bad "report_text Weak: $end_out"
+echo "$end_out" | grep -q 'Strong:' && ok "report_text Strong" || bad "report_text Strong"
+if grep -q 'q_live_01 practice gap' "$HERMES_HOME/memories/MEMORY.md"; then
+  bad "old practice-gap topic"
+else
+  ok "no q_live practice-gap topic"
+fi
+if grep -q 'Project Praetor' "$HERMES_HOME/memories/MEMORY.md" || grep -q 'praetor' "$HERMES_HOME/memories/MEMORY.md"; then
+  ok "topic uses source label"
+else
+  bad "topic missing source label"
+fi
+
 echo "practice_jd: passed=$pass failed=$fail"
 [ "$fail" -eq 0 ]
diff --git a/tests/test_memory_view.py b/tests/test_memory_view.py
index 99bb9ae..bbe47f6 100644
--- a/tests/test_memory_view.py
+++ b/tests/test_memory_view.py
@@ -95,16 +95,18 @@ class UiContractTest(unittest.TestCase):
         self.assertIn('id="jd-paste"', html)
         self.assertIn('id="persona"', html)
         self.assertIn('id="temperature"', html)
         self.assertIn('id="jd-context"', html)
         self.assertIn('id="skip"', html)
         self.assertIn("/api/packs", js)
         self.assertIn("jd_kind", js)
         self.assertIn("/api/session/skip", js)
+        self.assertIn("report_text", js)
+        self.assertNotIn("Persisted ${data.persisted_count", js)
 
 
 class HttpSmokeTest(unittest.TestCase):
     def test_memory_endpoint_and_static(self) -> None:
         import json
         import os
         import shutil
         import tempfile
