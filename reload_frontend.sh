#!/bin/bash
# Quick script to reload Home Assistant and verify frontend update

echo "🔄 Reloading Home Assistant Frontend..."
echo "========================================"
echo ""

# Check if files were built recently
echo "📁 Checking built files..."
ls -lh config/www/voice-*.js
echo ""

# Verify the correct URL is in the built file
echo "🔍 Verifying WebSocket URL in built file..."
if grep -q ":8080/ws" config/www/voice-receiving-card.js; then
    echo "✅ CORRECT: Found ':8080/ws' in voice-receiving-card.js"
else
    echo "❌ ERROR: ':8080/ws' NOT found in built file!"
    echo "   Run: cd frontend && npm run build"
    exit 1
fi
echo ""

# Check if Home Assistant container is running
echo "🐳 Checking Home Assistant container..."
if docker ps | grep -q homeassistant; then
    echo "✅ Home Assistant container is running"
    
    echo ""
    echo "🔄 Restarting Home Assistant to reload frontend..."
    docker restart homeassistant
    
    echo ""
    echo "⏳ Waiting for Home Assistant to start (30 seconds)..."
    sleep 30
    
    echo ""
    echo "✅ Home Assistant restarted!"
else
    echo "⚠️  Home Assistant container not found"
    echo "   Please restart Home Assistant manually"
fi

echo ""
echo "========================================"
echo "📋 Next Steps:"
echo "========================================"
echo ""
echo "1. Open Home Assistant in your browser"
echo "   URL: http://localhost:8123"
echo ""
echo "2. Hard refresh the page:"
echo "   - Windows/Linux: Ctrl + Shift + R"
echo "   - Mac: Cmd + Shift + R"
echo ""
echo "3. Open the Voice Receiving Card"
echo ""
echo "4. Open browser console (F12)"
echo ""
echo "5. Click 'Auto Listen' button"
echo ""
echo "6. Verify the WebSocket URL:"
echo "   ✅ Should see: ws://localhost:8080/ws"
echo "   ❌ Should NOT see: /api/voice-streaming/ws"
echo ""
echo "7. Check connection status:"
echo "   - Status should change: disconnected → connecting → connected"
echo ""
echo "========================================"
echo "🐛 Troubleshooting:"
echo "========================================"
echo ""
echo "If still seeing old URL:"
echo "  • Clear browser cache completely"
echo "  • Try incognito/private window"
echo "  • Check Network tab for cached files"
echo ""
echo "If connection fails:"
echo "  • Ensure WebRTC server is running on port 8080"
echo "  • Check: netstat -tuln | grep 8080"
echo "  • Check docker logs: docker logs voice-streaming"
echo ""
