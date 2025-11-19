#!/bin/bash

# 5G Testing Environment - Tmux Session Manager
# Author: Gregory
# Date: November 2025
# 
# This script creates organized tmux sessions for 5G testing with FlexRIC integration
# Components: Docker containers, FlexRIC, gNB, UE, AMF logs, xApps, SINR emulator

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="/home/gregory/5G"

# Session name
SESSION_NAME="5G_Testing"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}                    5G Testing Environment                      ${BLUE}║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC} Session: ${CYAN}${SESSION_NAME}${NC}                                         ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC} Components: Docker, FlexRIC, gNB, UE, AMF, xApps, SINR       ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
}

# Check if tmux is installed
check_tmux() {
    if ! command -v tmux &> /dev/null; then
        print_error "tmux is not installed. Please install it: sudo apt install tmux"
        exit 1
    fi
}

# Check if session already exists and kill it
cleanup_session() {
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        print_warning "Existing session '$SESSION_NAME' found. Killing it..."
        tmux kill-session -t "$SESSION_NAME"
        sleep 2
    fi
}

# Function to create tmux session with multiple panes
create_tmux_session() {
    print_status "Creating tmux session: $SESSION_NAME"
    
    # Create new session with first pane
    tmux new-session -d -s "$SESSION_NAME" -n "5G_Testing"
    
    # Enable mouse support for pane selection, resizing, and scrolling
    tmux set-option -t "$SESSION_NAME" mouse on
    
    # Create 6 additional panes by splitting systematically
    # Split horizontally to create 2 columns
    tmux split-window -h -t "$SESSION_NAME:0.0"
    
    # Split left column into 4 panes (Docker, FlexRIC, gNB, AMF)
    tmux split-window -v -t "$SESSION_NAME:0.0"
    tmux split-window -v -t "$SESSION_NAME:0.1"
    tmux split-window -v -t "$SESSION_NAME:0.2"
    
    # Split right column into 3 panes (UE, xApp, SINR)
    tmux split-window -v -t "$SESSION_NAME:0.4"
    tmux split-window -v -t "$SESSION_NAME:0.5"
    
    # Select the first pane
    tmux select-pane -t "$SESSION_NAME:0.0"
    
    print_status "Tmux session created with 7 panes (mouse support enabled)"
}

# Function to start Docker containers
start_docker() {
    print_status "Starting Docker containers..."
    tmux send-keys -t "$SESSION_NAME:0.0" "cd $BASE_DIR/oai-cn5g" C-m
    tmux send-keys -t "$SESSION_NAME:0.0" "echo 'Starting Docker containers...'" C-m
    tmux send-keys -t "$SESSION_NAME:0.0" "docker compose up -d" C-m
    tmux send-keys -t "$SESSION_NAME:0.0" "echo 'Docker containers started. Monitoring...'" C-m
    tmux send-keys -t "$SESSION_NAME:0.0" "docker ps" C-m
}

# Function to start FlexRIC
start_flexric() {
    print_status "Starting FlexRIC Near-RT RIC..."
    tmux send-keys -t "$SESSION_NAME:0.1" "cd $BASE_DIR" C-m
    tmux send-keys -t "$SESSION_NAME:0.1" "echo 'Starting FlexRIC Near-RT RIC...'" C-m
    tmux send-keys -t "$SESSION_NAME:0.1" "./flexric/build/examples/ric/nearRT-RIC" C-m
}

# Function to start gNB
start_gnb() {
    print_status "Starting gNB..."
    tmux send-keys -t "$SESSION_NAME:0.2" "cd $BASE_DIR/openairinterface5g/cmake_targets/ran_build/build" C-m
    tmux send-keys -t "$SESSION_NAME:0.2" "echo 'Starting gNB with FlexRIC integration...'" C-m
    tmux send-keys -t "$SESSION_NAME:0.2" "sudo ./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.fr1.106PRB.usrpb210.conf --gNBs.[0].min_rxtxtime 6 --rfsim" C-m
}

# Function to start AMF logs
start_amf_logs() {
    print_status "Starting AMF logs monitoring..."
    tmux send-keys -t "$SESSION_NAME:0.3" "echo 'Monitoring AMF logs...'" C-m
    tmux send-keys -t "$SESSION_NAME:0.3" "docker logs oai-amf -f" C-m
}

# Function to start UE
start_ue() {
    print_status "Starting UE..."
    tmux send-keys -t "$SESSION_NAME:0.4" "cd $BASE_DIR/openairinterface5g/cmake_targets/ran_build/build" C-m
    tmux send-keys -t "$SESSION_NAME:0.4" "echo 'Starting UE...'" C-m
    tmux send-keys -t "$SESSION_NAME:0.4" "sudo ./nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --uicc0.imsi 001010000000001 --rfsim" C-m
}

