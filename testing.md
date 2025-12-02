# Testing Guide for Raspberry Pi Datawall System

## 🧪 Pre-Deployment Testing

Before deploying to all 12 Raspberry Pis, thoroughly test on a single unit.

---

## Phase 1: GitHub Repository Verification

### 1.1 Verify All Files Are Uploaded
```bash
# Clone your repo locally to verify
git clone https://github.com/sfcoderep/sfRaspiRestart.git
cd sfRaspiRestart
ls -la
```

**Expected files:**
- ✅ install.sh
- ✅ datawall-restart.sh
- ✅ datawall-restart.service
- ✅ update.sh
- ✅ datawall.conf
- ✅ README.md
- ✅ .github/workflows/deploy.yml

### 1.2 Test GitHub Actions
```bash
# Make a small change and push
echo "# Test" >> README.md
git add .
git commit -m "Test CI/CD"
git push
```

**Expected:** Green checkmark on GitHub Actions tab

---

## Phase 2: Single Pi Installation Test

### 2.1 Fresh Installation
On your test Raspberry Pi:

```bash
# Run installer
curl -sL https://raw.githubusercontent.com/sfcoderep/sfRaspiRestart/main/install.sh | sudo bash
```

**Expected output:**
```
Installing Raspberry Pi Datawall Auto-Restart System...
Downloading latest files from GitHub...
Creating configuration file...
Installing dependencies...
Setting up automatic updates...
Enabling and starting service...
Installation complete!
```

### 2.2 Verify Installation
```bash
# Check files were created
ls -la /opt/datawall/
ls -la /etc/datawall.conf
ls -la /etc/systemd/system/datawall-restart.service

# Verify cron job was added
sudo crontab -l | grep update.sh
```

**Expected:** All files present, cron job scheduled

---

## Phase 3: Configuration Testing

### 3.1 Edit Configuration
```bash
sudo nano /etc/datawall.conf
```

**Set these values:**
```bash
DASHBOARD_URL="http://sfign01.sf.local:8088/data/perspective/client/SFcncTabletPROD"
RESTART_INTERVAL=2m  # Use 2 minutes for testing
DASHBOARD_SELECTION=1  # Test top button first
BUTTON_WAIT_TIME=10
```

### 3.2 Restart Service
```bash
sudo systemctl restart datawall-restart
```

### 3.3 Watch It Work
```bash
# Monitor logs in real-time
sudo journalctl -u datawall-restart -f
```

**Expected log output:**
```
Dec 02 10:15:23 raspberrypi datawall-restart.sh: 2024-12-02 10:15:23 - Datawall restart service started
Dec 02 10:15:23 raspberrypi datawall-restart.sh: 2024-12-02 10:15:23 - Restart interval: 2m
Dec 02 10:15:23 raspberrypi datawall-restart.sh: 2024-12-02 10:15:23 - Dashboard selection: Button 1
Dec 02 10:15:23 raspberrypi datawall-restart.sh: 2024-12-02 10:15:23 - Stopping Firefox...
Dec 02 10:15:26 raspberrypi datawall-restart.sh: 2024-12-02 10:15:26 - Starting Firefox with URL: http://...
Dec 02 10:15:31 raspberrypi datawall-restart.sh: 2024-12-02 10:15:31 - Firefox started (PID: 1234)
Dec 02 10:15:31 raspberrypi datawall-restart.sh: 2024-12-02 10:15:31 - Waiting 10 seconds for page to load...
Dec 02 10:15:41 raspberrypi datawall-restart.sh: 2024-12-02 10:15:41 - Clicking dashboard button 1...
Dec 02 10:15:41 raspberrypi datawall-restart.sh: 2024-12-02 10:15:41 - Clicked top dashboard button
Dec 02 10:15:42 raspberrypi datawall-restart.sh: 2024-12-02 10:15:42 - Restart cycle complete. Next restart in 2m
```

---

## Phase 4: Functional Verification

### 4.1 Visual Verification Checklist
Watch the screen during restart cycle:

- [ ] Firefox closes completely
- [ ] Firefox reopens in fullscreen/kiosk mode
- [ ] Ignition page loads (button selection screen)
- [ ] Correct button is automatically clicked (after 10 seconds)
- [ ] Dashboard loads successfully
- [ ] Mouse cursor is hidden
- [ ] Screen stays fullscreen (no bars/menus visible)

### 4.2 Test Each Dashboard Button
```bash
# Test button 1 (top)
sudo nano /etc/datawall.conf  # Set DASHBOARD_SELECTION=1
sudo systemctl restart datawall-restart
# Watch screen - does it click the top button?

# Test button 2 (middle)
sudo nano /etc/datawall.conf  # Set DASHBOARD_SELECTION=2
sudo systemctl restart datawall-restart
# Watch screen - does it click the middle button?

# Test button 3 (bottom)
sudo nano /etc/datawall.conf  # Set DASHBOARD_SELECTION=3
sudo systemctl restart datawall-restart
# Watch screen - does it click the bottom button?
```

### 4.3 Timing Tests
```bash
# Wait 2 minutes (your test interval)
# Firefox should automatically restart

# Check logs to confirm
sudo journalctl -u datawall-restart -n 50
```

**Expected:** Restart cycle runs every 2 minutes

---

## Phase 5: Auto-Update Testing

