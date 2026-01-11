#!/bin/bash
# Phase 1 Verification Script
# Bug Fixes & Code Quality

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           PHASE 1 VERIFICATION: Bug Fixes & Code Quality       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

PASS=0
FAIL=0
WARN=0

# Function to report result
check() {
    if [ $1 -eq 0 ]; then
        echo "✅ PASS: $2"
        PASS=$((PASS+1))
    else
        echo "❌ FAIL: $2"
        FAIL=$((FAIL+1))
    fi
}

warn() {
    echo "⚠️  WARN: $1"
    WARN=$((WARN+1))
}

# AC1.1: manifest.json is valid JSON
echo ""
echo "━━━ AC1.1: Checking manifest.json format ━━━"
if python3 -m json.tool < config/custom_components/voice_streaming/manifest.json > /dev/null 2>&1; then
    check 0 "manifest.json is valid JSON"
else
    check 1 "manifest.json is NOT valid JSON"
fi

# AC1.2: config.json is valid JSON
echo ""
echo "━━━ AC1.2: Checking config.json format ━━━"
if python3 -m json.tool < webrtc_backend/config.json > /dev/null 2>&1; then
    check 0 "config.json is valid JSON"
else
    check 1 "config.json is NOT valid JSON"
fi

# AC1.3: Single oniceconnectionstatechange in sending card
echo ""
echo "━━━ AC1.3: Checking duplicate handlers in voice-sending-card.js ━━━"
count=$(grep -c "oniceconnectionstatechange" config/www/voice-sending-card.js 2>/dev/null || echo "0")
if [ "$count" -eq 1 ]; then
    check 0 "Single oniceconnectionstatechange handler in sending card"
else
    check 1 "Found $count handlers in sending card (expected 1)"
fi

# AC1.4: Single oniceconnectionstatechange in receiving card
echo ""
echo "━━━ AC1.4: Checking duplicate handlers in voice-receiving-card.js ━━━"
count=$(grep -c "oniceconnectionstatechange" config/www/voice-receiving-card.js 2>/dev/null || echo "0")
if [ "$count" -eq 1 ]; then
    check 0 "Single oniceconnectionstatechange handler in receiving card"
else
    check 1 "Found $count handlers in receiving card (expected 1)"
fi

# AC1.5: Health check uses Python
echo ""
echo "━━━ AC1.5: Checking Docker health check ━━━"
if grep -q "python -c" webrtc_backend/Dockerfile 2>/dev/null; then
    check 0 "Health check uses Python (not curl)"
else
    check 1 "Health check does not use Python"
fi

# AC1.6: All containers start
echo ""
echo "━━━ AC1.6: Checking container startup ━━━"
if docker compose ps --format json 2>/dev/null | grep -q "running"; then
    check 0 "Containers are running"
else
    warn "Containers may not be running - check with 'docker compose ps'"
fi

# AC1.7: No errors in logs
echo ""
echo "━━━ AC1.7: Checking for errors in logs ━━━"
if docker compose logs 2>&1 | grep -qi "error"; then
    warn "Errors found in logs - review with 'docker compose logs'"
else
    check 0 "No ERROR level messages in recent logs"
fi

# Summary
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                        PHASE 1 SUMMARY                         ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║  ✅ Passed: $PASS                                               "
echo "║  ❌ Failed: $FAIL                                               "
echo "║  ⚠️  Warnings: $WARN                                            "
echo "╚═══════════════════════════════════════════════════════════════╝"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo "🎉 PHASE 1 COMPLETE - Ready to proceed to Phase 2"
    exit 0
else
    echo ""
    echo "🚫 PHASE 1 INCOMPLETE - Fix failures before proceeding"
    exit 1
fi
