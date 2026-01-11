#!/bin/bash
# Phase 9 Verification Script
# Final Testing & Deployment

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
echo "║      PHASE 9 VERIFICATION: Final Testing & Deployment         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

echo "━━━ AC9.1: Checking Containers ━━━"
if docker compose ps | grep -q "voice_streaming.*Up"; then
    check 0 "Voice Streaming container is running"
else
    check 1 "Voice Streaming container is NOT running"
fi

echo ""
echo "━━━ AC8.1 (Prereq): Production Start Script ━━━"
if [ -f "start_production.sh" ]; then
    check 0 "start_production.sh exists"
    if [ -x "start_production.sh" ]; then
        check 0 "start_production.sh is executable"
    else
        check 1 "start_production.sh is NOT executable"
    fi
else
    check 1 "start_production.sh missing"
fi

echo ""
echo "━━━ AC9.4: System Health ━━━"
if curl -s http://localhost:8080/health | grep -q "healthy"; then
    check 0 "Backend health check passed"
else
    check 1 "Backend health check failed"
fi

echo ""
if [ $FAIL -eq 0 ]; then
    echo "🎉 PHASE 9 COMPLETE - System is Production Ready!"
    exit 0
else
    echo "🚫 PHASE 9 FAILED - $FAIL checks failed"
    exit 1
fi