# Function to start KMP monitoring xApp
start_xapp_monitor() {
    print_status "Starting KMP monitoring xApp..."
    tmux send-keys -t "$SESSION_NAME:0.5" "cd $BASE_DIR/flexric" C-m
    tmux send-keys -t "$SESSION_NAME:0.5" "echo 'Starting KMP monitoring xApp...'" C-m
    tmux send-keys -t "$SESSION_NAME:0.5" "./build/examples/xApp/c/monitor/xapp_kpm_moni" C-m
}

# Function to start SINR emulator agent
start_sinr_emulator() {
    print_status "Starting SINR emulator agent for MCS adaptation testing..."
    tmux send-keys -t "$SESSION_NAME:0.6" "cd $BASE_DIR/flexric" C-m
    tmux send-keys -t "$SESSION_NAME:0.6" "echo 'Starting SINR emulator agent for MCS testing...'" C-m
    tmux send-keys -t "$SESSION_NAME:0.6" "./build/examples/emulator/agent/emu_agent_ue_sinr_test" C-m
}

# Function to show session info
show_session_info() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                         SESSION LAYOUT                         ${CYAN}║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Pane 0: Docker Containers (oai-cn5g)                          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Pane 1: FlexRIC Near-RT RIC                                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Pane 2: gNB (nr-softmodem)                                    ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Pane 3: AMF Logs                                              ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Pane 4: UE (nr-uesoftmodem)                                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Pane 5: KMP Monitoring xApp                                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} Pane 6: SINR Emulator Agent                                   ${CYAN}║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC} Commands:                                                      ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} - tmux attach -t $SESSION_NAME     (attach to session)        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} - tmux kill-session -t $SESSION_NAME (kill session)          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} - Click on any pane to switch to it (mouse support)          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} - Ctrl+B then arrow keys (navigate between panes)            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} - Ctrl+B then q (show pane numbers)                           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} - Ctrl+B then d (detach from session)                         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} - Drag pane borders to resize (mouse support)                 ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Main execution function
main() {
    print_header
    
    # Checks
    check_tmux
    
    # Clean up existing session
    cleanup_session
    
    # Create tmux session
    create_tmux_session
    
    # Start components in sequence
    print_status "Starting all components automatically..."
    
    # 1. Start Docker containers first
    start_docker
    
    # 2. Start FlexRIC
    start_flexric  
    
    # 3. Start gNB
    start_gnb
    
    # 4. Start AMF logs monitoring
    start_amf_logs
    
    # 5. Start UE
    start_ue
    
    # 6. Start xApp monitor
    start_xapp_monitor
    
    # 7. Start SINR emulator
    start_sinr_emulator
    
    # Show session info
    show_session_info
    
    # Attach to the session
    print_status "Attaching to tmux session. Use Ctrl+B then d to detach."
    sleep 2
    tmux attach-session -t "$SESSION_NAME"
}

# Help function
show_help() {
    echo "5G Testing Environment - Tmux Session Manager"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  start       Start the complete 5G testing environment"
    echo "  stop        Stop and kill the tmux session"
    echo "  attach      Attach to existing session"
    echo "  status      Show session status"
    echo "  help        Show this help message"
    echo ""
    echo "Components started:"
    echo "  1. Docker containers (oai-cn5g) - Pane 0"
    echo "  2. FlexRIC Near-RT RIC - Pane 1"
    echo "  3. gNB (nr-softmodem) - Pane 2"
    echo "  4. AMF logs monitoring - Pane 3"
    echo "  5. UE (nr-uesoftmodem) - Pane 4"  
    echo "  6. KMP monitoring xApp - Pane 5"
    echo "  7. SINR emulator agent - Pane 6"
}

# Command line argument handling
case "${1:-start}" in
    start)
        main
        ;;
    stop)
        print_status "Stopping 5G testing session..."
        if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
            tmux kill-session -t "$SESSION_NAME"
            print_status "Session '$SESSION_NAME' stopped"
        else
            print_warning "No session '$SESSION_NAME' found"
        fi
        ;;
    attach)
        if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
            tmux attach-session -t "$SESSION_NAME"
        else
            print_error "No session '$SESSION_NAME' found. Run '$0 start' first."
        fi
        ;;
    status)
        if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
            print_status "Session '$SESSION_NAME' is running"
            tmux list-panes -t "$SESSION_NAME" -F "Pane #{pane_index}: #{pane_current_command}"
        else
            print_warning "No session '$SESSION_NAME' found"
        fi
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac

