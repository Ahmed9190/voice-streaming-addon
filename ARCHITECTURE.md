# Voice Streaming Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                     Home Assistant (Port 8123)                  │
│                                                                 │
│  ┌──────────────────┐              ┌──────────────────┐        │
│  │  Voice Sending   │              │ Voice Receiving  │        │
│  │      Card        │              │      Card        │        │
│  │                  │              │                  │        │
│  │  [🎤 Start]      │              │  [👂 Auto Listen]│        │
│  └────────┬─────────┘              └────────┬─────────┘        │
│           │                                 │                  │
│           │ WebSocket                       │ WebSocket        │
│           │ (Signaling)                     │ (Signaling)      │
└───────────┼─────────────────────────────────┼──────────────────┘
            │                                 │
            │                                 │
            ▼                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│              WebRTC Server (Port 8080)                          │
│                                                                 │
│  Endpoint: ws://localhost:8080/ws                               │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  WebSocket Handler                                       │  │
│  │  • Manages connections                                   │  │
│  │  • Handles signaling (offer/answer/ICE)                  │  │
│  │  • Tracks available streams                              │  │
│  │  • Broadcasts stream availability                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  WebRTC Peer Connections                                 │  │
│  │  • Audio track handling                                  │  │
│  │  • ICE candidate exchange                                │  │
│  │  • Media stream routing                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Message Flow

### Sender Flow

```
1. User clicks "Start" on Voice Sending Card
   ↓
2. Card connects to ws://localhost:8080/ws
   ↓
3. Card sends: { type: "start_sending" }
   ↓
4. Server creates RTCPeerConnection
   ↓
5. Server sends: { type: "sender_ready" }
   ↓
6. Card creates WebRTC offer
   ↓
7. Card sends: { type: "webrtc_offer", offer: {...} }
   ↓
8. Server responds: { type: "webrtc_answer", answer: {...} }
   ↓
9. ICE candidates exchanged
   ↓
10. Audio streaming begins 🎵
```

### Receiver Flow (Auto Listen)

```
1. User clicks "Auto Listen" on Voice Receiving Card
   ↓
2. Card connects to ws://localhost:8080/ws
   ↓
3. Card sends: { type: "get_available_streams" }
   ↓
4. Server responds: { type: "available_streams", streams: [...] }
   ↓
5. Card polls every 5 seconds for stream updates
   ↓
6. When stream detected:
   ↓
7. Card sends: { type: "start_receiving", stream_id: "..." }
   ↓
8. Server sends: { type: "webrtc_offer", offer: {...} }
   ↓
9. Card creates WebRTC answer
   ↓
10. Card sends: { type: "webrtc_answer", answer: {...} }
    ↓
11. ICE candidates exchanged
    ↓
12. Audio playback begins 🔊
```

## WebSocket Messages

### Client → Server

```json
// Request available streams
{ "type": "get_available_streams" }

// Start sending audio
{ "type": "start_sending" }

// Start receiving audio
{ "type": "start_receiving", "stream_id": "uuid-here" }

// Stop current stream
{ "type": "stop_stream" }

// WebRTC signaling
{ "type": "webrtc_offer", "offer": { "sdp": "...", "type": "offer" } }
{ "type": "webrtc_answer", "answer": { "sdp": "...", "type": "answer" } }
{ "type": "ice_candidate", "candidate": {...} }
```

### Server → Client

```json
// Available streams list
{ "type": "available_streams", "streams": ["uuid1", "uuid2"] }

// New stream available
{ "type": "stream_available", "stream_id": "uuid" }

// Stream ended
{ "type": "stream_ended", "stream_id": "uuid" }

// Sender ready for offer
{ "type": "sender_ready" }

// WebRTC signaling
{ "type": "webrtc_offer", "offer": {...} }
{ "type": "webrtc_answer", "answer": {...} }

// Audio data (for latency measurement)
{ "type": "audio_data", "timestamp": 1234567890 }
```

## Key Components

### WebRTCManager (`frontend/src/webrtc-manager.ts`)

- Manages WebSocket connection
- Handles WebRTC peer connection lifecycle
- Provides audio visualization
- Implements reconnection logic
- **New**: `getStreams()` method for polling

### Voice Sending Card

- Captures microphone audio
- Sends audio via WebRTC
- Displays audio visualization
- Configurable audio processing (noise suppression, echo cancellation)

### Voice Receiving Card

- **Auto Listen Mode**: Automatically detects and connects to streams
- Plays received audio
- Displays audio visualization
- Shows latency metrics
- Lists available streams

## Configuration

### Default Settings

- **WebSocket URL**: `ws://localhost:8080/ws`
- **Protocol**: Auto-detected (ws/wss based on HA protocol)
- **Port**: 8080
- **Polling Interval**: 5000ms (5 seconds)

### Custom Configuration

Both cards support custom server URL in the visual editor:

- Hostname/IP can be changed
- Port can be customized
- Protocol can be explicit (ws:// or wss://)

Example: `192.168.1.100:8080` or `ws://example.com:9000`
