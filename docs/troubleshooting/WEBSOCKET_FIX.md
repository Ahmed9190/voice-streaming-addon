# WebSocket Connection Fix

## Issue

The voice receiving card was attempting to connect to `wss://localhost/api/voice-streaming/ws` which doesn't exist. The actual WebRTC server runs on port 8080 with the endpoint `/ws`.

## Changes Made

### 1. WebRTC Manager (`frontend/src/webrtc-manager.ts`)

- **Fixed WebSocket URL construction**: Changed from `/api/voice-streaming/ws` to `:8080/ws`
- **Improved URL parsing**: Now properly extracts hostname and port from the server URL
- **Added `getStreams()` method**: Public method to request available streams from the server
- **Better error handling**: Validates WebSocket state before sending messages

### 2. Voice Receiving Card (`frontend/src/voice-receiving-card.ts`)

- **Implemented stream polling**: Auto Listen mode now properly polls for available streams every 5 seconds
- **Immediate stream request**: Requests streams immediately when Auto Listen is activated
- **Cleaner code**: Removed extensive comments and implemented the actual polling logic

### 3. Editor Helper Text

- Updated both sending and receiving card editors to show correct default: `localhost:8080/ws`

## Configuration

### Default Behavior

By default, the cards will connect to `ws://localhost:8080/ws` (or `wss://` if your Home Assistant is using HTTPS).

### Custom Server URL

If your WebRTC server is running on a different host or port, you can configure it in the card editor:

**Examples:**

- `192.168.1.100:8080` - Different host, same port
- `localhost:9000` - Same host, different port
- `ws://192.168.1.100:8080` - Explicit WebSocket protocol
- `wss://example.com:8080` - Secure WebSocket with custom domain

The protocol (ws/wss) will be automatically inferred from your Home Assistant's protocol if not specified.

## Testing

To verify the WebSocket connection:

1. Ensure the WebRTC server is running on port 8080
2. Open the voice receiving card in Home Assistant
3. Click "Auto Listen"
4. Check the browser console for connection logs
5. The status should change from "disconnected" → "connecting" → "connected"

## Architecture

```
Home Assistant (HTTPS on :8123)
    ↓
Voice Receiving Card (Frontend)
    ↓ WebSocket
WebRTC Server (:8080/ws)
```

The WebRTC server is separate from Home Assistant and handles the actual WebRTC signaling and media streaming.
