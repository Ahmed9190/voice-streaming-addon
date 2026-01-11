#!/bin/bash
# Phase 8 Verification Script
# Final Testing & Deployment

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        PHASE 8 VERIFICATION: Final Testing & Deployment        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')
DATE=$(date '+%Y-%m-%d %H:%M:%S')

PASS=0
FAIL=0
WARN=0

check() {
    if [ $1 -eq 0 ]; then
        echo "✅ PASS: $2"
        ((PASS++))
    else
        echo "❌ FAIL: $2"
        ((FAIL++))
    fi
}

warn() {
    echo "⚠️  WARN: $1"
    ((WARN++))
}

echo "Server IP: $SERVER_IP"
echo "Test Date: $DATE"
echo ""

# AC8.1: All containers running
echo ""
echo "━━━ AC8.1: Checking all containers running ━━━"
running_count=$(docker compose ps --format json 2>/dev/null | grep -c "running" || echo "0")
if [ "$running_count" -ge 3 ]; then
    check 0 "All $running_count containers running"
else
    check 1 "Only $running_count containers running (expected 3+)"
fi

# AC8.2: Health endpoint
echo ""
echo "━━━ AC8.2: Checking backend health ━━━"
health=$(curl -s http://localhost:8080/health 2>/dev/null || echo "")
if echo "$health" | grep -q "healthy"; then
    check 0 "Backend health check passed"
else
    check 1 "Backend health check failed"
fi

# AC8.3: Audio stream endpoint
echo ""
echo "━━━ AC8.3: Checking audio stream endpoint ━━━"
stream_status=$(curl -s http://localhost:8081/stream/status 2>/dev/null || echo "")
if echo "$stream_status" | grep -q "streaming"; then
    check 0 "Audio stream endpoint responding"
else
    check 1 "Audio stream endpoint not responding"
fi

# AC8.4: HTTPS accessible
echo ""
echo "━━━ AC8.4: Checking HTTPS access ━━━"
https_code=$(curl -sk "https://$SERVER_IP" -o /dev/null -w "%{http_code}" 2>/dev/null || echo "000")
if [ "$https_code" = "200" ] || [ "$https_code" = "302" ]; then
    check 0 "HTTPS accessible (HTTP $https_code)"
else
    check 1 "HTTPS not accessible (HTTP $https_code)"
fi

# AC8.5: Start script exists
echo ""
echo "━━━ AC8.5: Checking start_production.sh ━━━"
if [ -x "start_production.sh" ]; then
    check 0 "start_production.sh exists and is executable"
else
    warn "start_production.sh not found or not executable"
fi

# AC8.6: No errors in logs (last 100 lines)
echo ""
echo "━━━ AC8.6: Checking for errors in recent logs ━━━"
error_count=$(docker compose logs --tail=100 2>&1 | grep -ci "error" || echo "0")
if [ "$error_count" -eq 0 ]; then
    check 0 "No errors in last 100 log lines"
else
    warn "$error_count error messages in recent logs - review them"
fi

# Final verification section
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    FINAL MANUAL VERIFICATION                   ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Complete the following end-to-end tests:"
echo ""
echo "[ ] Test 1: Mobile Voice Sending"
echo "    • Open https://$SERVER_IP on mobile"
echo "    • Navigate to Voice Send panel"
echo "    • Grant microphone, speak"
echo "    • Verify waveform shows activity"
echo ""
echo "[ ] Test 2: Browser Reception"
echo "    • Open Voice Receive on another device"
echo "    • Connect to the stream"
echo "    • Verify audio is heard"
echo ""
echo "[ ] Test 3: Speaker Playback"
echo "    • In HA, call voice_streaming.play_on_speaker"
echo "    • Select a media_player entity"
echo "    • Verify audio plays on real speaker"
echo ""
echo "[ ] Test 4: Stability (optional)"
echo "    • Keep system running for 1 hour"
echo "    • Verify no crashes or disconnections"
echo ""
echo "[ ] Test 5: Offline Operation"
echo "    • Disconnect internet from server"
echo "    • Verify voice streaming still works"
echo ""

# Collect manual test results
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "Test 1 - Mobile voice sending works? (y/n): " t1
read -p "Test 2 - Browser reception works? (y/n): " t2
read -p "Test 3 - Speaker playback works? (y/n): " t3
read -p "Test 4 - Stability (1hr) - skip or pass? (y/n/s): " t4
read -p "Test 5 - Offline operation works? (y/n): " t5
echo ""

# Calculate results
manual_pass=0
manual_fail=0

for result in $t1 $t2 $t3 $t5; do
    if [ "$result" = "y" ]; then
        ((manual_pass++))
    else
        ((manual_fail++))
    fi
done

# Summary
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                   FINAL VERIFICATION SUMMARY                   ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║  Automated Tests:                                              ║"
echo "║    ✅ Passed: $PASS                                             "
echo "║    ❌ Failed: $FAIL                                             "
echo "║    ⚠️  Warnings: $WARN                                          "
echo "║                                                                ║"
echo "║  Manual Tests:                                                 ║"
echo "║    ✅ Passed: $manual_pass / 4                                  "
echo "║    ❌ Failed: $manual_fail / 4                                  "
echo "╚═══════════════════════════════════════════════════════════════╝"

total_fail=$((FAIL + manual_fail))

if [ $total_fail -eq 0 ]; then
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                                                               ║"
    echo "║   🎉🎉🎉 PRODUCTION DEPLOYMENT COMPLETE! 🎉🎉🎉              ║"
    echo "║                                                               ║"
    echo "║   All phases passed. System is production-ready.             ║"
    echo "║                                                               ║"
    echo "║   Access URL: https://$SERVER_IP                             ║"
    echo "║                                                               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Verified on: $DATE"
    echo ""
    
    # Generate final report
    cat > .handover/DEPLOYMENT-COMPLETE.md << EOF
# 🎉 Deployment Complete

**Date**: $DATE
**Server IP**: $SERVER_IP
**Status**: ✅ Production Ready

## Verification Results

### Automated Tests
- Containers running: ✅
- Backend health: ✅
- Audio stream: ✅
- HTTPS access: ✅

### Manual Tests
- Mobile voice sending: ✅
- Browser reception: ✅
- Speaker playback: ✅
- Offline operation: ✅

## Access Points

| Service | URL |
|---------|-----|
| Home Assistant | https://$SERVER_IP |
| Backend Health | http://$SERVER_IP:8080/health |
| Audio Stream | http://$SERVER_IP:8081/stream.mp3 |

## Commands

\`\`\`bash
# Start
./start_production.sh

# Stop
docker compose down

# Logs
docker compose logs -f

# Status
docker compose ps
\`\`\`

---
*Verified by Phase 8 verification script*
EOF
    
    echo "📄 Deployment report saved to: .handover/DEPLOYMENT-COMPLETE.md"
    exit 0
else
    echo ""
    echo "🚫 DEPLOYMENT INCOMPLETE"
    echo "$total_fail test(s) failed. Fix issues before production use."
    exit 1
fi
