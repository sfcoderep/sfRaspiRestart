#!/bin/bash
# datawall-restart.sh - Datawall auto-restart script

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
BUTTON_WAIT_TIME="${BUTTON_WAIT_TIME:-30}"

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

    SCREEN_INFO=$(xdotool getdisplaygeometry 2>/dev/null)
    if [ -n "$SCREEN_INFO" ]; then
        SCREEN_WIDTH=$(echo $SCREEN_INFO | awk '{print $1}')
        SCREEN_HEIGHT=$(echo $SCREEN_INFO | awk '{print $2}')
    else
        SCREEN_WIDTH=1920
        SCREEN_HEIGHT=1080
        log_message "Fallback screen resolution: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
    fi

    CENTER_X=$((SCREEN_WIDTH / 2))
    case $DASHBOARD_SELECTION in
        1) CLICK_Y=$((SCREEN_HEIGHT * 104 / 1000)) ;;
        2) CLICK_Y=$((SCREEN_HEIGHT * 3125 / 10000)) ;;
        3) CLICK_Y=$((SCREEN_HEIGHT * 52 / 100)) ;;
        *) CLICK_Y=$((SCREEN_HEIGHT * 104 / 1000)) ;;
    esac

    log_message "Clicking dashboard button ${DASHBOARD_SELECTION} at ($CENTER_X, $CLICK_Y)"
    xdotool mousemove $CENTER_X $CLICK_Y click 1
}

start_firefox() {
    log_message "Starting Firefox with URL: $DASHBOARD_URL"
    firefox --kiosk "$DASHBOARD_URL" &
    FIREFOX_PID=$!
    log_message "Firefox started (PID: $FIREFOX_PID), waiting for window..."
    for i in {1..20}; do
        if xdotool search --name "Firefox" &>/dev/null; then
            log_message "Firefox window detected after $i seconds"
            break
        fi
        sleep 0.5
    done

    FIREFOX_WINDOW=$(xdotool search --name "Firefox" | head -1)
    if [ -n "$FIREFOX_WINDOW" ]; then
        xdotool windowactivate "$FIREFOX_WINDOW"
        xdotool windowmove "$FIREFOX_WINDOW" 0 0
        xdotool windowsize "$FIREFOX_WINDOW" 100% 100%
        xdotool key --window "$FIREFOX_WINDOW" F11
    else
        log_message "Warning: Firefox window not found"
    fi

    click_dashboard_button
    unclutter -idle 0.1 -root &
}

restart_cycle() {
    log_message "Rebooting system in 15 seconds..."
    sleep 15
    sudo reboot
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
    log_message "Dashboard selection: $DASHBOARD_SELECTION"

    while ! xdotool getdisplaygeometry &>/dev/null; do
        log_message "Waiting for X server..."
        sleep 2
    done

    setup_display

    BOOT_MARKER="/run/datawall-first-run"

    if [ ! -e "$BOOT_MARKER" ]; then
        log_message "First boot detected, performing dumb Firefox restart..."
        touch "$BOOT_MARKER"
        start_firefox
        kill_firefox
        log_message "Restarting datawall-restart.service (dumb mode)"
        systemctl restart datawall-restart.service
        exit 0
    fi

    # Normal run: start Firefox and continue
    start_firefox

    SLEEP_SECONDS=$(parse_interval "$RESTART_INTERVAL")
    while true; do
        log_message "Next system reboot in $RESTART_INTERVAL"
        sleep "$SLEEP_SECONDS"
        restart_cycle
    done
}

main
