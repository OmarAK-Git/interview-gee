diff --git a/app/static/app.css b/app/static/app.css
index 7432295..3b28291 100644
--- a/app/static/app.css
+++ b/app/static/app.css
@@ -73,8 +73,17 @@ button.live, button[aria-pressed="true"] { background: #8b3a3a; color: #fff; }
 .weakness-card blockquote {
   margin: 0.4rem 0 0;
   padding-left: 0.6rem;
   border-left: 2px solid #3a4458;
   color: var(--muted);
   font-size: 0.85rem;
   font-style: italic;
 }
+.setup { display: flex; flex-wrap: wrap; gap: 0.75rem; margin-top: 0.75rem; align-items: flex-end; }
+.setup label { color: var(--muted); font-size: 0.85rem; display: flex; flex-direction: column; gap: 0.25rem; }
+.setup input, .setup select, .setup textarea {
+  background: var(--panel); color: var(--ink); border: 1px solid #2a3140; border-radius: 8px; padding: 0.3rem 0.45rem;
+}
+.context {
+  max-height: 8rem; overflow: auto; white-space: pre-wrap;
+  background: var(--panel); border-radius: 8px; padding: 0.6rem; margin-top: 0.6rem; font-size: 0.85rem; color: var(--muted);
+}
diff --git a/app/static/app.js b/app/static/app.js
index e4bb3e1..fc653a5 100644
--- a/app/static/app.js
+++ b/app/static/app.js
@@ -6,16 +6,23 @@ const stt = createSttAdapter();
 const chat = document.getElementById("chat");
 const meta = document.getElementById("meta");
 const memory = document.getElementById("memory");
 const answer = document.getElementById("answer");
 const composer = document.getElementById("composer");
 const micBtn = document.getElementById("mic");
 const micHint = document.getElementById("mic-hint");
 const inferenceSel = document.getElementById("inference");
+const jdKind = document.getElementById("jd-kind");
+const packWrap = document.getElementById("pack-wrap");
+const pasteWrap = document.getElementById("paste-wrap");
+const packSel = document.getElementById("pack-id");
+const tempInput = document.getElementById("temperature");
+const tempVal = document.getElementById("temperature-val");
+const jdContext = document.getElementById("jd-context");
 
 function selectedInference() {
   const v = inferenceSel?.value === "codex" ? "codex" : "nous";
   try {
     localStorage.setItem("crossfire-inference", v);
   } catch {
     /* ignore */
   }
@@ -106,21 +113,51 @@ async function refreshMemory() {
   const data = await api("/api/memory");
   renderWeaknesses(data);
 }
 
 function showMeta(data) {
   const bits = [];
   if (data.session_id) bits.push(`<span class="chip">session ${data.session_id}</span>`);
   if (data.inference) bits.push(`<span class="chip">${data.inference}</span>`);
+  if (data.source_label) bits.push(`<span class="chip">${data.source_label}</span>`);
+  if (data.temperature) bits.push(`<span class="chip">temp ${data.temperature}</span>`);
   if (data.opening_target_source) bits.push(`<span class="chip">${data.opening_target_source}</span>`);
   if (data.assessment_status === "skipped") bits.push(`<span class="chip">assessment skipped</span>`);
   meta.innerHTML = bits.join(" ");
 }
 
+function syncJdKind() {
+  const isPack = jdKind.value === "pack";
+  packWrap.hidden = !isPack;
+  pasteWrap.hidden = isPack;
+}
+
+jdKind.addEventListener("change", syncJdKind);
+syncJdKind();
+
+tempInput.addEventListener("input", () => {
+  tempVal.textContent = tempInput.value;
+});
+
+async function loadPacks() {
+  try {
+    const data = await api("/api/packs");
+    packSel.replaceChildren();
+    for (const p of data.packs || []) {
+      const opt = document.createElement("option");
+      opt.value = p.id;
+      opt.textContent = `${p.employer} ┬╖ ${p.role}`;
+      packSel.appendChild(opt);
+    }
+  } catch {
+    /* packs unavailable */
+  }
+}
+
 function setMicUi(on) {
   micBtn.setAttribute("aria-pressed", on ? "true" : "false");
   micBtn.classList.toggle("live", on);
   micBtn.textContent = on ? "Done" : "Speak";
 }
 
 function stopVoice() {
   stt.stop();
@@ -151,21 +188,23 @@ function startVoice() {
 function finishVoiceAndSend() {
   stopVoice();
   window.setTimeout(() => {
     if (answer.value.trim()) composer.requestSubmit();
   }, 200);
 }
 
 const sendBtn = document.getElementById("send");
+const skipBtn = document.getElementById("skip");
 const startBtn = document.getElementById("start");
 const endBtn = document.getElementById("end");
 
 function setBusy(on) {
   sendBtn.disabled = on;
+  skipBtn.disabled = on;
   startBtn.disabled = on;
   endBtn.disabled = on;
   answer.disabled = on;
 }
 
 async function withWait(label, fn) {
   const wait = document.createElement("div");
   wait.className = "bubble interviewer waiting";
@@ -179,27 +218,44 @@ async function withWait(label, fn) {
     wait.remove();
     setBusy(false);
   }
 }
 
 document.getElementById("start").addEventListener("click", async () => {
   tts.cancel();
   stopVoice();
-  const data = await withWait("Interviewer is thinkingΓÇª", () => api("/api/session/start", {
-    method: "POST",
-    headers: { "Content-Type": "application/json" },
-    body: JSON.stringify({ inference: selectedInference() }),
-  }));
-  chat.innerHTML = "";
-  showMeta(data);
-  if (data.attribution) bubble("interviewer", data.attribution);
-  bubble("interviewer", data.question || data.tts_text || "(no question)");
-  tts.speak(data.tts_text || data.question);
-  await refreshMemory();
+  try {
+    const data = await withWait("Interviewer is thinkingΓÇª", () => api("/api/session/start", {
+      method: "POST",
+      headers: { "Content-Type": "application/json" },
+      body: JSON.stringify({
+        inference: selectedInference(),
+        jd_kind: jdKind.value,
+        pack_id: packSel.value,
+        paste: document.getElementById("jd-paste").value,
+        persona: document.getElementById("persona").value,
+        temperature: tempInput.value,
+      }),
+    }));
+    chat.innerHTML = "";
+    showMeta(data);
+    if (data.context_text) {
+      jdContext.textContent = data.context_text;
+      jdContext.hidden = false;
+    } else {
+      jdContext.hidden = true;
+    }
+    if (data.attribution) bubble("interviewer", data.attribution);
+    bubble("interviewer", data.question || data.tts_text || "(no question)");
+    tts.speak(data.tts_text || data.question);
+    await refreshMemory();
+  } catch (err) {
+    bubble("interviewer", err.message || "Need a job description");
+  }
 });
 
 document.getElementById("end").addEventListener("click", async () => {
   tts.cancel();
   stopVoice();
   const data = await withWait("Wrapping upΓÇª", () =>
     api("/api/session/end", { method: "POST", body: "{}" }),
   );
@@ -213,17 +269,17 @@ composer.addEventListener("submit", async (e) => {
   const text = answer.value.trim();
   if (!text) return;
   bubble("operator", text);
   answer.value = "";
   const data = await withWait("Interviewer is thinkingΓÇª", () =>
     api("/api/session/answer", {
       method: "POST",
       headers: { "Content-Type": "application/json" },
-      body: JSON.stringify({ text }),
+      body: JSON.stringify({ text, temperature: tempInput.value }),
     }),
   );
   showMeta(data);
   const extra = data.assessment_status === "skipped" ? "skipped" : "";
   bubble("interviewer", data.question || data.tts_text, extra);
   tts.speak(data.tts_text || data.question);
   await refreshMemory();
 });
@@ -240,15 +296,31 @@ micBtn.addEventListener("click", () => {
     micHint.hidden = false;
     micHint.textContent = "Voice replies need Chrome or Edge on this localhost page.";
     return;
   }
   if (stt.isListening()) finishVoiceAndSend();
   else startVoice();
 });
 
+skipBtn.addEventListener("click", async () => {
+  tts.cancel();
+  stopVoice();
+  const data = await withWait("Interviewer is thinkingΓÇª", () =>
+    api("/api/session/skip", {
+      method: "POST",
+      headers: { "Content-Type": "application/json" },
+      body: JSON.stringify({ temperature: tempInput.value }),
+    }),
+  );
+  showMeta(data);
+  bubble("interviewer", data.question || data.tts_text, "skipped");
+  tts.speak(data.tts_text || data.question);
+});
+
 if (!stt.supported()) {
   micBtn.disabled = true;
   micHint.hidden = false;
   micHint.textContent = "Voice replies need Chrome or Edge.";
 }
 
 refreshMemory().catch(() => {});
+loadPacks();
diff --git a/app/static/index.html b/app/static/index.html
index 913b1a3..846a4d6 100644
--- a/app/static/index.html
+++ b/app/static/index.html
@@ -6,23 +6,46 @@
   <title>Crossfire practice</title>
   <link rel="stylesheet" href="/static/app.css" />
 </head>
 <body>
   <header>
     <h1>Crossfire</h1>
     <p class="sub">Live interview practice. Hermes asks. You answer. Memory persists.</p>
     <div class="meta" id="meta"></div>
+    <div id="session-setup" class="setup">
+      <label>JD
+        <select id="jd-kind">
+          <option value="pack">Shipped pack</option>
+          <option value="paste">Paste</option>
+        </select>
+      </label>
+      <label id="pack-wrap">Pack
+        <select id="pack-id"></select>
+      </label>
+      <label id="paste-wrap" hidden>Paste JD
+        <textarea id="jd-paste" rows="4" placeholder="Paste one job description for this session"></textarea>
+      </label>
+      <label>Persona (optional)
+        <input id="persona" type="text" placeholder="e.g. Staff detection engineer, 8 years, late-stage loop" />
+      </label>
+      <label>Temperature
+        <input id="temperature" type="range" min="1" max="5" value="2" />
+        <span id="temperature-val">2</span>
+      </label>
+    </div>
+    <div id="jd-context" class="context" hidden></div>
   </header>
   <main>
     <section id="chat" aria-live="polite"></section>
     <form id="composer">
       <textarea id="answer" rows="4" placeholder="Type or speak your answerΓÇª Enter to send, Shift+Enter for a new line" required></textarea>
       <div class="row">
         <button type="submit" id="send">Send</button>
+        <button type="button" id="skip">Skip</button>
         <button type="button" id="mic" aria-pressed="false" title="Answer by voice. Click again when you are done to send.">Speak</button>
         <button type="button" id="start">New session</button>
         <button type="button" id="end">End session</button>
         <label class="inference">Inference
           <select id="inference" title="Applies on New session. Hermes stays the harness.">
             <option value="nous">Nous</option>
             <option value="codex">Codex</option>
           </select>
diff --git a/tests/test_memory_view.py b/tests/test_memory_view.py
index 67fe513..99bb9ae 100644
--- a/tests/test_memory_view.py
+++ b/tests/test_memory_view.py
@@ -85,16 +85,26 @@ class UiContractTest(unittest.TestCase):
         self.assertIn(">Speak</button>", html)
         self.assertIn("stt.js", js)
         self.assertTrue((ROOT / "app" / "static" / "stt.js").is_file())
         self.assertIn('id="memory"', html)
         self.assertNotIn("<pre", html)
         self.assertIn('e.key !== "Enter"', js)
         self.assertIn("finishVoiceAndSend", js)
         self.assertIn("renderWeaknesses", js)
+        self.assertIn('id="jd-kind"', html)
+        self.assertIn('id="pack-id"', html)
+        self.assertIn('id="jd-paste"', html)
+        self.assertIn('id="persona"', html)
+        self.assertIn('id="temperature"', html)
+        self.assertIn('id="jd-context"', html)
+        self.assertIn('id="skip"', html)
+        self.assertIn("/api/packs", js)
+        self.assertIn("jd_kind", js)
+        self.assertIn("/api/session/skip", js)
 
 
 class HttpSmokeTest(unittest.TestCase):
     def test_memory_endpoint_and_static(self) -> None:
         import json
         import os
         import shutil
         import tempfile
