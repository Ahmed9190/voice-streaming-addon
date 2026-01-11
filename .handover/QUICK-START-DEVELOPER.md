# 🚀 Quick Start: Development Workflow

## For Senior Developer - Phase-by-Phase Implementation

**Total Phases**: 8  
**Total Effort**: ~7 hours  
**Documents**: `.handover/PROJECT-SPECS.md` (full specs)

---

## Phase Dependency Chain

```
Phase 1 ──► Phase 2 ──► Phase 3 ──► Phase 4 ──► Phase 5 ──► Phase 6 ──► Phase 7 ──► Phase 8
   │           │           │           │           │           │           │           │
   │           │           │           │           │           │           │           │
 Bugs      LAN Config    SSL Cert   Cross-Dev   Hardening   HA Media   Monitoring   Final
                                       │                        │                     │
                                       │                        │                     │
                                 MILESTONE 1              MILESTONE 2            MILESTONE 3
                               Mobile sends              Plays on              Production
                                  voice                  speaker                 ready
```

---

## Implementation Workflow

For **each phase**:

```bash
1. Read phase specification in PROJECT-SPECS.md
2. Implement all tasks listed
3. Run verification script:
   ./.handover/verification-scripts/verify-phase-X.sh
4. Fix any failures
5. Confirm all acceptance criteria pass
6. Proceed to next phase
```

---

## Verification Scripts

| Script              | Phase | Description                 |
| ------------------- | ----- | --------------------------- |
| `verify-phase-1.sh` | 1     | Bug fixes & code quality    |
| `verify-phase-2.sh` | 2     | LAN-only configuration      |
| `verify-phase-3.sh` | 3     | SSL certificates for LAN    |
| `verify-phase-4.sh` | 4     | Cross-device verification   |
| `verify-phase-5.sh` | 5     | Production hardening        |
| `verify-phase-6.sh` | 6     | HA Media Player integration |
| `verify-phase-7.sh` | 7     | Reliability & monitoring    |
| `verify-phase-8.sh` | 8     | Final testing & deployment  |
| `verify-all.sh`     | All   | Master script (runs all)    |

**Run from project root:**

```bash
./.handover/verification-scripts/verify-phase-1.sh
```

---

## Phase Summary

### Phase 1: Bug Fixes & Code Quality (45 min)

**Files to modify:**

- `config/custom_components/voice_streaming/manifest.json` → Fix JSON
- `webrtc_backend/config.json` → Remove comments
- `config/www/voice-sending-card.js` → Remove duplicate handler
- `config/www/voice-receiving-card.js` → Remove duplicate handler
- `webrtc_backend/Dockerfile` → Fix health check

### Phase 2: LAN-Only Configuration (30 min)

**Files to modify:**

- `webrtc_backend/webrtc_server_relay.py` → Empty ICE servers
- `config/www/voice-sending-card.js` → Empty ICE servers
- `config/www/voice-receiving-card.js` → Empty ICE servers

### Phase 3: SSL Certificates for LAN (30 min)

**Files to create:**

- `ssl/generate_lan_cert.sh` → Certificate generation script
- `ssl/MOBILE_TRUST.md` → Mobile trust instructions

### Phase 4: Cross-Device Verification (30 min)

**Manual testing only** - No code changes

### Phase 5: Production Hardening (45 min)

**Files to modify:**

- `docker-compose.yml` → Timezone, logging, ports, restart

### Phase 6: HA Media Player Integration (2 hours)

**Files to create/modify:**

- `webrtc_backend/audio_stream_server.py` → New file
- `webrtc_backend/webrtc_server_relay.py` → Integrate audio server
- `config/custom_components/voice_streaming/__init__.py` → Add services
- `config/custom_components/voice_streaming/services.yaml` → New file
- `nginx.conf` → Add audio stream route

### Phase 7: Reliability & Monitoring (1 hour)

**Files to modify:**

- `config/www/voice-sending-card.js` → Increase reconnect attempts
- `config/www/voice-receiving-card.js` → Increase reconnect attempts
- `webrtc_backend/webrtc_server_relay.py` → Add /metrics endpoint

### Phase 8: Final Testing & Deployment (30 min)

**Files to create:**

- `start_production.sh` → Production start script
- `DEPLOYMENT.md` → Deployment documentation

---

## Key Milestones

| Milestone             | After Phase | Verification                |
| --------------------- | ----------- | --------------------------- |
| 🎯 Mobile sends voice | Phase 4     | Send from phone, hear on PC |
| 🎯 Plays on speaker   | Phase 6     | Audio on Sonos/Google Home  |
| 🎯 Production ready   | Phase 8     | All tests pass, 1hr stable  |

---

## Quick Commands

```bash
# Start services
docker compose up -d

# View logs
docker compose logs -f

# Check health
curl http://localhost:8080/health

# Run specific phase verification
./.handover/verification-scripts/verify-phase-1.sh

# Run all verifications
./.handover/verification-scripts/verify-all.sh
```

---

## Definition of Done

A phase is **DONE** when:

- ✅ All tasks completed
- ✅ All acceptance criteria pass
- ✅ Verification script runs without failures
- ✅ No new errors in logs
- ✅ Changes committed to version control
- ✅ Next phase can safely begin

---

_Ready for implementation. Start with Phase 1._
