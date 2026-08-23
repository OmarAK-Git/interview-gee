diff --git a/scripts/practice_session.sh b/scripts/practice_session.sh
index 398c7b2..dcf1646 100644
--- a/scripts/practice_session.sh
+++ b/scripts/practice_session.sh
@@ -38,16 +38,20 @@ EOF
 
 crossfire_practice_ensure_skill() {
   local dest="${HERMES_SKILLS_DIR}/crossfire-interviewer"
   mkdir -p "$dest" "${HERMES_HOME}/memories"
   cp "${CROSSFIRE_SKILL_PATH}/SKILL.md" "${dest}/SKILL.md"
   if [ -f "${CROSSFIRE_SKILL_PATH}/questions.md" ]; then
     cp "${CROSSFIRE_SKILL_PATH}/questions.md" "${dest}/questions.md"
   fi
+  if [ -d "${CROSSFIRE_SKILL_PATH}/sources" ]; then
+    mkdir -p "${dest}/sources"
+    cp "${CROSSFIRE_SKILL_PATH}/sources/"*.md "${dest}/sources/" 2>/dev/null || true
+  fi
 }
 
 crossfire_practice_kv() {
   printf '%s=%s\n' "$1" "$2"
 }
 
 crossfire_practice_append_transcript() {
   local role="${1:-}" text="${2:-}"
diff --git a/skills/crossfire-interviewer/SKILL.md b/skills/crossfire-interviewer/SKILL.md
index 230fbb2..6140d5b 100644
--- a/skills/crossfire-interviewer/SKILL.md
+++ b/skills/crossfire-interviewer/SKILL.md
@@ -179,8 +179,47 @@ Use when the operator starts interactive Hermes against the **Monday profile** (
 | Opener (first question of a return session) | `--toolsets skills` (and `memory` if in-context `MEMORY.md` is loaded). Omit `session_search`. |
 | After opener | `session_search` optional. If unavailable or errors, continue from `MEMORY.md` and the current transcript ΓÇö degrade gracefully, do not fail the session. |
 
 ### Assessment and exit
 
 - Emit **propose-only YAML** after each answer (same shape as session one). Do **not** write `MEMORY.md` or `.crossfire/candidate-skills/`.
 - Buffer assessments until session end. On normal exit, surface any qualifying proposals (`persist_recommended: true` or `count(missing_elements) >= 2`) so the operator or a future harness can flush them. A raw SIGKILL path is not guaranteed to flush.
 - Demo weaknesses staged under `.crossfire/profiles/stage` must **never** be treated as Monday history. Only weaknesses already in the operatorΓÇÖs Monday `MEMORY.md` inform opener targeting.
+
+## Practice interviewer (session JD)
+
+Use for the practice UI (`sparring-1.1.x`). Demo session-one/two contracts above stay in force when the demo harness is driving. Practice already strips Hermes `--toolsets`; the session JD is in the operator prompt, not read from disk at runtime.
+
+### Session context
+
+The wrapper names exactly one JD for this session (a shipped pack or pasted text), an optional interviewer persona, and a temperature 1ΓÇô5 (default 2). Interview only that JD. Do not mix facts from another employer or pack. Do not invent systems, metrics, or employers that are not in the session JD.
+
+If `MEMORY.md` has a weakness whose family fits this JD, the first question may target those missing elements. Do not speak `weakness_id`. Do not ask the operator to pick a topic.
+
+Optional persona (job title, what they do, how long they have been there) flavors voice only. Empty persona = default Crossfire interviewer.
+
+### Asking
+
+Ask one question at a time.
+
+- Temperature 1: core competency only; prefer staying on the current story (probe).
+- Temperature 2 (default): core competency, typical angle; may open a new core competency after a complete answer.
+- Temperature 3ΓÇô5: edge competency or a rarer in-role angle. Still fact-bound. Not trivia. Not a question that would never appear for this role.
+
+Force a recent real story when the family is behavioral: last time, I not we, a number, what changed. For technical: problem, approach, tradeoff, verification. For product: user, constraint, decision, metric.
+
+### After a real answer
+
+1. Declare exactly one family.
+2. `missing_elements` is what was actually absent ΓÇö not the full checklist.
+3. Emit the same propose-only YAML as session one. `persist_recommended: true` only when `count(missing_elements) >= 2`.
+4. Then probe the gaps or ask the next question per temperature. Prefer a probe when the answer was thin.
+
+Do not write `MEMORY.md`. Do not ask the operator to confirm persist.
+
+### Skip
+
+If the wrapper says the last question was skipped, do not emit assessment YAML. Ask a different question from the same JD. If they skipped because it sounded invented, stay inside allowed facts.
+
+### End
+
+If the wrapper asks for a closer, one short spoken line is enough. The wrapper owns the strong/weak report. Still do not write `MEMORY.md`.
diff --git a/tests/source_packs.sh b/tests/source_packs.sh
index 1ec993c..9a9063e 100644
--- a/tests/source_packs.sh
+++ b/tests/source_packs.sh
@@ -22,10 +22,17 @@ printf '%s' "$mc" | grep -qiE 'Praetor|ALTER_EGO|McCain|advisory-only|never-cont
 pr=$(cat "$SRC/praetor.md")
 printf '%s' "$pr" | grep -qiE 'McCain|ALTER_EGO|Agent Suite|R-281517|KL-divergence|shadow profile' \
   && bad "praetor leak" || ok "praetor leak"
 
 ae=$(cat "$SRC/alter-ego.md")
 printf '%s' "$ae" | grep -qiE 'McCain|Praetor|Agent Suite|R-281517|advisory-only|never-contain' \
   && bad "alter-ego leak" || ok "alter-ego leak"
 
+SKILL="$REPO_ROOT/skills/crossfire-interviewer/SKILL.md"
+grep -q '## Practice interviewer (session JD)' "$SKILL" && ok "skill procedure heading" || bad "skill procedure heading"
+grep -q 'q_technical_01' "$SKILL" && ok "demo q_technical_01 remains" || bad "demo q_technical_01 remains"
+grep -Fq 'Walk through how Praetor decides not to contain' "$SKILL" && ok "demo question verbatim" || bad "demo question verbatim"
+grep -q 'temperature' "$SKILL" && ok "skill mentions temperature" || bad "skill mentions temperature"
+grep -q 'Skip' "$SKILL" && ok "skill mentions Skip" || bad "skill mentions Skip"
+
 echo "source_packs: passed=$pass failed=$fail"
 [ "$fail" -eq 0 ]
