#!/bin/bash
# update.sh - Automatic update script from GitHub

INSTALL_DIR="/opt/datawall"
REPO_URL="https://raw.githubusercontent.com/sfcoderep/sfRaspiRestart/main"
SERVICE_NAME="datawall-restart"

cd "$INSTALL_DIR" || exit 1

# Download and compare main script
curl -sL "$REPO_URL/datawall-restart.sh" -o datawall-restart.sh.new

if [ -f datawall-restart.sh.new ]; then
    if ! cmp -s datawall-restart.sh datawall-restart.sh.new; then
        echo "$(date): New version detected, updating..."
        mv datawall-restart.sh.new datawall-restart.sh
        chmod +x datawall-restart.sh
        
        # Restart service
        systemctl restart "$SERVICE_NAME"
        echo "$(date): Service restarted with new version"
    else
        rm datawall-restart.sh.new
    fi
fi

# Update service file if changed
curl -sL "$REPO_URL/datawall-restart.service" -o /tmp/datawall-restart.service.new
if ! cmp -s /etc/systemd/system/datawall-restart.service /tmp/datawall-restart.service.new; then
    echo "$(date): Service file updated"
    mv /tmp/datawall-restart.service.new /etc/systemd/system/datawall-restart.service
    systemctl daemon-reload
    systemctl restart "$SERVICE_NAME"
else
    rm /tmp/datawall-restart.service.new
fi