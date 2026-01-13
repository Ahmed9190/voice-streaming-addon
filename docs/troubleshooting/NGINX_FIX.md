# ✅ NGINX WEBSOCKET PROXY FIX

## The Problem

WebSocket connection was failing with:

```
WebSocket connection to 'wss://localhost/ws' failed
```

### Root Cause

The Nginx configuration was **not passing the `/ws` path** to the backend WebRTC server.

**Old Configuration (WRONG):**

```nginx
location /ws {
    proxy_pass http://127.0.0.1:8080;  # ❌ Missing /ws path
}
```

When a request came to `https://localhost/ws`, Nginx was proxying to `http://127.0.0.1:8080/` (without the `/ws` path), causing a 404 or connection failure.

## The Fix

**New Configuration (CORRECT):**

```nginx
location /ws {
    proxy_pass http://127.0.0.1:8080/ws;  # ✅ Includes /ws path
    proxy_read_timeout 86400s;
    proxy_send_timeout 86400s;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

### What Changed

1. ✅ Added `/ws` to `proxy_pass` directive
2. ✅ Added missing proxy headers (Host, X-Real-IP, X-Forwarded-For)
3. ✅ Reloaded Nginx configuration

## Request Flow

```
Browser
  ↓
wss://localhost/ws (HTTPS port 443)
  ↓
Nginx SSL Termination
  ↓
location /ws { proxy_pass http://127.0.0.1:8080/ws; }
  ↓
WebRTC Server (http://127.0.0.1:8080/ws)
  ↓
WebSocket Connection Established ✅
```

## Testing

### Test 1: Direct Connection to WebRTC Server

```bash
curl -i http://localhost:8080/ws
# Should return: 400 Bad Request (expecting WebSocket upgrade)
```

### Test 2: WebSocket Through Nginx

```bash
python3 test_nginx_websocket.py
# Should show: ✅ Connected successfully!
```

### Test 3: Browser Console

1. Open Home Assistant
2. Open Voice Receiving Card
3. Click "Auto Listen"
4. Check console (F12):

```
[WebRTC] Connecting to: wss://localhost/ws
WebSocket connection to 'wss://localhost/ws' established ✅
```

## Configuration

### Voice Receiving Card Settings

**Option 1: Use Nginx Proxy (Recommended)**

```yaml
server_url: https://localhost/ws
# OR leave empty - it will use default
```

**Option 2: Direct to WebRTC Server**

```yaml
server_url: ws://localhost:8080/ws
```

## Verification Checklist

- [x] Nginx configuration updated
- [x] Nginx configuration tested: `nginx -t`
- [x] Nginx reloaded: `nginx -s reload`
- [ ] Test WebSocket connection: `python3 test_nginx_websocket.py`
- [ ] Browser hard refresh: Ctrl + Shift + R
- [ ] Voice Receiving Card connects successfully

## Troubleshooting

### If WebSocket Still Fails

1. **Check Nginx is running:**

   ```bash
   docker ps | grep nginx
   ```

2. **Check Nginx logs:**

   ```bash
   docker logs ha-nginx | tail -50
   ```

3. **Verify WebRTC server is responding:**

   ```bash
   curl http://localhost:8080/ws
   # Should return 400 (expecting WebSocket upgrade)
   ```

4. **Test Nginx config:**

   ```bash
   docker exec ha-nginx nginx -t
   ```

5. **Reload Nginx:**
   ```bash
   docker exec ha-nginx nginx -s reload
   ```

### Common Issues

**Issue: SSL Certificate Error**

- The test script disables SSL verification for self-signed certs
- Browser may show security warning - this is normal for self-signed certs

**Issue: Connection Timeout**

- Check firewall: `sudo ufw status`
- Ensure port 443 is open
- Check if Nginx is listening: `netstat -tuln | grep 443`

**Issue: 502 Bad Gateway**

- WebRTC server is not running
- Check: `docker ps | grep voice-streaming`
- Start: `docker start voice-streaming`

## Files Modified

1. **`nginx.conf`**

   - Changed `proxy_pass http://127.0.0.1:8080` to `http://127.0.0.1:8080/ws`
   - Added proxy headers for proper WebSocket handling

2. **`test_nginx_websocket.py`** (NEW)
   - Test script for verifying WebSocket connections through Nginx
   - Handles SSL for self-signed certificates

## Next Steps

1. **Test the connection:**

   ```bash
   python3 test_nginx_websocket.py
   ```

2. **If test passes, refresh browser:**

   - Hard refresh: Ctrl + Shift + R
   - Open Voice Receiving Card
   - Click "Auto Listen"
   - Should connect successfully!

3. **Monitor Nginx logs:**
   ```bash
   docker logs -f ha-nginx
   ```

---

**Status:** ✅ Nginx configuration fixed and reloaded
**Action Required:** Test WebSocket connection and refresh browser
