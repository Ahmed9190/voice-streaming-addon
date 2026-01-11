# 🏭 Implementation Plan: LAN Production-Ready Setup

**Goal**: Make the WebRTC Voice Streaming solution production-ready for internal network use **without internet connectivity**.

**Constraints**:

- No external STUN/TURN servers (Google's stun.l.google.com won't be reachable)
- All clients on the same local network
- Self-hosted, fully offline operation

---

## Executive Summary

| Phase | Description                      | Effort     | Priority     |
| ----- | -------------------------------- | ---------- | ------------ |
| 1     | Critical Bug Fixes               | 30 min     | 🔴 Must      |
| 2     | Offline WebRTC Configuration     | 45 min     | 🔴 Must      |
| 3     | Production Hardening             | 1 hour     | 🟠 Important |
| 4     | Reliability & Monitoring         | 1 hour     | 🟠 Important |
| 5     | Deployment & Testing             | 30 min     | 🟢 Final     |
| **6** | **Cross-Device Network Access**  | **1 hr**   | **🔴 Must**  |
| **7** | **SSL Certificates for LAN IPs** | **30 min** | **🔴 Must**  |
| **8** | **HA Media Player Integration**  | **2 hrs**  | **🔴 Must**  |

**Total Estimated Time**: ~8 hours

---

## 🆕 YOUR SPECIFIC ISSUES

### Issue 1: Mobile Can See UI But Can't Send Voice

**Root Cause**: The browser on your phone requires **valid HTTPS** to access `getUserMedia()` (microphone). The current SSL certificate is only valid for `localhost`, so when you access via the server's IP address, the browser blocks microphone access.

**Solution**: Phase 6 + Phase 7 (Network access + SSL for LAN IP)

### Issue 2: Want to Output to Home Assistant Media Player

**Root Cause**: Currently the audio stream goes to a WebRTC receiver card in the browser. To play on real speakers (Sonos, Google Home, etc.), we need to:

1. Convert WebRTC audio to an HTTP audio stream
2. Create a `media_player.play_media` compatible URL
3. Allow HA to play this stream on any configured speaker

**Solution**: Phase 8 (HA Media Player Integration)

---

## Phase 1: Critical Bug Fixes (30 min)

### 1.1 Fix `manifest.json` (JSON Format)

**File**: `config/custom_components/voice_streaming/manifest.json`

**Problem**: Uses YAML-like syntax, not valid JSON

**Fix**:

```json
{
  "domain": "voice_streaming",
  "name": "Voice Streaming",
  "documentation": "https://github.com/Ahmed9190/voice-streaming-addon",
  "dependencies": ["websocket_api"],
  "codeowners": ["@Ahmed9190"],
  "requirements": [],
  "version": "1.0.0"
}
```

---

### 1.2 Fix `config.json` (Remove Comments)

**File**: `webrtc_backend/config.json`

**Problem**: Contains `#` comment lines which are invalid JSON

**Fix**: Remove comment lines, keep only valid JSON

---

### 1.3 Remove Duplicate Event Handlers

**Files**:

- `config/www/voice-sending-card.js`
- `config/www/voice-receiving-card.js`

**Problem**: `oniceconnectionstatechange` assigned twice, second overwrites first

**Fix**: Delete the duplicate/shorter handler block, keep the comprehensive one

---

### 1.4 Fix Docker Health Check

**File**: `webrtc_backend/Dockerfile`

**Problem**: Uses `curl` which isn't installed

