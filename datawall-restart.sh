#!/bin/bash
# datawall-restart.sh - Main script for datawall management
# Implements: start -> kill -> start -> click -> wait -> reboot

CONFIG_FILE="/etc/datawall.conf"
LOG_FILE="/var/log/datawall-restart.log"

# Load configuration
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "Configuration file not found at $CONFIG_FILE"
    exit 1
fi

# Defaults
DASHBOARD_URL="${DASHBOARD_URL:-http://localhost:8088}"
RESTART_INTERVAL="${RESTART_INTERVAL:-4h}"
DASHBOARD_SELECTION="${DASHBOARD_SELECTION:-1}"
BUTTON_WAIT_TIME="${BUTTON_WAIT_TIME:-10}"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

setup_display() {
    export DISPLAY=:0
    if [ -f /home/admin/.Xauthority ]; then
        export XAUTHORITY=/home/admin/.Xauthority
    elif [ -f /home/pi/.Xauthority ]; then
        export XAUTHORITY=/home/pi/.Xauthority
    else
        export XAUTHORITY=$HOME/.Xauthority
    fi
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
}

kill_firefox() {
    log_message "Stopping Firefox..."
    pkill -f firefox >/dev/null 2>&1 || true
    sleep 2
    pkill -9 -f firefox >/dev/null 2>&1 || true
}

click_dashboard_button() {
    log_message "Waiting ${BUTTON_WAIT_TIME} seconds for page to load..."
    sleep "$BUTTON_WAIT_TIME"

    SCREEN_INFO=$(xdotool getdisplaygeometry 2>/dev/null)
    if [ -n "$SCREEN_INFO" ]; then
        SCREEN_WIDTH=$(echo $SCREEN_INFO | awk '{print $1}')
        SCREEN_HEIGHT=$(echo $SCREEN_INFO | awk '{print $2}')
    else
        SCREEN_WIDTH=1920
        SCREEN_HEIGHT=1080
        log_message "Could not detect screen resolution, using fallback: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
    fi

    CENTER_X=$((SCREEN_WIDTH / 2))
    log_message "Screen resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
    log_message "Clicking dashboard button ${DASHBOARD_SELECTION}..."

    case $DASHBOARD_SELECTION in
        1)
            CLICK_Y=$((SCREEN_HEIGHT * 104 / 1000))
            ;;
        2)
            CLICK_Y=$((SCREEN_HEIGHT * 3125 / 10000))
            ;;
        3)
            CLICK_Y=$((SCREEN_HEIGHT * 52 / 100))
            ;;
        *)
            log_message "Invalid DASHBOARD_SELECTION: $DASHBOARD_SELECTION (use 1,2,3)"
            return 1
            ;;
    esac

    xdotool mousemove "$CENTER_X" "$CLICK_Y" click 1
    log_message "Clicked dashboard button at ($CENTER_X, $CLICK_Y)"

    # small confirm fullscreen toggle to keep window focused
    sleep 1
    FIREFOX_WINDOW=$(xdotool search --name "Firefox" 2>/dev/null | tail -1)
    if [ -n "$FIREFOX_WINDOW" ]; then
        xdotool windowactivate "$FIREFOX_WINDOW"
        sleep 0.5
        xdotool key --window "$FIREFOX_WINDOW" F11
        sleep 0.3
        xdotool key --window "$FIREFOX_WINDOW" F11
    fi
}

start_firefox() {
    log_message "Starting Firefox with URL: $DASHBOARD_URL"
    firefox --kiosk "$DASHBOARD_URL" &
    FIREFOX_PID=$!
    log_message "Firefox started (PID: $FIREFOX_PID), waiting for window..."

    # Wait for newest firefox window
    for i in {1..30}; do
        FIREFOX_WINDOW=$(xdotool search --name "Firefox" 2>/dev/null | tail -1)
        if [ -n "$FIREFOX_WINDOW" ]; then
            log_message "Firefox window detected (ID: $FIREFOX_WINDOW) after ${i}s"
            break
        fi
        sleep 1
    done

    if [ -z "$FIREFOX_WINDOW" ]; then
        log_message "Warning: Firefox window not found"
        return 1
    fi

    # Bring to front and maximize / fullscreen aggressively
    xdotool windowactivate "$FIREFOX_WINDOW"
    sleep 1
    xdotool windowmove "$FIREFOX_WINDOW" 0 0
    sleep 0.3
    xdotool windowsize "$FIREFOX_WINDOW" 100% 100%
    sleep 0.3
    xdotool key --window "$FIREFOX_WINDOW" F11
    sleep 0.3
    xdotool key --window "$FIREFOX_WINDOW" F11
    sleep 0.3
    xdotool key --window "$FIREFOX_WINDOW" F11

    log_message "Attempted to set Firefox fullscreen"
    return 0
}

restart_cycle() {
    log_message "Starting restart cycle - will reboot system in 15 seconds"
    sleep 15
    log_message "Rebooting Raspberry Pi now..."
    sudo /usr/sbin/reboot
}

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

main() {
    log_message "Datawall restart service started"
    log_message "Restart interval: $RESTART_INTERVAL"
    log_message "Dashboard selection: Button $DASHBOARD_SELECTION"

    # Wait until X server is ready
    while ! xdotool getdisplaygeometry &>/dev/null; do
        log_message "Waiting for X server..."
        sleep 2
    done

    setup_display
    sleep 5

    # --- required dumb sequence: start, kill, start ---
    log_message "FIRST START of Firefox (expected to possibly fail fullscreen)"
    start_firefox
    sleep 2

    log_message "KILLING Firefox to reset fullscreen state"
    kill_firefox
    sleep 4

    log_message "SECOND START of Firefox (expected to be correct fullscreen)"
    start_firefox
    sleep 3

    # launch unclutter to hide cursor (background)
    unclutter -idle 0.1 -root >/dev/null 2>&1 &

    # now perform normal click flow
    click_dashboard_button

    SLEEP_SECONDS=$(parse_interval "$RESTART_INTERVAL")

    # Main loop: wait interval then reboot
    while true; do
        log_message "Next system reboot in $RESTART_INTERVAL"
        sleep "$SLEEP_SECONDS"
        restart_cycle
    done
}

main
