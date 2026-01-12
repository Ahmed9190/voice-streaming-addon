# 🚀 Setup Guide: Zero to Running

This guide will take you from a fresh clone to a working voice streaming setup.

---

## Prerequisites Checklist

Before you begin, ensure you have:

- [ ] **Docker** (version 20.10+)

  ```bash
  docker --version
  # Expected: Docker version 20.10.x or higher
  ```

- [ ] **Docker Compose** (v2 plugin)

  ```bash
  docker compose version
  # Expected: Docker Compose version v2.x.x
  ```

- [ ] **User in Docker group** (to run without sudo)

  ```bash
  groups | grep docker
  # If missing: sudo usermod -aG docker $USER && newgrp docker
  ```

- [ ] **Ports available**: 80, 443, 8080, 8123

  ```bash
  sudo lsof -i :80 -i :443 -i :8080 -i :8123
  # Should return empty or you need to stop conflicting services
  ```

- [ ] **Modern browser** with WebRTC support (Chrome, Firefox, Edge)

---

## Step-by-Step Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/Ahmed9190/voice-streaming-addon.git webrtc_voice_sending
cd webrtc_voice_sending
```

### Step 2: Verify SSL Certificates Exist

```bash
ls -la ssl/
# Expected output:
# homeassistant.crt  (certificate file)
# homeassistant.key  (private key)
# openssl.cnf        (config file)
```

If certificates are missing, generate them:

```bash
mkdir -p ssl && cd ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout homeassistant.key -out homeassistant.crt \
  -subj "/C=US/ST=State/L=City/O=Org/CN=localhost"
cd ..
```

### Step 3: Start All Services

```bash
./start_services.sh
```

This script will:

1. Build the `voice_streaming` Docker image
2. Start Home Assistant, WebRTC backend, and Nginx containers
3. Wait 10 seconds for services to initialize
4. Display running container status

**Expected output:**

```
Starting Voice Streaming Services
=================================
Building and starting Docker services...
[+] Building X.Xs (...)
[+] Running 3/3
 ✔ Container homeassistant    Started
 ✔ Container voice-streaming  Started
 ✔ Container ha-nginx         Started
...
Services started successfully!
Access Home Assistant at: https://localhost
WebRTC backend API at: http://localhost:8080
```

### Step 4: Access Home Assistant

1. Open your browser and navigate to: **https://localhost**
2. ⚠️ **Accept the security warning** (self-signed certificate)

   - Chrome: Click "Advanced" → "Proceed to localhost"
   - Firefox: Click "Advanced" → "Accept the Risk and Continue"

3. **First-time HA setup** (if prompted):
   - Create a username and password
   - Set your location/timezone
   - Skip any optional integrations for now

### Step 5: Verify Custom Panels

After logging in:

1. Look at the **left sidebar** for:

   - 🎤 **Voice Send** (sends audio)
   - 🎧 **Voice Receive** (receives audio)

2. If panels are missing:
   - Check **Settings** → **Dashboards**
   - Verify `configuration.yaml` has the `panel_custom` entries

### Step 6: Test the Setup

**Quick Health Check:**

```bash
# Check backend is healthy
curl http://localhost:8080/health
# Expected: {"status": "healthy", "webrtc_available": true, ...}
```

**Full Integration Test:**

```bash
# Requires Python 3 with aiohttp
pip install aiohttp
python integration_test.py
```

**Expected output:**

```
Starting End-to-End Integration Test
===================================
1. Testing Home Assistant accessibility...
   ✓ Home Assistant is accessible
2. Testing WebRTC backend accessibility...
   ✓ WebRTC backend is healthy
3. Testing voice streaming card availability...
   ✓ Voice streaming card is correctly served

Integration test completed
```

---

## Voice Streaming Usage

### Sending Voice

1. Open **Voice Send** panel from the sidebar
2. Click the 🎤 microphone button
3. **Allow microphone access** when prompted by browser
4. Speak into your microphone
5. Status indicator shows:
   - 🟢 Green (Active): Streaming in progress
   - 🟠 Orange (Connecting): Establishing connection
   - 🔴 Red (Inactive): Not streaming

### Receiving Voice

1. Open **Voice Receive** panel from the sidebar
2. Click **"Watch Streams"** to monitor for active senders
3. When a stream appears, click the 🎧 button to start receiving
4. Audio will play through your browser speakers

---

## Stopping Services

```bash
./stop_services.sh
```

Or manually:

```bash
docker compose down
```

---

## Troubleshooting Common Issues

### Problem: "Connection Refused" on port 8080

**Cause**: Voice streaming container not running

**Solution**:

```bash
docker compose ps
# If voice-streaming is not running:
docker compose logs voice-streaming
# Look for errors, then:
docker compose up -d voice-streaming
```

### Problem: "Microphone permission denied"

**Cause**: Browser blocked microphone access

**Solution**:

1. Click the lock/info icon in the browser address bar
2. Find "Microphone" permission
3. Change to "Allow"
4. Refresh the page

### Problem: Voice panels not appearing in sidebar

**Cause**: `configuration.yaml` not properly loaded

**Solution**:

```bash
# Verify config exists
cat config/configuration.yaml | grep -A5 "panel_custom"

# Restart Home Assistant to reload config
docker compose restart homeassistant
```

### Problem: SSL Certificate errors

**Cause**: Self-signed certificate not trusted

**Solution**:

- Accept the warning in browser (development only)
- For production: Use Let's Encrypt or your own CA-signed certificates

### Problem: "ICE connection failed"

**Cause**: WebRTC cannot establish peer connection (usually NAT/firewall related)

**Solution**:

1. Ensure all clients are on the same network
2. Check firewall allows UDP traffic
3. For cross-network: Configure a TURN server (not included by default)

---

## Quick Reference

| Command                                | Purpose              |
| -------------------------------------- | -------------------- |
| `./start_services.sh`                  | Start all services   |
| `./stop_services.sh`                   | Stop all services    |
| `docker compose logs -f`               | View live logs       |
| `docker compose restart homeassistant` | Restart only HA      |
| `docker compose build voice_streaming` | Rebuild backend      |
| `python integration_test.py`           | Run validation tests |

---

## Next Steps

After successful setup:

1. Read [02-ARCHITECTURE.md](./02-ARCHITECTURE.md) to understand the system
2. Review [04-GOTCHAS.md](./04-GOTCHAS.md) before modifying code
3. Check [ONBOARDING-CHECKLIST.md](./ONBOARDING-CHECKLIST.md) for development tasks

---

_Generated by Elite Staff Engineer Handover Protocol (ESEHP-ASKS v2.0)_