**Fix**: Use Python for health check:

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1
```

---

## Phase 2: Offline WebRTC Configuration (45 min)

### 2.1 Remove External STUN Servers

For LAN-only operation, external STUN servers are:

- **Unreachable** (no internet)
- **Unnecessary** (host candidates work on same network)

**Strategy**: Use empty `iceServers` array + rely on host candidates

---

### 2.2 Update Backend ICE Configuration

**File**: `webrtc_backend/webrtc_server_relay.py`

**Changes**:

```python
# In setup_sender() and anywhere RTCPeerConnection is created
pc = RTCPeerConnection(configuration={
    "iceServers": []  # Empty for LAN-only
})
```

---

### 2.3 Update Frontend ICE Configuration

**Files**:

- `config/www/voice-sending-card.js`
- `config/www/voice-receiving-card.js`

**Changes**:

```javascript
this.peerConnection = new RTCPeerConnection({
  iceServers: [], // No STUN needed for LAN
  iceCandidatePoolSize: 0,
  iceTransportPolicy: "all",
});
```

---

### 2.4 Update config.json for LAN Mode

**File**: `webrtc_backend/config.json`

```json
{
  "webrtc": {
    "ice_servers": [],
    "rtc_config": {
      "bundlePolicy": "max-bundle",
      "rtcpMuxPolicy": "require",
      "sdpSemantics": "unified-plan"
    },
    "audio_constraints": {
      "sample_rate": 16000,
      "channels": 1,
      "echo_cancellation": true,
      "noise_suppression": true,
      "auto_gain_control": true
    },
    "connection_timeout": 30,
    "reconnect_attempts": 5
  },
  "server": {
    "port": 8080,
    "host": "0.0.0.0",
    "max_connections": 50,
    "queue_size": 100
  },
  "lan_mode": {
    "enabled": true,
    "description": "Internal network only, no external STUN/TURN"
  }
}
```

---

## Phase 3: Production Hardening (1 hour)

### 3.1 Set Proper Timezone

**File**: `docker-compose.yml`

```yaml
environment:
  - TZ=YOUR_TIMEZONE # e.g., Europe/Berlin, America/New_York
```

---

### 3.2 Remove/Disable USB Device Mapping

**File**: `docker-compose.yml`

```yaml
# Comment out or remove if not using Zigbee/Z-Wave
# devices:
#   - /dev/ttyUSB0:/dev/ttyUSB0
```

---

### 3.3 Add Container Restart Policies

**File**: `docker-compose.yml`

Ensure all services have:

```yaml
restart: unless-stopped
```

---

### 3.4 Configure Proper Logging

**File**: `docker-compose.yml`

Add logging limits to prevent disk fill:

```yaml
services:
  voice_streaming:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

---

### 3.5 Set Server IP/Hostname

**Files**: Frontend cards and nginx.conf

For production, replace `localhost` with server's actual LAN IP or hostname:

- Option A: Use server's static IP (e.g., `192.168.1.100`)
- Option B: Use mDNS hostname (e.g., `homeassistant.local`)

---

### 3.6 Increase Connection Limits

**File**: `webrtc_backend/webrtc_server_relay.py`

Add connection limits and cleanup:

```python
MAX_CONNECTIONS = 50
MAX_STREAMS = 10
```

---

## Phase 4: Reliability & Monitoring (1 hour)

### 4.1 Add Reconnection Logic Improvements

**Files**: Frontend cards

- Increase `maxReconnectAttempts` from 3 to 10
- Add exponential backoff
- Show reconnection status to user

---

### 4.2 Add Connection Status Indicators

**Files**: Frontend cards

Visual indicators for:

- ✅ Connected
- 🟡 Connecting/Reconnecting
- 🔴 Disconnected
- ⚠️ No streams available

---

### 4.3 Add Stream Health Monitoring

**File**: `webrtc_backend/webrtc_server_relay.py`

Add periodic health broadcast:

```python
async def broadcast_health():
    """Send health status to all connected clients"""
    status = {
        "type": "health",
        "active_streams": len(self.active_streams),
        "connected_clients": len(self.connections)
    }
    # Broadcast to all
```

---

### 4.4 Add Graceful Shutdown

**File**: `webrtc_backend/webrtc_server_relay.py`

Handle SIGTERM/SIGINT to close all connections cleanly:

```python
import signal

async def shutdown():
    """Close all connections gracefully"""
    for conn_id in list(self.connections.keys()):
        await self.cleanup_connection(conn_id)
```

---

### 4.5 Add Simple Metrics Endpoint

**File**: `webrtc_backend/webrtc_server_relay.py`

Add `/metrics` endpoint:

```python
async def metrics(self, request):
    return web.json_response({
        "uptime_seconds": time.time() - self.start_time,
        "total_connections": self.total_connections,
        "active_connections": len(self.connections),
        "active_streams": len(self.active_streams)
    })
```

---

## Phase 5: Deployment & Testing (30 min)

### 5.1 Create Production Start Script

**File**: `start_production.sh`

