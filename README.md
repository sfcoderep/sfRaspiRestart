# Raspberry Pi Datawall Auto-Restart System

Automated system for managing 12 Raspberry Pi 5 datawalls with periodic restarts and Ignition SCADA dashboard display.

## Features

- 🔄 Automatic Firefox restart every 4-6 hours (configurable)
- 🌐 Opens Ignition SCADA dashboard in fullscreen kiosk mode
- 🚀 Auto-deploys updates from GitHub
- 📊 Systemd service for reliability
- 🔧 Easy configuration management

## Quick Start

### One-Line Installation

Run this command on each Raspberry Pi as root:
```bash
curl -sL https://raw.githubusercontent.com/sfcoderep/sfRaspiRestart/main/install.sh | sudo bash
```

### Configuration

1. Edit the configuration file:
```bash
sudo nano /etc/datawall.conf
```

2. Set your Ignition dashboard URL:
```bash
DASHBOARD_URL="http://your-server:8088/data/perspective/client/YourProject"
RESTART_INTERVAL=4h
```

3. Restart the service:
```bash
sudo systemctl restart datawall-restart
```

## Manual Installation

If you prefer step-by-step installation:
```bash
# Clone repository
cd /opt
sudo git clone https://github.com/sfcoderep/sfRaspiRestart.git datawall

# Run installer
cd datawall
sudo chmod +x install.sh
sudo ./install.sh
```

## Management Commands

### Check Status
```bash
sudo systemctl status datawall-restart
```

### View Logs
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

## Configuration Options

Edit `/etc/datawall.conf`:

| Option | Description | Example |
|--------|-------------|---------|
| `DASHBOARD_URL` | Your Ignition dashboard URL | `http://10.0.0.100:8088/data/perspective/client/Main` |
| `RESTART_INTERVAL` | Time between restarts | `4h`, `6h`, `300m`, `21600s` |

## How It Works

1. **Systemd Service**: Runs `datawall-restart.sh` on boot
2. **Main Script**: Kills Firefox and reopens dashboard every X hours
3. **Auto-Update**: Cron job checks GitHub hourly for updates
4. **Kiosk Mode**: Firefox runs fullscreen with hidden cursor

## File Structure
```
/opt/datawall/
├── datawall-restart.sh    # Main restart script
├── update.sh              # Auto-update script
└── install.sh             # Installation script

/etc/
├── datawall.conf          # Configuration file
└── systemd/system/
    └── datawall-restart.service  # Systemd service
```

## Deployment Workflow

### Push Updates
Simply push changes to your GitHub repository:
```bash
git add .
git commit -m "Update restart interval"
git push origin main
```

All Raspberry Pis will automatically pull updates within 1 hour.

### Force Immediate Update
On any Pi:
```bash
sudo /opt/datawall/update.sh
```

## Troubleshooting

### Firefox Won't Start
```bash
# Check display is available
echo $DISPLAY

# Verify X server
ps aux | grep X

# Check permissions
ls -la /home/pi/.Xauthority
```

### Service Not Running
```bash
# Check service status
sudo systemctl status datawall-restart

# View detailed logs
sudo journalctl -u datawall-restart -n 50

# Restart service
sudo systemctl restart datawall-restart
```

### Updates Not Working
```bash
# Check cron job
sudo crontab -l

# Manually test update
sudo /opt/datawall/update.sh

# Check update logs
sudo tail -f /var/log/datawall-update.log
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

### Set Static IP
Edit `/etc/dhcpcd.conf`:
```
interface eth0
static ip_address=192.168.1.XX/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1
```

## Security Notes

- System runs as `pi` user (non-root)
- Only update script needs root for service restart
- Configuration file readable by all users
- GitHub updates use HTTPS

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - feel free to modify and distribute

## Support

For issues or questions:
- Open an issue on GitHub
- Check logs: `sudo journalctl -u datawall-restart -f`
- Verify configuration: `cat /etc/datawall.conf`