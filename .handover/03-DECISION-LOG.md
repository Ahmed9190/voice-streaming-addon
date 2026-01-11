# 📋 Decision Log: The "Why" Behind the Code

This document captures the architectural decisions, trade-offs, and rationale that shaped this codebase. Understanding these decisions will help you maintain consistency and avoid undoing intentional choices.

---

## Decision 1: Relay Architecture over Peer-to-Peer

### Context

WebRTC typically operates in a peer-to-peer (P2P) model where browsers connect directly. We needed to support broadcasting (one sender → many receivers).

### Decision

Implement a **centralized relay server** using `aiortc` that receives audio from senders and redistributes to receivers.

### Rationale

| Factor                 | P2P                        | Relay (chosen)           |
| ---------------------- | -------------------------- | ------------------------ |
| Broadcast support      | Complex (mesh)             | Simple (hub-spoke)       |
| NAT traversal          | Each pair needs connection | Single server connection |
| Server-side processing | Not possible               | Possible                 |
| Bandwidth (sender)     | O(n) per receiver          | O(1) fixed               |
| Latency                | Lower (direct)             | Slightly higher          |

### Trade-offs

- ✅ One sender can serve unlimited receivers
- ✅ Server can record, process, or analyze audio
- ❌ Single point of failure
- ❌ Added ~10-30ms latency vs direct P2P

### References

- `webrtc_server_relay.py`: `setup_sender()` and `setup_receiver()` methods
- `active_streams` dictionary stores sender tracks for rebroadcast

---

## Decision 2: Web Components over Modern Frameworks

### Context

Home Assistant supports custom dashboard cards. Options included React, Vue, LitElement, or vanilla Web Components.

### Decision

Use **vanilla JavaScript Web Components** with Shadow DOM.

### Rationale

- HA's panel_custom expects ES modules that self-register
- No build step required (directly serve `.js` files)
- Shadow DOM isolates styles from HA's theme system
- LitElement adds ~7KB but isn't strictly necessary

### Trade-offs

- ✅ Zero dependencies on frontend
- ✅ No bundler/transpiler setup
- ✅ Works with any HA version
- ❌ More verbose than React/Vue
- ❌ No reactive rendering system

### Code Pattern

```javascript
class VoiceSendingCard extends HTMLElement {
  constructor() {
    super();
    this.attachShadow({ mode: "open" });
  }

  render() {
    this.shadowRoot.innerHTML = `<style>...</style><div>...</div>`;
  }
}
customElements.define("voice-sending-card", VoiceSendingCard);
```

---

## Decision 3: Self-Signed SSL Certificates

### Context

WebRTC's `getUserMedia()` API requires a "secure context" (HTTPS or localhost).

### Decision

Generate **self-signed certificates** for development.

### Rationale

- Let's Encrypt requires public domain + port 80/443 exposure
- Development environment doesn't have stable DNS
- Browser warning is acceptable for local development

### Trade-offs

- ✅ Works immediately without DNS setup
- ✅ Development-friendly
- ❌ Browser security warnings
- ❌ Must replace for production

### Migration Path (Production)

1. Register domain, point DNS to server
2. Install `certbot`: `sudo apt install certbot`
3. `certbot certonly --standalone -d yourdomain.com`
4. Update `nginx.conf` to use Let's Encrypt certs

---

## Decision 4: aiortc Library for Python WebRTC

### Context

Multiple Python WebRTC libraries exist: aiortc, pion-python, etc.

### Decision

Use **aiortc** for the WebRTC backend.

### Rationale

| Library     | Maturity | Async         | Audio Support |
| ----------- | -------- | ------------- | ------------- |
| aiortc      | High     | Yes (asyncio) | Full          |
| pion-python | Low      | Partial       | Limited       |

aiortc is the de-facto standard for Python WebRTC, maintained, and used in production.

### Trade-offs

- ✅ Mature, well-documented
- ✅ Native asyncio integration
- ✅ Supports audio processing
- ❌ Installation can be complex (libavcodec)
- ❌ ~50MB Docker image size increase

---

## Decision 5: Docker Compose for Orchestration

### Context

The system has three services: Home Assistant, WebRTC backend, Nginx.

### Decision

Use **Docker Compose** for local orchestration.

### Rationale

- Standard development workflow
- Single command startup (`docker compose up -d`)
- Volume mounts for live code changes
- Consistent environments across machines

### Trade-offs

- ✅ Easy local development
- ✅ Matches production-like environment
- ❌ Docker Desktop licensing for commercial use
- ❌ Slightly slower than native execution

### Why Not Kubernetes?

