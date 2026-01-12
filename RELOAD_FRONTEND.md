# Force Home Assistant to Reload Updated Cards

## The Problem

The browser is still loading the old cached JavaScript files that use the incorrect WebSocket URL (`/api/voice-streaming/ws` instead of `:8080/ws`).

## ✅ Solution (Choose ONE method)

### Method 1: Hard Refresh Browser (Fastest)

1. Open Home Assistant in your browser
2. Press **Ctrl + Shift + R** (Windows/Linux) or **Cmd + Shift + R** (Mac)
3. This forces the browser to bypass cache and reload all resources
4. Refresh the dashboard page with the cards

### Method 2: Clear Browser Cache

1. Open browser DevTools (F12)
2. Right-click the refresh button
3. Select "Empty Cache and Hard Reload"
4. Or go to Settings → Privacy → Clear browsing data → Cached images and files

### Method 3: Restart Home Assistant (Most Reliable)

```bash
# If using Docker
docker restart homeassistant

# If using systemd
sudo systemctl restart home-assistant

# Or from HA UI
# Settings → System → Restart
```

### Method 4: Add Cache Buster (Permanent Fix)

Add a version parameter to force reload on updates:

1. Edit your dashboard YAML
2. Update the card resources:

```yaml
type: custom:voice-receiving-card
# Add this line to force reload
_version: 2 # Increment this number when you update the code
```

## 🧪 Verify the Fix

After reloading, check the browser console (F12):

**Before (OLD - Incorrect):**

```
WebSocket connection to 'wss://localhost/api/voice-streaming/ws' failed
```

**After (NEW - Correct):**

```
WebSocket connection to 'ws://localhost:8080/ws' established
```

## 🔍 Additional Verification

### Check Network Tab

1. Open DevTools (F12)
2. Go to Network tab
3. Reload the page
4. Find `voice-receiving-card.js`
5. Check the "Size" column:
   - If it says "(disk cache)" or "(memory cache)" → Still using old version
   - If it shows actual size (e.g., "13.0 KB") → New version loaded ✅

### Check File Timestamp

1. In Network tab, click on `voice-receiving-card.js`
2. Check "Headers" → "Last-Modified"
3. Should be: `Sat, 11 Jan 2026 21:33:XX GMT` (recent)

### Verify WebSocket URL in Code

1. In Network tab, click on `voice-receiving-card.js`
2. Go to "Response" tab
3. Search for `:8080/ws`
4. Should find it in the code ✅

## 🚨 If Still Not Working

### Nuclear Option: Clear Everything

```bash
# 1. Stop Home Assistant
docker stop homeassistant

# 2. Clear browser cache completely
# (Settings → Clear all browsing data)

# 3. Restart Home Assistant
docker start homeassistant

# 4. Open HA in incognito/private window
# This ensures no cache is used
```

### Check File Permissions

```bash
# Ensure HA can read the files
ls -la config/www/voice-*.js

# Should show readable permissions
# -rw-r--r-- means readable by all ✅
```

### Verify File Content

```bash
# Check if the built file has the correct URL
grep ":8080/ws" config/www/voice-receiving-card.js

# Should output: :8080/ws
```

## 📝 For Future Updates

Whenever you rebuild the frontend:

1. **Rebuild**:

   ```bash
   cd frontend
   npm run build
   ```

2. **Force Reload** (choose one):

   - Hard refresh: Ctrl + Shift + R
   - Or restart Home Assistant
   - Or use incognito mode for testing

3. **Verify** in browser console:
   - Look for correct WebSocket URL
   - Check for connection success

---

**Current Status**: Files built correctly at 22:33, just need browser to reload them!
