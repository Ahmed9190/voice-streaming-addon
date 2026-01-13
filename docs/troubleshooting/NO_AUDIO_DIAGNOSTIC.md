# No Audio Output - Diagnostic Guide

## Symptoms

- Card shows "Playing: stream_xxx"
- WebRTC connection established
- No audio heard
- No visualization bars moving

## Diagnostic Steps

### Step 1: Check Audio Element State

**Run this in browser console (F12):**

```javascript
const card = document.querySelector("voice-receiving-card");
const audio = card.shadowRoot.querySelector("audio");

console.log("Has stream:", !!audio.srcObject);
console.log("Paused:", audio.paused);
console.log("Volume:", audio.volume);
console.log("Muted:", audio.muted);
console.log("Tracks:", audio.srcObject?.getTracks().length);

// Check track state
audio.srcObject?.getTracks().forEach((track) => {
  console.log("Track:", track.kind, "enabled:", track.enabled, "muted:", track.muted, "state:", track.readyState);
});
```

**Or use the diagnostic script:**

```javascript
// Copy and paste contents of audio_diagnostic.js
```

### Step 2: Check Sender is Actually Sending

**In sender card console:**

```javascript
const senderCard = document.querySelector("voice-sending-card");
// Check if microphone is active
// Check if peer connection is sending
```

### Step 3: Check Server Logs

```bash
docker logs voice-streaming | tail -50
```

Look for:

- Audio track being added
- RTP packets being sent
- Any errors

### Step 4: Check Browser Audio Output

1. **Check browser tab** - Should have speaker icon 🔊
2. **Right-click tab** → "Mute site" should be unchecked
3. **Check system volume** - Not muted
4. **Check audio output device** - Correct device selected

### Step 5: Check WebRTC Stats

```javascript
const card = document.querySelector("voice-receiving-card");
const manager = card.webrtc;
const pc = manager.peerConnection;

if (pc) {
  pc.getStats().then((stats) => {
    stats.forEach((report) => {
      if (report.type === "inbound-rtp" && report.kind === "audio") {
        console.log("Audio RTP Stats:", {
          packetsReceived: report.packetsReceived,
          packetsLost: report.packetsLost,
          bytesReceived: report.bytesReceived,
          jitter: report.jitter,
        });
      }
    });
  });
}
```

## Common Issues

### Issue 1: Track is Muted

**Check:**

```javascript
const track = audio.srcObject.getAudioTracks()[0];
console.log("Track muted:", track.muted);
console.log("Track enabled:", track.enabled);
```

**Fix:**

```javascript
track.enabled = true;
```

### Issue 2: Audio Element Muted

**Check:**

```javascript
console.log("Audio muted:", audio.muted);
console.log("Volume:", audio.volume);
```

**Fix:**

```javascript
audio.muted = false;
audio.volume = 1.0;
audio.play();
```

### Issue 3: No Audio Track in Stream

**Check:**

```javascript
const tracks = audio.srcObject.getTracks();
console.log("Total tracks:", tracks.length);
console.log("Audio tracks:", audio.srcObject.getAudioTracks().length);
```

**If 0 audio tracks:**

- Sender is not sending audio
- Check sender microphone permissions
- Check sender card is actually capturing audio

### Issue 4: Sender Not Capturing Audio

**On sender card, check:**

```javascript
const senderCard = document.querySelector("voice-sending-card");
// Check if getUserMedia was successful
// Check if microphone is active
```

### Issue 5: Browser Autoplay Policy

**Try:**

```javascript
audio
  .play()
  .then(() => {
    console.log("Playing!");
  })
  .catch((e) => {
    console.error("Play failed:", e);
    // If NotAllowedError, click anywhere on page
  });
```

## Quick Fixes to Try

### Fix 1: Force Unmute and Play

```javascript
const card = document.querySelector("voice-receiving-card");
const audio = card.shadowRoot.querySelector("audio");
audio.muted = false;
audio.volume = 1.0;
audio.play();
```

### Fix 2: Check Track is Enabled

```javascript
const track = audio.srcObject.getAudioTracks()[0];
track.enabled = true;
console.log("Track enabled:", track.enabled);
```

### Fix 3: Recreate Audio Context

```javascript
// Sometimes audio context gets suspended
const audioContext = new AudioContext();
const source = audioContext.createMediaStreamSource(audio.srcObject);
const destination = audioContext.createMediaStreamDestination();
source.connect(destination);
audio.srcObject = destination.stream;
audio.play();
```

## Expected Working State

```javascript
✅ audio.srcObject: MediaStream
✅ audio.paused: false
✅ audio.volume: 1.0
✅ audio.muted: false
✅ audio.srcObject.active: true
✅ audio.srcObject.getAudioTracks().length: 1
✅ track.enabled: true
✅ track.muted: false
✅ track.readyState: "live"
```

## Next Steps

1. Run the diagnostic script
2. Check what's different from expected state
3. Apply appropriate fix
4. If still no audio, check sender is actually sending

---

**Most likely causes:**

1. Audio element or track is muted
2. Sender not actually capturing/sending audio
3. Browser autoplay blocked
