diff --git a/app/server.py b/app/server.py
index 1da5dcd..6f36576 100644
--- a/app/server.py
+++ b/app/server.py
@@ -7,17 +7,17 @@ import os
 import subprocess
 import sys
 from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
 from pathlib import Path
 from urllib.parse import urlparse
 
 from inference import normalize_inference
 from memory_view import parse_weaknesses
-from packs import list_source_packs, start_session_args
+from packs import list_source_packs, normalize_temperature, start_session_args
 
 REPO_ROOT = Path(__file__).resolve().parent.parent
 SCRIPT = REPO_ROOT / "scripts" / "practice_session.sh"
 STATIC = Path(__file__).resolve().parent / "static"
 PACKS = REPO_ROOT / "skills" / "crossfire-interviewer" / "sources"
 HOST = os.environ.get("CROSSFIRE_UI_HOST", "127.0.0.1")
 PORT = int(os.environ.get("CROSSFIRE_UI_PORT", "8787"))
 
@@ -178,27 +178,60 @@ class Handler(BaseHTTPRequestHandler):
         if path == "/api/session/answer":
             text = (payload.get("text") or "").strip()
             if not text:
                 self._json(400, {"error": "empty answer"})
                 return
             if not SESSION["run_id"]:
                 self._json(409, {"error": "no active session"})
                 return
+            extra_env: dict[str, str] = {"CROSSFIRE_RUN_ID": SESSION["run_id"]}
+            if "temperature" in payload:
+                try:
+                    extra_env["CROSSFIRE_TEMPERATURE"] = str(
+                        normalize_temperature(payload.get("temperature"))
+                    )
+                except ValueError as exc:
+                    self._json(400, {"error": str(exc)})
+                    return
             code, out, err = run_practice(
                 ["answer", text],
-                extra_env={"CROSSFIRE_RUN_ID": SESSION["run_id"]},
+                extra_env=extra_env,
             )
             parsed = kv_parse(out)
             if code != 0 and parsed.get("assessment_status") != "skipped":
                 self._json(500, {"error": err or out, "stdout": out, **parsed})
                 return
             self._json(200, parsed)
             return
 
+        if path == "/api/session/skip":
+            if not SESSION["run_id"]:
+                self._json(409, {"error": "no active session"})
+                return
+            extra_env: dict[str, str] = {"CROSSFIRE_RUN_ID": SESSION["run_id"]}
+            if "temperature" in payload:
+                try:
+                    extra_env["CROSSFIRE_TEMPERATURE"] = str(
+                        normalize_temperature(payload.get("temperature"))
+                    )
+                except ValueError as exc:
+                    self._json(400, {"error": str(exc)})
+                    return
+            code, out, err = run_practice(
+                ["skip"],
+                extra_env=extra_env,
+            )
+            parsed = kv_parse(out)
+            if code != 0:
+                self._json(500, {"error": err or out, "stdout": out, **parsed})
+                return
+            self._json(200, parsed)
+            return
+
         if path == "/api/session/end":
             if not SESSION["run_id"]:
                 self._json(409, {"error": "no active session"})
                 return
             code, out, err = run_practice(
                 ["end"],
                 extra_env={"CROSSFIRE_RUN_ID": SESSION["run_id"]},
             )
