/** TTS adapter. Web Speech now; swap in elevenlabs.js later. */
export function createTtsAdapter() {
  const synth = window.speechSynthesis || null;

  return {
    speak(text) {
      if (!text || !synth || document.getElementById("mute")?.checked) return;
      synth.cancel();
      const u = new SpeechSynthesisUtterance(text);
      u.rate = 1;
      synth.speak(u);
    },
    cancel() {
      synth?.cancel();
    },
  };
}