Overkill for single-host development. K8s would be appropriate for multi-node production deployment.

---

## Decision 6: No TURN Server by Default

### Context

STUN servers help discover public IPs, but TURN servers relay traffic when direct connection is impossible (symmetric NAT, firewalls).

### Decision

**Omit TURN server** configuration by default.

### Rationale

- TURN requires hosting/bandwidth costs
- Most home networks don't need TURN
- Adds complexity for initial setup
- Can be added later when needed

### Trade-offs

- ✅ Simpler initial configuration
- ✅ Works on same network
- ❌ Will fail on restrictive corporate networks
- ❌ Users must add their own TURN if needed

### Adding TURN Later

```javascript
{
  iceServers: [
    { urls: "stun:stun.l.google.com:19302" },
    {
      urls: "turn:your-turn-server.com:3478",
      username: "user",
      credential: "password",
    },
  ];
}
```

---

## Decision 7: Two WebRTC Server Implementations

### Context

The `webrtc_backend/` directory contains two server files:

- `webrtc_server.py`
- `webrtc_server_relay.py`

### Decision

Keep both files; Dockerfile **uses `webrtc_server_relay.py`** as the production entry point.

### Rationale

| File                     | Purpose                                     |
| ------------------------ | ------------------------------------------- |
| `webrtc_server.py`       | Original single-connection implementation   |
| `webrtc_server_relay.py` | Evolution with multi-receiver relay support |

The relay version supersedes the basic version but the basic version remains for:

1. Reference/comparison
2. Fallback if relay has issues
3. Simpler debugging (single connection)

### ⚠️ Important

The Dockerfile `CMD` directive specifies:

```dockerfile
CMD ["python", "webrtc_server_relay.py"]
```

Ensure you edit the correct file when making backend changes.

---

## Decision 8: 16kHz Mono Audio

### Context

Audio quality vs. latency trade-off.

### Decision

Default audio constraints: **16kHz sample rate, mono channel**.

### Rationale

| Setting       | 16kHz Mono | 48kHz Stereo |
| ------------- | ---------- | ------------ |
| Bandwidth     | ~256 kbps  | ~1.5 Mbps    |
| Latency       | Lower      | Higher       |
| Voice quality | Sufficient | Overkill     |
| Music quality | Poor       | Good         |

Voice communication doesn't benefit from stereo or high sample rates. 16kHz is telephony-quality.

### Changing This

In `voice-sending-card.js`:

```javascript
this.mediaStream = await navigator.mediaDevices.getUserMedia({
  audio: {
    sampleRate: 48000, // Change here
    channelCount: 2, // Change here
    // ...
  },
});
```

---

## Decision 9: WebSocket for Signaling (not HTTP Polling)

### Context

WebRTC signaling requires exchanging SDP offers/answers and ICE candidates.

### Decision

Use **WebSocket** connections for all signaling.

### Rationale

- Real-time bidirectional communication
- Single persistent connection (no polling overhead)
- Natural fit for streaming state updates
- Standard pattern for WebRTC signaling

### Trade-offs

- ✅ Low latency signaling
- ✅ Server can push events (stream_available, etc.)
- ❌ Requires handling disconnection/reconnection
- ❌ Stateful connections (harder to load balance)

---

## Decision 10: Host Networking Removed

### Context

Early docker-compose used `network_mode: host` for Home Assistant.

### Decision

Switch to **bridge networking** with explicit port mappings.

### Rationale

- Host networking doesn't work on macOS/Windows Docker
- Bridge networking is more portable
- Explicit ports are easier to understand
- WebRTC works fine with port mappings through Nginx

### Current Configuration

```yaml
homeassistant:
  ports:
    - "8123:8123"
    - "1900:1900/udp"
    - "5353:5353/udp"
```

---

## Summary Matrix

| Decision      | Chosen         | Rejected Alternative | Key Reason        |
| ------------- | -------------- | -------------------- | ----------------- |
| Architecture  | Relay          | Peer-to-Peer         | Broadcast support |
| Frontend      | Web Components | React/Vue            | HA compatibility  |
| SSL           | Self-signed    | Let's Encrypt        | Dev simplicity    |
| WebRTC lib    | aiortc         | pion-python          | Maturity          |
| Orchestration | Docker Compose | K8s/Podman           | Local dev focus   |
| TURN          | None           | Self-hosted          | Simplicity        |
| Audio         | 16kHz Mono     | 48kHz Stereo         | Voice-optimized   |
| Signaling     | WebSocket      | HTTP polling         | Real-time needs   |

---

_Generated by Elite Staff Engineer Handover Protocol (ESEHP-ASKS v2.0)_
