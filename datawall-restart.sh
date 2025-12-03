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
DASHBOARD_SELECTION="${DASHBOARD_SELECTION:-1}"
BUTTON_WAIT_TIME="${BUTTON_WAIT_TIME:-10}"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

setup_display() {
    export DISPLAY=:0
    # Detect username automatically
    if [ -f /home/admin/.Xauthority ]; then
        export XAUTHORITY=/home/admin/.Xauthority
    elif [ -f /home/pi/.Xauthority ]; then
        export XAUTHORITY=/home/pi/.Xauthority
    else
        export XAUTHORITY=$HOME/.Xauthority
    fi
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
    
    # Get screen resolution
    SCREEN_INFO=$(xdotool getdisplaygeometry 2>/dev/null)
    if [ -n "$SCREEN_INFO" ]; then
        SCREEN_WIDTH=$(echo $SCREEN_INFO | awk '{print $1}')
        SCREEN_HEIGHT=$(echo $SCREEN_INFO | awk '{print $2}')
    else
        # Fallback to common resolution if detection fails
        SCREEN_WIDTH=1920
        SCREEN_HEIGHT=1080
        log_message "Could not detect screen resolution, using fallback: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
    fi
    
    # Calculate center X position
    CENTER_X=$((SCREEN_WIDTH / 2))
    
    log_message "Screen resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
    log_message "Clicking dashboard button ${DASHBOARD_SELECTION}..."
    
    # Click based on button position
    # Buttons occupy the top 5/8ths (62.5%) of screen, divided into 3 equal sections
    # Each button is approximately 20.83% of screen height (62.5% / 3)
    case $DASHBOARD_SELECTION in
        1)
            # Top button - "Single CNC Dashboard"
            # Click in middle of first section (at 10.4% from top)
            CLICK_Y=$((SCREEN_HEIGHT * 104 / 1000))
            xdotool mousemove $CENTER_X $CLICK_Y click 1
            log_message "Clicked top dashboard button at ($CENTER_X, $CLICK_Y)"
            ;;
        2)
            # Middle button - "Horseshoe Cell Dashboard"
            # Click in middle of second section (at 31.25% from top)
            CLICK_Y=$((SCREEN_HEIGHT * 3125 / 10000))
            xdotool mousemove $CENTER_X $CLICK_Y click 1
            log_message "Clicked middle dashboard button at ($CENTER_X, $CLICK_Y)"
            ;;
        3)
            # Bottom button - "UMC350-HD Cell"
            # Click in middle of third section (at 52% from top)
            CLICK_Y=$((SCREEN_HEIGHT * 52 / 100))
            xdotool mousemove $CENTER_X $CLICK_Y click 1
            log_message "Clicked bottom dashboard button at ($CENTER_X, $CLICK_Y)"
            ;;
        *)
            log_message "Invalid DASHBOARD_SELECTION: $DASHBOARD_SELECTION (use 1, 2, or 3)"
            ;;
    esac
    
    # Ensure still fullscreen after click
    sleep 2
    FIREFOX_WINDOW=$(xdotool search --name "Firefox" 2>/dev/null | head -1)
    if [ -n "$FIREFOX_WINDOW" ]; then
        xdotool windowactivate "$FIREFOX_WINDOW"
        sleep 0.5
        xdotool key --window "$FIREFOX_WINDOW" F11
        sleep 0.5
        xdotool key --window "$FIREFOX_WINDOW" F11
    fi
}

start_firefox() {
    log_message "Starting Firefox with URL: $DASHBOARD_URL"
    
    # Launch Firefox in kiosk mode
    firefox --kiosk "$DASHBOARD_URL" &
    FIREFOX_PID=$!
    
    log_message "Firefox started (PID: $FIREFOX_PID), waiting for window to appear..."
    
    # Wait for Firefox window to appear (up to 10 seconds)
    for i in {1..20}; do
        if xdotool search --name "Firefox" > /dev/null 2>&1; then
            log_message "Firefox window detected after $i seconds"
            break
        fi
        sleep 0.5
    done
    
    sleep 2
    
    # Get Firefox window ID
    FIREFOX_WINDOW=$(xdotool search --name "Firefox" | head -1)
    
    if [ -n "$FIREFOX_WINDOW" ]; then
        log_message "Firefox window ID: $FIREFOX_WINDOW"
        
        # Activate window
        xdotool windowactivate "$FIREFOX_WINDOW"
        sleep 1
        
        # Move to 0,0 and maximize
        xdotool windowmove "$FIREFOX_WINDOW" 0 0
        sleep 0.5
        xdotool windowsize "$FIREFOX_WINDOW" 100% 100%
        sleep 1
        
        # Press F11 to toggle fullscreen (works better than --kiosk sometimes)
        xdotool key --window "$FIREFOX_WINDOW" F11
        sleep 1
        
        # Verify fullscreen with another F11 toggle
        xdotool key --window "$FIREFOX_WINDOW" F11
        sleep 0.5
        xdotool key --window "$FIREFOX_WINDOW" F11
        
        log_message "Firefox maximized and set to fullscreen"
    else
        log_message "Warning: Could not find Firefox window"
    fi
    
    # Hide cursor
    unclutter -idle 0.1 -root &
    
    # Auto-click the dashboard button
    click_dashboard_button
}

restart_cycle() {
    log_message "Starting restart cycle - will reboot system in 15 seconds"
    
    # Give time for log to be written
    sleep 15
    
    # Reboot the Raspberry Pi
    log_message "Rebooting Raspberry Pi now..."
    sudo reboot
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
    
    # On first start, launch Firefox immediately
    sleep 60
    setup_display
    sleep 10
    start_firefox
    
    SLEEP_SECONDS=$(parse_interval "$RESTART_INTERVAL")
    
    # Wait for the interval, then reboot
    while true; do
        log_message "Next system reboot in $RESTART_INTERVAL"
        sleep "$SLEEP_SECONDS"
        restart_cycle
    done
}

main