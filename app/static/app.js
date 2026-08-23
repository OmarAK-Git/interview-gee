import { createTtsAdapter } from "./tts.js";
import { createSttAdapter } from "./stt.js";

const tts = createTtsAdapter();
const stt = createSttAdapter();
const chat = document.getElementById("chat");
const meta = document.getElementById("meta");
const memory = document.getElementById("memory");
const answer = document.getElementById("answer");
const composer = document.getElementById("composer");
const micBtn = document.getElementById("mic");
const micHint = document.getElementById("mic-hint");
const inferenceSel = document.getElementById("inference");
const jdKind = document.getElementById("jd-kind");
const packWrap = document.getElementById("pack-wrap");
const pasteWrap = document.getElementById("paste-wrap");
const packSel = document.getElementById("pack-id");
const tempInput = document.getElementById("temperature");
const tempVal = document.getElementById("temperature-val");
const jdContext = document.getElementById("jd-context");

function selectedInference() {
  const v = inferenceSel?.value === "codex" ? "codex" : "nous";
  try {
    localStorage.setItem("crossfire-inference", v);
  } catch {
    /* ignore */
  }
  return v;
}

try {
  const saved = localStorage.getItem("crossfire-inference");
  if (saved === "codex" || saved === "nous") inferenceSel.value = saved;
} catch {
  /* ignore */
}

function bubble(role, text, extra = "") {
  const el = document.createElement("div");
  el.className = `bubble ${role} ${extra}`.trim();
  el.textContent = text;
  chat.appendChild(el);
  chat.scrollTop = chat.scrollHeight;
}

async function api(path, opts) {
  const res = await fetch(path, opts);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || res.statusText);
  return data;
}

function formatWhen(iso) {
  if (!iso) return "";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" });
}

function renderWeaknesses(data) {
  memory.replaceChildren();
  const records = Array.isArray(data.weaknesses) ? data.weaknesses : [];
  if (!data.exists || records.length === 0) {
    memory.textContent = "No weaknesses recorded yet.";
    return;
  }
  for (const w of records) {
    const card = document.createElement("article");
    card.className = "weakness-card";

    const family = document.createElement("span");
    family.className = `family ${w.family || ""}`;
    family.textContent = w.family || "unknown";
    card.appendChild(family);

    const title = document.createElement("h3");
    title.textContent = w.topic || "Untitled topic";
    card.appendChild(title);

    const missing = Array.isArray(w.missing_elements) ? w.missing_elements : [];
    if (missing.length) {
      const list = document.createElement("div");
      list.className = "missing";
      for (const item of missing) {
        const tag = document.createElement("span");
        tag.className = "tag";
        tag.textContent = item;
        list.appendChild(tag);
      }
      card.appendChild(list);
    }

    const metaLine = document.createElement("p");
    metaLine.className = "weak-meta";
    const times = Number(w.observation_count) || 1;
    const when = formatWhen(w.last_seen);
    metaLine.textContent = `Seen ${times} time${times === 1 ? "" : "s"}${when ? ` · ${when}` : ""}`;
    card.appendChild(metaLine);

    const ev = w.evidence || {};
    if (ev.kind === "quote" && ev.value) {
      const q = document.createElement("blockquote");
      q.textContent = ev.value;
      card.appendChild(q);
    }

    memory.appendChild(card);
  }
}

async function refreshMemory() {
  const data = await api("/api/memory");
  renderWeaknesses(data);
}

function showMeta(data) {
  const bits = [];
  if (data.session_id) bits.push(`<span class="chip">session ${data.session_id}</span>`);
  if (data.inference) bits.push(`<span class="chip">${data.inference}</span>`);
  if (data.source_label) bits.push(`<span class="chip">${data.source_label}</span>`);
  if (data.temperature) bits.push(`<span class="chip">temp ${data.temperature}</span>`);
  if (data.opening_target_source) bits.push(`<span class="chip">${data.opening_target_source}</span>`);
  if (data.assessment_status === "skipped") bits.push(`<span class="chip">assessment skipped</span>`);
  meta.innerHTML = bits.join(" ");
}

function syncJdKind() {
  const isPack = jdKind.value === "pack";
  packWrap.hidden = !isPack;
  pasteWrap.hidden = isPack;
}

jdKind.addEventListener("change", syncJdKind);
syncJdKind();

tempInput.addEventListener("input", () => {
  tempVal.textContent = tempInput.value;
});

async function loadPacks() {
  try {
    const data = await api("/api/packs");
    packSel.replaceChildren();
    for (const p of data.packs || []) {
      const opt = document.createElement("option");
      opt.value = p.id;
      opt.textContent = `${p.employer} · ${p.role}`;
      packSel.appendChild(opt);
    }
  } catch {
    /* packs unavailable */
  }
}

