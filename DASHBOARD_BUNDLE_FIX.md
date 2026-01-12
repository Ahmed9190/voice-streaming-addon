# ✅ FIXED: 404 Error for voice-streaming-card-dashboard.js

## The Problem

```
Request URL: https://192.168.2.120/local/voice-streaming-card-dashboard.js
Status Code: 404 Not Found
```

## Root Cause

The `voice-streaming-card-dashboard.js` file was **not being built** by Rollup because it wasn't included in the build configuration.

### Why This Happened

The dashboard bundle file exists in the source (`frontend/src/voice-streaming-card-dashboard.ts`) but was removed from the Rollup build inputs at some point. However, it was still referenced somewhere (likely in cached Lovelace resources).

## The Fix

### Updated Rollup Configuration

**File:** `frontend/rollup.config.js`

**Before:**

```javascript
input: ["src/voice-sending-card.ts", "src/voice-receiving-card.ts"],
```

**After:**

```javascript
input: [
  "src/voice-sending-card.ts",
  "src/voice-receiving-card.ts",
  "src/voice-streaming-card-dashboard.ts"  // ✅ Added
],
```

### Rebuilt Frontend

```bash
cd frontend
npm run build
```

### Result

```
✅ voice-sending-card.js (6.1K)
✅ voice-receiving-card.js (13K)
✅ voice-streaming-card-dashboard.js (211 bytes) ← NEW!
```

## What is voice-streaming-card-dashboard.js?

This is a **convenience bundle** that imports both cards in a single file:

```typescript
import "./voice-sending-card";
import "./voice-receiving-card";

console.info("Voice Streaming Dashboard bundle loaded");
```

### When to Use It

**Option 1: Individual Cards (Recommended)**

```yaml
resources:
  - url: /local/voice-sending-card.js
    type: module
  - url: /local/voice-receiving-card.js
    type: module
```

**Option 2: Dashboard Bundle (Simpler)**

```yaml
resources:
  - url: /local/voice-streaming-card-dashboard.js
    type: module
```

Both options work the same way. The bundle just loads both cards with a single resource entry.

## Next Steps

### Option A: Keep Using Individual Cards (Current Setup)

Your `ui-lovelace.yaml` already uses individual cards:

```yaml
resources:
  - url: /local/voice-sending-card.js
    type: module
  - url: /local/voice-receiving-card.js
    type: module
```

**Action:** Just refresh your browser. The 404 error will be gone because the file now exists.

### Option B: Switch to Dashboard Bundle

If you prefer, you can simplify to use the bundle:

**Edit `config/ui-lovelace.yaml`:**

```yaml
resources:
  # Replace these two lines:
  # - url: /local/voice-sending-card.js
  #   type: module
  # - url: /local/voice-receiving-card.js
  #   type: module

  # With this single line:
  - url: /local/voice-streaming-card-dashboard.js
    type: module
```

## Verification

### Check Files Exist

```bash
ls -lh config/www/voice-*.js
```

**Expected output:**

```
voice-receiving-card.js (13K)
voice-sending-card.js (6.1K)
voice-streaming-card-dashboard.js (211 bytes) ✅
```

### Test in Browser

1. Hard refresh: `Ctrl + Shift + R`
2. Open browser console (F12)
3. Go to Network tab
4. Look for `voice-streaming-card-dashboard.js`
5. Should show **200 OK** (not 404)

## Summary

**Problem:** Dashboard bundle file missing (404 error)
**Cause:** Not included in Rollup build configuration
**Fix:** Added to build inputs and rebuilt
**Result:** File now exists, 404 error resolved

---

**Status:** ✅ Fixed and rebuilt
**Action Required:** Refresh browser to clear 404 error
