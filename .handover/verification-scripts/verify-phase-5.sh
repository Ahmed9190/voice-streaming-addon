#!/bin/bash
# Phase 5 Verification Script
# Production Hardening

# don't use set -e

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║          PHASE 5 VERIFICATION: Production Hardening            ║"
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

# AC5.1: Timezone is correct
echo ""
echo "━━━ AC5.1: Checking timezone configuration ━━━"
if grep -q "TZ=" docker-compose.yml; then
    check 0 "Timezone configured"
else
    check 1 "Timezone NOT configured"
fi

# AC5.2: Log rotation configured
echo ""
echo "━━━ AC5.2: Checking log rotation ━━━"
if grep -q "max-size" docker-compose.yml && grep -q "max-file" docker-compose.yml; then
    check 0 "Log rotation configured in docker-compose.yml"
else
    check 1 "Log rotation NOT configured"
fi

# AC5.3: No USB device errors
echo ""
echo "━━━ AC5.3: Checking for USB device mapping ━━━"
if grep -q "^[^#]*devices:" docker-compose.yml && grep -q "/dev/ttyUSB" docker-compose.yml; then
    warn "USB device mapping active - may cause errors if device not present"
else
    check 0 "No active USB device mapping (or commented out)"
fi

# AC5.4: Restart policy set
echo ""
echo "━━━ AC5.4: Checking restart policies ━━━"
restart_count=$(grep -c "restart:" docker-compose.yml 2>/dev/null || echo "0")
if [ "$restart_count" -ge 1 ]; then
    check 0 "Restart policies configured ($restart_count services)"
else
    check 1 "No restart policies found"
fi

# AC5.5: Port 8081 exposed
echo ""
echo "━━━ AC5.5: Checking audio stream port (8081) ━━━"
if grep -q "network_mode: host" docker-compose.yml; then
    check 0 "Host network mode active - port 8081 will be accessible directly"
elif grep -q "8081:8081" docker-compose.yml; then
    check 0 "Port 8081 mapped explicitly"
else
    check 1 "Port 8081 NOT exposed - needed for HA media player integration"
fi

# AC5.6: Containers running with new config
echo ""
echo "━━━ AC5.6: Verifying containers with new config ━━━"
if docker compose up -d 2>&1 | grep -qi "error"; then
    check 1 "Error starting containers with new config"
else
    check 0 "Containers started with updated config"
fi

# Summary
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                        PHASE 5 SUMMARY                         ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║  ✅ Passed: $PASS                                               "
echo "║  ❌ Failed: $FAIL                                               "
echo "║  ⚠️  Warnings: $WARN                                            "
echo "╚═══════════════════════════════════════════════════════════════╝"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo "🎉 PHASE 5 COMPLETE - Production hardening applied"
    echo "→ Proceed to Phase 6: HA Media Player Integration"
    exit 0
else
    echo ""
    echo "🚫 PHASE 5 INCOMPLETE - Fix failures before proceeding"
    exit 1
fi
