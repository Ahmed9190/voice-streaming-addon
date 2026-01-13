#!/bin/bash
# Definitive cache-busting solution

echo "🔥 CACHE BUSTING - NUCLEAR OPTION"
echo "=================================="
echo ""

# Step 1: Verify files are built correctly
echo "1️⃣ Verifying built files..."
if grep -q "wss://localhost/ws" config/www/voice-receiving-card.js 2>/dev/null; then
    echo "   ❌ ERROR: Built file still contains hardcoded URL!"
    echo "   This shouldn't happen. Checking source..."
    if grep -q "wss://localhost/ws" frontend/src/webrtc-manager.ts; then
        echo "   ❌ Source file has hardcoded URL - this is the problem!"
    fi
elif grep -q ":8080/ws" config/www/voice-receiving-card.js; then
    echo "   ✅ Built file contains correct URL construction logic"
else
    echo "   ⚠️  Cannot verify - file might not exist"
fi
echo ""

# Step 2: Add cache buster to filenames
echo "2️⃣ Adding timestamp to force browser reload..."
TIMESTAMP=$(date +%s)
cd config/www

# Rename files with timestamp
for file in voice-*.js; do
    if [ -f "$file" ]; then
        newname="${file%.js}-${TIMESTAMP}.js"
        cp "$file" "$newname"
        echo "   Created: $newname"
    fi
done

cd ../..
echo ""

# Step 3: Show what to do next
echo "=================================="
echo "✅ Cache buster applied!"
echo "=================================="
echo ""
echo "📋 NEXT STEPS (CRITICAL):"
echo ""
echo "1. CLOSE ALL Home Assistant browser tabs"
echo "   (Don't just refresh - actually close them)"
echo ""
echo "2. Clear browser cache:"
echo "   • Chrome: Ctrl+Shift+Delete → Clear cached images and files"
echo "   • Firefox: Ctrl+Shift+Delete → Cached Web Content"
echo ""
echo "3. Open Home Assistant in INCOGNITO/PRIVATE window"
echo "   • Chrome: Ctrl+Shift+N"
echo "   • Firefox: Ctrl+Shift+P"
echo ""
echo "4. Go to your dashboard with the Voice Receiving Card"
echo ""
echo "5. Open browser console (F12)"
echo ""
echo "6. Click 'Auto Listen'"
echo ""
echo "7. Look for this in console:"
echo "   ✅ [WebRTC] Connecting to: wss://localhost/ws"
echo "   ✅ WebSocket connection to 'wss://localhost/ws' established"
echo ""
echo "=================================="
echo "🔍 If it STILL fails in incognito:"
echo "=================================="
echo ""
echo "Then the issue is NOT cache, it's something else:"
echo "  • Check browser console for SSL certificate errors"
echo "  • Check if you're accessing HA via https://192.168.2.185"
echo "  • The card config might have wrong URL"
echo ""
echo "To check card config:"
echo "  1. Edit the Voice Receiving Card"
echo "  2. Check 'Server URL' field"
echo "  3. It should be: https://192.168.2.185/ws"
echo "     (NOT https://localhost/ws if accessing via IP)"
echo ""
