# 🤖 AI Session Implementation Guide

## WebRTC Voice Streaming - LAN Production Deployment

**Purpose**: This document is designed to be used across multiple AI sessions to ensure consistent, complete implementation of the WebRTC Voice Streaming project.

**For**: AI Assistants / Senior Developers  
**Project Root**: `/mnt/Files/Programming/home_assistant/webrtc_voice_sending`

---

## ⚠️ Critical Instructions

**READ THIS FIRST:**

1. **DO NOT STOP** until the current phase's verification script passes
2. After automated verification passes, **GENERATE THE MANUAL VERIFICATION CHECKLIST** for the user
3. **NEVER proceed to the next phase** until:
   - ✅ Automated verification passes
   - ✅ User confirms manual verification passes
4. If verification fails, **DEBUG AND FIX** the issues
5. On session start, **CHECK THE STATE FILE** to see current progress

---

## 📁 Project Context Files

Before starting any work, read these files to understand the project:

| File                                                 | Purpose                       | Read First? |
| ---------------------------------------------------- | ----------------------------- | ----------- |
| `.handover/.state/webrtc_voice_sending-state.json`   | Current implementation status | ✅ YES      |
| `.handover/PROJECT-SPECS.md`                         | Full specifications           | ✅ YES      |
| `.handover/.context/webrtc_voice_sending-context.md` | Analysis insights             | If needed   |
| `.handover/04-GOTCHAS.md`                            | Known issues to avoid         | If needed   |
| `.handover/02-ARCHITECTURE.md`                       | System design                 | If needed   |

---

## 🔄 Session Start Protocol

When starting a new session, follow these steps:

### Step 1: Check Current State

```bash
cat .handover/.state/webrtc_voice_sending-state.json
```

Look for:

- `current_phase.phase` - Which phase we're on
- `implementation.phases[].status` - Which phases are done
- `recovery_info.next_action` - What to do next

### Step 2: Determine Next Action

| If State Shows        | Then Do                                          |
| --------------------- | ------------------------------------------------ |
| Phase X "pending"     | Start implementing Phase X                       |
| Phase X "in_progress" | Continue Phase X, run verification               |
| Phase X "complete"    | Proceed to Phase X+1                             |
| All phases complete   | Run final verification, ask user for manual test |

### Step 3: Implement and Verify

Follow the implementation workflow below.

---

## 🛠️ Implementation Workflow

For **EACH** phase, you MUST complete ALL of these steps:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        PHASE IMPLEMENTATION                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. READ the phase spec from PROJECT-SPECS.md                       │
│     └─► Understand all tasks and acceptance criteria                │
│                                                                      │
│  2. IMPLEMENT all tasks                                             │
│     └─► Make the code changes                                       │
│     └─► Create any new files                                        │
│                                                                      │
│  3. RUN the verification script                                     │
│     └─► ./.handover/verification-scripts/verify-phase-X.sh         │
│                                                                      │
│  4. If FAILED:                                                      │
│     └─► Analyze the failure                                         │
│     └─► Fix the issue                                               │
│     └─► GOTO step 3 (re-run verification)                          │
│                                                                      │
│  5. If PASSED:                                                      │
│     └─► Update state file                                           │
│     └─► GENERATE manual verification checklist                      │
│     └─► ASK user to confirm manual verification                     │
│                                                                      │
│  6. Only after user confirms:                                       │
│     └─► Proceed to next phase                                       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Phase Quick Reference

