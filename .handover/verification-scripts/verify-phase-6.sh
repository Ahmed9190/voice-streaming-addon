#!/bin/bash
# Phase 6 Verification Script
# Home Assistant Media Player Integration

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      PHASE 6 VERIFICATION: HA Media Player Integration         ║"
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

# AC6.1: Audio stream server file exists
echo ""
echo "━━━ AC6.1: Checking audio_stream_server.py exists ━━━"
if [ -f "webrtc_backend/audio_stream_server.py" ]; then
    check 0 "audio_stream_server.py exists"
else
    check 1 "audio_stream_server.py NOT found"
fi

# AC6.2: Audio stream endpoint responds
echo ""
echo "━━━ AC6.2: Checking audio stream status endpoint ━━━"
response=$(curl -s http://localhost:8081/stream/status 2>/dev/null || echo "")
if echo "$response" | grep -q "streaming"; then
    check 0 "Audio stream status endpoint responds"
else
    check 1 "Audio stream status endpoint NOT responding"
fi

# AC6.3: HA services.yaml exists
echo ""
echo "━━━ AC6.3: Checking services.yaml ━━━"
if [ -f "config/custom_components/voice_streaming/services.yaml" ]; then
    check 0 "services.yaml exists"
else
    check 1 "services.yaml NOT found"
fi

# AC6.4: Services contain play_on_speaker
echo ""
echo "━━━ AC6.4: Checking play_on_speaker service defined ━━━"
if grep -q "play_on_speaker" config/custom_components/voice_streaming/services.yaml 2>/dev/null; then
    check 0 "play_on_speaker service defined"
else
    check 1 "play_on_speaker service NOT defined"
fi

# AC6.5: HA component updated
echo ""
echo "━━━ AC6.5: Checking HA component has service registration ━━━"
if grep -q "async_register" config/custom_components/voice_streaming/__init__.py 2>/dev/null; then
    check 0 "Service registration found in __init__.py"
else
    check 1 "Service registration NOT found"
fi

# AC6.6: Nginx audio stream route configured
echo ""
echo "━━━ AC6.6: Checking nginx audio stream route ━━━"
if grep -q "audio-stream\|8081" nginx.conf 2>/dev/null; then
    check 0 "Nginx audio stream route configured"
else
    warn "Nginx audio stream route may not be configured"
fi

# Manual test section
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📢 MANUAL TESTS REQUIRED FOR PHASE 6:"
echo ""
echo "To complete Phase 6, you must test the following manually:"
echo ""
echo "[ ] AC6.7: HA service appears in Developer Tools → Services"
echo "    1. Go to Home Assistant"
echo "    2. Developer Tools → Services"
echo "    3. Search for 'voice_streaming.play_on_speaker'"
echo "    4. Should appear in the list"
echo ""
echo "[ ] AC6.8: Audio plays on speaker"
echo "    1. Start sending voice from mobile"
echo "    2. Call service: voice_streaming.play_on_speaker"
echo "    3. Select your media_player entity"
echo "    4. Click 'Call Service'"
echo "    5. Audio should play on the speaker"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Summary
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                        PHASE 6 SUMMARY                         ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║  ✅ Passed (Automated): $PASS                                   "
echo "║  ❌ Failed: $FAIL                                               "
echo "║  ⚠️  Warnings: $WARN                                            "
echo "╚═══════════════════════════════════════════════════════════════╝"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo "Automated checks passed."
    echo ""
    read -p "AC6.7 - Service appears in HA? (y/n): " ac67
    read -p "AC6.8 - Audio plays on speaker? (y/n): " ac68
    
    if [ "$ac67" = "y" ] && [ "$ac68" = "y" ]; then
        echo ""
        echo "🎉 PHASE 6 COMPLETE - HA Media Player Integration working!"
        echo "🔊 MILESTONE: Audio plays on real speaker!"
        echo "→ Proceed to Phase 7: Reliability & Monitoring"
        exit 0
    else
        echo ""
        echo "🚫 PHASE 6 INCOMPLETE - Manual tests failed"
        exit 1
    fi
else
    echo ""
    echo "🚫 PHASE 6 INCOMPLETE - Fix automated failures first"
    exit 1
fi
