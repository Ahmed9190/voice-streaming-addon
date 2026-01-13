# SSL Certificate Error - Complete Fix Guide

## 🔍 Understanding the Error

```
SecurityError: Failed to register a ServiceWorker for scope ('https://192.168.2.185/')
with script ('https://192.168.2.185/sw-modern.js'):
An SSL certificate error occurred when fetching the script.
```

### Root Cause

Your nginx proxy is using a **self-signed SSL certificate** that your browser doesn't trust. Service Workers have **strict security requirements** and will refuse to load if there's any SSL certificate issue.

## ⚡ Quick Fix (Choose One Solution)

---

## **Solution 1: Trust the Certificate in Your Browser** (Fastest)

### For Desktop Chrome/Edge/Brave

**Option A: Temporary (until browser restart)**

1. Navigate to `https://192.168.2.185`
2. You'll see a warning: "Your connection is not private"
3. Click **"Advanced"**
4. Click **"Proceed to 192.168.2.185 (unsafe)"**
5. Reload the page (`Ctrl+R` or `F5`)

**Option B: Permanent (recommended)**

1. Open Chrome settings: `chrome://settings/security`
2. Scroll down and click **"Manage certificates"**
3. Go to the **"Authorities"** tab
4. Click **"Import"**
5. Browse to: `/mnt/Files/Programming/home_assistant/webrtc_voice_sending/ssl/homeassistant.crt`
6. Check **"Trust this certificate for identifying websites"**
7. Click **OK**
8. Restart Chrome
9. Navigate to `https://192.168.2.185` - you should see a 🔒 lock icon

### For Firefox

**Temporary:**

1. Navigate to `https://192.168.2.185`
2. Click "Advanced" → "Accept the Risk and Continue"

**Permanent:**

1. Settings → Privacy & Security → Certificates → **View Certificates**
2. **Authorities** tab → **Import**
3. Select `ssl/homeassistant.crt`
4. Check **"Trust this CA to identify websites"**
5. Click OK

### For Linux System-Wide Trust

```bash
# Run from project root
sudo cp ssl/homeassistant.crt /usr/local/share/ca-certificates/homeassistant.crt
sudo update-ca-certificates

# Restart browser completely
killall chrome chromium firefox
```

---

## **Solution 2: Regenerate Certificate with Proper SANs** (Best for Production)

Your existing script already supports this! Just run:

```bash
cd /mnt/Files/Programming/home_assistant/webrtc_voice_sending/ssl
./generate_lan_cert.sh
```

This will:

- ✅ Detect your LAN IP automatically (192.168.2.185)
- ✅ Add Subject Alternative Names (SANs)
- ✅ Backup old certificates
- ✅ Generate a new valid certificate

Then restart nginx:

```bash
cd /mnt/Files/Programming/home_assistant/webrtc_voice_sending
docker compose restart nginx
```

After this, you **still need to trust the certificate** in your browser (see Solution 1).

---

## **Solution 3: Use HTTP for Local Testing** (Not Recommended)

⚠️ **Warning:** WebRTC requires HTTPS in production. Only use HTTP for quick testing.

1. Stop nginx:

   ```bash
   docker compose stop nginx
   ```

2. Access via HTTP:
   ```
   http://192.168.2.185:8123
   ```

**Limitations:**

- WebRTC may not work properly over HTTP
- No service worker support
- Not suitable for production

---

## ✅ Verification Steps

After applying any solution:

1. **Clear browser cache:**

   - Chrome: `Ctrl+Shift+Delete` → Clear "Cached images and files"
   - Or open DevTools (`F12`) → Application → Clear storage

2. **Hard reload:**

   - `Ctrl+Shift+R` (Chrome/Firefox)
   - Or `Ctrl+F5`

3. **Check for SSL icon:**

   - Address bar should show a 🔒 lock icon (maybe with a warning triangle)
   - Click the lock to verify certificate details

4. **Check browser console:**

   - Open DevTools (`F12`) → Console tab
   - The SSL error should be **gone**
   - No more "SecurityError" messages

5. **Test Service Worker:**
   - DevTools → Application tab → Service Workers
   - Should show service worker registered for `https://192.168.2.185`

---

## 🚀 Recommended Workflow

```bash
# 1. Regenerate certificate (optional, yours is probably fine)
cd ssl
./generate_lan_cert.sh

# 2. Restart nginx
cd ..
docker compose restart nginx

# 3. Trust certificate in browser (see Solution 1 above)

# 4. Clear browser cache and hard reload (Ctrl+Shift+R)

# 5. Verify certificate
openssl s_client -connect 192.168.2.185:443 -servername 192.168.2.185 < /dev/null 2>/dev/null | openssl x509 -noout -text | grep -A1 "Subject Alternative"
```

---

## 📱 Mobile Devices

For iOS/Android, see: `ssl/MOBILE_TRUST.md`

Quick summary:

- **iOS**: Email/AirDrop the `.crt` file → Install Profile → Trust in Settings
- **Android**: Settings → Security → Install certificate from storage

---

## 🐛 Troubleshooting

### Error persists after trusting certificate

1. **Completely restart browser** (don't just close windows):

   ```bash
   killall chrome chromium firefox
   ```

2. **Clear ALL browser data**:

   - Chrome: `chrome://settings/clearBrowserData`
   - Select "All time"
   - Check "Cached images and files" + "Site settings"

3. **Check certificate is actually trusted**:
   - Visit `https://192.168.2.185`
   - Click lock icon → "Certificate" → Should say "Trusted"

### Still see "Not Secure" warning

This is **normal** for self-signed certificates. The important part is:

- ✅ No "SecurityError" in console
- ✅ Service Worker registers successfully
- ✅ Site loads and functions

### Certificate mismatch errors

Your certificate should include these SANs:

```
DNS.1 = localhost
DNS.2 = homeassistant.local
IP.1 = 127.0.0.1
IP.2 = 192.168.2.185
```

Verify with:

```bash
openssl x509 -in ssl/homeassistant.crt -noout -text | grep -A1 "Subject Alternative"
```

If missing your LAN IP, regenerate:

```bash
cd ssl
./generate_lan_cert.sh
docker compose restart nginx
```

---

## 🎯 Summary

**The Fastest Fix Right Now:**

1. Navigate to `https://192.168.2.185`
2. Click "Advanced" → "Proceed anyway"
3. `Ctrl+Shift+R` to hard reload
4. Check console - error should be gone

**For permanent fix:** Import the certificate into your browser's trust store (see Solution 1, Option B above).

The service worker error will disappear once the browser trusts the certificate! 🎉
