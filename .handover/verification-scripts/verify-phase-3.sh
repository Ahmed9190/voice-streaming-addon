#!/bin/bash
# Phase 3 Verification Script
# SSL Certificates for LAN

# Don't use set -e as it causes issues with arithmetic expressions

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║         PHASE 3 VERIFICATION: SSL Certificates for LAN        ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

PASS=0
FAIL=0
WARN=0

# Detect LAN IP using multiple methods for compatibility
SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || hostname -I 2>/dev/null | awk '{print $1}' || echo "")
echo "Detected Server IP: $SERVER_IP"
echo ""

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

# AC3.1: Script exists and is executable
echo ""
echo "━━━ AC3.1: Checking generation script ━━━"
if [ -x ssl/generate_lan_cert.sh ]; then
    check 0 "ssl/generate_lan_cert.sh exists and is executable"
else
    check 1 "ssl/generate_lan_cert.sh not found or not executable"
fi

# AC3.2: Certificate contains LAN IP
echo ""
echo "━━━ AC3.2: Checking certificate contains LAN IP ━━━"
if openssl x509 -in ssl/homeassistant.crt -text -noout 2>/dev/null | grep -q "$SERVER_IP"; then
    check 0 "Certificate contains LAN IP: $SERVER_IP"
else
    check 1 "Certificate does NOT contain LAN IP: $SERVER_IP"
fi

# AC3.3: Certificate contains localhost
echo ""
echo "━━━ AC3.3: Checking certificate contains localhost ━━━"
if openssl x509 -in ssl/homeassistant.crt -text -noout 2>/dev/null | grep -q "localhost"; then
    check 0 "Certificate contains localhost"
else
    check 1 "Certificate does NOT contain localhost"
fi

# AC3.4: Nginx restart succeeds
echo ""
echo "━━━ AC3.4: Testing Nginx restart ━━━"
if docker compose restart nginx 2>&1 | grep -qi "error"; then
    check 1 "Nginx restart failed"
else
    check 0 "Nginx restart successful"
fi

# Wait for Nginx to be ready
sleep 3

# AC3.5: HTTPS accessible via IP
echo ""
echo "━━━ AC3.5: Checking HTTPS accessibility via IP ━━━"
HTTP_CODE=$(curl -sk "https://$SERVER_IP" -o /dev/null -w "%{http_code}" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    check 0 "HTTPS accessible via IP (HTTP $HTTP_CODE)"
else
    check 1 "HTTPS NOT accessible via IP (HTTP $HTTP_CODE)"
fi

# Summary
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                        PHASE 3 SUMMARY                         ║"
echo "╠═══════════════════════════════════════════════════════════════╣"
echo "║  ✅ Passed: $PASS                                               "
echo "║  ❌ Failed: $FAIL                                               "
echo "║  ⚠️  Warnings: $WARN                                            "
echo "╚═══════════════════════════════════════════════════════════════╝"

if [ $FAIL -eq 0 ]; then
    echo ""
    echo "🎉 PHASE 3 COMPLETE - SSL certificates configured"
    echo ""
    echo "Server accessible at: https://$SERVER_IP"
    echo ""
    echo "Next: Install certificate on mobile device (see ssl/MOBILE_TRUST.md)"
    echo "Then proceed to Phase 4 for cross-device testing"
    exit 0
else
    echo ""
    echo "🚫 PHASE 3 INCOMPLETE - Fix failures before proceeding"
    exit 1
fi