```bash
#!/bin/bash
set -e

echo "🏭 Starting Production Voice Streaming Services"
echo "================================================"

# Verify Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running!"
    exit 1
fi

# Build and start services
docker compose build --no-cache
docker compose up -d

# Wait for services
echo "Waiting for services to start..."
sleep 15

# Health checks
echo "Running health checks..."

# Check voice streaming backend
if curl -sf http://localhost:8080/health > /dev/null; then
    echo "✅ Voice Streaming Backend: Healthy"
else
    echo "❌ Voice Streaming Backend: FAILED"
    docker compose logs voice_streaming
    exit 1
fi

# Check Home Assistant (may take longer)
for i in {1..30}; do
    if curl -sf -k https://localhost > /dev/null; then
        echo "✅ Home Assistant: Healthy"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Home Assistant: FAILED to start"
        exit 1
    fi
    sleep 2
done

echo ""
echo "🎉 All services running!"
echo "========================"
echo "Home Assistant: https://$(hostname -I | awk '{print $1}')"
echo "Voice Backend:  http://$(hostname -I | awk '{print $1}'):8080/health"
echo ""
echo "Open the Voice Send and Voice Receive panels from the HA sidebar."
```

---

### 5.2 Create Test Script for LAN Mode

**File**: `test_lan_mode.py`

```python
#!/usr/bin/env python3
"""Test script for LAN-only voice streaming setup"""

import asyncio
import aiohttp
import socket

async def test_lan_mode():
    print("🧪 LAN Mode Production Test")
    print("=" * 40)

    # Get local IP
    hostname = socket.gethostname()
    local_ip = socket.gethostbyname(hostname)
    print(f"Server IP: {local_ip}")

    tests_passed = 0
    tests_total = 4

    # Test 1: Backend health
    print("\n1. Testing backend health...")
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(f"http://localhost:8080/health") as resp:
                data = await resp.json()
                if data.get("status") == "healthy":
                    print("   ✅ Backend is healthy")
                    tests_passed += 1
                else:
                    print(f"   ❌ Unexpected response: {data}")
    except Exception as e:
        print(f"   ❌ Failed: {e}")

    # Test 2: WebSocket connection
    print("\n2. Testing WebSocket connection...")
    try:
        async with aiohttp.ClientSession() as session:
            async with session.ws_connect("ws://localhost:8080/ws") as ws:
                msg = await asyncio.wait_for(ws.receive_json(), timeout=5)
                if msg.get("type") == "available_streams":
                    print("   ✅ WebSocket connected, received stream list")
                    tests_passed += 1
                await ws.close()
    except Exception as e:
        print(f"   ❌ Failed: {e}")

    # Test 3: Home Assistant accessible
    print("\n3. Testing Home Assistant...")
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get("https://localhost", ssl=False) as resp:
                if resp.status == 200:
                    print("   ✅ Home Assistant accessible")
                    tests_passed += 1
    except Exception as e:
        print(f"   ❌ Failed: {e}")

    # Test 4: Voice card served
    print("\n4. Testing voice cards...")
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(
                "https://localhost/local/voice-sending-card.js",
                ssl=False
            ) as resp:
                if resp.status == 200:
                    content = await resp.text()
                    if "VoiceSendingCard" in content:
                        print("   ✅ Voice cards correctly served")
                        tests_passed += 1
    except Exception as e:
        print(f"   ❌ Failed: {e}")

    # Summary
    print("\n" + "=" * 40)
    print(f"Tests passed: {tests_passed}/{tests_total}")

    if tests_passed == tests_total:
        print("🎉 All tests passed! System is production-ready.")
        return 0
    else:
        print("⚠️ Some tests failed. Review the issues above.")
        return 1

if __name__ == "__main__":
    exit(asyncio.run(test_lan_mode()))
```

---

### 5.3 Pre-Deployment Checklist

Before going live:

- [ ] All Phase 1-4 changes applied
- [ ] `docker compose build --no-cache` completed without errors
- [ ] `./start_production.sh` runs successfully
- [ ] `python test_lan_mode.py` passes all tests
- [ ] Voice sending works from Device A
- [ ] Voice receiving works on Device B (same network)
- [ ] Audio quality is acceptable
- [ ] Reconnection works after network interruption
- [ ] Logs show no errors during operation

---

## File Changes Summary

