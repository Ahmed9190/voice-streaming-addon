# Analysis Context: webrtc_voice_sending

## Discovery Log

- **2026-01-11T16:12:14**: Initiated deep scan of webrtc_voice_sending project
- **2026-01-11T16:12:20**: Identified tech stack: Python + JavaScript + Docker + Nginx
- **2026-01-11T16:12:25**: Detected WebRTC relay architecture pattern
- **2026-01-11T16:12:30**: Found dual WebRTC server implementations (basic vs relay)
- **2026-01-11T16:12:35**: Identified entry point: `start_services.sh` → `docker compose up -d`
- **2026-01-11T16:12:40**: FOUND POTENTIAL ISSUE - `config.json` contains comments (invalid JSON)
- **2026-01-11T16:12:45**: FOUND POTENTIAL ISSUE - `manifest.json` uses YAML syntax, not JSON
- **2026-01-11T16:12:50**: Scanned frontend cards: voice-sending-card.js, voice-receiving-card.js
- **2026-01-11T16:13:00**: Analyzed custom_components/voice_streaming for HA integration
- **2026-01-11T16:13:10**: Verified SSL certificates present in /ssl directory
- **2026-01-11T16:13:20**: Identified 10 frontend card variants in config/www/

## "Aha!" Moments (The "Why")

1. **Why two WebRTC server files?**

   - `webrtc_server.py`: Basic implementation with fallback when aiortc unavailable
   - `webrtc_server_relay.py`: Production relay server that enables one-to-many audio streaming
   - The Dockerfile uses `webrtc_server_relay.py` (the relay version)

2. **Why Nginx reverse proxy?**

   - WebRTC's `getUserMedia()` API requires HTTPS in modern browsers
   - Self-signed certificates are used for development
   - Nginx handles SSL termination and proxies to HA and voice_streaming services

3. **Why Web Components instead of React/Vue?**

   - Home Assistant's custom panels/cards must use vanilla JS or LitElement
   - No external bundler required - JS files served directly from `/local/`
   - Cards register themselves via `customElements.define()`

4. **Why the relay pattern?**
   - Enables broadcast: one sender → multiple receivers
   - Server can process/record audio streams
   - Better NAT traversal via centralized STUN/ICE handling

## Technical Debt & Gotchas

- **Critical**: `config.json` in webrtc_backend contains comments which makes it invalid JSON. Python's json.load() will fail.
- **Critical**: `manifest.json` in custom_components/voice_streaming uses YAML-like format instead of JSON format
- **Warning**: Duplicate `oniceconnectionstatechange` handlers in voice-sending-card.js (lines 298-325)
- **Warning**: Duplicate `oniceconnectionstatechange` handlers in voice-receiving-card.js (lines 573-601)
- **Note**: Self-signed SSL certificates will cause browser warnings
- **Note**: No TURN server configured - may fail behind restrictive NATs
- **Note**: Max reconnection attempts hardcoded to 3 in frontend cards

## Component Inventory

| Component            | Path                                        | Purpose                   |
| -------------------- | ------------------------------------------- | ------------------------- |
| Home Assistant       | docker-compose.yml (service: homeassistant) | Core automation platform  |
| WebRTC Backend       | webrtc_backend/                             | Audio relay and signaling |
| Nginx Proxy          | nginx.conf                                  | SSL termination, routing  |
| Voice Sending Card   | config/www/voice-sending-card.js            | UI for sending audio      |
| Voice Receiving Card | config/www/voice-receiving-card.js          | UI for receiving audio    |
| HA Custom Component  | config/custom_components/voice_streaming/   | WebSocket API integration |

## Data Flow

```
Browser → getUserMedia() → MediaStream
       → RTCPeerConnection → WebSocket(wss://.../api/voice-streaming/ws)
       → Nginx → voice_streaming container (port 8080)
       → VoiceStreamingServer.setup_sender() → stores track
       → Receiver connects → setup_receiver() → creates offer
       → Audio relayed via RTCPeerConnection → Receiver's browser
       → AudioElement playback
```
