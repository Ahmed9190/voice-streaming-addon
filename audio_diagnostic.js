// Audio Diagnostic Script
// Run this in the browser console (F12) to check audio element state

console.log("🔍 Audio Diagnostic Starting...");
console.log("================================");

const card = document.querySelector('voice-receiving-card');
if (!card) {
  console.error("❌ Voice receiving card not found!");
} else {
  console.log("✅ Card found");

  const audio = card.shadowRoot.querySelector('audio');
  if (!audio) {
    console.error("❌ Audio element not found!");
  } else {
    console.log("✅ Audio element found");
    console.log("");

    console.log("📊 Audio Element State:");
    console.log("  srcObject:", !!audio.srcObject);
    console.log("  paused:", audio.paused);
    console.log("  volume:", audio.volume);
    console.log("  muted:", audio.muted);
    console.log("  readyState:", audio.readyState, ["HAVE_NOTHING", "HAVE_METADATA", "HAVE_CURRENT_DATA", "HAVE_FUTURE_DATA", "HAVE_ENOUGH_DATA"][audio.readyState]);
    console.log("  currentTime:", audio.currentTime);
    console.log("  duration:", audio.duration);
    console.log("");

    if (audio.srcObject) {
      const stream = audio.srcObject;
      console.log("📡 MediaStream State:");
      console.log("  id:", stream.id);
      console.log("  active:", stream.active);
      console.log("  tracks:", stream.getTracks().length);
      console.log("");

      stream.getTracks().forEach((track, i) => {
        console.log(`  Track ${i}:`);
        console.log("    kind:", track.kind);
        console.log("    id:", track.id);
        console.log("    enabled:", track.enabled);
        console.log("    muted:", track.muted);
        console.log("    readyState:", track.readyState);
        console.log("    label:", track.label);

        if (track.kind === 'audio') {
          const settings = track.getSettings();
          console.log("    settings:", settings);
        }
      });
      console.log("");
    }

    console.log("🔧 Attempting manual play...");
    audio.play()
      .then(() => {
        console.log("✅ Manual play succeeded!");
        console.log("  paused after play:", audio.paused);
      })
      .catch((error) => {
        console.error("❌ Manual play failed:", error.name, error.message);
      });

    console.log("");
    console.log("🔊 Testing volume...");
    const originalVolume = audio.volume;
    audio.volume = 1.0;
    console.log("  Volume set to 1.0");

    console.log("");
    console.log("🔇 Testing mute...");
    if (audio.muted) {
      console.log("  ⚠️ Audio is MUTED! Unmuting...");
      audio.muted = false;
    } else {
      console.log("  ✅ Audio is not muted");
    }
  }
}

console.log("");
console.log("================================");
console.log("🔍 Diagnostic Complete");
