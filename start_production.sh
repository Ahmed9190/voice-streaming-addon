#!/bin/bash
# Production Start Script for WebRTC Voice Sending
# Phase 9: Task 9.1

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      STARTING WEBRTC VOICE SENDING SYSTEM (PRODUCTION)        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"

# 1. Check Pre-requisites
echo -e "\n${BLUE}👉 Checking Docker...${NC}"
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running! Please start Docker first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker is running${NC}"

# 2. Stop existing services
echo -e "\n${BLUE}👉 Stopping existing services...${NC}"
docker compose down
echo -e "${GREEN}✅ Services stopped${NC}"

# 3. Build and Start
echo -e "\n${BLUE}👉 Building and Starting services...${NC}"
docker compose up -d --build
echo -e "${GREEN}✅ Services started in detached mode${NC}"

# 4. Wait for Health Check
echo -e "\n${BLUE}👉 Waiting for backend health...${NC}"
MAX_RETRIES=30
COUNT=0
URL="http://127.0.0.1:8080/health"

while [ $COUNT -lt $MAX_RETRIES ]; do
    if curl -s "$URL" | grep -q "healthy"; then
        echo -e "${GREEN}✅ Backend is healthy!${NC}"
        break
    fi
    echo -n "."
    sleep 1
    COUNT=$((COUNT+1))
done

if [ $COUNT -eq $MAX_RETRIES ]; then
    echo -e "\n${RED}❌ Backend failed to start or is unhealthy.${NC}"
    docker compose logs voice_streaming
    exit 1
fi

# 5. Get Network Info
# Try to find the specific WiFi subnet first (192.168.2.x)
IP=$(ip addr show | grep 'inet ' | grep '192.168.2\.' | awk '{print $2}' | cut -d/ -f1 | head -n 1)

# Fallback to any 192.168 address
if [ -z "$IP" ]; then
    IP=$(ip addr show | grep 'inet ' | grep '192.168' | awk '{print $2}' | cut -d/ -f1 | head -n 1)
fi

# Final Fallback
if [ -z "$IP" ]; then
    IP="192.168.2.185"
fi

# 6. Display Access Info
echo -e "\n${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                  🚀 SYSTEM IS READY 🚀                        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo -e "\nAccess the system at:"
echo -e "   🏠 Home Assistant:   ${GREEN}https://${IP}${NC}"
echo -e "   ⚙️  Backend Status:   ${GREEN}http://${IP}:8080/health${NC}"
echo -e "   📈 Metrics:          ${GREEN}http://${IP}:8080/metrics${NC}"
echo -e "   📻 Audio Stream:     ${GREEN}http://${IP}:8081/stream/latest.mp3${NC}"
echo -e "\n${BLUE}Logs:${NC} docker compose logs -f"
echo -e "\n${GREEN}Deployment Complete.${NC}"
exit 0
