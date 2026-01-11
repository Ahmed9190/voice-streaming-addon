#!/bin/bash
# Phase 2 Verification Script
# LAN-Only Configuration

set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        PHASE 2 VERIFICATION: LAN-Only Configuration           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

PASS=0
FAIL=0
WARN=0

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

# AC2.1: No Google STUN in backend
echo ""
echo "━━━ AC2.1: Checking for Google STUN in backend ━━━"
if grep -rq "stun.*google" webrtc_backend/*.py 2>/dev/null; then
    check 1 "Google STUN servers found in backend Python files"
else
    check 0 "No Google STUN servers in backend"
fi

# AC2.2: No Google STUN in frontend
echo ""
echo "━━━ AC2.2: Checking for Google STUN in frontend ━━━"
if grep -q "stun.*google" config/www/voice-sending-card.js config/www/voice-receiving-card.js 2>/dev/null; then
    check 1 "Google STUN servers found in frontend JS files"
else
    check 0 "No Google STUN servers in frontend"
fi

# AC2.3: No stunprotocol.org
echo ""
echo "━━━ AC2.3: Checking for stunprotocol.org ━━━"
if grep -rq "stunprotocol" . --include="*.py" --include="*.js" 2>/dev/null; then
    check 1 "stunprotocol.org references found"
else
    check 0 "No stunprotocol.org references"
fi

# AC2.4 & AC2.5: Manual tests required
echo ""
echo "━━━ AC2.4 & AC2.5: Manual Tests Required ━━━"
warn "AC2.4: Manually test voice send/receive on localhost"
warn "AC2.5: Disconnect internet and verify voice still works"

# Summary
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                        PHASE 2 SUMMARY                         ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║  ✅ Passed: $PASS                                               "
echo "║  ❌ Failed: $FAIL                                               "
echo "║  ⚠️  Warnings: $WARN                                            "
echo "╚═══════════════════════════════════════════════════════════════╝"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo "📝 NOTE: Complete manual tests AC2.4 and AC2.5 before proceeding"
    echo ""
    echo "Manual Test Checklist:"
    echo "[ ] AC2.4: Voice works on localhost (same machine)"
    echo "[ ] AC2.5: Voice works with internet disconnected"
    echo ""
    echo "If manual tests pass → Ready for Phase 3"
    exit 0
else
    echo ""
    echo "🚫 PHASE 2 INCOMPLETE - Fix failures before proceeding"
    exit 1
fi
