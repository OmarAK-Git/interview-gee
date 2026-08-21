/** Browser speech-to-text. Web Speech now; no API keys. */
export function createSttAdapter() {
  const Rec = window.SpeechRecognition || window.webkitSpeechRecognition;
  let rec = null;
  let listening = false;
  let want = false;
  let committed = "";
  let lastFinal = "";

  function supported() {
    return Boolean(Rec);
  }

  function emit(onText, interim) {
    const parts = [committed, lastFinal, interim].filter(Boolean);
    onText?.(parts.join(" ").replace(/\s+/g, " ").trim());
  }

  function start({ onText, onEnd, onError }) {
    if (!Rec || want) return false;
    rec = new Rec();
    rec.continuous = true;
    rec.interimResults = true;
    rec.lang = "en-US";
    listening = true;
    want = true;
    committed = "";
    lastFinal = "";

    rec.onresult = (ev) => {
      let finalText = "";
      let interim = "";
      for (let i = 0; i < ev.results.length; i++) {
        const piece = ev.results[i][0].transcript;
        if (ev.results[i].isFinal) finalText += (finalText ? " " : "") + piece;
        else interim += (interim ? " " : "") + piece;
      }
      lastFinal = finalText;
      emit(onText, interim);
    };
    rec.onerror = (ev) => {
      if (ev.error === "aborted" || ev.error === "no-speech") return;
      onError?.(ev.error || "speech error");
    };
    rec.onend = () => {
      listening = false;
      if (lastFinal) {
        committed = [committed, lastFinal].filter(Boolean).join(" ");
        lastFinal = "";
        emit(onText, "");
      }
      if (want) {
        try {
          rec.start();
          listening = true;
          return;
        } catch {
          want = false;
        }
      }
      rec = null;
      onEnd?.();
    };
    rec.start();
    return true;
  }

  function stop() {
    want = false;
    try {
      rec?.stop();
    } catch {
      /* already stopped */
    }
  }

  function isListening() {
    return want;
  }

  return { supported, start, stop, isListening };
}
