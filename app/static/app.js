import { createTtsAdapter } from "./tts.js";

const tts = createTtsAdapter();
const chat = document.getElementById("chat");
const meta = document.getElementById("meta");
const memory = document.getElementById("memory");
const answer = document.getElementById("answer");

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

async function refreshMemory() {
  const data = await api("/api/memory");
  memory.textContent = data.exists ? data.text : "No MEMORY.md yet.";
}

function showMeta(data) {
  const bits = [];
  if (data.session_id) bits.push(`<span class="chip">session ${data.session_id}</span>`);
  if (data.opening_target_source) bits.push(`<span class="chip">${data.opening_target_source}</span>`);
  if (data.assessment_status === "skipped") bits.push(`<span class="chip">assessment skipped</span>`);
  meta.innerHTML = bits.join(" ");
}

document.getElementById("start").addEventListener("click", async () => {
  tts.cancel();
  const data = await api("/api/session/start", { method: "POST", body: "{}" });
  chat.innerHTML = "";
  showMeta(data);
  if (data.attribution) bubble("interviewer", data.attribution);
  bubble("interviewer", data.question || data.tts_text || "(no question)");
  tts.speak(data.tts_text || data.question);
  await refreshMemory();
});

document.getElementById("end").addEventListener("click", async () => {
  tts.cancel();
  const data = await api("/api/session/end", { method: "POST", body: "{}" });
  bubble("interviewer", `Session ended. Persisted ${data.persisted_count || 0} weakness(es).`);
  await refreshMemory();
});

document.getElementById("composer").addEventListener("submit", async (e) => {
  e.preventDefault();
  const text = answer.value.trim();
  if (!text) return;
  bubble("operator", text);
  answer.value = "";
  const data = await api("/api/session/answer", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ text }),
  });
  showMeta(data);
  const extra = data.assessment_status === "skipped" ? "skipped" : "";
  bubble("interviewer", data.question || data.tts_text, extra);
  tts.speak(data.tts_text || data.question);
  await refreshMemory();
});

refreshMemory().catch(() => {});
