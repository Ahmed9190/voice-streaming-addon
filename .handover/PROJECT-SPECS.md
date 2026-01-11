# 📋 Project Specification Document

## WebRTC Voice Streaming - LAN Production Deployment

**Document Version**: 2.0  
**Created**: 2026-01-11  
**Updated**: 2026-01-11  
**Status**: Ready for Development  
**Target Environment**: Internal LAN (Offline)

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Current State Analysis](#2-current-state-analysis)
3. [Target State](#3-target-state)
4. [Development Phases](#4-development-phases)
5. [Verification Scripts](#5-verification-scripts)
6. [Phase 1: Bug Fixes & Code Quality](#phase-1-bug-fixes--code-quality)
7. [Phase 2: LAN-Only Configuration](#phase-2-lan-only-configuration)
8. [Phase 3: SSL Certificates for LAN](#phase-3-ssl-certificates-for-lan)
9. [Phase 4: Cross-Device Verification](#phase-4-cross-device-verification)
10. [Phase 5: Production Hardening](#phase-5-production-hardening)
11. [Phase 6: HA Media Player Integration](#phase-6-ha-media-player-integration)
12. [Phase 7: Reliability & Monitoring](#phase-7-reliability--monitoring)
13. [Phase 8: Final Testing & Deployment](#phase-8-final-testing--deployment)
14. [Definition of Done](#definition-of-done)
15. [Risk Register](#risk-register)

---

## 1. Project Overview

### 1.1 Objective

Transform the existing WebRTC Voice Streaming proof-of-concept into a **production-ready** internal voice communication system that:

1. Works entirely on a local network without internet connectivity
2. Allows mobile devices to send voice streams
3. Plays received audio on Home Assistant-compatible speakers (Sonos, Google Home, etc.)

### 1.2 Success Metrics

| Metric                          | Target       |
| ------------------------------- | ------------ |
| Cross-device voice transmission | ✅ Working   |
| Mobile → Server latency         | < 500ms      |
| Audio playback on HA speaker    | ✅ Working   |
| System uptime                   | 99%+         |
| Connection establishment time   | < 10 seconds |

### 1.3 Constraints

- **No internet connectivity** - Must work fully offline
- **Same network** - All devices on the same LAN
- **Self-hosted** - No external cloud services
- **Browser-based** - No native app installation required

---

## 2. Current State Analysis

### 2.1 What Works

| Feature                      | Status | Notes                      |
| ---------------------------- | ------ | -------------------------- |
| Voice sending from localhost | ✅     | Browser on same machine    |
| Voice receiving on localhost | ✅     | Browser on same machine    |
| Multi-receiver relay         | ✅     | One sender, many receivers |
| Docker deployment            | ✅     | All containers start       |

### 2.2 What Doesn't Work

| Issue                            | Root Cause                  | Impact      |
| -------------------------------- | --------------------------- | ----------- |
| Mobile can see UI but can't send | SSL cert only for localhost | 🔴 Critical |
| No audio on HA speakers          | No media_player integration | 🔴 Critical |
| External STUN servers referenced | Code has Google STUN URLs   | 🟠 Medium   |
| Invalid JSON files               | Comments in JSON            | 🟠 Medium   |
| Duplicate event handlers         | Code quality issue          | 🟡 Low      |

### 2.3 Technical Debt

1. `config.json` - Contains comments (invalid JSON)
2. `manifest.json` - Uses YAML syntax instead of JSON
3. Duplicate `oniceconnectionstatechange` handlers in frontend
4. Docker health check uses `curl` (not installed)
5. Timezone hardcoded to Africa/Cairo

---

## 3. Target State

### 3.1 Architecture (End State)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                            LAN Network                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  📱 Mobile Device                                                        │
│       │                                                                  │
│       │ HTTPS (trusted cert for LAN IP)                                 │
│       ▼                                                                  │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │                      Server (Docker)                             │    │
│  │  ┌─────────┐    ┌─────────────┐    ┌──────────────────────────┐ │    │
│  │  │ Nginx   │───▶│ Home        │    │ Voice Streaming Service  │ │    │
│  │  │ :443    │    │ Assistant   │    │ :8080 (WebRTC signaling) │ │    │
│  │  │         │    │ :8123       │    │ :8081 (Audio HTTP stream)│ │    │
│  │  └─────────┘    └─────────────┘    └──────────────────────────┘ │    │
│  └─────────────────────────────────────────────────────────────────┘    │
│       │                                                                  │
│       │ HTTP Audio Stream                                               │
│       ▼                                                                  │
│  🔊 HA-Compatible Speaker (Sonos, Google Home, etc.)                    │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 3.2 User Workflow (End State)

1. User opens `https://192.168.x.x` on mobile
2. User clicks "Voice Send" panel
3. User grants microphone permission
4. User speaks into phone
5. Audio streams to server via WebRTC
6. Server converts to HTTP audio stream
7. HA service plays stream on selected speaker
8. Audio heard on real speaker in room

---

## 4. Development Phases

### 4.1 Phase Order (Logical Dependency Chain)

```
Phase 1: Bug Fixes & Code Quality
    │
    ▼
Phase 2: LAN-Only Configuration
    │
    ▼
Phase 3: SSL Certificates for LAN
    │
    ▼
Phase 4: Cross-Device Verification ◄── MILESTONE: Mobile sends voice
    │
    ▼
Phase 5: Production Hardening
    │
    ▼
Phase 6: HA Media Player Integration ◄── MILESTONE: Plays on speaker
    │
    ▼
Phase 7: Reliability & Monitoring
    │
    ▼
Phase 8: Final Testing & Deployment ◄── MILESTONE: Production ready
```

### 4.2 Phase Summary

| Phase | Name                        | Effort  | Milestone             |
| ----- | --------------------------- | ------- | --------------------- |
| 1     | Bug Fixes & Code Quality    | 45 min  | -                     |
| 2     | LAN-Only Configuration      | 30 min  | -                     |
| 3     | SSL Certificates for LAN    | 30 min  | -                     |
| 4     | Cross-Device Verification   | 30 min  | ✅ Mobile sends voice |
| 5     | Production Hardening        | 45 min  | -                     |
| 6     | HA Media Player Integration | 2 hours | ✅ Plays on speaker   |
| 7     | Reliability & Monitoring    | 1 hour  | -                     |
| 8     | Final Testing & Deployment  | 30 min  | ✅ Production ready   |

**Total Estimated Effort**: ~7 hours

---

## 5. Verification Scripts

All verification scripts are located in the `verification-scripts/` folder.

### 5.1 Script Location

```
.handover/verification-scripts/
├── verify-phase-1.sh   # Bug Fixes & Code Quality
├── verify-phase-2.sh   # LAN-Only Configuration
├── verify-phase-3.sh   # SSL Certificates for LAN
├── verify-phase-4.sh   # Cross-Device Verification
├── verify-phase-5.sh   # Production Hardening
├── verify-phase-6.sh   # HA Media Player Integration
├── verify-phase-7.sh   # Reliability & Monitoring
├── verify-phase-8.sh   # Final Testing & Deployment
└── verify-all.sh       # Master script (runs all phases)
```

### 5.2 How to Run

```bash
# Run from project root directory
cd /path/to/webrtc_voice_sending

# Verify a specific phase
./.handover/verification-scripts/verify-phase-1.sh

# Run all phases in sequence
./.handover/verification-scripts/verify-all.sh
```

### 5.3 Development Workflow

For each phase:

1. **Read** the phase specification below
2. **Implement** all tasks listed
3. **Run** the verification script
4. **Fix** any failures
5. **Confirm** all acceptance criteria pass
6. **Proceed** to next phase

---

## Phase 1: Bug Fixes & Code Quality

**Objective**: Fix all known bugs and code quality issues before adding new features.

**Duration**: 45 minutes

**Prerequisites**: None

**Verification**: `.handover/verification-scripts/verify-phase-1.sh`

### Tasks

| ID  | Task                                        | File                                                     | Priority  |
| --- | ------------------------------------------- | -------------------------------------------------------- | --------- |
| 1.1 | Fix manifest.json format                    | `config/custom_components/voice_streaming/manifest.json` | 🔴 High   |
| 1.2 | Fix config.json format                      | `webrtc_backend/config.json`                             | 🔴 High   |
| 1.3 | Remove duplicate event handlers (sending)   | `config/www/voice-sending-card.js`                       | 🟠 Medium |
| 1.4 | Remove duplicate event handlers (receiving) | `config/www/voice-receiving-card.js`                     | 🟠 Medium |
| 1.5 | Fix Docker health check                     | `webrtc_backend/Dockerfile`                              | 🟠 Medium |

### Task 1.1: Fix manifest.json

**Current State** (YAML-like syntax):

```yaml
name: Voice Streaming
domain: voice_streaming
documentation: https://github.com/custom-components/voice_streaming
dependencies: ["websocket_api"]
codeowners: ["@yourusername"]
requirements: []
version: 1.0.0
```

**Target State** (Valid JSON):

```json
{
  "domain": "voice_streaming",
  "name": "Voice Streaming",
  "documentation": "https://github.com/custom-components/voice_streaming",
  "dependencies": ["websocket_api"],
  "codeowners": [],
  "requirements": [],
  "version": "1.0.0"
}
```

### Task 1.2: Fix config.json

**Problem**: Contains `#` comment lines which are invalid JSON

**Solution**: Remove all comment lines, keep only valid JSON

**Target State**:

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
    }
  },
  "server": {
    "port": 8080,
    "host": "0.0.0.0"
  }
}
```

### Task 1.3 & 1.4: Remove Duplicate Event Handlers

**Location**:

- `voice-sending-card.js`: Lines ~315-325
- `voice-receiving-card.js`: Lines ~591-601

**Action**: Delete the second (shorter) `oniceconnectionstatechange` assignment, keep the first (comprehensive) one.

### Task 1.5: Fix Docker Health Check

**Current State**:

```dockerfile
HEALTHCHECK ... CMD curl -f http://localhost:8080/health || exit 1
```

**Target State**:

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1
```

### Acceptance Criteria - Phase 1

| ID    | Criterion                                             | Pass Condition                  |
| ----- | ----------------------------------------------------- | ------------------------------- |
| AC1.1 | `manifest.json` is valid JSON                         | `python -m json.tool` succeeds  |
| AC1.2 | `config.json` is valid JSON                           | `python -m json.tool` succeeds  |
| AC1.3 | Single `oniceconnectionstatechange` in sending card   | `grep -c` returns 1             |
| AC1.4 | Single `oniceconnectionstatechange` in receiving card | `grep -c` returns 1             |
| AC1.5 | Health check uses Python                              | Dockerfile contains `python -c` |
| AC1.6 | All containers start                                  | `docker compose up -d` succeeds |
| AC1.7 | No errors in logs                                     | No ERROR level messages         |

**Run verification**: `./.handover/verification-scripts/verify-phase-1.sh`

---

## Phase 2: LAN-Only Configuration

**Objective**: Configure the system to work without any external network dependencies.

**Duration**: 30 minutes

**Prerequisites**: Phase 1 complete

**Verification**: `.handover/verification-scripts/verify-phase-2.sh`

### Tasks

| ID  | Task                                             | File                                    | Priority  |
| --- | ------------------------------------------------ | --------------------------------------- | --------- |
| 2.1 | Remove external STUN servers from backend        | `webrtc_backend/webrtc_server_relay.py` | 🔴 High   |
| 2.2 | Remove external STUN servers from sending card   | `config/www/voice-sending-card.js`      | 🔴 High   |
| 2.3 | Remove external STUN servers from receiving card | `config/www/voice-receiving-card.js`    | 🔴 High   |
| 2.4 | Update config.json for LAN mode                  | `webrtc_backend/config.json`            | 🟠 Medium |

### Task 2.1: Update Backend

**File**: `webrtc_backend/webrtc_server_relay.py`

Find all RTCPeerConnection creations and set empty ICE servers:

```python
pc = RTCPeerConnection(configuration={"iceServers": []})
```

### Task 2.2 & 2.3: Update Frontend Cards

**Files**: `voice-sending-card.js` and `voice-receiving-card.js`

**Current State**:

```javascript
this.peerConnection = new RTCPeerConnection({
  iceServers: [{ urls: "stun:stun.l.google.com:19302" }, { urls: "stun:stun1.l.google.com:19302" }, { urls: "stun:stun.stunprotocol.org:3478" }],
});
```

**Target State**:

```javascript
this.peerConnection = new RTCPeerConnection({
  iceServers: [], // Empty for LAN-only
  bundlePolicy: "max-bundle",
  rtcpMuxPolicy: "require",
  sdpSemantics: "unified-plan",
});
```

### Acceptance Criteria - Phase 2

| ID    | Criterion                   | Pass Condition               |
| ----- | --------------------------- | ---------------------------- |
| AC2.1 | No Google STUN in backend   | No "google" in Python files  |
| AC2.2 | No Google STUN in frontend  | No "google" in JS files      |
| AC2.3 | No stunprotocol.org in code | No references found          |
| AC2.4 | Voice works on localhost    | Manual test passes           |
| AC2.5 | Network disabled test       | Voice works without internet |

**Run verification**: `./.handover/verification-scripts/verify-phase-2.sh`

---

## Phase 3: SSL Certificates for LAN

**Objective**: Generate SSL certificates that are valid for the server's LAN IP address.

**Duration**: 30 minutes

**Prerequisites**: Phase 2 complete

**Verification**: `.handover/verification-scripts/verify-phase-3.sh`

### Tasks

| ID  | Task                                 | File                       | Priority  |
| --- | ------------------------------------ | -------------------------- | --------- |
| 3.1 | Create certificate generation script | `ssl/generate_lan_cert.sh` | 🔴 High   |
| 3.2 | Run script to generate certificate   | -                          | 🔴 High   |
| 3.3 | Restart Nginx to load new cert       | -                          | 🔴 High   |
| 3.4 | Document mobile trust instructions   | `ssl/MOBILE_TRUST.md`      | 🟠 Medium |

### Task 3.1: Create Generation Script

**File**: `ssl/generate_lan_cert.sh`

The script must:

1. Detect server's LAN IP automatically
2. Create OpenSSL config with Subject Alternative Names
3. Generate certificate valid for: localhost, LAN IP, hostname
4. Output clear instructions for next steps

### Task 3.4: Mobile Trust Documentation

**File**: `ssl/MOBILE_TRUST.md`

Document steps for:

- iOS certificate installation
- Android certificate installation
- Alternative: accepting browser warning

### Acceptance Criteria - Phase 3

| ID    | Criterion                       | Pass Condition                          |
| ----- | ------------------------------- | --------------------------------------- |
| AC3.1 | Script exists and is executable | `test -x ssl/generate_lan_cert.sh`      |
| AC3.2 | Certificate contains LAN IP     | IP found in cert Subject Alt Names      |
| AC3.3 | Certificate contains localhost  | localhost in cert Subject Alt Names     |
| AC3.4 | Nginx loads new certificate     | `docker compose restart nginx` succeeds |
| AC3.5 | HTTPS accessible via IP         | `curl -k https://$IP` returns 200/302   |

**Run verification**: `./.handover/verification-scripts/verify-phase-3.sh`

---

## Phase 4: Cross-Device Verification

**Objective**: Verify that mobile devices can successfully send voice to the server.

**Duration**: 30 minutes

**Prerequisites**: Phase 3 complete

**🎯 MILESTONE**: Mobile device can send voice

**Verification**: `.handover/verification-scripts/verify-phase-4.sh`

### Tasks

| ID  | Task                        | Description                  | Priority  |
| --- | --------------------------- | ---------------------------- | --------- |
| 4.1 | Trust certificate on mobile | Install or accept cert       | 🔴 High   |
| 4.2 | Test UI access from mobile  | Navigate to server IP        | 🔴 High   |
| 4.3 | Test microphone permission  | Grant access in browser      | 🔴 High   |
| 4.4 | Test voice transmission     | Verify waveform activity     | 🔴 High   |
| 4.5 | Test voice reception        | Hear audio on another device | 🟠 Medium |

### Test Procedure

1. **Access from Mobile**

   - Open browser on mobile device
   - Navigate to `https://YOUR_SERVER_IP`
   - Accept certificate warning or have cert installed
   - Expected: Home Assistant login page appears

2. **Grant Microphone Permission**

   - Click "Voice Send" panel
   - Click microphone button
   - Grant permission when prompted
   - Expected: Status shows "connected"

3. **Verify Transmission**

   - Speak into phone microphone
   - Watch waveform visualization
   - Expected: Waveform shows activity

4. **Verify Reception**
   - Open second device
   - Navigate to Voice Receive panel
   - Connect to stream
   - Expected: Audio heard

### Acceptance Criteria - Phase 4

| ID    | Criterion                 | Pass Condition                  |
| ----- | ------------------------- | ------------------------------- |
| AC4.1 | Mobile accesses HTTPS     | Page loads without error        |
| AC4.2 | Microphone prompt appears | Browser shows permission dialog |
| AC4.3 | Permission granted        | Status shows "connected"        |
| AC4.4 | Waveform shows activity   | Visual confirmation             |
| AC4.5 | Audio received            | Listen confirms audio           |
| AC4.6 | Latency acceptable        | < 1 second delay                |

**Run verification**: `./.handover/verification-scripts/verify-phase-4.sh`

---

## Phase 5: Production Hardening

**Objective**: Configure the system for reliable, long-term operation.

**Duration**: 45 minutes

**Prerequisites**: Phase 4 complete

**Verification**: `.handover/verification-scripts/verify-phase-5.sh`

### Tasks

| ID  | Task                      | File                 | Priority  |
| --- | ------------------------- | -------------------- | --------- |
| 5.1 | Set correct timezone      | `docker-compose.yml` | 🟠 Medium |
| 5.2 | Add log rotation          | `docker-compose.yml` | 🟠 Medium |
| 5.3 | Remove USB device mapping | `docker-compose.yml` | 🟡 Low    |
| 5.4 | Verify restart policies   | `docker-compose.yml` | 🟠 Medium |
| 5.5 | Add audio stream port     | `docker-compose.yml` | 🔴 High   |

### Task 5.1: Set Timezone

```yaml
services:
  homeassistant:
    environment:
      - TZ=Europe/Berlin # Change to your timezone
  voice_streaming:
    environment:
      - TZ=Europe/Berlin
```

### Task 5.2: Add Log Rotation

```yaml
services:
  voice_streaming:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

### Task 5.3: Remove USB Mapping

```yaml
# Comment out or remove:
# devices:
#   - /dev/ttyUSB0:/dev/ttyUSB0
```

### Task 5.5: Add Audio Stream Port

```yaml
voice_streaming:
  ports:
    - "8080:8080" # WebRTC signaling
    - "8081:8081" # HTTP audio stream (for Phase 6)
```

### Acceptance Criteria - Phase 5

| ID    | Criterion               | Pass Condition                                      |
| ----- | ----------------------- | --------------------------------------------------- |
| AC5.1 | Timezone is correct     | `docker exec homeassistant date` shows correct time |
| AC5.2 | Log rotation configured | LogConfig in docker inspect                         |
| AC5.3 | No USB device errors    | Containers start without device errors              |
| AC5.4 | Restart policy set      | RestartPolicy is "unless-stopped"                   |
| AC5.5 | Port 8081 exposed       | `docker compose ps` shows 8081                      |

**Run verification**: `./.handover/verification-scripts/verify-phase-5.sh`

---

## Phase 6: HA Media Player Integration

**Objective**: Enable playing voice streams on HA-compatible speakers.

**Duration**: 2 hours

**Prerequisites**: Phase 5 complete

**🎯 MILESTONE**: Audio plays on real speaker

**Verification**: `.handover/verification-scripts/verify-phase-6.sh`

### Tasks

| ID  | Task                         | File                                                     | Priority  |
| --- | ---------------------------- | -------------------------------------------------------- | --------- |
| 6.1 | Create audio stream server   | `webrtc_backend/audio_stream_server.py`                  | 🔴 High   |
| 6.2 | Integrate with relay server  | `webrtc_backend/webrtc_server_relay.py`                  | 🔴 High   |
| 6.3 | Update HA component          | `config/custom_components/voice_streaming/__init__.py`   | 🔴 High   |
| 6.4 | Create services.yaml         | `config/custom_components/voice_streaming/services.yaml` | 🔴 High   |
| 6.5 | Update nginx for audio route | `nginx.conf`                                             | 🟠 Medium |
| 6.6 | Test with HA media player    | -                                                        | 🔴 High   |

### Task 6.1: Audio Stream Server

Create `webrtc_backend/audio_stream_server.py`:

- HTTP endpoint at `/stream.mp3`
- Content-Type: `audio/mpeg`
- Chunked transfer encoding
- Receives audio from WebRTC relay
- Serves to multiple HTTP clients
- Status endpoint at `/stream/status`

### Task 6.3 & 6.4: HA Services

New services to implement:

- `voice_streaming.play_on_speaker` - Plays stream on a media_player entity
- `voice_streaming.stop_on_speaker` - Stops the stream

Service schema (`services.yaml`):

```yaml
play_on_speaker:
  name: Play Voice Stream on Speaker
  description: Play the live voice stream on a Home Assistant media player
  fields:
    entity_id:
      name: Media Player
      required: true
      selector:
        entity:
          domain: media_player
```

### Task 6.5: Update Nginx

Add audio stream route to `nginx.conf`:

```nginx
upstream audio_stream {
    server voice_streaming:8081;
}

location /audio-stream/ {
    proxy_pass http://audio_stream/;
    proxy_buffering off;
    chunked_transfer_encoding on;
}
```

### Acceptance Criteria - Phase 6

| ID    | Criterion                      | Pass Condition                |
| ----- | ------------------------------ | ----------------------------- |
| AC6.1 | Audio stream endpoint responds | `/stream/status` returns JSON |
| AC6.2 | HA service registered          | Service in Developer Tools    |
| AC6.3 | Service callable               | No error when calling         |
| AC6.4 | Audio plays on speaker         | Audible confirmation          |
| AC6.5 | Multiple concurrent receivers  | Test with 2+ speakers         |

**Run verification**: `./.handover/verification-scripts/verify-phase-6.sh`

---

## Phase 7: Reliability & Monitoring

**Objective**: Add features for long-term reliability and visibility.

**Duration**: 1 hour

**Prerequisites**: Phase 6 complete

**Verification**: `.handover/verification-scripts/verify-phase-7.sh`

### Tasks

| ID  | Task                           | File                     | Priority  |
| --- | ------------------------------ | ------------------------ | --------- |
| 7.1 | Increase reconnection attempts | Frontend cards           | 🟠 Medium |
| 7.2 | Add exponential backoff        | Frontend cards           | 🟠 Medium |
| 7.3 | Add metrics endpoint           | `webrtc_server_relay.py` | 🟠 Medium |
| 7.4 | Add graceful shutdown          | `webrtc_server_relay.py` | 🟠 Medium |
| 7.5 | Add stream health broadcast    | `webrtc_server_relay.py` | 🟡 Low    |

### Task 7.1: Increase Reconnection Attempts

**Change in both frontend cards**:

From:

```javascript
this.maxReconnectAttempts = 3;
```

To:

```javascript
this.maxReconnectAttempts = 10;
```

### Task 7.3: Add Metrics Endpoint

Add `/metrics` endpoint to `webrtc_server_relay.py`:

```python
async def metrics(self, request):
    return web.json_response({
        "uptime_seconds": time.time() - self.start_time,
        "active_connections": len(self.connections),
        "active_streams": len(self.active_streams),
        "total_audio_bytes": self.total_audio_bytes
    })
```

### Task 7.4: Add Graceful Shutdown

Handle SIGTERM/SIGINT signals to close connections cleanly:

```python
import signal

async def shutdown():
    """Close all connections gracefully"""
    for conn_id in list(self.connections.keys()):
        await self.cleanup_connection(conn_id)
```

### Acceptance Criteria - Phase 7

| ID    | Criterion               | Pass Condition                    |
| ----- | ----------------------- | --------------------------------- |
| AC7.1 | Reconnect attempts = 10 | Value found in source code        |
| AC7.2 | Metrics endpoint works  | `curl /metrics` returns JSON      |
| AC7.3 | Graceful shutdown       | Connections close cleanly on stop |
| AC7.4 | Network recovery        | System recovers from WiFi blip    |

**Run verification**: `./.handover/verification-scripts/verify-phase-7.sh`

---

## Phase 8: Final Testing & Deployment

**Objective**: Complete system verification and production deployment.

**Duration**: 30 minutes

**Prerequisites**: Phase 7 complete

**🎯 MILESTONE**: Production ready

**Verification**: `.handover/verification-scripts/verify-phase-8.sh`

### Tasks

| ID  | Task                           | File                  | Priority  |
| --- | ------------------------------ | --------------------- | --------- |
| 8.1 | Create production start script | `start_production.sh` | 🔴 High   |
| 8.2 | Run full integration test      | -                     | 🔴 High   |
| 8.3 | Stress test (1 hour)           | -                     | 🟠 Medium |
| 8.4 | Document deployment            | `DEPLOYMENT.md`       | 🟠 Medium |
| 8.5 | Clean up test files            | -                     | 🟡 Low    |

### Task 8.1: Production Start Script

Create `start_production.sh`:

- Verify Docker is running
- Build and start services
- Wait for services to initialize
- Run health checks
- Display access URLs

### Final Acceptance Criteria

| ID    | Criterion                   | Pass Condition                   |
| ----- | --------------------------- | -------------------------------- |
| AC8.1 | All containers running      | `docker compose ps` shows all Up |
| AC8.2 | Voice works mobile → server | Manual test passes               |
| AC8.3 | Audio plays on HA speaker   | Manual test passes               |
| AC8.4 | System stable for 1 hour    | No crashes/errors                |
| AC8.5 | Disconnection recovery      | Reconnects automatically         |
| AC8.6 | Latency < 1 second          | Measured and confirmed           |
| AC8.7 | No internet required        | Works with internet disabled     |

**Run verification**: `./.handover/verification-scripts/verify-phase-8.sh`

---

## Definition of Done

A phase is considered **DONE** when:

1. ✅ All tasks completed
2. ✅ All acceptance criteria pass
3. ✅ Verification script runs without failures
4. ✅ No new errors in logs
5. ✅ Changes committed to version control
6. ✅ Next phase can safely begin

---

## Risk Register

| Risk                        | Probability | Impact | Mitigation                      |
| --------------------------- | ----------- | ------ | ------------------------------- |
| WebRTC fails without STUN   | Low         | High   | Host candidates work on LAN     |
| Mobile browser blocks mic   | Medium      | High   | Proper SSL cert with SAN        |
| HA MediaPlayer incompatible | Low         | Medium | Test with common speakers first |
| Audio quality poor          | Low         | Medium | Audio constraints tuned         |
| Network latency high        | Low         | Medium | All on same LAN                 |

---

## Appendix A: Quick Reference

### Commands

```bash
# Start system
./start_production.sh

# Stop system
docker compose down

# View logs
docker compose logs -f

# Restart specific service
docker compose restart voice_streaming

# Check health
curl http://localhost:8080/health

# Check metrics
curl http://localhost:8080/metrics

# Generate new SSL cert
./ssl/generate_lan_cert.sh

# Run specific phase verification
./.handover/verification-scripts/verify-phase-1.sh

# Run all verifications
./.handover/verification-scripts/verify-all.sh
```

### Key URLs

| URL                                 | Purpose             |
| ----------------------------------- | ------------------- |
| `https://SERVER_IP`                 | Home Assistant      |
| `https://SERVER_IP/voice-streaming` | Voice Send panel    |
| `https://SERVER_IP/voice-receiving` | Voice Receive panel |
| `http://SERVER_IP:8080/health`      | Backend health      |
| `http://SERVER_IP:8080/metrics`     | Backend metrics     |
| `http://SERVER_IP:8081/stream.mp3`  | Audio stream        |

---

_Document prepared for Senior Developer implementation_  
\_Project Manager sign-off: ****\_\_\_****  
_Date: 2026-01-11_
