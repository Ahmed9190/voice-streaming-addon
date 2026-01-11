# 📱 Mobile Device Certificate Trust Guide

This guide explains how to trust the self-signed SSL certificate on mobile devices to enable secure WebRTC voice streaming.

---

## Why Is This Needed?

WebRTC's `getUserMedia()` API (required for microphone access) only works on:

- `localhost` (automatically trusted)
- HTTPS with a **trusted** certificate

Since we use a self-signed certificate for LAN access, mobile browsers need to trust it.

---

## Option 1: Accept Browser Warning (Quick, Less Secure)

### iOS Safari

1. Navigate to `https://YOUR_SERVER_IP`
2. Tap **"Show Details"**
3. Tap **"visit this website"**
4. Tap **"Visit Website"** in the popup
5. ⚠️ Microphone access may still fail on some iOS versions

### Android Chrome

1. Navigate to `https://YOUR_SERVER_IP`
2. Tap **"Advanced"**
3. Tap **"Proceed to [IP] (unsafe)"**
4. Microphone should work after this

---

## Option 2: Install Certificate (Recommended)

### Step 1: Get the Certificate File

The certificate is located at:

```
ssl/homeassistant.crt
```

Transfer it to your mobile device via:

- Email attachment
- Cloud storage (Google Drive, iCloud, Dropbox)
- AirDrop (iOS)
- USB file transfer
- QR code with download link

---

### iOS Installation

#### Part A: Install the Profile

1. Transfer `homeassistant.crt` to your iOS device
2. Open the file (tap on email attachment, Files app, etc.)
3. A prompt will appear: **"Profile Downloaded"**
4. Go to **Settings** → **General** → **VPN & Device Management**
5. Under **Downloaded Profile**, tap the certificate
6. Tap **Install** (enter passcode if prompted)
7. Tap **Install** again on the warning screen
8. Tap **Done**

#### Part B: Enable Full Trust

1. Go to **Settings** → **General** → **About**
2. Scroll to the bottom and tap **Certificate Trust Settings**
3. Under "Enable full trust for root certificates", toggle ON the certificate
4. Tap **Continue** on the warning

#### Verify

- Open Safari and navigate to `https://YOUR_SERVER_IP`
- Page should load without certificate warnings
- The lock icon should appear in the address bar

---

### Android Installation

#### Method A: Via Settings

1. Transfer `homeassistant.crt` to your device
2. Go to **Settings** → **Security** → **Encryption & credentials**
3. Tap **Install a certificate** → **CA certificate**
4. Tap **Install anyway** on the security warning
5. Select the `homeassistant.crt` file
6. Enter your PIN/password if prompted
7. Tap **Done**

#### Method B: Via Downloads

1. Download or transfer `homeassistant.crt` to your device
2. Open the file from your Downloads or Files app
3. Follow the prompts to install as a CA certificate
4. You may need to set a screen lock if you haven't already

#### Verify

- Open Chrome and navigate to `https://YOUR_SERVER_IP`
- Page should load without certificate warnings
- A lock icon should appear in the address bar

---

## Troubleshooting

### "Not Secure" Warning Still Appears

1. **Certificate not installed correctly**

   - Retry the installation steps
   - Make sure to complete the "trust" step on iOS

2. **Certificate doesn't include your IP**

   - Regenerate the certificate: `./ssl/generate_lan_cert.sh`
   - Reinstall on mobile device

3. **Wrong IP address**
   - Ensure you're accessing the server via the same IP that's in the certificate
   - Check certificate SANs: `openssl x509 -in ssl/homeassistant.crt -noout -text | grep -A1 "Subject Alternative Name"`

### Microphone Permission Denied

1. **iOS**: Settings → Safari → Microphone → Allow
2. **Android**: Chrome Settings → Site Settings → Microphone → Allow

### Certificate Expired

Certificates are valid for 365 days. To regenerate:

```bash
./ssl/generate_lan_cert.sh
docker compose restart nginx
```

Then reinstall on mobile devices.

---

## Security Note

⚠️ **Self-signed certificates** are secure for encryption but don't verify identity. Only use them on trusted networks (your home LAN).

For production use on public networks, consider:

- Let's Encrypt (free, requires domain name)
- Commercial SSL certificate

---

## Quick Reference

| Platform | Certificate Location                                | Trust Location                                          |
| -------- | --------------------------------------------------- | ------------------------------------------------------- |
| iOS      | Settings → General → VPN & Device Management        | Settings → General → About → Certificate Trust Settings |
| Android  | Settings → Security → Install certificate           | Automatically trusted after install                     |
| Chrome   | Settings → Privacy → Security → Manage certificates | -                                                       |
| Firefox  | Settings → Privacy & Security → View Certificates   | -                                                       |

---

_Document Version: 1.0_  
_Last Updated: 2026-01-11_