| Phase | Script              | Key Files to Modify                                            |
| ----- | ------------------- | -------------------------------------------------------------- |
| 1     | `verify-phase-1.sh` | manifest.json, config.json, voice-\*.js, Dockerfile            |
| 2     | `verify-phase-2.sh` | webrtc_server_relay.py, voice-\*.js                            |
| 3     | `verify-phase-3.sh` | ssl/generate_lan_cert.sh, ssl/MOBILE_TRUST.md                  |
| 4     | `verify-phase-4.sh` | None (manual testing only)                                     |
| 5     | `verify-phase-5.sh` | docker-compose.yml                                             |
| 6     | `verify-phase-6.sh` | audio_stream_server.py, **init**.py, services.yaml, nginx.conf |
| 7     | `verify-phase-7.sh` | voice-\*.js, webrtc_server_relay.py                            |
| 8     | `verify-phase-8.sh` | start_production.sh, DEPLOYMENT.md                             |

---

## 📝 Manual Verification Checklist Template

**After automated verification passes**, generate THIS checklist for the user:

```markdown
# ✅ Manual Verification Checklist - Phase X

**Phase**: [Phase Name]  
**Date**: [Current Date]  
**Automated Test**: ✅ PASSED

---

## Pre-Verification

- [ ] All containers are running (`docker compose ps`)
- [ ] No errors in recent logs (`docker compose logs --tail=50`)

## Verification Steps

[Phase-specific manual verification steps]

## Acceptance Confirmation

- [ ] I have verified step 1: [description]
- [ ] I have verified step 2: [description]
- [ ] I have verified step 3: [description]

## Result

- [ ] **PASS** - All verifications successful, proceed to next phase
- [ ] **FAIL** - Issues found (describe below)

### Issues Found (if any):
```

---

## 🔍 Phase-Specific Manual Verification

### Phase 1: Manual Verification

```markdown
# ✅ Manual Verification - Phase 1: Bug Fixes & Code Quality

## Verification Steps

1. **Check manifest.json is valid**

   - Open: `config/custom_components/voice_streaming/manifest.json`
   - [ ] Verify it's proper JSON format (no YAML)
   - [ ] Verify it parses without error

2. **Check config.json is valid**

   - Open: `webrtc_backend/config.json`
   - [ ] Verify no comment lines (no `#` characters)
   - [ ] Verify it parses without error

3. **Check duplicate handlers removed**

   - Open: `config/www/voice-sending-card.js`
   - Search for: `oniceconnectionstatechange`
   - [ ] Only ONE occurrence exists
   - Repeat for `voice-receiving-card.js`

4. **Check containers start**
   - Run: `docker compose up -d`
   - Run: `docker compose ps`
   - [ ] All 3 containers show "Up" status

## Confirmation

- [ ] All 4 checks pass
```

### Phase 2: Manual Verification

```markdown
# ✅ Manual Verification - Phase 2: LAN-Only Configuration

## Verification Steps

1. **Test voice on localhost**

   - Open: https://localhost in browser
   - Navigate to Voice Send panel
   - [ ] Click microphone, grant permission
   - [ ] Status shows "connected"
   - [ ] Waveform shows activity when speaking

2. **Test offline operation**

   - Disconnect internet (unplug cable or disable WiFi on server)
   - [ ] Voice sending still works
   - [ ] Voice receiving still works

3. **Verify no Google STUN references**
   - Run: `grep -r "google" config/www/*.js webrtc_backend/*.py`
   - [ ] No results returned

## Confirmation

- [ ] All 3 checks pass
```

### Phase 3: Manual Verification

```markdown
# ✅ Manual Verification - Phase 3: SSL Certificates for LAN

## Verification Steps

1. **Check certificate generation script**

   - [ ] File exists: `ssl/generate_lan_cert.sh`
   - [ ] File is executable

2. **Verify certificate contents**

   - Run: `openssl x509 -in ssl/homeassistant.crt -text -noout | grep -A1 "Subject Alternative Name"`
   - [ ] Shows localhost
   - [ ] Shows your server's IP address

3. **Test HTTPS access via IP**
   - Get server IP: `hostname -I | awk '{print $1}'`
   - Open: `https://[YOUR_IP]` in browser
   - [ ] Page loads (with or without certificate warning)

## Confirmation