### 5.1 Make a Change on GitHub
```bash
# On your computer, edit datawall-restart.sh
# Change a log message to test updates
nano datawall-restart.sh

# Find this line:
log_message "Datawall restart service started"

# Change to:
log_message "Datawall restart service started - TEST UPDATE"

# Commit and push
git add datawall-restart.sh
git commit -m "Test auto-update functionality"
git push
```

### 5.2 Force Update on Pi
```bash
# Manually trigger update (don't wait for hourly cron)
sudo /opt/datawall/update.sh

# Check if it detected the change
cat /var/log/datawall-update.log
```

**Expected output:**
```
Mon Dec  2 10:30:15 CST 2024: New version detected, updating...
Mon Dec  2 10:30:17 CST 2024: Service restarted with new version
```

### 5.3 Verify Update Applied
```bash
# Check logs for new message
sudo journalctl -u datawall-restart -n 20
```

**Expected:** You should see "TEST UPDATE" in the logs

---

## Phase 6: Click Accuracy Testing

### 6.1 Check Screen Resolution
```bash
xrandr | grep '*'
```

**Common resolutions:**
- 1920x1080 (Full HD)
- 1280x720 (HD)
- 3840x2160 (4K)

### 6.2 Visual Click Test
If buttons aren't being clicked correctly:

```bash
# Test click positions manually
export DISPLAY=:0
xdotool mousemove 960 300 click 1  # Top button
sleep 2
xdotool mousemove 960 540 click 1  # Middle button
sleep 2
xdotool mousemove 960 780 click 1  # Bottom button
```

Watch the screen - does the mouse click the right buttons?

### 6.3 Adjust Click Coordinates
If clicks are off-target, measure your button positions:

**For 1920x1080 screens:**
- Top button: Y = screen_height / 6 = ~300
- Middle button: Y = screen_height / 2 = ~540
- Bottom button: Y = screen_height * 5/6 = ~780

**For 1280x720 screens:**
- Top button: Y = ~200
- Middle button: Y = ~360
- Bottom button: Y = ~520

Edit coordinates in `datawall-restart.sh` if needed.

---

## Phase 7: Stability Testing

### 7.1 Overnight Test
```bash
# Set to 15-minute intervals
sudo nano /etc/datawall.conf  # RESTART_INTERVAL=15m
sudo systemctl restart datawall-restart

# Let it run overnight
# Check logs next morning
sudo journalctl -u datawall-restart --since "yesterday" | grep "Restart cycle complete"
```

**Expected:** Multiple successful restart cycles, no errors

### 7.2 Boot Test
```bash
# Reboot the Pi
sudo reboot

# After reboot, check service auto-started
sudo systemctl status datawall-restart
```

**Expected:** Service is `active (running)`

### 7.3 Network Interruption Test
```bash
# Disconnect network cable for 30 seconds
# Reconnect
# Check if Firefox recovers
sudo journalctl -u datawall-restart -f
```

---

## Phase 8: Final Pre-Deployment Checklist

Before deploying to all 12 Pis:

- [ ] All files uploaded to GitHub
- [ ] GitHub Actions workflow passes
- [ ] Installation script works
- [ ] Service starts automatically
- [ ] Firefox opens in fullscreen
- [ ] Correct dashboard button is clicked
- [ ] All 3 button positions tested and working
- [ ] Auto-restart works at configured interval
- [ ] Auto-update from GitHub works
- [ ] Service survives reboot
- [ ] Logs are clean (no errors)
- [ ] Mouse cursor is hidden
- [ ] Dashboard displays correctly

---

## Common Issues & Solutions

### Issue: Firefox doesn't start
**Solution:**
```bash
# Check display
echo $DISPLAY  # Should be :0

# Check X server
ps aux | grep X

# Check permissions
sudo chown pi:pi /home/pi/.Xauthority
```

### Issue: Button not clicked correctly
**Solution:**
```bash
# Increase wait time
BUTTON_WAIT_TIME=15

# Or adjust click coordinates in script
```

### Issue: Service won't start
**Solution:**
```bash
# Check logs
sudo journalctl -u datawall-restart -n 50

# Verify config file
cat /etc/datawall.conf

# Check script syntax
bash -n /opt/datawall/datawall-restart.sh
```

### Issue: Updates not working
**Solution:**
```bash
# Check cron job
sudo crontab -l

# Check update log
cat /var/log/datawall-update.log

# Test manually
sudo /opt/datawall/update.sh
```

---

## Production Deployment Timeline

Once testing passes:

**Week 1:** Deploy to 3 Pis (one per dashboard type)
**Week 2:** Monitor for issues, adjust as needed
**Week 3:** Deploy to remaining 9 Pis
**Week 4:** Full production monitoring

---

## Success Criteria

✅ **Installation:** All 12 Pis install without errors  
✅ **Functionality:** Each Pi opens correct dashboard  
✅ **Reliability:** 99%+ uptime over 1 week  
✅ **Updates:** All Pis update within 1 hour of GitHub push  
✅ **Performance:** Restart cycles complete in <30 seconds  

---

## Monitoring Commands (Post-Deployment)

```bash
# Quick health check
sudo systemctl status datawall-restart

# Recent logs
sudo journalctl -u datawall-restart -n 50

# Check last restart time
sudo journalctl -u datawall-restart | grep "Restart cycle complete" | tail -1

# Verify auto-update is scheduled
sudo crontab -l | grep update.sh
```