#!/bin/bash
# datawall-restart.sh - Main script for datawall management

CONFIG_FILE="/etc/datawall.conf"
LOG_FILE="/var/log/datawall-restart.log"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Default values if not set in config
DASHBOARD_URL="${DASHBOARD_URL:-http://localhost:8088}"
RESTART_INTERVAL="${RESTART_INTERVAL:-4h}"
DASHBOARD_SELECTION="${DASHBOARD_SELECTION:-1}"  # Which button to click (1, 2, or 3)
BUTTON_WAIT_TIME="${BUTTON_WAIT_TIME:-10}"  # Seconds to wait before clicking

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

setup_display() {
    export DISPLAY=:0
    export XAUTHORITY=/home/pi/.Xauthority
}

kill_firefox() {
    log_message "Stopping Firefox..."
    pkill -f firefox || true
    sleep 2
    pkill -9 -f firefox || true
}

click_dashboard_button() {
    log_message "Waiting ${BUTTON_WAIT_TIME} seconds for page to load..."
    sleep "$BUTTON_WAIT_TIME"
    
    log_message "Clicking dashboard button ${DASHBOARD_SELECTION}..."
    
    # Move mouse to center of screen first
    xdotool mousemove 960 540
    
    # Click based on button position (adjust Y coordinates as needed)
    case $DASHBOARD_SELECTION in
        1)
            # Top button - click upper third of screen
            xdotool mousemove 960 300 click 1
            log_message "Clicked top dashboard button"
            ;;
        2)
            # Middle button - click center of screen
            xdotool mousemove 960 540 click 1
            log_message "Clicked middle dashboard button"
            ;;
        3)
            # Bottom button - click lower third of screen
            xdotool mousemove 960 780 click 1
            log_message "Clicked bottom dashboard button"
            ;;
        *)
            log_message "Invalid DASHBOARD_SELECTION: $DASHBOARD_SELECTION (use 1, 2, or 3)"
            ;;
    esac
    
    # Make sure we're still fullscreen after click
    sleep 1
    xdotool key F11
}

start_firefox() {
    log_message "Starting Firefox with URL: $DASHBOARD_URL"
    
    # Launch Firefox in kiosk mode
    firefox --kiosk "$DASHBOARD_URL" &
    FIREFOX_PID=$!
    
    sleep 5
    
    # Hide cursor
    unclutter -idle 0.1 -root &
    
    # Make Firefox fullscreen
    sleep 2
    xdotool key F11
    
    log_message "Firefox started (PID: $FIREFOX_PID)"
    
    # Auto-click the dashboard button
    click_dashboard_button
}

restart_cycle() {
    setup_display
    kill_firefox
    sleep 3
    start_firefox
    log_message "Restart cycle complete. Next restart in $RESTART_INTERVAL"
}

# Parse interval to seconds for sleep
parse_interval() {
    local interval=$1
    local number=${interval//[^0-9]/}
    local unit=${interval//[0-9]/}
    
    case $unit in
        h) echo $((number * 3600)) ;;
        m) echo $((number * 60)) ;;
        s) echo $number ;;
        *) echo 14400 ;; # default 4 hours
    esac
}

# Main loop
main() {
    log_message "Datawall restart service started"
    log_message "Restart interval: $RESTART_INTERVAL"
    log_message "Dashboard selection: Button $DASHBOARD_SELECTION"
    
    SLEEP_SECONDS=$(parse_interval "$RESTART_INTERVAL")
    
    while true; do
        restart_cycle
        sleep "$SLEEP_SECONDS"
    done
}

main