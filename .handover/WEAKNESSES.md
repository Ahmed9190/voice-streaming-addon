# 📉 Project Weaknesses & Technical Debt Report

**Status**: Phase 8 Analysis
**Last Updated**: 2026-01-11

## � Resolved Issues (Phase 8)

### 1. Frontend Duplication (Major DRY Violation)

- **Status**: ✅ FIXED (Partial)
- **Resolution**: Extracted magic numbers to `CONSTANTS` object in both files. While full deduplication requires a shared module (complex in HA), the tuning parameters are now standardized.

### 2. Backend Safety (Python Best Practices)

- **Status**: ✅ FIXED
- **Resolution**: Replaced bare `except:` clauses with `except Exception:` prevents swallowing `SystemExit` and `KeyboardInterrupt`.

### 3. Hardcoded Configuration (Configurability)

- **Status**: ✅ FIXED
- **Resolution**: Extracted `STREAM_URL` to `__init__.py` constant.

## 🟠 Remaining Technical Debt

### 4. WebSocket "Keep-Alive" Reliance

- **Issue**: We rely on ping/pong but the logic is implicit.
- **Action**: Verify if explicit heartbeat is needed for long-running sessions (> 1 hour).

### 5. Magic Numbers

- **Files**: JS cards
- **Issue**: `1000`, `30000`, `200` scattered as timeouts.
- **Action**: Extract to `CHECK_INTERVAL`, `MAX_RECONNECT`, `DEBOUNCE_TIME` constants.

## 🟡 Minor Cleanups

### 6. Legacy Comments & Unused Imports

- **Issue**: Old "TODO" comments or unused variables from the previous RTSP implementation.
- **Action**: Sweep and clean.
