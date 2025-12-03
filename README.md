# Raspberry Pi Datawall Auto-Restart System

Automated system for managing 12 Raspberry Pi 5 datawalls with periodic physical reboots and Ignition SCADA dashboard display.

## Features

- 🔄 **Physical system reboot** every 4-6 hours (configurable) - fixes connectivity issues
- 🌐 Opens Ignition SCADA dashboard in fullscreen kiosk mode
- 🎯 Auto-clicks dashboard selection buttons with precision positioning
- 🚀 Auto-deploys updates from GitHub
- 📊 Systemd service for reliability
- 🔧 Easy configuration management
- 💻 Supports custom usernames (admin/pi)

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
DASHBOARD_SELECTION=1  # 1=Single CNC, 2=Horseshoe Cell, 3=UMC350-HD Cell
BUTTON_WAIT_TIME=20    # Increase if page loads slowly
```

3. Restart the service:
```bash
sudo systemctl restart datawall-restart
```

## Dashboard Button Selection

The system automatically clicks one of three dashboard buttons after the Ignition page loads:

- **`DASHBOARD_SELECTION=1`** - **Single CNC Dashboard** (top button)
- **`DASHBOARD_SELECTION=2`** - **Horseshoe Cell Dashboard** (middle button)
- **`DASHBOARD_SELECTION=3`** - **UMC350-HD Cell** (bottom button)

Example configuration for 12 datawalls:
- **Pi 1-4**: Single CNC Dashboard (Button 1)
- **Pi 5-8**: Horseshoe Cell Dashboard (Button 2)
- **Pi 9-12**: UMC350-HD Cell (Button 3)

## Configuration Options

Edit `/etc/datawall.conf`:

| Option | Description | Example |
|--------|-------------|---------|
| `DASHBOARD_URL` | Your Ignition dashboard URL | `http://sfign01.sf.local:8088/data/perspective/client/SFcncTabletPROD` |
| `RESTART_INTERVAL` | Time between **physical reboots** | `4h`, `6h`, `300m`, `21600s` |
| `DASHBOARD_SELECTION` | Which button to click (1-3) | `1` (Single CNC), `2` (Horseshoe), `3` (UMC350) |
| `BUTTON_WAIT_TIME` | Wait time before clicking (seconds) | `20`, `25`, `30` (increase for slow loads) |

## Management Commands

### Check Status
```bash
sudo systemctl status datawall-restart
```

### View Live Logs
```bash
sudo journalctl -u datawall-restart -f
```

### Restart Service (triggers immediate reboot cycle)
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

### Force Manual Update from GitHub
```bash
sudo /opt/datawall/update.sh
```

## How It Works

1. **Boot Sequence**: Systemd service starts automatically on boot
2. **Firefox Launch**: Opens fullscreen with Ignition dashboard URL
3. **Auto-Click**: Waits for page load (configurable), then clicks selected dashboard button
4. **Display**: Dashboard runs in kiosk mode with hidden cursor
5. **Physical Reboot**: After configured interval, Pi physically reboots
6. **Repeat**: Cycle continues indefinitely
7. **Auto-Update**: Hourly cron job checks GitHub for script updates

**Why Physical Reboot?** Fixes network connectivity issues, clears memory leaks, and ensures fresh state.

## File Structure

```
/opt/datawall/
├── datawall-restart.sh    # Main restart script with reboot logic
├── update.sh              # Auto-update script from GitHub
└── install.sh             # Installation script (downloaded during install)

/etc/
├── datawall.conf          # Configuration file (edit this!)
├── sudoers.d/
│   └── datawall-reboot    # Reboot permissions
└── systemd/system/
    └── datawall-restart.service  # Systemd service

/var/log/
├── datawall-restart.log   # Service logs
└── datawall-update.log    # Update logs
```

## Deployment Workflow

### Push Updates to All Pis
Simply push changes to your GitHub repository:

```bash
git add .
git commit -m "Adjust button click timing"
git push origin main
```

All 12 Raspberry Pis will automatically pull updates within 1 hour.

### Force Immediate Update
On any Pi:
```bash
sudo /opt/datawall/update.sh
```

### Test Changes Quickly
Set a short reboot interval for testing:
```bash
sudo nano /etc/datawall.conf
# Change: RESTART_INTERVAL=2m
sudo systemctl restart datawall-restart
# Pi will reboot in 2 minutes - watch it work!
# Don't forget to change back to 4h or 6h after testing
```

## Testing

See **[TESTING.md](TESTING.md)** for complete testing procedures including:
- Pre-deployment verification
- Button click accuracy testing
- Physical reboot cycle testing
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

### Firefox Won't Start or Not Fullscreen
```bash
# Check display
echo $DISPLAY  # Should be :0

# Verify X server is running
ps aux | grep X

# Check permissions
ls -la /home/admin/.Xauthority  # or /home/pi/.Xauthority
sudo chown admin:admin /home/admin/.Xauthority
```

### Wrong Button Being Clicked
```bash
# The script auto-detects screen resolution and calculates positions
# Check logs to see where it's clicking:
sudo journalctl -u datawall-restart -n 30 | grep "Clicked"

# You should see: "Clicked top dashboard button at (960, 112)"
# If coordinates look wrong, verify screen resolution:
xrandr | grep '*'

# Increase wait time if page hasn't loaded yet:
sudo nano /etc/datawall.conf
# Set: BUTTON_WAIT_TIME=30
sudo systemctl restart datawall-restart
```

