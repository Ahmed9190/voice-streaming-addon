# WebSocket Connection Fix - Summary

## ✅ Fixed Issues

### 1. **Incorrect WebSocket URL**

- **Before**: `wss://localhost/api/voice-streaming/ws` ❌
- **After**: `ws://localhost:8080/ws` ✅

### 2. **Missing Stream Polling**

- Added `getStreams()` method to WebRTCManager
- Implemented automatic polling every 5 seconds in Auto Listen mode
- Immediate stream request when Auto Listen is activated

### 3. **TypeScript Configuration**

- Fixed module resolution setting to prevent build errors

## 📝 Files Modified

1. **`frontend/src/webrtc-manager.ts`**

   - Changed WebSocket URL construction to use `:8080/ws`
   - Added public `getStreams()` method
   - Improved hostname/port parsing

2. **`frontend/src/voice-receiving-card.ts`**

   - Implemented proper stream polling in `startAutoListen()`
   - Calls `webrtc.getStreams()` every 5 seconds
   - Immediate stream request on activation

3. **`frontend/src/voice-receiving-editor.ts`**

   - Updated helper text to show correct default

4. **`frontend/src/voice-sending-editor.ts`**

   - Updated helper text to show correct default

5. **`frontend/tsconfig.json`**
   - Changed `moduleResolution` from `node16` to `node`

## 🔧 How to Use

### Default Configuration

No configuration needed! The cards will automatically connect to `localhost:8080/ws`.

### Custom Server

If your WebRTC server is on a different host/port, configure it in the card editor:

- Example: `192.168.1.100:8080`
- Example: `ws://example.com:9000`

## 🧪 Testing

1. **Rebuild the frontend** (already done):

   ```bash
   cd frontend
   npm run build
   ```

2. **Reload Home Assistant**:

   - Go to Developer Tools → YAML
   - Click "Reload" for Frontend resources
   - Or restart Home Assistant

3. **Test the Receiving Card**:
   - Add the Voice Receiving Card to your dashboard
   - Click "Auto Listen"
   - Status should change: disconnected → connecting → connected
   - Check browser console (F12) for WebSocket logs

## 🐛 Troubleshooting

### Connection Refused

- Ensure WebRTC server is running on port 8080
- Check: `netstat -tuln | grep 8080`

### Mixed Content Error

- If HA uses HTTPS, the WebSocket will try WSS
- Configure server URL explicitly: `ws://localhost:8080`

### No Streams Detected

- This is normal if no sender is active
- Start a Voice Sending Card first
- The receiver will automatically detect and connect

## 🎯 Next Steps

1. Start the WebRTC server (if not already running)
2. Reload Home Assistant frontend
3. Test both sending and receiving cards
4. Monitor browser console for any errors

---

**Status**: ✅ All changes implemented and built successfully
**Build Output**: `created ../config/www in 1.1s`
