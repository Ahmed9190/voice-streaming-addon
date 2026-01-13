#!/bin/bash
# Fix: Custom element doesn't exist

echo "🔧 Fixing 'Custom element doesn't exist' Error"
echo "=============================================="
echo ""

# Check if files exist
echo "1️⃣ Checking built files..."
if [ -f "config/www/voice-sending-card.js" ]; then
    echo "   ✅ voice-sending-card.js exists"
    SIZE=$(ls -lh config/www/voice-sending-card.js | awk '{print $5}')
    echo "      Size: $SIZE"
else
    echo "   ❌ voice-sending-card.js NOT FOUND!"
    echo "      Running build..."
    cd frontend && npm run build && cd ..
fi

if [ -f "config/www/voice-receiving-card.js" ]; then
    echo "   ✅ voice-receiving-card.js exists"
    SIZE=$(ls -lh config/www/voice-receiving-card.js | awk '{print $5}')
    echo "      Size: $SIZE"
else
    echo "   ❌ voice-receiving-card.js NOT FOUND!"
fi
echo ""

# Check if cards are registered
echo "2️⃣ Verifying card registration..."
if grep -q "customCards.push" config/www/voice-sending-card.js; then
    echo "   ✅ voice-sending-card is registered"
else
    echo "   ❌ voice-sending-card NOT registered!"
fi

if grep -q "customCards.push" config/www/voice-receiving-card.js; then
    echo "   ✅ voice-receiving-card is registered"
else
    echo "   ❌ voice-receiving-card NOT registered!"
fi
echo ""

# Check Lovelace resources
echo "3️⃣ Checking Lovelace resources..."
if grep -q "/local/voice-sending-card.js" config/ui-lovelace.yaml; then
    echo "   ✅ voice-sending-card.js in resources"
else
    echo "   ⚠️  voice-sending-card.js NOT in resources"
fi

if grep -q "/local/voice-receiving-card.js" config/ui-lovelace.yaml; then
    echo "   ✅ voice-receiving-card.js in resources"
else
    echo "   ⚠️  voice-receiving-card.js NOT in resources"
fi
echo ""

# Restart Home Assistant
echo "4️⃣ Restarting Home Assistant..."
if docker ps | grep -q homeassistant; then
    docker restart homeassistant
    echo "   ✅ Home Assistant restarted"
    echo "   ⏳ Waiting 30 seconds for startup..."
    sleep 30
else
    echo "   ⚠️  Home Assistant container not found"
fi
echo ""

echo "=============================================="
echo "✅ Fix Applied!"
echo "=============================================="
echo ""
echo "📋 NEXT STEPS:"
echo ""
echo "1. Open Home Assistant in browser"
echo "   URL: https://192.168.2.185"
echo ""
echo "2. HARD REFRESH the page:"
echo "   • Ctrl + Shift + R (Windows/Linux)"
echo "   • Cmd + Shift + R (Mac)"
echo ""
echo "3. OR use Incognito/Private window:"
echo "   • Ctrl + Shift + N (Chrome)"
echo "   • Ctrl + Shift + P (Firefox)"
echo ""
echo "4. Go to your dashboard"
echo ""
echo "5. The cards should now load!"
echo ""
echo "=============================================="
echo "🐛 If cards still don't load:"
echo "=============================================="
echo ""
echo "Check browser console (F12) for errors:"
echo ""
echo "• 404 errors → Files not accessible"
echo "  Fix: Check file permissions"
echo ""
echo "• Module errors → Build issue"
echo "  Fix: cd frontend && npm run build"
echo ""
echo "• 'already defined' → Duplicate registration"
echo "  Fix: Clear browser cache"
echo ""
echo "• No errors but card missing → Cache issue"
echo "  Fix: Clear ALL browser data"
echo ""