### Button Position Fine-Tuning
Current click positions (for standard 1920x1080):
- **Button 1 (Top)**: 10.4% from top (~112 pixels)
- **Button 2 (Middle)**: 31.25% from top (~337 pixels)
- **Button 3 (Bottom)**: 52% from top (~562 pixels)

These are calculated for buttons occupying the top 5/8ths of screen.

### Service Not Running
```bash
# Check service status
sudo systemctl status datawall-restart

# View detailed logs
sudo journalctl -u datawall-restart -n 50

# Check configuration syntax
bash -n /opt/datawall/datawall-restart.sh

# Verify config file exists
cat /etc/datawall.conf

# Restart service
sudo systemctl restart datawall-restart
```

### Reboot Not Working
```bash
# Check if sudoers file exists
ls -la /etc/sudoers.d/datawall-reboot

# Should contain:
cat /etc/sudoers.d/datawall-reboot
# Output: admin ALL=(ALL) NOPASSWD: /usr/sbin/reboot

# If missing, create it:
sudo bash -c 'echo "admin ALL=(ALL) NOPASSWD: /usr/sbin/reboot" > /etc/sudoers.d/datawall-reboot'
sudo chmod 440 /etc/sudoers.d/datawall-reboot
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

# Physical reboots should fix most connectivity issues automatically
```

## Raspberry Pi Setup Recommendations

### Enable Auto-Login (Required)
```bash
sudo raspi-config
# Select: System Options > Boot / Auto Login > Desktop Autologin
```

### Disable Screen Blanking (Required)
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
static ip_address=192.168.1.10X/24  # Change X for each Pi (101-112)
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
To avoid all 12 Pis rebooting simultaneously:

```bash
# Pi group 1 (Pis 1-4): Every 4 hours
RESTART_INTERVAL=4h

# Pi group 2 (Pis 5-8): Every 4 hours 20 minutes
RESTART_INTERVAL=260m

# Pi group 3 (Pis 9-12): Every 4 hours 40 minutes
RESTART_INTERVAL=280m
```

This spreads reboots across a 1-hour window.

### Custom Click Coordinates (Advanced)
If you have non-standard screen resolution or button layout, edit `/opt/datawall/datawall-restart.sh`:

```bash
sudo nano /opt/datawall/datawall-restart.sh

# Find the click_dashboard_button() function
# Modify the CLICK_Y calculations:

1)  CLICK_Y=$((SCREEN_HEIGHT * 104 / 1000))   # Top button (10.4%)
2)  CLICK_Y=$((SCREEN_HEIGHT * 3125 / 10000)) # Middle (31.25%)
3)  CLICK_Y=$((SCREEN_HEIGHT * 52 / 100))     # Bottom (52%)
```

## Monitoring

### Quick Health Check Script
```bash
#!/bin/bash
# check-pi-status.sh
for i in {101..112}; do
    echo "Checking Pi-$((i-100)) (192.168.1.$i):"
    ssh admin@192.168.1.$i "systemctl is-active datawall-restart && uptime"
done
```

### Log Monitoring
```bash
# View recent activity
sudo journalctl -u datawall-restart --since today

# Check last reboot
sudo journalctl -u datawall-restart | grep "will reboot system" | tail -1

# Monitor live
sudo journalctl -u datawall-restart -f

# Check for errors
sudo journalctl -u datawall-restart --since today | grep -i error
```

### Check Next Reboot Time
```bash
# See when next reboot is scheduled
sudo journalctl -u datawall-restart | grep "Next system reboot" | tail -1
```

## Security Notes

- System runs as `admin` user (non-root) for safety
- Only reboot command requires passwordless sudo
- Configuration file readable by all users (contains no secrets)
- GitHub updates use HTTPS
- No passwords or credentials stored in scripts
- Sudoers file has minimal permissions (440)

## Project Information

- **Repository**: https://github.com/sfcoderep/sfRaspiRestart
- **Ignition Server**: http://sfign01.sf.local:8088
- **Dashboard Project**: SFcncTabletPROD
- **Target Platform**: Raspberry Pi 5
- **OS**: Raspberry Pi OS (Debian-based)
- **Username**: admin (auto-detects admin/pi)

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

## Known Limitations

- Buttons must occupy top 5/8ths of screen (current Ignition layout)
- Click positions are calculated for 3 equal-height buttons
- Physical reboot means brief downtime (~45-60 seconds)
- Auto-update checks once per hour (manual update available)

---

**Version**: 2.0  
**Last Updated**: December 2024  
**Maintained By**: sfcoderep

## Changelog

### v2.0 (December 2024)
- ✨ Added physical system reboot for connectivity fixes
- 🎯 Improved button click accuracy (10.4%, 31.25%, 52% positioning)
- 🖥️ Auto-detection of screen resolution
- 🔧 Dynamic click coordinate calculation
- 👤 Support for both admin and pi usernames
- 📊 Enhanced logging with exact click coordinates

### v1.0 (December 2024)
- 🚀 Initial release
- Basic Firefox restart functionality
- Manual button clicking