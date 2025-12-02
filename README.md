# Raspberry Pi Datawall Auto-Restart System

Automated system for managing 12 Raspberry Pi 5 datawalls with periodic restarts and Ignition SCADA dashboard display.

## Features

- 🔄 Automatic Firefox restart every 4-6 hours (configurable)
- 🌐 Opens Ignition SCADA dashboard in fullscreen kiosk mode
- 🎯 Auto-clicks dashboard selection buttons
- 🚀 Auto-deploys updates from GitHub
- 📊 Systemd service for reliability
- 🔧 Easy configuration management

## Quick Start

### One-Line Installation

Run this command on each Raspberry Pi:

```bash
curl -sL https://raw.githubusercontent.com/sfcoderep/sfRaspiRestart/main/install.sh | sudo bash
```

### Configuration

1. Edit the configuration file:
```bash
sudo nano /etc/datawall.conf
```

2. Configure your settings:
```bash
DASHBOARD_URL="http://sfign01.sf.local:8088/data/perspective/client/SFcncTabletPROD"
RESTART_INTERVAL=4h
DASHBOARD_SELECTION=1  # 1=top button, 2=middle, 3=bottom
BUTTON_WAIT_TIME=10
```

3. Restart the service:
```bash
sudo systemctl restart datawall-restart
```

## Dashboard Button Selection

The system automatically clicks one of three dashboard buttons after the Ignition page loads:

- **`DASHBOARD_SELECTION=1`** - Clicks **top** button
- **`DASHBOARD_SELECTION=2`** - Clicks **middle** button
- **`DASHBOARD_SELECTION=3`** - Clicks **bottom** button

Example configuration for 12 datawalls:
- **Pi 1-4**: Dashboard A (Button 1)
- **Pi 5-8**: Dashboard B (Button 2)
- **Pi 9-12**: Dashboard C (Button 3)

## Configuration Options

Edit `/etc/datawall.conf`:

| Option | Description | Example |
|--------|-------------|---------|
| `DASHBOARD_URL` | Your Ignition dashboard URL | `http://sfign01.sf.local:8088/data/perspective/client/SFcncTabletPROD` |
| `RESTART_INTERVAL` | Time between restarts | `4h`, `6h`, `300m`, `21600s` |
| `DASHBOARD_SELECTION` | Which button to click (1-3) | `1` (top), `2` (middle), `3` (bottom) |
| `BUTTON_WAIT_TIME` | Wait time before clicking (seconds) | `10`, `15`, `20` |

## Management Commands

### Check Status
```bash
sudo systemctl status datawall-restart
```

### View Live Logs
```bash
sudo journalctl -u datawall-restart -f
```

### Restart Service
```bash
sudo systemctl restart datawall-restart
```

### Stop Service
```bash
sudo systemctl stop datawall-restart
```

### Check Update Logs
```bash
sudo tail -f /var/log/datawall-update.log
```

### Force Manual Update
```bash
sudo /opt/datawall/update.sh
```

## How It Works

1. **Systemd Service**: Runs `datawall-restart.sh` on boot and keeps it running
2. **Main Script**: Kills Firefox and reopens dashboard every configured interval
3. **Auto-Click**: Waits for page load, then clicks the specified dashboard button
4. **Auto-Update**: Cron job checks GitHub hourly for script updates
5. **Kiosk Mode**: Firefox runs fullscreen with hidden cursor

## File Structure

```
/opt/datawall/
├── datawall-restart.sh    # Main restart script
├── update.sh              # Auto-update script
└── install.sh             # Installation script (downloaded during install)

/etc/
├── datawall.conf          # Configuration file
└── systemd/system/
    └── datawall-restart.service  # Systemd service

/var/log/
├── datawall-restart.log   # Service logs
└── datawall-update.log    # Update logs
```

## Deployment Workflow

### Push Updates
Simply push changes to your GitHub repository:

```bash
git add .
git commit -m "Update button click timing"
git push origin main
```

All Raspberry Pis will automatically pull updates within 1 hour.

### Force Immediate Update
On any Pi:
```bash
sudo /opt/datawall/update.sh
```

Or restart the service to trigger a check:
```bash
sudo systemctl restart datawall-restart
```

## Testing

See **[TESTING.md](TESTING.md)** for complete testing procedures including:
- Pre-deployment verification
- Button click accuracy testing
- Auto-update testing
- Stability testing

## Deployment

See **[DEPLOYMENT.md](DEPLOYMENT.md)** for step-by-step deployment guide including:
- GitHub repository setup
- Raspberry Pi preparation
- Installation on 12 units
- Configuration per dashboard
- Monitoring and maintenance

## Troubleshooting

### Firefox Won't Start
```bash
# Check display
echo $DISPLAY  # Should be :0

# Verify X server is running
ps aux | grep X

# Check permissions
ls -la /home/pi/.Xauthority
sudo chown pi:pi /home/pi/.Xauthority
```