| File                                                     | Change Type           | Phase   |
| -------------------------------------------------------- | --------------------- | ------- |
| `config/custom_components/voice_streaming/manifest.json` | Fix JSON              | 1       |
| `webrtc_backend/config.json`                             | Fix JSON, LAN config  | 1, 2    |
| `config/www/voice-sending-card.js`                       | Fix handlers, LAN ICE | 1, 2, 4 |
| `config/www/voice-receiving-card.js`                     | Fix handlers, LAN ICE | 1, 2, 4 |
| `webrtc_backend/Dockerfile`                              | Fix healthcheck       | 1       |
| `webrtc_backend/webrtc_server_relay.py`                  | LAN ICE, monitoring   | 2, 4    |
| `docker-compose.yml`                                     | TZ, logging, restart  | 3       |
| `start_production.sh`                                    | New file              | 5       |
| `test_lan_mode.py`                                       | New file              | 5       |

---

## Risk Assessment

| Risk                   | Likelihood | Impact | Mitigation                  |
| ---------------------- | ---------- | ------ | --------------------------- |
| ICE fails without STUN | Low (LAN)  | High   | Host candidates work on LAN |
| Connection drops       | Medium     | Medium | Reconnection logic          |
| Audio quality issues   | Low        | Medium | Noise suppression enabled   |
| Container crash        | Low        | Medium | Restart policy              |
| Disk full (logs)       | Medium     | High   | Log rotation configured     |

---

## Success Criteria

The system is production-ready when:

1. ✅ All containers start without errors
2. ✅ Health endpoints return healthy status
3. ✅ WebSocket connections establish within 5 seconds
4. ✅ Audio streams end-to-end within 10 seconds of clicking "Send"
5. ✅ Multiple receivers can listen to same stream
6. ✅ System recovers from network interruption (<30 seconds)
7. ✅ No errors in logs during 1-hour stress test
8. ✅ **Mobile device can send voice over LAN**
9. ✅ **Audio plays on HA-compatible speakers**

---

## Phase 6: Cross-Device Network Access (1 hour)

### 6.1 Understanding the Problem

When you access from mobile via IP (e.g., `https://192.168.1.100`):

1. ✅ The page loads (UI visible)
2. ❌ `getUserMedia()` fails because browser doesn't trust the SSL cert for that IP
3. ❌ No microphone access = can't send voice

**Browser Security Rule**: Microphone access requires either:

- `localhost` (always trusted)
- Valid HTTPS with trusted certificate

### 6.2 Verify Server is Binding to All Interfaces

**File**: `webrtc_backend/webrtc_server_relay.py`

Ensure server binds to `0.0.0.0` (all interfaces), not `127.0.0.1`:

```python
async def run_server(self):
    port = 8080
    host = "0.0.0.0"  # ✅ Must be 0.0.0.0 for LAN access
```

### 6.3 Update Docker Compose for Network Access

**File**: `docker-compose.yml`

```yaml
services:
  homeassistant:
    ports:
      - "8123:8123" # Bind to all interfaces by default
    # NOT "127.0.0.1:8123:8123" which would be localhost only

  voice_streaming:
    ports:
      - "8080:8080" # Accessible from LAN

  nginx:
    ports:
      - "443:443" # HTTPS accessible from LAN
      - "80:80"
```

### 6.4 Get Your Server's LAN IP

```bash
# Find your server's IP address
hostname -I | awk '{print $1}'
# Example output: 192.168.1.100
```

**Important**: This IP should be static or reserved in your router's DHCP settings.

### 6.5 Test Network Accessibility

From your mobile device (on same network):

```
1. Open browser
2. Go to: https://YOUR_SERVER_IP (e.g., https://192.168.1.100)
3. You should see the HA login page (with SSL warning)
```

---

## Phase 7: SSL Certificates for LAN IPs (30 min)

### 7.1 The SSL Problem

Current certificate only covers `localhost`. When accessing via IP:

- Browser shows "Not Secure" warning
- More importantly: **`getUserMedia()` may be blocked**

### 7.2 Generate Certificate with LAN IP

**Script**: `ssl/generate_lan_cert.sh`

