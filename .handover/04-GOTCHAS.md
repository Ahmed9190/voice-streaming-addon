# ⚠️ Gotchas: Where the Bodies Are Buried

This document captures known issues, quirks, workarounds, and things that will trip you up. **Read this before modifying code.**

---

## 🔴 Critical Issues

### 1. Invalid JSON in `config.json`

**Location**: `webrtc_backend/config.json`

**Problem**: The file contains comment lines (starting with `#`) which makes it invalid JSON.

```json
# WebRTC Optimization Configuration   <-- THIS WILL BREAK PARSING
# This file contains settings...      <-- THIS TOO
{
  "webrtc": { ... }
}
```

**Impact**: Any Python code using `json.load()` will fail with `JSONDecodeError`.

**Current Status**: The server currently ignores this file and uses hardcoded defaults.

**Fix**:

```bash
# Remove comment lines
sed -i '/^#/d' webrtc_backend/config.json
```

Or rewrite without comments:

```json
{
  "webrtc": {
    "ice_servers": [...]
  }
}
```

---

### 2. Invalid manifest.json Format

**Location**: `config/custom_components/voice_streaming/manifest.json`

**Problem**: Uses YAML-like syntax instead of JSON.

```yaml
name: Voice Streaming          <-- YAML, not JSON
domain: voice_streaming
documentation: https://...
```

**Should be**:

```json
{
  "name": "Voice Streaming",
  "domain": "voice_streaming",
  "documentation": "https://...",
  "dependencies": ["websocket_api"],
  "codeowners": ["@yourusername"],
  "requirements": [],
  "version": "1.0.0"
}
```

**Impact**: Home Assistant may fail to load the component or show errors.

---

### 3. Duplicate Event Handlers

**Location**: Both frontend card files

**Files affected**:

- `config/www/voice-sending-card.js` (lines ~298 and ~316)
- `config/www/voice-receiving-card.js` (lines ~573 and ~591)

**Problem**: `oniceconnectionstatechange` is assigned twice:

```javascript
// First assignment (detailed)
this.peerConnection.oniceconnectionstatechange = () => {
  console.log('ICE connection state:', ...);
  if (this.peerConnection.iceConnectionState === 'failed' ||
      this.peerConnection.iceConnectionState === 'disconnected') {
    console.log('ICE connection failed or disconnected');
    this.updateStatus('error');
    this.errorMessage = 'Connection failed: ' + ...;  // <-- Detailed message
    this.updateError();
  } else if (...) {
    // Handle connected/completed
  }
};

// Second assignment (overwrites first!)
this.peerConnection.oniceconnectionstatechange = () => {
  console.log('ICE connection state:', ...);
  if (...) {
    this.errorMessage = 'Connection failed';  // <-- Generic message, no "else if"
    // Missing connected/completed handling!
  }
};
```

**Impact**: The second handler **replaces** the first. Success case handling is lost.

**Fix**: Remove the duplicate handler (delete lines ~316-325 in sending, ~591-601 in receiving).

---

## 🟠 Warnings

### 4. Self-Signed Certificate Browser Warnings

**What happens**: Every browser visit shows "Your connection is not private" warning.

**Workaround**:

- Click "Advanced" → "Proceed to localhost (unsafe)"
- Or import `ssl/homeassistant.crt` into browser's trusted certificates

**Production fix**: Use Let's Encrypt or organizational CA certificates.

---

### 5. No TURN Server = NAT Traversal Failures

**What happens**: WebRTC connections fail when:

- Clients are on different networks
- Behind symmetric NAT
- Corporate firewalls block UDP

**Symptoms**:

- Status shows "connecting" forever
- "ICE connection failed" errors

**Workaround**: Ensure all clients are on the same local network.

**Proper fix**: Add TURN server configuration:

```javascript
{
  iceServers: [
    { urls: "stun:stun.l.google.com:19302" },
    {
      urls: "turn:your-server.com:3478",
      username: "user",
      credential: "pass",
    },
  ];
}
```

---

### 6. Hardcoded Reconnection Limits

**Location**: Both frontend cards

**Code**:

```javascript
this.maxReconnectAttempts = 3;
```

**Impact**: After 3 failed reconnection attempts, the card stops trying.

