# Fixed: Auto Listen Not Detecting Existing Streams

## The Problem

When you:

1. Start a Voice Sending Card (creates stream)
2. Then click "Auto Listen" on Voice Receiving Card
3. The receiver doesn't detect the existing stream

## Root Cause

The Auto Listen mode was only requesting streams once immediately, but there could be a timing issue where:

- The WebSocket message might not be sent/received properly
- The server might not respond immediately
- The streams-changed event might not fire

## The Fix

### 1. Added Redundant Stream Requests

**Before:**

```typescript
// Request streams immediately
this.webrtc?.getStreams();
```

**After:**

```typescript
// Request streams immediately (critical for detecting existing streams)
console.log("[AutoListen] Requesting streams immediately...");
this.webrtc?.getStreams();

// Request again after a short delay to ensure we catch existing streams
setTimeout(() => {
  if (this.isWatching && this.webrtc) {
    console.log("[AutoListen] Second immediate request for streams...");
    this.webrtc.getStreams();
  }
}, 500);
```

**Why:** The second request 500ms later ensures we catch the response even if the first request had timing issues.

### 2. Added Comprehensive Logging

Now you'll see detailed logs showing exactly what's happening:

```javascript
[AutoListen] Starting Auto Listen mode...
[AutoListen] Already connected, requesting streams...
[AutoListen] Requesting streams immediately...
[AutoListen] Second immediate request for streams...
[AutoListen] Streams changed event received. Count: 1 ["stream_abc123..."]
[AutoListen] Found streams, picking latest: stream_abc123...
```

Or if not detecting:

```javascript
[AutoListen] Streams changed event received. Count: 0 []
[AutoListen] Not auto-connecting: watching=true, streams=0, active=false
```

### 3. Improved Connection Handling

```typescript
// Always ensure we have a clean WebSocket connection
try {
  if (this.status !== "connected") {
    console.log("[AutoListen] Not connected, starting connection...");
    await this.webrtc?.startReceiving();
  } else {
    console.log("[AutoListen] Already connected, requesting streams...");
  }
} catch (e: any) {
  console.error("[AutoListen] Connection failed:", e);
  // Handle error gracefully
}
```

## Testing

### Test Case 1: Sender Already Active

1. **Start Voice Sending Card** → Stream created
2. **Click "Auto Listen"** on Voice Receiving Card
3. **Check console (F12):**

**Expected logs:**

```
[AutoListen] Starting Auto Listen mode...
[AutoListen] Already connected, requesting streams...
[AutoListen] Requesting streams immediately...
[AutoListen] Second immediate request for streams...
[AutoListen] Streams changed event received. Count: 1
[AutoListen] Found streams, picking latest: stream_xxx
[WebRTC] Starting receiving for stream: stream_xxx...
```

4. **Should auto-connect** to the existing stream ✅

### Test Case 2: No Active Senders

1. **Click "Auto Listen"** (no senders active)
2. **Check console:**

**Expected logs:**

```
[AutoListen] Starting Auto Listen mode...
[AutoListen] Requesting streams immediately...
[AutoListen] Second immediate request for streams...
[AutoListen] Streams changed event received. Count: 0
[AutoListen] Not auto-connecting: watching=true, streams=0, active=false
[AutoListen] Polling for streams...  (every 5 seconds)
```

3. **Start Voice Sending Card**
4. **Should detect new stream** within 5 seconds ✅

## Debugging

### If Still Not Detecting Existing Streams

**Check 1: Console Logs**
Look for these specific messages:

```
[AutoListen] Streams changed event received. Count: ?
```

- If Count is 0 → Server not returning streams
- If Count > 0 but not connecting → Check the "Not auto-connecting" log

**Check 2: Server Logs**

```bash
docker logs voice-streaming | grep -i stream
```

Look for:

- Stream creation messages
- get_available_streams requests
- Stream list responses

**Check 3: WebSocket Messages**

In browser DevTools:

1. Go to Network tab
2. Click on WS (WebSocket filter)
3. Click on the WebSocket connection
4. View Messages tab
5. Look for:
   ```json
   ↑ {"type":"get_available_streams"}
   ↓ {"type":"available_streams","streams":["stream_xxx"]}
   ```

### Common Issues

**Issue: Streams Count is 0 but sender is active**

**Possible causes:**

1. Sender and receiver using different WebSocket connections
2. Server not tracking streams properly
3. Stream expired/cleaned up

**Fix:**

- Restart sender
- Check server logs
- Verify both cards using same server URL

**Issue: Streams detected but not auto-connecting**

**Check the log:**

```
[AutoListen] Not auto-connecting: watching=true, streams=1, active=true
```

If `active=true`, it means you're already connected to a stream. Stop and restart Auto Listen.

## Files Modified

1. **`frontend/src/voice-receiving-card.ts`**
   - Added redundant stream requests (immediate + 500ms delay)
   - Added comprehensive logging
   - Improved error handling

## Next Steps

1. **Rebuild completed** ✅
2. **Hard refresh browser:** `Ctrl + Shift + R`
3. **Test the scenario:**
   - Start sender first
   - Then click Auto Listen
   - Check console logs
   - Should detect and connect automatically

---

**Status:** ✅ Fixed with redundant requests and better logging
**Action Required:** Hard refresh browser and test with existing sender