```bash
#!/bin/bash
# Generate SSL certificate valid for localhost AND your LAN IP

# Get the server's IP address
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Generating certificate for IP: $SERVER_IP"

# Create OpenSSL config with SAN (Subject Alternative Name)
cat > ssl/openssl_lan.cnf << EOF
[req]
default_bits = 2048
prompt = no
default_md = sha256
distinguished_name = dn
x509_extensions = v3_req

[dn]
C = US
ST = State
L = City
O = HomeAssistant
CN = homeassistant.local

[v3_req]
subjectAltName = @alt_names
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth

[alt_names]
DNS.1 = localhost
DNS.2 = homeassistant.local
DNS.3 = $(hostname)
IP.1 = 127.0.0.1
IP.2 = $SERVER_IP
EOF

# Generate certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ssl/homeassistant.key \
  -out ssl/homeassistant.crt \
  -config ssl/openssl_lan.cnf

echo "✅ Certificate generated!"
echo "Valid for:"
echo "  - localhost"
echo "  - homeassistant.local"
echo "  - $(hostname)"
echo "  - 127.0.0.1"
echo "  - $SERVER_IP"
```

### 7.3 Run the Script

```bash
chmod +x ssl/generate_lan_cert.sh
./ssl/generate_lan_cert.sh
```

### 7.4 Restart Nginx to Load New Certificate

```bash
docker compose restart nginx
```

### 7.5 Trust Certificate on Mobile (Optional but Recommended)

**For iOS**:

1. Email the `ssl/homeassistant.crt` file to yourself
2. Open on iPhone, install profile
3. Go to Settings → General → About → Certificate Trust Settings
4. Enable full trust for the certificate

**For Android**:

1. Copy `homeassistant.crt` to phone
2. Settings → Security → Install certificate
3. Select the certificate file

**Alternative**: Just accept the browser warning each time (works but less convenient)

### 7.6 Verify Mobile Microphone Access

After installing/trusting certificate:

1. Navigate to `https://YOUR_SERVER_IP/voice-streaming`
2. Click microphone button
3. Browser should prompt for microphone permission
4. Grant permission → voice should stream!

---

## Phase 8: Home Assistant Media Player Integration (2 hours)

### 8.1 Architecture Overview

```
Mobile (Sender)                     HA Server                    Speaker
     │                                  │                           │
     │  WebRTC Audio Stream             │                           │
     ├─────────────────────────────────>│                           │
     │                                  │                           │
     │                      ┌───────────┴───────────┐               │
     │                      │  Audio Stream Server  │               │
     │                      │  (Convert to HTTP)    │               │
     │                      └───────────┬───────────┘               │
     │                                  │                           │
     │                    http://server:8081/stream.mp3             │
     │                                  │                           │
     │                      ┌───────────┴───────────┐               │
     │                      │  HA media_player      │               │
     │                      │  play_media service   │               │
     │                      └───────────┬───────────┘               │
     │                                  │                           │
     │                                  │  Play audio               │
     │                                  ├──────────────────────────>│
     │                                  │                           │
```

### 8.2 Create Audio Stream Server

**File**: `webrtc_backend/audio_stream_server.py`

```python
"""
Audio Stream Server for Home Assistant Media Player Integration

This server receives WebRTC audio from the relay server and converts it
to an HTTP audio stream that HA media_player entities can play.
"""

import asyncio
import logging
from aiohttp import web
from collections import deque
import struct
import time

logger = logging.getLogger(__name__)

class AudioStreamServer:
    def __init__(self, relay_server):
        self.relay_server = relay_server
        self.audio_buffer = deque(maxlen=100)  # Buffer for audio chunks
        self.is_streaming = False
        self.clients = set()
        self.app = web.Application()
        self.setup_routes()

    def setup_routes(self):
        self.app.router.add_get('/stream', self.audio_stream_handler)
        self.app.router.add_get('/stream.mp3', self.audio_stream_handler)
        self.app.router.add_get('/stream/status', self.stream_status)

    async def stream_status(self, request):
        """Status endpoint for HA to check if stream is active"""
        return web.json_response({
            "streaming": self.is_streaming,
            "clients": len(self.clients),
            "buffer_size": len(self.audio_buffer)
        })

    async def audio_stream_handler(self, request):
        """
        HTTP streaming endpoint that HA media_player can consume.
        Returns audio/mpeg stream.
        """
        response = web.StreamResponse(
            status=200,
            reason='OK',
            headers={
                'Content-Type': 'audio/mpeg',
                'Cache-Control': 'no-cache, no-store',
                'Connection': 'keep-alive',
                'Transfer-Encoding': 'chunked',
            }
        )
        await response.prepare(request)

        client_id = id(request)
        self.clients.add(client_id)
        logger.info(f"New stream client connected: {client_id}")

        try:
            while True:
                if self.audio_buffer:
                    chunk = self.audio_buffer.popleft()
                    await response.write(chunk)
                else:
                    # No audio, send silence or wait
                    await asyncio.sleep(0.02)  # 20ms

        except asyncio.CancelledError:
            pass
        except Exception as e:
            logger.error(f"Stream error: {e}")
        finally:
            self.clients.discard(client_id)
            logger.info(f"Stream client disconnected: {client_id}")

        return response

    def push_audio(self, audio_data):
        """Called by relay server when audio is received"""
        self.audio_buffer.append(audio_data)
        self.is_streaming = True

    async def run(self, port=8081):
        runner = web.AppRunner(self.app)
        await runner.setup()
        site = web.TCPSite(runner, '0.0.0.0', port)
        await site.start()
        logger.info(f"Audio stream server started on port {port}")
```