diff --git a/scripts/practice_session.sh b/scripts/practice_session.sh
index 8f8da39..02c8e55 100644
--- a/scripts/practice_session.sh
+++ b/scripts/practice_session.sh
@@ -10,21 +10,43 @@ source "${_practice_dir}/weakness_memory.sh"
 # shellcheck source=scripts/stage_candidate_skill.sh
 source "${_practice_dir}/stage_candidate_skill.sh"
 
 crossfire_practice_state_path() {
   printf '%s/%s/practice.state' "$CROSSFIRE_RUNS_DIR" "${CROSSFIRE_RUN_ID:?run_id required}"
 }
 
 crossfire_practice_load_state() {
-  local f
+  local f ctx
   f=$(crossfire_practice_state_path)
   [ -f "$f" ] || fail_closed "no practice session; run start"
   # shellcheck disable=SC1090
   source "$f"
+  if [ -z "${CROSSFIRE_JD_CONTEXT:-}" ]; then
+    ctx="${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/jd-context.md"
+    if [ -f "$ctx" ]; then
+      CROSSFIRE_JD_CONTEXT=$(cat "$ctx")
+      export CROSSFIRE_JD_CONTEXT
+    fi
+  fi
+}
+
+crossfire_practice_interviewer_preamble() {
+  cat <<EOF
+You are the Crossfire interviewer for a practice session.
+Practice session JD (only allowed facts):
+${CROSSFIRE_JD_CONTEXT}
+
+Source: ${CROSSFIRE_JD_SOURCE_LABEL} (${CROSSFIRE_JD_SOURCE_ID})
+Temperature: ${CROSSFIRE_TEMPERATURE:-2} (1=stay on story/core; 2=typical core; 3-5=rarer in-role, still in this JD).
+Interviewer persona (optional, flavor only): ${CROSSFIRE_PERSONA:-}
+Follow the Practice interviewer (session JD) section of the crossfire-interviewer skill.
+Do not invent employers or systems that are not in the session JD.
+Do not write MEMORY.md.
+EOF
 }
 
 crossfire_practice_save_state() {
   local f dir
   dir="${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}"
   mkdir -p "$dir/spool" "$dir/transcript" "$dir/skipped"
   f="${dir}/practice.state"
   cat >"$f" <<EOF
@@ -105,22 +127,23 @@ crossfire_practice_start() {
       question=$(crossfire_stub_opener_question "${CROSSFIRE_OPENER_FAMILY}" "${CROSSFIRE_OPENER_MISSING_CSV}")
     else
       question="Walk through how Praetor decides not to contain. What is the advisory boundary, and how would you know the decision was wrong?"
     fi
   else
     stdout=$(mktemp)
     stderr=$(mktemp)
     if [ "$target_source" = "MEMORY.md" ]; then
-      cmdline=$(crossfire_build_opener_cmdline \
-        "$CROSSFIRE_OPENER_WEAKNESS_ID" "$CROSSFIRE_OPENER_FAMILY" \
-        "$CROSSFIRE_OPENER_MISSING_CSV" MEMORY.md \
-        "${HERMES_SKILLS_DIR}/crossfire-interviewer")
+      prompt="$(crossfire_practice_interviewer_preamble)
+Session-two style opener. opening_target_source=MEMORY.md weakness_id=${CROSSFIRE_OPENER_WEAKNESS_ID} family=${CROSSFIRE_OPENER_FAMILY} missing_elements=[${CROSSFIRE_OPENER_MISSING_CSV}]. Ask ONE question that targets those missing elements and stays inside this session JD. Do not name weakness_id. Reply with the question only."
+      cmdline="hermes chat -Q --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "${HERMES_SKILLS_DIR}/crossfire-interviewer") --source tool -q $(printf '%q' "$prompt")"
     else
-      cmdline="hermes chat -Q --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "${HERMES_SKILLS_DIR}/crossfire-interviewer") --source tool -q $(printf '%q' "You are the Crossfire interviewer. Ask ONE interview question from the McCain / Mastercard / Praetor / ALTER_EGO source material. Reply with the question only.")"
+      prompt="$(crossfire_practice_interviewer_preamble)
+Ask ONE interview question from this JD only. Reply with the question only."
+      cmdline="hermes chat -Q --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "${HERMES_SKILLS_DIR}/crossfire-interviewer") --source tool -q $(printf '%q' "$prompt")"
     fi
     cmdline=$(crossfire_practice_inject_inference "$cmdline")
     if ! crossfire_hermes_invoke "$cmdline" "$stdout" "$stderr"; then
       rm -f "$stdout" "$stderr"
       fail_closed "practice start: Hermes invoke failed"
     fi
     CROSSFIRE_SESSION_ID=$(crossfire_parse_session_id_from_stderr "$stderr")
     CROSSFIRE_SESSION_ID="${CROSSFIRE_SESSION_ID:-sess_live_practice}"
@@ -152,17 +175,20 @@ crossfire_practice_answer() {
   local stdout stderr proposal qid status="ok" persist="false" question=""
   local spool_file skip_file cmdline skill
 
   [ -n "$answer" ] || fail_closed "empty answer"
   : "${CROSSFIRE_RUN_ID:?}"
   crossfire_practice_load_state
   CROSSFIRE_INFERENCE=$(crossfire_practice_resolve_inference)
   export CROSSFIRE_INFERENCE
+  CROSSFIRE_TEMPERATURE="${CROSSFIRE_TEMPERATURE:-2}"
+  export CROSSFIRE_TEMPERATURE
   crossfire_require_monday_home
+  [ -n "${CROSSFIRE_JD_CONTEXT:-}" ] || fail_closed "answer requires a session JD"
   CROSSFIRE_TURN=$((CROSSFIRE_TURN + 1))
   qid="q_live_$(printf '%02d' "$CROSSFIRE_TURN")"
   crossfire_practice_append_transcript "operator" "$answer"
 
   skill="${HERMES_SKILLS_DIR}/crossfire-interviewer"
   stdout=$(mktemp)
   stderr=$(mktemp)
 
@@ -190,19 +216,21 @@ persist_recommended: false
 For Mastercard Agent Suite (R-281517), how would you sequence rollout when a false positive could freeze a merchant?
 EOF
     fi
     CROSSFIRE_SESSION_ID="${CROSSFIRE_SESSION_ID:-sess_stub_practice}"
     : >"$stderr"
     echo "session_id: ${CROSSFIRE_SESSION_ID}" >>"$stderr"
   else
     [ -n "$CROSSFIRE_SESSION_ID" ] || fail_closed "missing session_id"
-    cmdline="hermes chat -Q --resume $(printf '%q' "$CROSSFIRE_SESSION_ID") --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "$skill") --source tool -q $(printf '%q' "Operator answer: ${answer}
+    prompt="$(crossfire_practice_interviewer_preamble)
+Operator answer: ${answer}
 
-Assess against exactly one family checklist. Emit propose-only YAML (family, missing_elements, evidence, persist_recommended) then ask ONE follow-up interview question. One model pass. Do not ask the operator to confirm persistence. Do not write MEMORY.md.")"
+Assess against exactly one family checklist. missing_elements = what was actually absent, not the full checklist. Emit propose-only YAML (family, missing_elements, evidence, persist_recommended) then ask ONE follow-up interview question per temperature. One model pass. Do not ask the operator to confirm persistence. Do not write MEMORY.md."
+    cmdline="hermes chat -Q --resume $(printf '%q' "$CROSSFIRE_SESSION_ID") --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "$skill") --source tool -q $(printf '%q' "$prompt")"
     cmdline=$(crossfire_practice_inject_inference "$cmdline")
     if ! crossfire_hermes_invoke "$cmdline" "$stdout" "$stderr"; then
       # Keep the user text; skip assessment; continue.
       status="skipped"
       skip_file="${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/skipped/${qid}.stdout"
       mkdir -p "$(dirname "$skip_file")"
       cat "$stdout" >"$skip_file" || true
       cat "$stderr" >>"$skip_file" || true
@@ -246,16 +274,54 @@ Assess against exactly one family checklist. Emit propose-only YAML (family, mis
   crossfire_practice_append_transcript "interviewer" "$question"
   crossfire_practice_kv event answer
   crossfire_practice_kv assessment_status "$status"
   crossfire_practice_kv persist_recommended "$persist"
   crossfire_practice_kv question "$question"
   crossfire_practice_kv tts_text "$question"
 }
 
+crossfire_practice_skip() {
+  local stdout stderr question
+  : "${CROSSFIRE_RUN_ID:?}"
+  crossfire_practice_load_state
+  CROSSFIRE_INFERENCE=$(crossfire_practice_resolve_inference)
+  export CROSSFIRE_INFERENCE
+  CROSSFIRE_TEMPERATURE="${CROSSFIRE_TEMPERATURE:-2}"
+  export CROSSFIRE_TEMPERATURE
+  crossfire_require_monday_home
+  [ -n "${CROSSFIRE_JD_CONTEXT:-}" ] || fail_closed "skip requires a session JD"
+
+  if [ "${CROSSFIRE_PRACTICE_STUB:-0}" = "1" ]; then
+    question="Different question from the same JD ΓÇö what tradeoff did you accept?"
+  else
+    stdout=$(mktemp)
+    stderr=$(mktemp)
+    prompt="$(crossfire_practice_interviewer_preamble)
+The operator skipped the last question (it may have sounded invented). Do not emit assessment YAML. Ask ONE different interview question from the same JD only. Reply with the question only."
+    cmdline="hermes chat -Q --resume $(printf '%q' "$CROSSFIRE_SESSION_ID") --reasoning none --max-turns 3 --toolsets skills --skills $(printf '%q' "${HERMES_SKILLS_DIR}/crossfire-interviewer") --source tool -q $(printf '%q' "$prompt")"
+    cmdline=$(crossfire_practice_inject_inference "$cmdline")
+    if ! crossfire_hermes_invoke "$cmdline" "$stdout" "$stderr"; then
+      question="I will stay inside this job description. What problem were you solving, and how did you verify it?"
+    else
+      question=$(crossfire_extract_spoken_question "$(cat "$stdout")")
+      [ -n "$question" ] || question="Same JD, different angle: what would make this decision wrong?"
+    fi
+    rm -f "$stdout" "$stderr"
+  fi
+  crossfire_practice_save_state
+  crossfire_practice_append_transcript "interviewer" "(skipped previous) $question"
+  crossfire_practice_kv event skip
+  crossfire_practice_kv skipped true
+  crossfire_practice_kv assessment_status skipped
+  crossfire_practice_kv persist_recommended false
+  crossfire_practice_kv question "$question"
+  crossfire_practice_kv tts_text "$question"
+}
+
 crossfire_practice_end() {
   local spool_dir f persisted=0
   : "${CROSSFIRE_RUN_ID:?}"
   crossfire_practice_load_state
   crossfire_require_monday_home
   spool_dir="${CROSSFIRE_RUNS_DIR}/${CROSSFIRE_RUN_ID}/spool"
   mkdir -p "$(dirname "$HERMES_MEMORY_MD")"
 
@@ -297,27 +363,31 @@ crossfire_practice_end() {
   shopt -u nullglob
 
   crossfire_practice_kv event end
   crossfire_practice_kv persisted_count "$persisted"
   crossfire_practice_kv ack ok
 }
 
 usage() {
-  echo "usage: $0 start | answer <text> | end" >&2
-  echo "  Requires CROSSFIRE_RUN_ID for answer/end (printed by start)." >&2
+  echo "usage: $0 start | answer <text> | skip | end" >&2
+  echo "  Requires CROSSFIRE_RUN_ID for answer/skip/end (printed by start)." >&2
   exit 2
 }
 
 cmd="${1:-}"
 shift || true
 case "$cmd" in
   start) crossfire_practice_start ;;
   answer)
     CROSSFIRE_RUN_ID="${CROSSFIRE_RUN_ID:?set CROSSFIRE_RUN_ID from start}"
     crossfire_practice_answer "${1:-}"
     ;;
+  skip)
+    CROSSFIRE_RUN_ID="${CROSSFIRE_RUN_ID:?set CROSSFIRE_RUN_ID from start}"
+    crossfire_practice_skip
+    ;;
   end)
     CROSSFIRE_RUN_ID="${CROSSFIRE_RUN_ID:?set CROSSFIRE_RUN_ID from start}"
     crossfire_practice_end
     ;;
   *) usage ;;
 esac