### Wrong Button Being Clicked
```bash
# Increase wait time for slower page loads
sudo nano /etc/datawall.conf
# Set: BUTTON_WAIT_TIME=15 or 20

# Verify button selection
cat /etc/datawall.conf | grep DASHBOARD_SELECTION

# Test click manually
export DISPLAY=:0
xdotool mousemove 960 300 click 1  # Top button
```

### Button Click Misses Target
```bash
# Check your screen resolution
xrandr | grep '*'

# For non-standard resolutions, edit click coordinates
sudo nano /opt/datawall/datawall-restart.sh
# Adjust the xdotool mousemove coordinates
```

### Service Not Running
```bash
# Check service status
sudo systemctl status datawall-restart

# View detailed logs
sudo journalctl -u datawall-restart -n 50

# Check configuration syntax
bash -n /opt/datawall/datawall-restart.sh

# Restart service
sudo systemctl restart datawall-restart
```

### Updates Not Working
```bash
# Check cron job exists
sudo crontab -l | grep update.sh

# Manually test update
sudo /opt/datawall/update.sh

# Check update logs
sudo tail -f /var/log/datawall-update.log

# Verify GitHub connectivity
curl -I https://raw.githubusercontent.com/sfcoderep/sfRaspiRestart/main/install.sh
```

### Network/Ignition Connection Issues
```bash
# Test Ignition server connectivity
curl -I http://sfign01.sf.local:8088

# Check DNS resolution
nslookup sfign01.sf.local

# Verify network interface
ip addr show
ping sfign01.sf.local
```

## Raspberry Pi Setup Recommendations

### Enable Auto-Login
```bash
sudo raspi-config
# Select: System Options > Boot / Auto Login > Desktop Autologin
```

### Disable Screen Blanking
Add to `/etc/xdg/lxsession/LXDE-pi/autostart`:
```
@xset s off
@xset -dpms
@xset s noblank
```

### Set Static IP (Recommended)
Edit `/etc/dhcpcd.conf`:
```
interface eth0
static ip_address=192.168.1.10X/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1
```

### Install Prerequisites (Automatic)
The installer automatically installs:
- `firefox-esr` - Web browser
- `xdotool` - Mouse/keyboard automation
- `unclutter` - Hides mouse cursor

## Advanced Configuration

### Stagger Restart Times
To avoid all Pis restarting simultaneously:

```bash
# Pi group 1: Every 4 hours
RESTART_INTERVAL=4h

# Pi group 2: Every 4 hours 15 minutes (255m)
RESTART_INTERVAL=255m

# Pi group 3: Every 4 hours 30 minutes (270m)
RESTART_INTERVAL=270m
```

### Custom Click Coordinates
For non-standard screen resolutions, edit `/opt/datawall/datawall-restart.sh`:

```bash
# Find the click_dashboard_button() function
# Adjust xdotool mousemove coordinates:

1)  xdotool mousemove 960 300 click 1  # Top button
2)  xdotool mousemove 960 540 click 1  # Middle button
3)  xdotool mousemove 960 780 click 1  # Bottom button
```

## Monitoring

### Quick Health Check Script
```bash
#!/bin/bash
# check-pi-status.sh
for i in {101..112}; do
    echo "Pi-$((i-100)):"
    ssh pi@192.168.1.$i "systemctl is-active datawall-restart"
done
```

### Log Monitoring
```bash
# View all restart cycles from today
sudo journalctl -u datawall-restart --since today | grep "Restart cycle complete"

# Count restarts in last 24 hours
sudo journalctl -u datawall-restart --since "24 hours ago" | grep -c "Restart cycle complete"

# Check for errors
sudo journalctl -u datawall-restart --since today | grep -i error
```

## Security Notes

- System runs as `pi` user (non-root) for safety
- Only update script requires root privileges for service restart
- Configuration file readable by all users (contains no secrets)
- GitHub updates use HTTPS
- No passwords or credentials stored in scripts

## Project Information

- **Repository**: https://github.com/sfcoderep/sfRaspiRestart
- **Ignition Server**: http://sfign01.sf.local:8088
- **Dashboard Project**: SFcncTabletPROD
- **Target Platform**: Raspberry Pi 5
- **OS**: Raspberry Pi OS (Debian-based)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/improvement`)
3. Commit your changes (`git commit -m 'Add some improvement'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Create a Pull Request

## License

MIT License - feel free to modify and distribute

## Support

For issues or questions:
- **GitHub Issues**: https://github.com/sfcoderep/sfRaspiRestart/issues
- **Check Logs**: `sudo journalctl -u datawall-restart -f`
- **Verify Config**: `cat /etc/datawall.conf`
- **Service Status**: `sudo systemctl status datawall-restart`

---

**Version**: 1.0  
**Last Updated**: December 2024  
**Maintained By**: sfcoderep