### 8.3 Integrate with Relay Server

**File**: `webrtc_backend/webrtc_server_relay.py` (modify)

Add audio forwarding to the stream server:

```python
from audio_stream_server import AudioStreamServer

class VoiceStreamingServer:
    def __init__(self):
        # ... existing code ...
        self.audio_stream_server = AudioStreamServer(self)

    async def run_server(self):
        # Start audio stream server
        asyncio.create_task(self.audio_stream_server.run(port=8081))

        # ... rest of existing code ...
```

### 8.4 Update Docker Compose

**File**: `docker-compose.yml`

Add port for audio streaming:

```yaml
voice_streaming:
  ports:
    - "8080:8080" # WebRTC signaling
    - "8081:8081" # HTTP audio stream for HA media players
```

### 8.5 Update Nginx Configuration

**File**: `nginx.conf`

Add upstream for audio stream:

```nginx
upstream audio_stream {
    server voice_streaming:8081;
}

# In the server block, add:
location /audio-stream/ {
    proxy_pass http://audio_stream/;
    proxy_http_version 1.1;
    proxy_set_header Connection "";
    proxy_buffering off;
    proxy_cache off;
    chunked_transfer_encoding on;
}
```

### 8.6 Create Home Assistant Service

**File**: `config/custom_components/voice_streaming/__init__.py` (update)

```python
"""Voice Streaming integration for Home Assistant."""
import logging
from homeassistant.components import websocket_api
from homeassistant.core import HomeAssistant, ServiceCall
from homeassistant.helpers import config_validation as cv
import voluptuous as vol

_LOGGER = logging.getLogger(__name__)

DOMAIN = "voice_streaming"
AUDIO_STREAM_URL = "http://voice-streaming:8081/stream.mp3"

async def async_setup(hass: HomeAssistant, config: dict):
    """Set up the Voice Streaming component."""
    _LOGGER.info("Setting up Voice Streaming component")

    hass.data[DOMAIN] = {
        'websocket_connections': {},
        'stream_url': AUDIO_STREAM_URL,
    }

    # Register service to play voice stream on a media player
    async def play_voice_stream(call: ServiceCall):
        """Play the voice stream on specified media player."""
        entity_id = call.data.get('entity_id')

        if not entity_id:
            _LOGGER.error("No entity_id specified")
            return

        # Get the stream URL (accessible from HA network)
        stream_url = f"http://voice-streaming:8081/stream.mp3"

        _LOGGER.info(f"Playing voice stream on {entity_id}")

        await hass.services.async_call(
            'media_player',
            'play_media',
            {
                'entity_id': entity_id,
                'media_content_id': stream_url,
                'media_content_type': 'music',
            }
        )

    async def stop_voice_stream(call: ServiceCall):
        """Stop the voice stream on specified media player."""
        entity_id = call.data.get('entity_id')

        if entity_id:
            await hass.services.async_call(
                'media_player',
                'media_stop',
                {'entity_id': entity_id}
            )

    # Register services
    hass.services.async_register(
        DOMAIN,
        'play_on_speaker',
        play_voice_stream,
        schema=vol.Schema({
            vol.Required('entity_id'): cv.entity_id,
        })
    )

    hass.services.async_register(
        DOMAIN,
        'stop_on_speaker',
        stop_voice_stream,
        schema=vol.Schema({
            vol.Optional('entity_id'): cv.entity_id,
        })
    )

    # Register WebSocket API
    websocket_api.async_register_command(hass, websocket_voice_streaming)

    return True

@websocket_api.websocket_command({"type": "voice_streaming/connect"})
@websocket_api.async_response
async def websocket_voice_streaming(hass, connection, msg):
    """Handle voice streaming WebSocket connection."""
    connection.send_message(websocket_api.result_message(msg["id"], {
        "status": "connected",
        "stream_url": hass.data[DOMAIN]['stream_url']
    }))
```

