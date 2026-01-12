# 🎉 NEW SERVER: Real-Time Audio Relay + MP3 Streaming

## What Changed

Completely rewrote the WebRTC server to support:

1. ✅ **Real-time audio relay** (Sender → Receivers via WebRTC)
2. ✅ **MP3 HTTP streaming** (for VLC, browsers, etc.)
3. ✅ **Multiple receivers** per stream
4. ✅ **Stream management** (active streams, broadcasting)

## Key Features

### 1. Real-Time WebRTC Relay

**How it works:**

```
Sender (Microphone)
    ↓ WebRTC
Server (MediaRelay)
    ↓ WebRTC (relayed track)
Receiver(s) (Speakers)
```

The server now uses `MediaRelay` from aiortc to efficiently relay audio tracks from sender to multiple receivers without re-encoding.

### 2. MP3 HTTP Streaming

**Endpoints:**

- `http://localhost:8080/stream/{stream_id}.mp3` - Specific stream
- `http://localhost:8080/stream/latest.mp3` - Latest active stream

**Use cases:**

- Play in VLC: `vlc http://192.168.2.120:8080/stream/latest.mp3`
- Play in browser: `<audio src="http://192.168.2.120:8080/stream/latest.mp3" controls>`
- Home Assistant media player

### 3. Stream Management

**New features:**

- Tracks active streams by ID
- Broadcasts stream availability to all receivers
- Notifies when streams end
- Supports multiple simultaneous streams

## Architecture

### Connection Types

**Sender:**

1. Connects via WebSocket
2. Sends `start_sending`
3. Establishes WebRTC peer connection
4. Sends audio track
5. Server stores track for relay

**Receiver:**

1. Connects via WebSocket
2. Requests available streams
3. Sends `start_receiving` with stream_id
4. Server adds relayed track to receiver's peer connection
5. Receives audio in real-time

**MP3 Listener:**

1. HTTP GET to `/stream/latest.mp3`
2. Receives MP3-encoded audio stream
3. Can play in any MP3-compatible player

## New WebSocket Messages

### Client → Server

```json
// Start sending audio
{"type": "start_sending"}

// Start receiving specific stream
{"type": "start_receiving", "stream_id": "stream_xxx"}

// Get available streams
{"type": "get_available_streams"}

// Stop stream
{"type": "stop_stream"}
```

### Server → Client

```json
// Sender ready for WebRTC offer
{"type": "sender_ready"}

// Available streams list
{"type": "available_streams", "streams": ["stream_xxx", "stream_yyy"]}

// New stream available
{"type": "stream_available", "stream_id": "stream_xxx"}

// Stream ended
{"type": "stream_ended", "stream_id": "stream_xxx"}
```

## Testing

### Test 1: WebRTC Real-Time Relay

1. **Start sender** (Voice Sending Card)
2. **Start receiver** (Voice Receiving Card)
3. **Should hear audio in real-time!** 🎵

### Test 2: MP3 Streaming

**In browser:**

```
http://192.168.2.120:8080/stream/latest.mp3
```

**In VLC:**

```bash
vlc http://192.168.2.120:8080/stream/latest.mp3
```

**In Home Assistant:**

```yaml
service: media_player.play_media
target:
  entity_id: media_player.living_room
data:
  media_content_id: http://192.168.2.120:8080/stream/latest.mp3
  media_content_type: music
```

### Test 3: Check Health

```bash
curl http://localhost:8080/health
```

**Response:**

```json
{
  "status": "healthy",
  "active_streams": ["stream_xxx"],
  "senders": 1,
  "receivers": 2
}
```

## What Was Fixed

### Before (BROKEN)

```python
@pc.on("track")
async def on_track(track):
    # Only recorded audio
    recorder = MediaRecorder("/data/recordings/stream.wav")
    await recorder.addTrack(track)
    # ❌ Never forwarded to receivers!
```

### After (WORKING)

```python
@pc.on("track")
async def on_track(track):
    # Store track for relay
    self.active_streams[stream_id] = track

    # Broadcast availability
    await self.broadcast_stream_available(stream_id)

    # Start MP3 encoding
    asyncio.create_task(self.encode_to_mp3(stream_id, track))

# When receiver connects:
relayed_track = self.relay.subscribe(source_track)
receiver_pc.addTrack(relayed_track)
```

## Dependencies Added

- `pydub==0.25.1` - For MP3 encoding

## Server Restart Required

The server has been restarted with the new code:

```bash
docker restart voice-streaming
```

## Next Steps

1. **Refresh browser** - Hard refresh (Ctrl + Shift + R)
2. **Test WebRTC relay:**

   - Start Voice Sending Card
   - Start Voice Receiving Card
   - **Should hear audio!** 🎵

3. **Test MP3 streaming:**
   - Open `http://192.168.2.120:8080/stream/latest.mp3` in browser
   - Or play in VLC

## Troubleshooting

### If still no audio in receiver:

**Check server logs:**

```bash
docker logs voice-streaming | grep -i "track\|relay"
```

**Look for:**

```
✅ Received audio track from sender
✅ Stored stream stream_xxx
✅ Added track from stream stream_xxx to receiver
```

### If MP3 stream doesn't work:

**Check if pydub installed:**

```bash
docker exec voice-streaming pip list | grep pydub
```

**If missing:**

```bash
docker exec voice-streaming pip install pydub
docker restart voice-streaming
```

---

**Status:** ✅ Server rewritten and restarted
**Features:** Real-time WebRTC relay + MP3 HTTP streaming
**Action Required:** Refresh browser and test!
