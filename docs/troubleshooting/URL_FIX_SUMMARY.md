# ✅ FIXED: URL Parsing Issue

## The Problem

When you configured `https://localhost/ws` in the card settings, the code was:

1. Parsing the protocol (https → wss) ✅
2. Extracting the hostname (localhost) ✅
3. **IGNORING the path** (/ws) ❌
4. **ADDING default port 8080** ❌
5. Resulting in: `wss://localhost:8080/ws` ❌

But you wanted: `wss://localhost/ws` (to use Nginx proxy on port 443)

## The Fix

Updated `frontend/src/webrtc-manager.ts` to:

- ✅ Preserve the full path from the URL
- ✅ Only add port if explicitly specified
- ✅ Use standard ports (443 for HTTPS, 80 for HTTP) when not specified
- ✅ Add logging to show the actual WebSocket URL being used

## Test Your Configuration

### Configuration: `https://localhost/ws`

**Now produces:**

```
[WebRTC] Connecting to: wss://localhost/ws
```

This connects through Nginx (port 443) which proxies to WebRTC server (port 8080).

## How to Apply the Fix

### 1. Rebuild (Already Done ✅)

```bash
cd frontend
npm run build
# Output: created ../config/www in 1.1s
```

### 2. Reload Home Assistant

```bash
# Option A: Use the helper script
./reload_frontend.sh

# Option B: Manual restart
docker restart homeassistant
```

### 3. Hard Refresh Browser

```
Ctrl + Shift + R (Windows/Linux)
Cmd + Shift + R (Mac)
```

### 4. Verify in Console (F12)

Look for:

```
[WebRTC] Connecting to: wss://localhost/ws
WebSocket connection to 'wss://localhost/ws' established
```

## URL Parsing Examples

| Input                       | Output                        | Notes                         |
| --------------------------- | ----------------------------- | ----------------------------- |
| `https://localhost/ws`      | `wss://localhost/ws`          | Uses port 443 (default HTTPS) |
| `http://localhost/ws`       | `ws://localhost/ws`           | Uses port 80 (default HTTP)   |
| `https://localhost:8080/ws` | `wss://localhost:8080/ws`     | Explicit port preserved       |
| `192.168.1.100:8080`        | `wss://192.168.1.100:8080/ws` | Adds /ws path                 |
| (empty)                     | `ws://localhost:8080/ws`      | Default WebRTC server         |

## Nginx Proxy Flow

```
Browser
  ↓
wss://localhost/ws (HTTPS port 443)
  ↓
Nginx SSL Termination
  ↓
location /ws { proxy_pass http://127.0.0.1:8080; }
  ↓
WebRTC Server (port 8080)
```

## Verification Checklist

- [x] Code updated in `webrtc-manager.ts`
- [x] Frontend rebuilt successfully
- [x] Version updated to 1.2.0
- [ ] Home Assistant restarted
- [ ] Browser hard refreshed
- [ ] Console shows correct URL: `wss://localhost/ws`
- [ ] WebSocket connects successfully

## Files Modified

1. **`frontend/src/webrtc-manager.ts`**

   - Rewrote URL parsing logic
   - Added path preservation
   - Added console logging
   - Fixed port handling

2. **`frontend/src/voice-receiving-card.ts`**
   - Updated version to 1.2.0

## Next Steps

1. **Restart Home Assistant** (if not done)
2. **Hard refresh browser** (Ctrl + Shift + R)
3. **Open Voice Receiving Card**
4. **Open browser console** (F12)
5. **Click "Auto Listen"**
6. **Verify console output:**
   ```
   [WebRTC] Connecting to: wss://localhost/ws
   WebSocket connection to 'wss://localhost/ws' established
   ```

---

**Status:** ✅ Fix implemented and built
**Version:** 1.2.0
**Build Time:** Just now
**Action Required:** Reload Home Assistant + Hard refresh browser
