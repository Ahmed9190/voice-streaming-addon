# ✅ Onboarding Checklist

Use this checklist to verify your environment is ready and you understand the codebase.

---

## Prerequisites Verification

### Environment Setup

- [ ] Docker installed and running (`docker --version`)
- [ ] Docker Compose v2 installed (`docker compose version`)
- [ ] User in docker group (`groups | grep docker`)
- [ ] Ports 80, 443, 8080, 8123 are free
- [ ] Modern browser with WebRTC support

### Repository Setup

- [ ] Cloned the repository
- [ ] SSL certificates exist in `ssl/` directory
- [ ] Can run `./start_services.sh` without errors
- [ ] All three containers running (`docker compose ps` shows 3 services)

---

## Access Verification

### Home Assistant

- [ ] Can access https://localhost in browser
- [ ] Accepted self-signed certificate warning
- [ ] Can log into Home Assistant dashboard
- [ ] **Voice Send** panel visible in sidebar
- [ ] **Voice Receive** panel visible in sidebar

### WebRTC Backend

- [ ] Health check passes:
  ```bash
  curl http://localhost:8080/health
  # Returns: {"status": "healthy", "webrtc_available": true, ...}
  ```

### Integration Test

- [ ] Python 3 available
- [ ] aiohttp installed (`pip install aiohttp`)
- [ ] Integration test passes:
  ```bash
  python integration_test.py
  # All checks show ✓
  ```

---

## Functional Verification

### Voice Sending

- [ ] Open **Voice Send** panel
- [ ] Click microphone button
- [ ] Browser prompts for microphone access → Allow
- [ ] Status changes to "connected" (green)
- [ ] Waveform visualization shows activity when speaking
- [ ] Can stop streaming (button turns red)

### Voice Receiving

- [ ] Open **Voice Receive** panel in separate browser/tab
- [ ] While sender is active, click "Watch Streams"
- [ ] Stream appears in available list
- [ ] Click to receive stream
- [ ] Audio plays through speakers
- [ ] Visualization shows activity

---

## Documentation Review

### Required Reading

- [ ] Read [00-README-FIRST.md](./00-README-FIRST.md) - Project overview
- [ ] Read [01-SETUP-GUIDE.md](./01-SETUP-GUIDE.md) - Verified setup
- [ ] Read [02-ARCHITECTURE.md](./02-ARCHITECTURE.md) - Understood system design
- [ ] Read [04-GOTCHAS.md](./04-GOTCHAS.md) - Aware of known issues

### Optional Reading

- [ ] Read [03-DECISION-LOG.md](./03-DECISION-LOG.md) - Understands design rationale
- [ ] Read [plan.md](../plan.md) - Original product roadmap
- [ ] Read [requirements.md](../requirements.md) - Detailed development guide

---

## Code Familiarity

### Know the Key Files

- [ ] Can locate `docker-compose.yml` and understand service definitions
- [ ] Can locate `nginx.conf` and understand routing
- [ ] Can locate `webrtc_backend/webrtc_server_relay.py` (production server)
- [ ] Can locate `config/www/voice-sending-card.js` (sender UI)
- [ ] Can locate `config/www/voice-receiving-card.js` (receiver UI)
- [ ] Can locate `config/configuration.yaml` (HA config)

### Understand the Flow

- [ ] Can trace: Browser → Nginx → WebRTC Backend
- [ ] Can trace: WebSocket connection path
- [ ] Can trace: Audio stream from sender to receiver
- [ ] Understands relay pattern (sender → server → receivers)

---

## Development Workflow

### Making Changes

- [ ] Know to edit `webrtc_server_relay.py` (not basic version)
- [ ] Know to edit correct `.js` files (voice-sending/receiving-card.js)
- [ ] Know how to restart containers after changes:
  ```bash
  docker compose restart voice_streaming  # Backend changes
  # Frontend JS changes are instant (refresh browser)
  docker compose restart homeassistant    # HA config changes
  ```

### Viewing Logs

- [ ] Can view all logs: `docker compose logs -f`
- [ ] Can view specific service: `docker compose logs -f voice-streaming`
- [ ] Can view browser console for frontend errors

### Debugging

- [ ] Know to check browser console for WebRTC errors
- [ ] Know to check ICE connection state messages
- [ ] Know that "ICE failed" usually means network/NAT issue

---

## Known Issues Awareness

### Critical (Must Know)

- [ ] `config.json` has invalid JSON (comments) - currently ignored
- [ ] `manifest.json` uses YAML syntax - may cause HA errors
- [ ] Duplicate event handlers in frontend cards
- [ ] No TURN server = will fail cross-network

### Warnings

- [ ] Self-signed SSL = browser warnings
- [ ] Health check may show unhealthy (curl not installed)
- [ ] 10 JS files exist but only 2 are active
- [ ] Timezone hardcoded to Africa/Cairo

---

## First Tasks (Recommended)

### Low Risk - Get Familiar

- [ ] Add a `console.log()` to frontend and verify it appears
- [ ] Modify health check response and verify change
- [ ] Change a CSS style in the card and see it update

### Medium Risk - Small Improvements

- [ ] Fix duplicate event handlers in JS files (see Gotchas)
- [ ] Fix manifest.json to proper JSON format
- [ ] Remove comments from config.json

### Higher Risk - Feature Work

- [ ] Add TURN server configuration
- [ ] Implement audio recording
- [ ] Add volume control to receiver

---

## Escalation Points

If you encounter issues:

1. **Container won't start**: Check `docker compose logs`
2. **WebRTC connection fails**: Check browser console for ICE errors
3. **No audio**: Verify microphone permissions, check `mediaStream` object
4. **Configuration not loading**: Restart HA, check YAML syntax

For architecture questions, refer to [02-ARCHITECTURE.md](./02-ARCHITECTURE.md).

For known bugs, check [04-GOTCHAS.md](./04-GOTCHAS.md).

---

## Sign-Off

When you've completed this checklist, you should be able to:

- ✅ Start and stop the system
- ✅ Make basic code changes
- ✅ Debug common issues
- ✅ Understand the architecture
- ✅ Know where the problems are

Welcome to the project! 🎉

---

_Generated by Elite Staff Engineer Handover Protocol (ESEHP-ASKS v2.0)_