- [ ] All 3 checks pass
```

### Phase 4: Manual Verification

```markdown
# ✅ Manual Verification - Phase 4: Cross-Device Communication

## Verification Steps

**⚠️ This phase is ENTIRELY manual testing**

### Test Setup

- Server IP: ******\_\_\_******
- Mobile Device: ******\_\_\_******
- Mobile Browser: ******\_\_\_******

### Tests

1. **Mobile Access**

   - Open mobile browser
   - Navigate to: `https://[SERVER_IP]`
   - [ ] Page loads (accept certificate warning if needed)
   - [ ] Can log into Home Assistant

2. **Microphone Permission**

   - Click "Voice Send" in sidebar
   - Click microphone button
   - [ ] Browser prompts for microphone permission
   - [ ] After granting, status shows "connected"

3. **Voice Transmission**

   - Speak into phone microphone
   - [ ] Waveform visualization shows activity
   - [ ] No errors in console

4. **Voice Reception**

   - On another device, open Voice Receive panel
   - Connect to the stream
   - [ ] Audio is heard from the sending device

5. **Latency Check**
   - Clap or make distinctive sound
   - [ ] Delay is less than 1 second

## Confirmation

- [ ] All 5 checks pass

🎯 **MILESTONE ACHIEVED**: Mobile can send voice!
```

### Phase 5: Manual Verification

```markdown
# ✅ Manual Verification - Phase 5: Production Hardening

## Verification Steps

1. **Check timezone**

   - Run: `docker exec homeassistant date`
   - [ ] Shows correct local time

2. **Check log rotation**

   - Run: `docker inspect voice-streaming --format='{{.HostConfig.LogConfig}}'`
   - [ ] Shows max-size and max-file settings

3. **Check restart policy**

   - Run: `docker inspect voice-streaming --format='{{.HostConfig.RestartPolicy.Name}}'`
   - [ ] Shows "unless-stopped"

4. **Check port 8081**

   - Run: `docker compose ps`
   - [ ] Shows 8081 in ports column for voice_streaming

5. **Test container restart**
   - Run: `docker compose restart voice_streaming`
   - [ ] Container comes back up within 30 seconds
   - Run: `curl http://localhost:8080/health`
   - [ ] Returns healthy status

## Confirmation

- [ ] All 5 checks pass
```

### Phase 6: Manual Verification

```markdown
# ✅ Manual Verification - Phase 6: HA Media Player Integration

## Verification Steps

**⚠️ Requires a configured media_player in Home Assistant**

### Pre-requisites

- Media player entity ID: ******\_\_\_******
- Voice sending working from Phase 4

### Tests

1. **Audio Stream Endpoint**

   - Run: `curl http://localhost:8081/stream/status`
   - [ ] Returns JSON with streaming status

2. **HA Service Registration**

   - Open Home Assistant
   - Go to Developer Tools → Services
   - Search for "voice_streaming"
   - [ ] `voice_streaming.play_on_speaker` appears
   - [ ] `voice_streaming.stop_on_speaker` appears

3. **Play on Speaker Test**

   - Start sending voice from mobile
   - In HA Services, call `voice_streaming.play_on_speaker`
   - Select your media_player entity
   - Click "Call Service"
   - [ ] Audio plays on the speaker!

4. **Stop on Speaker Test**
   - Call `voice_streaming.stop_on_speaker`
   - [ ] Audio stops on the speaker

## Confirmation

- [ ] All 4 checks pass

🎯 **MILESTONE ACHIEVED**: Audio plays on real speaker!
```

### Phase 7: Manual Verification

```markdown
# ✅ Manual Verification - Phase 7: Reliability & Monitoring

## Verification Steps

1. **Metrics Endpoint**

   - Run: `curl http://localhost:8080/metrics`
   - [ ] Returns JSON with uptime, connections, streams

2. **Reconnection Test**

   - Start sending voice from mobile
   - Turn on Airplane mode for 3 seconds
   - Turn off Airplane mode
   - [ ] Connection recovers automatically within 30 seconds

