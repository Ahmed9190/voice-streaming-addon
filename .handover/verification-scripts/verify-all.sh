#!/bin/bash
# Master Verification Script
# Runs all phase verifications in sequence

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        WEBRTC VOICE STREAMING - COMPLETE VERIFICATION          ║"
echo "║                    All 8 Phases                                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "This script will verify each phase in sequence."
echo "If a phase fails, you must fix it before proceeding."
echo ""
echo "Phase Overview:"
echo "  Phase 1: Bug Fixes & Code Quality"
echo "  Phase 2: LAN-Only Configuration"
echo "  Phase 3: SSL Certificates for LAN"
echo "  Phase 4: Cross-Device Verification   ← MILESTONE: Mobile sends voice"
echo "  Phase 5: Production Hardening"
echo "  Phase 6: HA Media Player Integration ← MILESTONE: Plays on speaker"
echo "  Phase 7: Reliability & Monitoring"
echo "  Phase 8: Final Testing & Deployment  ← MILESTONE: Production ready"
echo ""

cd "$(dirname "$0")/../.." || exit 1
SCRIPT_DIR=".handover/verification-scripts"

run_phase() {
    phase=$1
    name=$2
    script=$3
    
    echo ""
    echo "══════════════════════════════════════════════════════════════════"
    echo " RUNNING: Phase $phase - $name"
    echo "══════════════════════════════════════════════════════════════════"
    echo ""
    
    if [ -x "$script" ]; then
        bash "$script"
        result=$?
        if [ $result -ne 0 ]; then
            echo ""
            echo "❌ Phase $phase FAILED"
            echo "Fix the issues and re-run verification."
            return 1
        fi
        return 0
    else
        echo "⚠️  Script not found or not executable: $script"
        return 1
    fi
}

prompt_continue() {
    phase=$1
    next=$2
    read -p "Phase $phase passed. Continue to Phase $next? (y/n): " answer
    [ "$answer" != "y" ] && exit 0
}

# Phase 1: Bug Fixes
run_phase 1 "Bug Fixes & Code Quality" "$SCRIPT_DIR/verify-phase-1.sh" || exit 1
prompt_continue 1 2

# Phase 2: LAN Configuration
run_phase 2 "LAN-Only Configuration" "$SCRIPT_DIR/verify-phase-2.sh" || exit 1
read -p "Complete manual tests (AC2.4, AC2.5) before continuing. Ready? (y/n): " ready2
[ "$ready2" != "y" ] && exit 0

# Phase 3: SSL Certificates
run_phase 3 "SSL Certificates for LAN" "$SCRIPT_DIR/verify-phase-3.sh" || exit 1
prompt_continue 3 4

# Phase 4: Cross-Device (MILESTONE)
run_phase 4 "Cross-Device Verification" "$SCRIPT_DIR/verify-phase-4.sh" || exit 1
echo ""
echo "🎯 MILESTONE ACHIEVED: Mobile can send voice!"
echo ""
prompt_continue 4 5

# Phase 5: Production Hardening
run_phase 5 "Production Hardening" "$SCRIPT_DIR/verify-phase-5.sh" || exit 1
prompt_continue 5 6

# Phase 6: HA Media Player (MILESTONE)
run_phase 6 "HA Media Player Integration" "$SCRIPT_DIR/verify-phase-6.sh" || exit 1
echo ""
echo "🎯 MILESTONE ACHIEVED: Audio plays on real speaker!"
echo ""
prompt_continue 6 7

# Phase 7: Reliability & Monitoring
run_phase 7 "Reliability & Monitoring" "$SCRIPT_DIR/verify-phase-7.sh" || exit 1
prompt_continue 7 8

# Phase 8: Final Testing (MILESTONE)
run_phase 8 "Final Testing & Deployment" "$SCRIPT_DIR/verify-phase-8.sh" || exit 1

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║   🎉🎉🎉 ALL 8 PHASES COMPLETE! 🎉🎉🎉                       ║"
echo "║                                                               ║"
echo "║   ✅ Phase 1: Bug Fixes                                       ║"
echo "║   ✅ Phase 2: LAN Configuration                               ║"
echo "║   ✅ Phase 3: SSL Certificates                                ║"
echo "║   ✅ Phase 4: Cross-Device          [Mobile sends voice]      ║"
echo "║   ✅ Phase 5: Production Hardening                            ║"
echo "║   ✅ Phase 6: HA Media Player       [Plays on speaker]        ║"
echo "║   ✅ Phase 7: Reliability                                     ║"
echo "║   ✅ Phase 8: Final Testing         [Production ready]        ║"
echo "║                                                               ║"
echo "║   System is PRODUCTION READY!                                 ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