**What to do**: Refresh the page, or increase the limit.

---

### 7. MediaRecorder Path Hardcoded to `/tmp`

**Location**: `webrtc_backend/webrtc_server.py` (line 163)

**Code**:

```python
recorder = MediaRecorder("/tmp/stream.wav")
```

**Impact**:

- Recordings are lost on container restart
- No configurable recording location
- `/tmp` may fill up with large recordings

**If you want persistent recordings**:

1. Mount a volume: `-v ./recordings:/app/recordings`
2. Change path: `MediaRecorder("/app/recordings/stream.wav")`

---

### 8. Health Check May Fail Initially

**Location**: `webrtc_backend/Dockerfile`

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
  CMD curl -f http://localhost:8080/health || exit 1
```

**Problem**: Uses `curl` but `curl` is not installed in the slim Python image.

**Impact**: Docker will report the container as unhealthy (but it works fine).

**Fix**: Add curl to Dockerfile or use Python for health check:

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')"
```

---

## 🟡 Notes

### 9. Multiple Frontend Card Variants

**Location**: `config/www/`

There are **10 JavaScript files**, many with overlapping functionality:

| File                                | Purpose             | Status         |
| ----------------------------------- | ------------------- | -------------- |
| `voice-sending-card.js`             | Send audio          | ✅ Active      |
| `voice-receiving-card.js`           | Receive audio       | ✅ Active      |
| `voice-streaming-card.js`           | Original combined   | ⚠️ Legacy      |
| `voice-streaming-card-relay.js`     | Combined with relay | ⚠️ Alternative |
| `voice-streaming-card-dashboard.js` | Dashboard variant   | ⚠️ Alternative |
| `hello-world-card.js`               | Test/demo           | 🧪 Dev only    |
| `hello-world-panel.js`              | Test/demo           | 🧪 Dev only    |
| `minimal-panel.js`                  | Test/demo           | 🧪 Dev only    |
| `simple-hello-world-card.js`        | Test/demo           | 🧪 Dev only    |
| `test.html`                         | Test page           | 🧪 Dev only    |

**Which to edit?** Only `voice-sending-card.js` and `voice-receiving-card.js` are referenced in `configuration.yaml`.

---

### 10. Timezone Hardcoded to Africa/Cairo

**Location**: `docker-compose.yml`

```yaml
environment:
  - TZ=Africa/Cairo
```

**Impact**: Log timestamps and HA automations use this timezone.

**Fix**: Change to your timezone:

```yaml
environment:
  - TZ=America/New_York # or your timezone
```

---

### 11. Device Mapping May Fail

**Location**: `docker-compose.yml`

```yaml
devices:
  - /dev/ttyUSB0:/dev/ttyUSB0 # Optional: for Zigbee/Z-Wave
```

**Impact**: If you don't have a USB device at `/dev/ttyUSB0`, container startup may fail.

**Fix**: Comment out if not using Zigbee/Z-Wave:

```yaml
# devices:
#   - /dev/ttyUSB0:/dev/ttyUSB0
```

---

### 12. Watchtower Disabled for HA

**Location**: `docker-compose.yml`

```yaml
labels:
  - "com.centurylinklabs.watchtower.enable=false"
```

**Why**: Prevents Watchtower from auto-updating Home Assistant (can break things).

**Impact**: You must manually update HA.

---

## 🛠️ Workaround Summary

| Issue                 | Quick Workaround            |
| --------------------- | --------------------------- |
| Invalid config.json   | Remove comment lines        |
| Invalid manifest.json | Convert to proper JSON      |
| Duplicate handlers    | Delete second handler       |
| SSL warnings          | Accept in browser           |
| NAT failures          | Use same network            |
| Container unhealthy   | Ignore or add curl          |
| Wrong timezone        | Edit docker-compose.yml     |
| USB device error      | Comment out devices mapping |

---

## Checklist Before Modifying Code

- [ ] Identified which `.js` file is actually being used (check `configuration.yaml`)
- [ ] Checked for duplicate event handlers
- [ ] Tested on same network first (before cross-network)
- [ ] Verified browser console for errors
- [ ] Checked Docker logs: `docker compose logs -f`

---

_Generated by Elite Staff Engineer Handover Protocol (ESEHP-ASKS v2.0)_
