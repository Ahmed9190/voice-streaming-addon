# WebSocket Debugging Quick Reference

## ✅ Verify WebSocket Connection

### Browser Console (F12)

Open the browser console and look for these messages:

**Successful Connection:**

```
WebSocket connection to 'ws://localhost:8080/ws' established
[AutoListen] Found streams, picking latest: abc123...
```

**Failed Connection:**

```
WebSocket connection to 'wss://localhost/api/voice-streaming/ws' failed
❌ This is the OLD incorrect URL
```

```
WebSocket connection to 'ws://localhost:8080/ws' failed
❌ Server not running or port blocked
```

## 🔍 Common Issues & Solutions

### Issue 1: "WebSocket connection failed"

**Symptoms:**

- Card shows "error" status
- Console shows connection refused

**Solutions:**

1. Check if WebRTC server is running:

   ```bash
   netstat -tuln | grep 8080
   # Should show: tcp 0 0 0.0.0.0:8080 LISTEN
   ```

2. Start the WebRTC server if not running

3. Check firewall:
   ```bash
   sudo ufw status
   # Ensure port 8080 is allowed
   ```

### Issue 2: "Invalid URL" error

**Symptoms:**

- Error message: "Invalid Server URL"
- Card immediately shows error state

**Solutions:**

1. Clear the server URL in card config (use default)
2. If using custom URL, ensure format is correct:
   - ✅ `192.168.1.100:8080`
   - ✅ `ws://localhost:8080`
   - ❌ `localhost/ws` (missing port)
   - ❌ `http://localhost:8080` (wrong protocol)

### Issue 3: "No streams detected"

**Symptoms:**

- Receiver shows "connected" but no streams
- Stream list shows "No streams detected"

**Solutions:**

1. This is NORMAL if no sender is active
2. Start a Voice Sending Card first
3. Wait 5 seconds for polling to detect the stream
4. Check console for "get_available_streams" messages

### Issue 4: Mixed Content Error (HTTPS)

**Symptoms:**

- Error: "Mixed Content: blocked loading insecure WebSocket"
- Only happens when HA uses HTTPS

**Solutions:**

1. Configure server URL explicitly with `ws://`:
   ```
   Server URL: ws://localhost:8080
   ```
2. Or use secure WebSocket if server supports it:
   ```
   Server URL: wss://localhost:8080
   ```

### Issue 5: Card stuck in "connecting"

**Symptoms:**

- Status shows "connecting" indefinitely
- No error message

**Solutions:**

1. Reload the page (Ctrl+F5)
2. Check WebSocket in Network tab:
   - Open DevTools → Network → WS filter
   - Should see connection attempt
3. Check server logs for errors
4. Try clearing browser cache

## 🧪 Testing Checklist

### Pre-flight Checks

- [ ] WebRTC server is running on port 8080
- [ ] Port 8080 is accessible (not blocked by firewall)
- [ ] Home Assistant frontend is loaded
- [ ] Browser console is open (F12)

### Sending Card Test

1. [ ] Add Voice Sending Card to dashboard
2. [ ] Click "Start" button
3. [ ] Status changes: disconnected → connecting → connected
4. [ ] Microphone permission granted
5. [ ] Audio visualization shows activity
6. [ ] Console shows WebSocket connection established

### Receiving Card Test

1. [ ] Add Voice Receiving Card to dashboard
2. [ ] Click "Auto Listen" button
3. [ ] Status changes: disconnected → connecting → connected
4. [ ] Console shows "get_available_streams" requests
5. [ ] If sender active: stream appears in list
6. [ ] If sender active: audio plays automatically
7. [ ] Audio visualization shows activity

## 📊 Network Tab Inspection

### How to Check WebSocket Traffic

1. Open DevTools (F12)
2. Go to Network tab
3. Click "WS" filter
4. Reload the page or trigger connection
5. Click on the WebSocket connection
6. View Messages tab

### Expected Messages (Receiver)

```
↑ {"type":"get_available_streams"}
↓ {"type":"available_streams","streams":[]}
↑ {"type":"get_available_streams"}
↓ {"type":"available_streams","streams":["abc123"]}
↑ {"type":"start_receiving","stream_id":"abc123"}
↓ {"type":"webrtc_offer","offer":{...}}
↑ {"type":"webrtc_answer","answer":{...}}
↑ {"type":"ice_candidate","candidate":{...}}
↓ {"type":"ice_candidate","candidate":{...}}
```

## 🛠️ Manual WebSocket Test

### Using `websocat` (if installed)

```bash
# Install websocat
cargo install websocat

# Connect to WebSocket
websocat ws://localhost:8080/ws

# Send message (type and press Enter)
{"type":"get_available_streams"}

# Should receive response
{"type":"available_streams","streams":[]}
```

### Using Python

```python
import asyncio
import websockets
import json

async def test():
    async with websockets.connect('ws://localhost:8080/ws') as ws:
        await ws.send(json.dumps({"type": "get_available_streams"}))
        response = await ws.recv()
        print(response)

asyncio.run(test())
```

## 📝 Logging

### Enable Verbose Logging

Add to Home Assistant `configuration.yaml`:

```yaml
logger:
  default: info
  logs:
    custom_components.voice_streaming: debug
```

### Browser Console Filters

```javascript
// Filter for WebSocket messages
localStorage.debug = "websocket:*";

// Filter for WebRTC messages
localStorage.debug = "webrtc:*";
```

## 🎯 Quick Fixes

### Reset Everything

1. Stop all cards (click Stop buttons)
2. Reload Home Assistant frontend (Ctrl+F5)
3. Clear browser cache
4. Restart WebRTC server
5. Start fresh

### Force Reconnect

1. Change server URL to something invalid
2. Save
3. Change back to correct URL (or empty for default)
4. Save
5. Click Auto Listen again

### Check Card Configuration

```yaml
# Example working config
type: custom:voice-receiving-card
name: Voice Receiver
# server_url: leave empty for default localhost:8080
auto_play: true
```

---

**Remember**: The default `ws://localhost:8080/ws` should work out of the box if the WebRTC server is running!
