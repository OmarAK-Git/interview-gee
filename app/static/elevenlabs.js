/** ElevenLabs adapter stub. Fill in after you pick a voice. No API keys in the repo. */
export function createElevenLabsAdapter() {
  return {
    speak(_text) {
      console.warn("ElevenLabs adapter is a stub — use tts.js (Web Speech) until you wire a voice.");
    },
    cancel() {},
  };
}