3. **Graceful Shutdown**

   - Start voice sending
   - Run: `docker compose stop voice_streaming`
   - Check mobile browser console
   - [ ] Connection closed cleanly (no crash errors)

4. **Restart Recovery**
   - Run: `docker compose start voice_streaming`
   - Reconnect on mobile
   - [ ] Reconnection successful

## Confirmation

- [ ] All 4 checks pass
```

### Phase 8: Manual Verification

```markdown
# ✅ Manual Verification - Phase 8: Final Testing & Deployment

## Final System Test

### Environment

- Server IP: ******\_\_\_******
- Test Date: ******\_\_\_******

### End-to-End Test

1. **Full Workflow Test**

   - [ ] Start containers with `./start_production.sh` (or docker compose)
   - [ ] Access HA from mobile via HTTPS
   - [ ] Send voice from mobile
   - [ ] Receive on browser (another device)
   - [ ] Play on HA speaker

2. **Stability Test**

   - [ ] System ran for at least 30 minutes without issues
   - [ ] No memory leaks (check with `docker stats`)
   - [ ] No error accumulation in logs

3. **Offline Test**

   - Disconnect server from internet
   - [ ] Voice streaming still works

4. **Documentation Check**
   - [ ] `start_production.sh` exists and is executable
   - [ ] All verification scripts pass

## Final Confirmation

- [ ] **SYSTEM IS PRODUCTION READY**

🎯 **MILESTONE ACHIEVED**: Production deployment complete!
```

---

## 🔄 State File Update Template

After each phase completes, update the state file:

```json
{
  "implementation": {
    "phases": [
      { "id": 1, "name": "Bug Fixes", "status": "complete" },
      { "id": 2, "name": "LAN Config", "status": "complete" },
      ...
    ]
  },
  "current_phase": {
    "phase": [NEXT_PHASE_NUMBER],
    "phase_name": "[NEXT_PHASE_NAME]",
    "progress_percentage": 0
  },
  "recovery_info": {
    "can_resume": true,
    "next_action": "Start Phase [X] implementation"
  }
}
```

---

## 🚨 Error Recovery Protocol

If something goes wrong:

### Verification Script Fails

1. Read the error message carefully
2. Check the specific file/line mentioned
3. Fix the issue
4. Re-run the verification script
5. Repeat until passing

### Containers Won't Start

```bash
# Check logs
docker compose logs --tail=100

# Rebuild if needed
docker compose down
docker compose build --no-cache
docker compose up -d
```

### WebRTC Connection Fails

1. Check browser console for errors
2. Verify WebSocket endpoint is accessible
3. Check ICE servers are empty (for LAN mode)
4. Verify SSL certificate is trusted

### Audio Not Playing on Speaker

1. Verify audio stream endpoint responds
2. Check media_player entity is valid
3. Verify speaker is connected to HA
4. Check volume is not muted

---

## 📊 Progress Tracking

Use this section to track implementation progress:

| Phase | Automated | Manual | Notes     |
| ----- | --------- | ------ | --------- |
| 1     | ⬜        | ⬜     |           |
| 2     | ⬜        | ⬜     |           |
| 3     | ⬜        | ⬜     |           |
| 4     | ⬜        | ⬜     | MILESTONE |
| 5     | ⬜        | ⬜     |           |
| 6     | ⬜        | ⬜     | MILESTONE |
| 7     | ⬜        | ⬜     |           |
| 8     | ⬜        | ⬜     | MILESTONE |

Legend: ⬜ Pending | ✅ Passed | ❌ Failed

---

## 🎯 Session End Protocol

Before ending any session:

1. **Update the state file** with current progress
2. **Commit any code changes** if using version control
3. **Document any issues** found in the context file
4. **Note the next action** in `recovery_info.next_action`

---

_This document enables seamless handoff between AI sessions for continuous development._
