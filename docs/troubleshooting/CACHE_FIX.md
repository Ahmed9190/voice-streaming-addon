# 🚨 CACHE ISSUE - Quick Fix

## The Problem

You're seeing: `WebSocket connection to 'wss://localhost/api/voice-streaming/ws' failed`

This is the **OLD URL**. The browser is using **cached JavaScript files**.

## ✅ Quick Fix (30 seconds)

### Option 1: Hard Refresh Browser (FASTEST)

```
1. Open Home Assistant in browser
2. Press: Ctrl + Shift + R (Windows/Linux)
        OR Cmd + Shift + R (Mac)
3. Done! ✅
```

### Option 2: Restart Home Assistant

```bash
./reload_frontend.sh
```

Or manually:

```bash
docker restart homeassistant
# Wait 30 seconds
# Then hard refresh browser (Ctrl + Shift + R)
```

### Option 3: Incognito Mode (TEST)

```
1. Open Home Assistant in incognito/private window
2. This bypasses all cache
3. If it works here, it's definitely a cache issue
```

## 🔍 Verify It Worked

Open browser console (F12) and look for:

**✅ CORRECT (New):**

```
WebSocket connection to 'ws://localhost:8080/ws' established
```

**❌ WRONG (Old - Cached):**

```
WebSocket connection to 'wss://localhost/api/voice-streaming/ws' failed
```

## 📊 Check Network Tab

1. Open DevTools (F12)
2. Go to Network tab
3. Reload page
4. Find `voice-receiving-card.js`
5. Check "Size" column:
   - `(disk cache)` or `(memory cache)` = ❌ Still cached
   - `13.0 KB` (actual size) = ✅ New version loaded

## 🛠️ Nuclear Option

If nothing works:

```bash
# 1. Clear ALL browser data
# Settings → Privacy → Clear browsing data → Everything

# 2. Restart Home Assistant
docker restart homeassistant

# 3. Wait 30 seconds

# 4. Open in NEW incognito window
```

## ✅ Verification Checklist

- [ ] Built files exist: `ls -lh config/www/voice-*.js`
- [ ] Correct URL in file: `grep ":8080/ws" config/www/voice-receiving-card.js`
- [ ] Home Assistant restarted
- [ ] Browser hard refreshed (Ctrl + Shift + R)
- [ ] Console shows `ws://localhost:8080/ws`
- [ ] Status changes to "connected"

---

**Files are built correctly!** Just need browser to load them. 🚀
