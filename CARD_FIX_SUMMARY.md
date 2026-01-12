# ✅ CARD LOADING FIX - Summary

## The Issue

```
Configuration error
Custom element doesn't exist: voice-sending-card.
```

## Root Cause

Home Assistant hadn't loaded the custom card JavaScript files. This happens when:

1. Cards are added/updated but HA not restarted
2. Browser has cached old resources list
3. Lovelace resources not refreshed

## The Fix Applied

### ✅ Verification Completed

- voice-sending-card.js: **EXISTS** (6.1K)
- voice-receiving-card.js: **EXISTS** (13K)
- Both cards: **REGISTERED** in JavaScript
- Both cards: **IN RESOURCES** (ui-lovelace.yaml)

### ✅ Actions Taken

1. Verified all files exist and are correct
2. Restarted Home Assistant to reload resources
3. Waiting 30 seconds for startup

## Next Steps (CRITICAL)

### Step 1: Wait for Home Assistant to Start

The script is restarting HA. Wait about 30 seconds.

### Step 2: Hard Refresh Browser

**DO NOT just refresh!** You must do a HARD refresh:

- **Windows/Linux:** `Ctrl + Shift + R`
- **Mac:** `Cmd + Shift + R`

### Step 3: Or Use Incognito Window (RECOMMENDED)

This guarantees no cache:

- **Chrome:** `Ctrl + Shift + N`
- **Firefox:** `Ctrl + Shift + P`
- Then go to: `https://192.168.2.120`

### Step 4: Verify Cards Load

1. Go to your dashboard
2. Both cards should now appear
3. No "Custom element doesn't exist" error

## If Cards Still Don't Load

### Check Browser Console (F12)

**Look for these errors:**

**404 Error:**

```
Failed to load resource: /local/voice-sending-card.js 404
```

**Fix:** File permissions issue

```bash
chmod 644 config/www/voice-*.js
```

**Module Error:**

```
Uncaught SyntaxError: Unexpected token
```

**Fix:** Rebuild cards

```bash
cd frontend && npm run build
```

**Already Defined:**

```
Custom element 'voice-sending-card' already defined
```

**Fix:** Clear browser cache completely

**No Errors:**
If console shows no errors but card missing → **CACHE ISSUE**

- Clear ALL browser data
- Use incognito window

## Quick Verification Commands

```bash
# Check files exist
ls -lh config/www/voice-*.js

# Check HA is running
docker ps | grep homeassistant

# Check HA logs for errors
docker logs homeassistant | grep -i error | tail -20

# Restart HA again if needed
docker restart homeassistant
```

## Configuration Summary

### Lovelace Resources (ui-lovelace.yaml)

```yaml
resources:
  - url: /local/voice-sending-card.js
    type: module
  - url: /local/voice-receiving-card.js
    type: module
```

### Dashboard Cards

```yaml
# Voice Sender
- type: custom:voice-sending-card
  title: Voice Sender

# Voice Receiver
- type: custom:voice-receiving-card
  title: Voice Receiver
  server_url: https://192.168.2.120/ws # Match your HA URL!
```

## Timeline

1. ✅ Files built: 22:43
2. ✅ Resources configured: ui-lovelace.yaml
3. ✅ HA restarting: NOW
4. ⏳ Wait 30 seconds
5. 🔄 Hard refresh browser
6. ✅ Cards should load!

---

**Status:** Home Assistant is restarting. Wait 30 seconds, then hard refresh your browser!
