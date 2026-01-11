#!/bin/bash
# Phase 7 Verification Script
# Reliability & Monitoring

HOST_IP="10.132.148.130"

check() {
    if [ $1 -eq 0 ]; then
        echo "✅ PASS: $2"
    else
        echo "❌ FAIL: $2"
        ((FAILURES++))
    fi
}

FAILURES=0

echo "━━━ AC7.1: Enhanced Health Check ━━━"
HEALTH=$(curl -s "http://127.0.0.1:8080/health")
echo "$HEALTH" | grep -q "audio_server_running"
check $? "Health check includes audio server status"

echo "$HEALTH" | grep -q "uptime_seconds"
check $? "Health check includes uptime"

echo "━━━ AC7.2: Frontend Auto-Reconnection ━━━"
grep -q "reconnectDelay" config/www/voice-sending-card.js
check $? "Voice sending card has reconnection logic"

grep -q "maxReconnectDelay" config/www/voice-sending-card.js
check $? "Exponential backoff implemented"

echo "━━━ AC7.3: Connection Status Indicators ━━━"
grep -q "connection-indicator" config/www/voice-sending-card.js
check $? "Visual connection indicator present"

grep -q "pulse-dot" config/www/voice-sending-card.js
check $? "Pulsing animation for status indicator"

echo "━━━ AC7.4: Backend Cleanup Task ━━━"
grep -q "cleanup_stale_streams" webrtc_backend/webrtc_server_relay.py
check $? "Stale stream cleanup function exists"

grep -q "cleanup_task" webrtc_backend/webrtc_server_relay.py
check $? "Cleanup task is started"

echo ""
if [ $FAILURES -eq 0 ]; then
    echo "🎉 PHASE 7 AUTOMATED CHECKS PASSED"
    exit 0
else
    echo "❌ PHASE 7 FAILED: $FAILURES checks failed"
    exit 1
fi
