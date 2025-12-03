#!/bin/bash
# install.sh - Initial setup script for Raspberry Pi datawalls

set -e

echo "Installing Raspberry Pi Datawall Auto-Restart System..."

# Configuration
INSTALL_DIR="/opt/datawall"
SERVICE_NAME="datawall-restart"
CONFIG_FILE="/etc/datawall.conf"

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Download latest files from GitHub
echo "Downloading latest files from GitHub..."
cd "$INSTALL_DIR"
curl -sL https://raw.githubusercontent.com/sfcoderep/sfRaspiRestart/main/datawall-restart.sh -o datawall-restart.sh
curl -sL https://raw.githubusercontent.com/sfcoderep/sfRaspiRestart/main/datawall-restart.service -o /etc/systemd/system/datawall-restart.service
curl -sL https://raw.githubusercontent.com/sfcoderep/sfRaspiRestart/main/update.sh -o update.sh

chmod +x datawall-restart.sh
chmod +x update.sh

# Create config file if it doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Creating configuration file..."
    cat > "$CONFIG_FILE" << 'EOF'
# Datawall Configuration
DASHBOARD_URL="http://sfign01.sf.local:8088/data/perspective/client/SFcncTabletPROD"
RESTART_INTERVAL=4h
DASHBOARD_SELECTION=1
BUTTON_WAIT_TIME=10
EOF
    echo "Please edit $CONFIG_FILE to configure your dashboard settings"
fi

# Install dependencies
echo "Installing dependencies..."
apt-get update
apt-get install -y firefox-esr xdotool unclutter

# Setup reboot permissions
echo "Setting up reboot permissions..."
echo "admin ALL=(ALL) NOPASSWD: /usr/sbin/reboot" > /etc/sudoers.d/datawall-reboot
chmod 440 /etc/sudoers.d/datawall-reboot

# Setup auto-update cron job (checks every hour)
echo "Setting up automatic updates..."
CRON_JOB="0 * * * * $INSTALL_DIR/update.sh >> /var/log/datawall-update.log 2>&1"
(crontab -l 2>/dev/null | grep -v "update.sh"; echo "$CRON_JOB") | crontab -

# Enable and start service
echo "Enabling and starting service..."
systemctl daemon-reload
systemctl enable "$SERVICE_NAME.service"
systemctl start "$SERVICE_NAME.service"

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Edit configuration: sudo nano $CONFIG_FILE"
echo "2. Set your DASHBOARD_SELECTION (1=top, 2=middle, 3=bottom)"
echo "3. Restart service: sudo systemctl restart $SERVICE_NAME"
echo "4. Check status: sudo systemctl status $SERVICE_NAME"
echo "5. View logs: sudo journalctl -u $SERVICE_NAME -f"
echo ""
echo "The system will automatically check for updates from GitHub every hour."