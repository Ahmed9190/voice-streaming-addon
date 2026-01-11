# 🗺️ Architecture Map

Quick reference for navigating the codebase.

## Directory Tree

```
webrtc_voice_sending/
│
├── 🐳 INFRASTRUCTURE
│   ├── docker-compose.yml         # Orchestrates 3 services
│   ├── nginx.conf                 # SSL proxy, routes /api/voice-streaming
│   ├── start_services.sh          # → docker compose up -d
│   └── stop_services.sh           # → docker compose down
│
├── 🔒 SSL
│   └── ssl/
│       ├── homeassistant.crt      # Self-signed certificate
│       ├── homeassistant.key      # Private key
│       └── openssl.cnf            # OpenSSL config
│
├── 🐍 BACKEND (voice_streaming container)
│   └── webrtc_backend/
│       ├── Dockerfile             # Python 3.11-slim + aiortc
│       ├── requirements.txt       # aiohttp, aiortc, numpy
│       ├── webrtc_server_relay.py # ⭐ PRODUCTION SERVER (relay pattern)
│       ├── webrtc_server.py       # Legacy/basic single-client
│       ├── config.json            # ⚠️ Invalid JSON (has comments)
│       ├── README.md              # Backend docs
│       ├── test_server.py         # Backend unit tests
│       ├── test_ws.py             # WebSocket tests
│       └── performance_test.py    # Load testing
│
├── 🏠 HOME ASSISTANT (homeassistant container)
│   └── config/
│       ├── configuration.yaml     # Defines custom panels
│       │
│       ├── www/                   # Static JS served at /local/
│       │   ├── voice-sending-card.js      # ⭐ SENDER UI
│       │   ├── voice-receiving-card.js    # ⭐ RECEIVER UI
│       │   ├── voice-streaming-card*.js   # Legacy alternatives
│       │   └── hello-world*.js            # Test files
│       │
│       └── custom_components/
│           └── voice_streaming/
│               ├── __init__.py    # HA component (websocket_api)
│               └── manifest.json  # ⚠️ YAML syntax, should be JSON
│
├── 🧪 TESTING
│   ├── integration_test.py        # End-to-end validation
│   ├── test_setup.sh              # Environment checker
│   ├── test_voice_receiving_card.py
│   └── test_websocket.py
│
├── 📄 DOCUMENTATION
│   ├── README.md                  # Project overview
│   ├── USAGE.md                   # Quick usage guide
│   ├── plan.md                    # Product roadmap
│   ├── requirements.md            # Detailed dev guide
│   ├── GEMINI.md                  # AI assistant config
│   ├── QWEN.md                    # AI assistant config
│   │
│   └── .handover/                 # ⭐ HANDOVER DOCS (you are here)
│       ├── 00-README-FIRST.md
│       ├── 01-SETUP-GUIDE.md
│       ├── 02-ARCHITECTURE.md
│       ├── 03-DECISION-LOG.md
│       ├── 04-GOTCHAS.md
│       ├── ONBOARDING-CHECKLIST.md
│       └── architecture-map.md    # This file
│
└── 📦 OTHER
    ├── tmp/                       # Temporary files
    ├── venv/                      # Python virtual env (gitignored)
    └── __pycache__/               # Python cache
```

## Service Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                        Docker Compose                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐     │
│  │   nginx      │     │homeassistant │     │voice-streaming│     │
│  │   :443/:80   │────▶│    :8123     │     │    :8080     │     │
│  │              │     │              │     │              │     │
│  │              │──────────────────────────▶              │     │
│  │ Reverse Proxy│     │  HA Core     │     │ WebRTC Relay │     │
│  │ SSL/TLS     │     │  Panels      │     │  Signaling   │     │
│  └──────────────┘     └──────────────┘     └──────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
         ▲                                          ▲
         │ HTTPS                                    │ WebSocket
         │                                          │
    ┌────┴────────────────────────────────────────┴────┐
    │                    Browser                        │
    │  ┌─────────────────┐    ┌─────────────────┐     │
    │  │ Voice Send Card │    │ Voice Recv Card │     │
    │  │ getUserMedia()  │    │ audio.play()    │     │
    │  │ RTCPeerConn     │    │ RTCPeerConn     │     │
    │  └─────────────────┘    └─────────────────┘     │
    └──────────────────────────────────────────────────┘
```

## File → Purpose Quick Reference

| When you want to...    | Edit this file                                         |
| ---------------------- | ------------------------------------------------------ |
| Change Docker setup    | `docker-compose.yml`                                   |
| Change proxy routing   | `nginx.conf`                                           |
| Change backend logic   | `webrtc_backend/webrtc_server_relay.py`                |
| Change sender UI       | `config/www/voice-sending-card.js`                     |
| Change receiver UI     | `config/www/voice-receiving-card.js`                   |
| Add HA integration     | `config/custom_components/voice_streaming/__init__.py` |
| Change HA panels       | `config/configuration.yaml`                            |
| Change WebRTC settings | `config.json` (after fixing JSON) + card JS files      |

## Key Classes/Functions

### Backend (`webrtc_server_relay.py`)

| Class/Method              | Purpose                              |
| ------------------------- | ------------------------------------ |
| `VoiceStreamingServer`    | Main server class                    |
| `.setup_routes()`         | Registers `/health`, `/ws` endpoints |
| `.websocket_handler()`    | Handles client connections           |
| `.setup_sender()`         | Configures client as audio sender    |
| `.setup_receiver()`       | Configures client as audio receiver  |
| `.handle_webrtc_offer()`  | Processes SDP offers                 |
| `.handle_ice_candidate()` | Handles ICE candidate exchange       |
| `.cleanup_connection()`   | Cleans up on disconnect              |

### Frontend (`voice-sending-card.js`)

| Method                      | Purpose                            |
| --------------------------- | ---------------------------------- |
| `connectedCallback()`       | Called when card inserted to DOM   |
| `render()`                  | Generates Shadow DOM HTML          |
| `startSending()`            | Gets mic, connects WS, creates RTC |
| `stopSending()`             | Closes connections, stops stream   |
| `connectWebSocket()`        | Establishes WS connection          |
| `handleWebSocketMessage()`  | Processes server messages          |
| `startAudioVisualization()` | Draws waveform on canvas           |

---

_Generated by Elite Staff Engineer Handover Protocol (ESEHP-ASKS v2.0)_