function setMicUi(on) {
  micBtn.setAttribute("aria-pressed", on ? "true" : "false");
  micBtn.classList.toggle("live", on);
  micBtn.textContent = on ? "Done" : "Speak";
}

function stopVoice() {
  stt.stop();
  setMicUi(false);
}

function startVoice() {
  tts.cancel();
  const ok = stt.start({
    onText(text) {
      answer.value = text;
    },
    onEnd() {
      setMicUi(false);
    },
    onError(err) {
      setMicUi(false);
      micHint.hidden = false;
      micHint.textContent = `Mic: ${err}. You can still type.`;
    },
  });
  if (ok) {
    setMicUi(true);
    micHint.hidden = true;
  }
}

function finishVoiceAndSend() {
  stopVoice();
  window.setTimeout(() => {
    if (answer.value.trim()) composer.requestSubmit();
  }, 200);
}

const sendBtn = document.getElementById("send");
const skipBtn = document.getElementById("skip");
const startBtn = document.getElementById("start");
const endBtn = document.getElementById("end");

function setBusy(on) {
  sendBtn.disabled = on;
  skipBtn.disabled = on;
  startBtn.disabled = on;
  endBtn.disabled = on;
  answer.disabled = on;
}

async function withWait(label, fn) {
  const wait = document.createElement("div");
  wait.className = "bubble interviewer waiting";
  wait.textContent = label;
  chat.appendChild(wait);
  chat.scrollTop = chat.scrollHeight;
  setBusy(true);
  try {
    return await fn();
  } finally {
    wait.remove();
    setBusy(false);
  }
}

document.getElementById("start").addEventListener("click", async () => {
  tts.cancel();
  stopVoice();
  try {
    const data = await withWait("Interviewer is thinking…", () => api("/api/session/start", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        inference: selectedInference(),
        jd_kind: jdKind.value,
        pack_id: packSel.value,
        paste: document.getElementById("jd-paste").value,
        persona: document.getElementById("persona").value,
        temperature: tempInput.value,
      }),
    }));
    chat.innerHTML = "";
    showMeta(data);
    if (data.context_text) {
      jdContext.textContent = data.context_text;
      jdContext.hidden = false;
    } else {
      jdContext.hidden = true;
    }
    if (data.attribution) bubble("interviewer", data.attribution);
    bubble("interviewer", data.question || data.tts_text || "(no question)");
    tts.speak(data.tts_text || data.question);
    await refreshMemory();
  } catch (err) {
    bubble("interviewer", err.message || "Need a job description");
  }
});

document.getElementById("end").addEventListener("click", async () => {
  tts.cancel();
  stopVoice();
  const data = await withWait("Wrapping up…", () =>
    api("/api/session/end", { method: "POST", body: "{}" }),
  );
  bubble("interviewer", `Session ended. Persisted ${data.persisted_count || 0} weakness(es).`);
  await refreshMemory();
});

composer.addEventListener("submit", async (e) => {
  e.preventDefault();
  stopVoice();
  const text = answer.value.trim();
  if (!text) return;
  bubble("operator", text);
  answer.value = "";
  const data = await withWait("Interviewer is thinking…", () =>
    api("/api/session/answer", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text, temperature: tempInput.value }),
    }),
  );
  showMeta(data);
  const extra = data.assessment_status === "skipped" ? "skipped" : "";
  bubble("interviewer", data.question || data.tts_text, extra);
  tts.speak(data.tts_text || data.question);
  await refreshMemory();
});

answer.addEventListener("keydown", (e) => {
  if (e.key !== "Enter" || e.shiftKey) return;
  e.preventDefault();
  if (stt.isListening()) finishVoiceAndSend();
  else composer.requestSubmit();
});

micBtn.addEventListener("click", () => {
  if (!stt.supported()) {
    micHint.hidden = false;
    micHint.textContent = "Voice replies need Chrome or Edge on this localhost page.";
    return;
  }
  if (stt.isListening()) finishVoiceAndSend();
  else startVoice();
});

skipBtn.addEventListener("click", async () => {
  tts.cancel();
  stopVoice();
  const data = await withWait("Interviewer is thinking…", () =>
    api("/api/session/skip", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ temperature: tempInput.value }),
    }),
  );
  showMeta(data);
  bubble("interviewer", data.question || data.tts_text, "skipped");
  tts.speak(data.tts_text || data.question);
});

if (!stt.supported()) {
  micBtn.disabled = true;
  micHint.hidden = false;
  micHint.textContent = "Voice replies need Chrome or Edge.";
}

refreshMemory().catch(() => {});
loadPacks();
