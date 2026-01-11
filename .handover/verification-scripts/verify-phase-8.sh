#!/bin/bash
# Phase 8 Verification Script
# Code Review & Optimization Loop

PASS=0
FAIL=0

check() {
    if [ $1 -eq 0 ]; then
        echo "✅ PASS: $2"
    else
        echo "❌ FAIL: $2"
        FAIL=$((FAIL+1))
    fi
}

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      PHASE 8 VERIFICATION: Code Review & Optimization         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

echo "━━━ AC8.1: Code Quality & Safety (Clean Code) ━━━"

# Check for bare excepts in Python backend
echo "Checking for bare excepts in backend code..."
if grep -r "except:" webrtc_backend/webrtc_server_relay.py; then
    check 1 "Bare except clauses found in webrtc_server_relay.py (Risky!)"
else
    check 0 "No bare except clauses found in webrtc_server_relay.py"
fi

if grep -r "except:" webrtc_backend/audio_stream_server.py; then
    check 1 "Bare except clauses found in audio_stream_server.py (Risky!)"
else
    check 0 "No bare except clauses found in audio_stream_server.py"
fi

# Check for Python syntax errors
echo "Checking Python syntax..."
export PYTHONPYCACHEPREFIX=$(mktemp -d)
if python3 -m py_compile webrtc_backend/*.py; then
    check 0 "Backend Python syntax is valid"
else
    check 1 "Backend Python syntax errors found"
fi
rm -rf "$PYTHONPYCACHEPREFIX"

echo ""
echo "━━━ AC8.2: Frontend DRY & Maintainability ━━━"

# Check for Constants extraction in JS
echo "Checking for extracted constants in Frontend..."
HEADER_SEND=$(head -n 25 config/www/voice-sending-card.js | grep "const CONSTANTS =")
if [ -n "$HEADER_SEND" ]; then
    check 0 "CONSTANTS object defined in voice-sending-card.js"
else
    check 1 "CONSTANTS object missing in voice-sending-card.js"
fi

HEADER_RECV=$(head -n 25 config/www/voice-receiving-card.js | grep "const CONSTANTS =")
if [ -n "$HEADER_RECV" ]; then
    check 0 "CONSTANTS object defined in voice-receiving-card.js"
else
    check 1 "CONSTANTS object missing in voice-receiving-card.js"
fi

# Check usage
if grep -q "CONSTANTS.RECONNECT" config/www/voice-sending-card.js; then
    check 0 "voice-sending-card.js uses CONSTANTS"
else
    check 1 "voice-sending-card.js still using magic numbers (or not using CONSTANTS)"
fi

if grep -q "CONSTANTS.TIMERS" config/www/voice-receiving-card.js; then
    check 0 "voice-receiving-card.js uses CONSTANTS"
else
    check 1 "voice-receiving-card.js still using magic numbers (or not using CONSTANTS)"
fi

echo ""
echo "━━━ AC8.4: Documentation of Weaknesses ━━━"
if [ -f ".handover/WEAKNESSES.md" ]; then
    check 0 "WEAKNESSES.md exists"
else
    check 1 "WEAKNESSES.md is missing"
fi

# Check config extraction
echo "Checking for Hardcoded Config extraction..."
if grep -q "STREAM_URL =" config/custom_components/voice_streaming/__init__.py; then
    check 0 "STREAM_URL extracted to constant in __init__.py"
else
    check 1 "STREAM_URL is still hardcoded inline in __init__.py"
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "🎉 PHASE 8 COMPLETE - Codebase is clean, optimized, and documented!"
    exit 0
else
    echo "🚫 PHASE 8 FAILED - $FAIL checks failed"
    exit 1
fi