diff --git a/tests/practice_jd.sh b/tests/practice_jd.sh
index 838894e..61a6cff 100644
--- a/tests/practice_jd.sh
+++ b/tests/practice_jd.sh
@@ -33,10 +33,28 @@ start_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
   bad "start with pack failed"
   echo "$start_out"
   echo "practice_jd: passed=$pass failed=$fail"
   exit 1
 }
 echo "$start_out" | grep -q 'source_id=praetor' && ok "source_id printed" || bad "source_id printed"
 echo "$start_out" | grep -q 'temperature=2' && ok "temperature printed" || bad "temperature printed"
 
+run_id=$(echo "$start_out" | awk -F= '/^run_id=/{print $2; exit}')
+
+grep -q 'crossfire_practice_interviewer_preamble' "$REPO_ROOT/scripts/practice_session.sh" \
+  && ok "preamble helper exists" || bad "preamble helper exists"
+grep -q 'Practice session JD' "$REPO_ROOT/scripts/practice_session.sh" \
+  && ok "prompt names session JD" || bad "prompt names session JD"
+
+skip_out=$(HOME="$HOME" HERMES_HOME="$HERMES_HOME" CROSSFIRE_PRACTICE_STUB=1 \
+  CROSSFIRE_RUNS_DIR="$CROSSFIRE_RUNS_DIR" CROSSFIRE_RUN_ID="$run_id" \
+  CROSSFIRE_TEMPERATURE=4 \
+  bash "$REPO_ROOT/scripts/practice_session.sh" skip) || {
+  bad "skip command failed: $skip_out"
+}
+echo "$skip_out" | grep -q 'skipped=true' && ok "skip kv" || bad "skip kv: $skip_out"
+echo "$skip_out" | grep -q 'persist_recommended=false' && ok "skip no persist" || bad "skip persist"
+spool_count=$(find "$CROSSFIRE_RUNS_DIR/$run_id/spool" -name '*.yaml' 2>/dev/null | wc -l | tr -d ' ')
+[ "$spool_count" = "0" ] && ok "skip wrote no spool" || bad "skip wrote spool ($spool_count)"
+
 echo "practice_jd: passed=$pass failed=$fail"
 [ "$fail" -eq 0 ]
