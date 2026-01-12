# WebSocket URL Parsing - Test Cases

## How the URL Construction Works Now

### Test Case 1: Custom URL with HTTPS and path

**Input:** `https://localhost/ws`
**Result:** `wss://localhost/ws` ✅

- Protocol: https → wss
- Host: localhost
- Port: (empty - uses default 443)
- Path: /ws

### Test Case 2: Custom URL with HTTP and path

**Input:** `http://192.168.1.100/ws`
**Result:** `ws://192.168.1.100/ws` ✅

- Protocol: http → ws
- Host: 192.168.1.100
- Port: (empty - uses default 80)
- Path: /ws

### Test Case 3: Custom URL with explicit port

**Input:** `https://localhost:8080/ws`
**Result:** `wss://localhost:8080/ws` ✅

- Protocol: https → wss
- Host: localhost
- Port: 8080
- Path: /ws

### Test Case 4: No protocol (infers from page)

**Input:** `localhost/ws`
**Result (if HA is HTTPS):** `wss://localhost/ws` ✅
**Result (if HA is HTTP):** `ws://localhost/ws` ✅

- Protocol: inferred from window.location.protocol
- Host: localhost
- Port: (empty)
- Path: /ws

### Test Case 5: Host and port only

**Input:** `192.168.1.100:8080`
**Result:** `wss://192.168.1.100:8080/ws` ✅

- Protocol: inferred from page
- Host: 192.168.1.100
- Port: 8080
- Path: /ws (default added)

### Test Case 6: Empty (default behavior)

**Input:** (empty/not configured)
**Result:** `ws://localhost:8080/ws` ✅

- Protocol: ws (or wss if HA is HTTPS)
- Host: localhost (from window.location.hostname)
- Port: 8080 (default WebRTC server port)
- Path: /ws

### Test Case 7: WebSocket protocol directly

**Input:** `wss://example.com/custom/path`
**Result:** `wss://example.com/custom/path` ✅

- Protocol: wss (preserved)
- Host: example.com
- Port: (empty - default 443)
- Path: /custom/path

## Your Specific Case

**Configuration:** `https://localhost/ws`

**Old Behavior (WRONG):**

```
Input:  https://localhost/ws
Parse:  hostname=localhost, port=(empty)→8080, path=(ignored)
Result: wss://localhost:8080/ws ❌
```

**New Behavior (CORRECT):**

```
Input:  https://localhost/ws
Parse:  hostname=localhost, port=(empty), path=/ws
Result: wss://localhost/ws ✅
```

This will now connect through your Nginx proxy at port 443 (default HTTPS), which then proxies to the WebRTC server on port 8080.

## Nginx Proxy Flow

```
Browser
  ↓
wss://localhost/ws (port 443 - HTTPS)
  ↓
Nginx (listening on port 443)
  ↓
location /ws { proxy_pass http://127.0.0.1:8080; }
  ↓
WebRTC Server (port 8080)
```

## Console Output

You should now see in the browser console:

```
[WebRTC] Connecting to: wss://localhost/ws
WebSocket connection to 'wss://localhost/ws' established
```

## Testing Different Configurations

### For Direct Connection (bypass Nginx)

```yaml
server_url: "ws://localhost:8080/ws"
```

### For Nginx Proxy (HTTPS)

```yaml
server_url: "https://localhost/ws"
# OR leave empty and it will use default
```

### For Remote Server

```yaml
server_url: "wss://example.com/api/voice-streaming/ws"
```

### For Custom Port

```yaml
server_url: "192.168.1.100:9000"
# Will become: wss://192.168.1.100:9000/ws
```
