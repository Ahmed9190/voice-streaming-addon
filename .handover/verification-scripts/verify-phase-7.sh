#!/bin/bash
# Phase 7 Verification Script
# Reliability & Monitoring

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         PHASE 7 VERIFICATION: Reliability & Monitoring         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

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

# AC7.1: Reconnect attempts increased
echo ""
echo "━━━ AC7.1: Checking maxReconnectAttempts value ━━━"
sending_attempts=$(grep -o "maxReconnectAttempts.*=.*[0-9]*" config/www/voice-sending-card.js 2>/dev/null | grep -o "[0-9]*" | tail -1 || echo "0")
receiving_attempts=$(grep -o "maxReconnectAttempts.*=.*[0-9]*" config/www/voice-receiving-card.js 2>/dev/null | grep -o "[0-9]*" | tail -1 || echo "0")

if [ "$sending_attempts" -ge 10 ] && [ "$receiving_attempts" -ge 10 ]; then
    check 0 "Reconnect attempts set to 10+ (sending: $sending_attempts, receiving: $receiving_attempts)"
else
    check 1 "Reconnect attempts too low (sending: $sending_attempts, receiving: $receiving_attempts) - should be 10+"
fi

# AC7.2: Metrics endpoint works
echo ""
echo "━━━ AC7.2: Checking /metrics endpoint ━━━"
metrics_response=$(curl -s http://localhost:8080/metrics 2>/dev/null || echo "")
if echo "$metrics_response" | grep -q "uptime\|connections\|streams"; then
    check 0 "/metrics endpoint returns data"
    echo "    Response: $metrics_response"
else
    check 1 "/metrics endpoint not working or not returning expected data"
fi

# AC7.3: Graceful shutdown handler
echo ""
echo "━━━ AC7.3: Checking graceful shutdown handler ━━━"
if grep -q "signal\|SIGTERM\|SIGINT\|shutdown" webrtc_backend/webrtc_server_relay.py 2>/dev/null; then
    check 0 "Signal handler found in webrtc_server_relay.py"
else
    check 1 "No signal handler for graceful shutdown"
fi

# AC7.4: Exponential backoff (check for backoff-related code)
echo ""
echo "━━━ AC7.4: Checking reconnection backoff logic ━━━"
if grep -q "reconnectDelay\|backoff\|Math.min\|Math.pow" config/www/voice-sending-card.js 2>/dev/null; then
    check 0 "Reconnection delay/backoff logic found"
else
    warn "No explicit backoff logic found - may use fixed delay"
fi

# AC7.5: Health broadcast (optional)
echo ""
echo "━━━ AC7.5: Checking stream health broadcast ━━━"
if grep -q "broadcast_health\|health_broadcast" webrtc_backend/webrtc_server_relay.py 2>/dev/null; then
    check 0 "Stream health broadcast implemented"
else
    warn "Stream health broadcast not implemented (optional)"
fi

# Manual recovery test
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📢 MANUAL TEST REQUIRED: Network Recovery"
echo ""
echo "Test Steps:"
echo "1. Start voice sending from mobile"
echo "2. Verify it's working"
echo "3. Toggle airplane mode ON briefly (2-3 seconds)"
echo "4. Toggle airplane mode OFF"
echo "5. Wait up to 30 seconds"
echo "6. Verify connection automatically recovers"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Summary
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                        PHASE 7 SUMMARY                         ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║  ✅ Passed: $PASS                                               "
echo "║  ❌ Failed: $FAIL                                               "
echo "║  ⚠️  Warnings: $WARN                                            "
echo "╚═══════════════════════════════════════════════════════════════╝"

if [ $FAIL -eq 0 ]; then
    echo ""
    read -p "Did network recovery test pass? (y/n): " recovery_test
    
    if [ "$recovery_test" = "y" ]; then
        echo ""
        echo "🎉 PHASE 7 COMPLETE - Reliability & Monitoring implemented"
        echo "→ Proceed to Phase 8: Final Testing & Deployment"
        exit 0
    else
        echo ""
        echo "⚠️  Network recovery needs improvement"
        exit 1
    fi
else
    echo ""
    echo "🚫 PHASE 7 INCOMPLETE - Fix failures before proceeding"
    exit 1
fi
