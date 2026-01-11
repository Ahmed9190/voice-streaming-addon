#!/bin/bash
# Phase 6 Verification Script
# HA Media Player Integration

HOST_IP="10.132.148.130"

check() {
    if [ $1 -eq 0 ]; then
        echo "✅ PASS: $2"
    else
        echo "❌ FAIL: $2"
        exit 1
    fi
}

echo "━━━ AC6.1: Checking Audio Stream Server port 8081 ━━━"
nc -z -w 2 127.0.0.1 8081
check $? "Port 8081 is listening"

echo "━━━ AC6.2: Checking Audio Health Endpoint ━━━"
curl -k -s "http://127.0.0.1:8081/stream/status" | grep "active_streams"
check $? "Health endpoint /stream/status is responsive"

echo "━━━ AC6.3: Checking Nginx Proxy for Audio ━━━"
curl -k -s -o /dev/null -w "%{http_code}" "https://127.0.0.1/api/voice-audio/stream/status" | grep "200"
check $? "Nginx proxy /api/voice-audio/ works"

echo "━━━ AC6.4: Checking HA Service Registration ━━━"
# We check config for the service file
if [ -f "config/custom_components/voice_streaming/services.yaml" ]; then
    grep "play_on_speaker" config/custom_components/voice_streaming/services.yaml
    check $? "Service 'play_on_speaker' defined in services.yaml"
else
    check 1 "services.yaml missing"
fi

echo ""
echo "🎉 PHASE 6 AUTOMATED CHECKS PASSED"