### 8.7 Create services.yaml

**File**: `config/custom_components/voice_streaming/services.yaml`

```yaml
play_on_speaker:
  name: Play Voice Stream on Speaker
  description: Play the live voice stream on a Home Assistant media player
  fields:
    entity_id:
      name: Media Player
      description: The media player entity to play on
      required: true
      example: "media_player.living_room_speaker"
      selector:
        entity:
          domain: media_player

stop_on_speaker:
  name: Stop Voice Stream
  description: Stop the voice stream on a media player
  fields:
    entity_id:
      name: Media Player
      description: The media player entity to stop
      required: false
      example: "media_player.living_room_speaker"
      selector:
        entity:
          domain: media_player
```

### 8.8 Usage in Home Assistant

**Option 1: Call Service from UI**

1. Go to Developer Tools → Services
2. Select `voice_streaming.play_on_speaker`
3. Choose your media player entity (e.g., `media_player.sonos_living_room`)
4. Click "Call Service"

**Option 2: Add Dashboard Button**

```yaml
# In your dashboard YAML
type: button
name: Play Voice on Speaker
tap_action:
  action: call-service
  service: voice_streaming.play_on_speaker
  data:
    entity_id: media_player.living_room_speaker
icon: mdi:broadcast
```

**Option 3: Automation**

```yaml
automation:
  - alias: "Auto-play voice stream when sender starts"
    trigger:
      - platform: webhook
        webhook_id: voice_stream_started
    action:
      - service: voice_streaming.play_on_speaker
        data:
          entity_id: media_player.kitchen_speaker
```

### 8.9 Test the Integration

1. Start sending voice from mobile
2. Call service: `voice_streaming.play_on_speaker`
3. Audio should play on your speaker!

---

## Updated File Changes Summary

| File                                                     | Change Type                | Phase   |
| -------------------------------------------------------- | -------------------------- | ------- |
| `config/custom_components/voice_streaming/manifest.json` | Fix JSON                   | 1       |
| `webrtc_backend/config.json`                             | Fix JSON, LAN config       | 1, 2    |
| `config/www/voice-sending-card.js`                       | Fix handlers, LAN ICE      | 1, 2, 4 |
| `config/www/voice-receiving-card.js`                     | Fix handlers, LAN ICE      | 1, 2, 4 |
| `webrtc_backend/Dockerfile`                              | Fix healthcheck            | 1       |
| `webrtc_backend/webrtc_server_relay.py`                  | LAN ICE, audio forwarding  | 2, 4, 8 |
| `docker-compose.yml`                                     | TZ, logging, ports         | 3, 6, 8 |
| `start_production.sh`                                    | New file                   | 5       |
| `test_lan_mode.py`                                       | New file                   | 5       |
| `ssl/generate_lan_cert.sh`                               | **New file**               | **7**   |
| `webrtc_backend/audio_stream_server.py`                  | **New file**               | **8**   |
| `config/custom_components/voice_streaming/__init__.py`   | **Update services**        | **8**   |
| `config/custom_components/voice_streaming/services.yaml` | **New file**               | **8**   |
| `nginx.conf`                                             | **Add audio stream route** | **8**   |

---

## Complete Workflow Summary

```
📱 Mobile Phone                    🖥️ Server                     🔊 Speaker
      │                                │                              │
      │ 1. Open https://SERVER_IP      │                              │
      │    (trusted SSL cert)          │                              │
      ├───────────────────────────────>│                              │
      │                                │                              │
      │ 2. Click Send, grant mic       │                              │
      ├───────────────────────────────>│                              │
      │                                │                              │
      │ 3. WebRTC audio stream         │                              │
      │=============================>  │                              │
      │                                │                              │
      │                    4. Convert to HTTP stream                  │
      │                                │                              │
      │                    5. HA service: play_on_speaker             │
      │                                ├─────────────────────────────>│
      │                                │                              │
      │                    6. Audio plays on real speaker!            │
      │                                │                            🎵│
```

---

_Plan generated by Elite Staff Engineer Handover Protocol (ESEHP-ASKS v2.0)_
_Ready for implementation_
