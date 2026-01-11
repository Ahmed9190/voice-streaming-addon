#!/bin/bash
# Phase 4 Verification Script
# Cross-Device Verification

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        PHASE 4 VERIFICATION: Cross-Device Communication        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

SERVER_IP=$(hostname -I | awk '{print $1}')

echo "This phase requires MANUAL TESTING with a mobile device."
echo ""
echo "Server IP: $SERVER_IP"
echo "URL: https://$SERVER_IP"
echo ""

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    CROSS-DEVICE TEST CHECKLIST                 ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Prerequisites:"
echo "  • Mobile device connected to same WiFi network"
echo "  • Server running (docker compose up -d)"
echo "  • Certificate trusted on mobile (optional but recommended)"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "TEST STEPS:"
echo ""
echo "[ ] AC4.1: Access from Mobile"
echo "    1. Open browser on mobile"
echo "    2. Navigate to: https://$SERVER_IP"
echo "    3. Accept certificate warning if shown"
echo "    4. ✓ Home Assistant page loads"
echo ""
echo "[ ] AC4.2: Microphone Permission"
echo "    1. Log into Home Assistant"
echo "    2. Click 'Voice Send' in sidebar"
echo "    3. Click microphone button"
echo "    4. ✓ Browser prompts for microphone access"
echo ""
echo "[ ] AC4.3: Permission Granted"
echo "    1. Grant microphone permission"
echo "    2. ✓ Status shows 'connected' (green)"
echo ""
echo "[ ] AC4.4: Voice Transmission"
echo "    1. Speak into phone microphone"
echo "    2. ✓ Waveform visualization shows activity"
echo ""
echo "[ ] AC4.5: Voice Reception"
echo "    1. Open another device (or localhost browser)"
echo "    2. Go to 'Voice Receive' panel"
echo "    3. Select the stream and connect"
echo "    4. ✓ Audio plays through receiving device"
echo ""
echo "[ ] AC4.6: Latency Check"
echo "    1. Make a distinctive sound (clap)"
echo "    2. Listen for delay on receiving end"
echo "    3. ✓ Delay is less than 1 second"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "RESULT:"
echo ""
echo "If ALL checks pass:"
echo "  🎉 PHASE 4 COMPLETE - Mobile voice streaming works!"
echo "  → Proceed to Phase 5"
echo ""
echo "If ANY check fails:"
echo "  🚫 Debug the issue before proceeding"
echo "  • Check browser console for errors"
echo "  • Check docker compose logs voice_streaming"
echo "  • Verify WebSocket connection in Network tab"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Enter test results below:"
echo ""
read -p "AC4.1 - Mobile accesses HTTPS? (y/n): " ac41
read -p "AC4.2 - Microphone prompt appears? (y/n): " ac42
read -p "AC4.3 - Permission granted, connected? (y/n): " ac43
read -p "AC4.4 - Waveform shows activity? (y/n): " ac44
read -p "AC4.5 - Audio received on other device? (y/n): " ac45
read -p "AC4.6 - Latency acceptable (< 1 sec)? (y/n): " ac46
echo ""

PASS=0
FAIL=0

for result in $ac41 $ac42 $ac43 $ac44 $ac45 $ac46; do
    if [ "$result" = "y" ] || [ "$result" = "Y" ]; then
        ((PASS++))
    else
        ((FAIL++))
    fi
done

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                        PHASE 4 SUMMARY                         ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║  ✅ Passed: $PASS / 6                                           "
echo "║  ❌ Failed: $FAIL / 6                                           "
echo "╚═══════════════════════════════════════════════════════════════╝"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo "🎉 PHASE 4 COMPLETE - Mobile voice streaming verified!"
    echo "→ Proceed to Phase 5: Production Hardening"
    exit 0
else
    echo ""
    echo "🚫 PHASE 4 INCOMPLETE - $FAIL test(s) failed"
    echo "Debug issues before proceeding"
    exit 1
fi
