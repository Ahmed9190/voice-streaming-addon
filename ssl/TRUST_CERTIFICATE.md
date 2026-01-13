# How to Trust the Self-Signed Certificate

## The Problem

Your browser doesn't trust the self-signed SSL certificate, causing:

- Service Worker registration failures
- "Not Secure" warnings
- WebRTC connection issues

## Solution: Trust the Certificate

### Chrome/Chromium/Edge (Desktop)

1. **Navigate to the site**: `https://192.168.2.185`

2. **Accept the certificate warning**:

   - Click "Advanced" on the warning page
   - Click "Proceed to 192.168.2.185 (unsafe)"

3. **Install the certificate permanently** (recommended):
   - In Chrome, go to: `chrome://settings/security`
   - Click "Manage certificates"
   - Go to "Authorities" tab
   - Click "Import"
   - Select: `/mnt/Files/Programming/home_assistant/webrtc_voice_sending/ssl/homeassistant.crt`
   - Check "Trust this certificate for identifying websites"
   - Click OK

### Firefox (Desktop)

1. Navigate to `https://192.168.2.185`
2. Click "Advanced" → "Accept the Risk and Continue"

**OR install permanently:**

- Settings → Privacy & Security → Certificates → View Certificates
- Authorities tab → Import → Select `homeassistant.crt`
- Check "Trust this CA to identify websites"

### Mobile Devices (Android/iOS)

See `MOBILE_TRUST.md` for detailed mobile instructions.

### Linux System-Wide Trust

```bash
# Copy certificate to system trust store
sudo cp ssl/homeassistant.crt /usr/local/share/ca-certificates/homeassistant.crt
sudo update-ca-certificates
```

## Verification

After trusting the certificate:

1. Reload `https://192.168.2.185`
2. Check for a **lock icon** 🔒 in the address bar
3. The service worker error should disappear
4. Check browser console - no SSL errors

## Alternative: Use HTTP for Local Development

If you don't need SSL for testing:

1. Access via `http://192.168.2.185` (port 80)
2. Note: WebRTC may have limitations over HTTP
3. Production should always use HTTPS
