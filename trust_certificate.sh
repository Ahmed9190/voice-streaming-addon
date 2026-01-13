#!/bin/bash
#
# Quick SSL Trust Fix
# Helps you trust the self-signed certificate
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          SSL Certificate Trust Helper                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERT_FILE="${SCRIPT_DIR}/ssl/homeassistant.crt"

if [ ! -f "$CERT_FILE" ]; then
    echo -e "${RED}❌ Certificate not found: $CERT_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Certificate found: $CERT_FILE${NC}"
echo ""

# Verify certificate details
echo -e "${YELLOW}📋 Certificate Details:${NC}"
echo ""
echo -e "${BLUE}Subject:${NC}"
openssl x509 -in "$CERT_FILE" -noout -subject

echo ""
echo -e "${BLUE}Valid Until:${NC}"
openssl x509 -in "$CERT_FILE" -noout -enddate

echo ""
echo -e "${BLUE}Subject Alternative Names:${NC}"
openssl x509 -in "$CERT_FILE" -noout -text | grep -A1 "Subject Alternative Name" | tail -1

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""

# Determine OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo -e "${YELLOW}🐧 Linux detected${NC}"
    echo ""
    echo -e "${BLUE}Option 1: System-wide trust (requires sudo)${NC}"
    echo -e "This will make the certificate trusted by ALL applications."
    echo ""
    read -p "Install certificate system-wide? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installing certificate...${NC}"
        sudo cp "$CERT_FILE" /usr/local/share/ca-certificates/homeassistant.crt
        sudo update-ca-certificates
        echo -e "${GREEN}✓ Certificate installed system-wide!${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  You still need to restart your browser completely:${NC}"
        echo -e "   killall chrome chromium firefox"
        echo ""
    fi
    
    echo -e "${BLUE}Option 2: Browser-specific trust${NC}"
    echo ""
    echo -e "${YELLOW}For Chrome/Chromium/Edge:${NC}"
    echo -e "  1. Open: chrome://settings/security"
    echo -e "  2. Click 'Manage certificates'"
    echo -e "  3. Go to 'Authorities' tab"
    echo -e "  4. Click 'Import'"
    echo -e "  5. Select: $CERT_FILE"
    echo -e "  6. Check 'Trust this certificate for identifying websites'"
    echo -e "  7. Restart browser"
    echo ""
    echo -e "${YELLOW}For Firefox:${NC}"
    echo -e "  1. Settings → Privacy & Security → Certificates → View Certificates"
    echo -e "  2. Authorities tab → Import"
    echo -e "  3. Select: $CERT_FILE"
    echo -e "  4. Check 'Trust this CA to identify websites'"
    echo -e "  5. Restart browser"
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${YELLOW}🍎 macOS detected${NC}"
    echo ""
    echo -e "${BLUE}Installing certificate to Keychain...${NC}"
    
    read -p "Add certificate to macOS Keychain? [y/N]: " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CERT_FILE"
        echo -e "${GREEN}✓ Certificate added to Keychain!${NC}"
        echo -e "${YELLOW}⚠️  Restart your browser for changes to take effect.${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Unsupported OS: $OSTYPE${NC}"
    echo -e "${YELLOW}Please manually import the certificate:${NC}"
    echo -e "  $CERT_FILE"
fi

echo ""
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}📋 Next Steps:${NC}"
echo -e "${GREEN}════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  1. ${BLUE}Restart your browser completely${NC}"
echo -e "     killall chrome chromium firefox"
echo ""
echo -e "  2. ${BLUE}Navigate to:${NC}"
echo -e "     https://192.168.2.185"
echo ""
echo -e "  3. ${BLUE}Verify the lock icon 🔒 appears in the address bar${NC}"
echo ""
echo -e "  4. ${BLUE}Clear cache and hard reload:${NC}"
echo -e "     Ctrl+Shift+R (Chrome/Firefox)"
echo ""
echo -e "  5. ${BLUE}Check browser console (F12):${NC}"
echo -e "     No more SSL/SecurityError messages should appear"
echo ""
echo -e "${YELLOW}📱 For mobile devices, see: ssl/MOBILE_TRUST.md${NC}"
echo ""
