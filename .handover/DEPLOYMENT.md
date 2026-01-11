# 🚀 Deployment Guide

**Project**: WebRTC Voice Sending for Home Assistant
**Version**: 1.0.0
**Date**: 2026-01-11

## 📋 Prerequisites

- **Hardware**: Linux server (Raspberry Pi, mini PC, etc)
- **OS**: Linux (Debian/Ubuntu/Alpine)
- **Dependencies**:
  - Docker & Docker Compose
  - `curl`, `ffmpeg` (optional for debug)
- **Network**:
  - Static IP recommended (e.g., `192.168.2.120`)
  - Ports: 8123 (HA), 8080 (Signal/API), 8081 (Audio), 50000-50100 (UDP RTP)

## 🛠️ Quick Start (Production)

1.  **Navigate to project directory**:

    ```bash
    cd /path/to/webrtc_voice_sending
    ```

2.  **Run the production start script**:

    ```bash
    ./start_production.sh
    ```

    This script will:

    - Check Docker status
    - Build/Pull containers
    - Start services
    - Wait for health checks
    - Display access URLs

3.  **Verify Access**:
    - **Home Assistant**: [https://SERVER_IP:8123](https://SERVER_IP:8123)
    - **Backend Status**: [http://SERVER_IP:8080/health](http://SERVER_IP:8080/health)

## 📦 Container Architecture

| Service           | Image                                 | Ports      | Description                         |
| :---------------- | :------------------------------------ | :--------- | :---------------------------------- |
| `homeassistant`   | `homeassistant/home-assistant:stable` | Host       | Core automation platform            |
| `voice_streaming` | _Local Build_ (`webrtc_backend`)      | 8080, 8081 | WebRTC signaling & Audio generation |
| `nginx`           | `nginx:alpine`                        | Host       | SSL Termination for Secure Context  |

## 🔧 Configuration

### Environment Variables

- `TZ`: Timezone (default: `Africa/Cairo`)
- `HOST_IP`: Inferred by scripts, can be overridden in `docker-compose.yml`.

### SSL Certificates

Located in `./ssl/`. Must be generated for valid LAN access (WebRTC requires HTTPS).

- Regenerate: `./ssl/generate_lan_cert.sh`

## 🩺 Monitoring & Maintenance

- **View Logs**:

  ```bash
  docker compose logs -f verify_streaming
  ```

- **Check Health**:

  ```bash
  curl http://localhost:8080/health
  # Returns: {"status": "healthy", ...}
  ```

- **Restart Backend**:

  ```bash
  docker compose restart voice_streaming
  ```

- **Cleanup Stale Streams**:
  Automatic every 5 minutes.

## 🛑 Shutdown

To stop all services gracefully:

```bash
docker compose down
```

---

**Status**: Production Ready ✅
