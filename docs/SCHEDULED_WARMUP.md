# Scheduled warm-up (optional)

Run a warm-up request every morning so the first Cursor request isn’t cold.

---

## Option A: launchd (macOS, recommended)

1. Create the plist (replace `YOUR_USER` and path if needed):

```bash
cat > ~/Library/LaunchAgents/com.neuralfarm.warmup.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.neuralfarm.warmup</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/env</string>
    <string>bash</string>
    <string>-c</string>
    <string>cd ~/neural-farm && source .venv/bin/activate && python cluster_monitor.py --wake</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>8</integer>
    <key>Minute</key>
    <integer>0</integer>
  </dict>
  <key>StandardOutPath</key>
  <string>/tmp/neuralfarm_warmup.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/neuralfarm_warmup.err</string>
</dict>
</plist>
EOF
```

2. Load it:

```bash
launchctl load ~/Library/LaunchAgents/com.neuralfarm.warmup.plist
```

3. To disable later: `launchctl unload ~/Library/LaunchAgents/com.neuralfarm.warmup.plist`

---

## Option B: cron

```bash
crontab -e
```

Add (runs at 8:00 every day; adjust path):

```
0 8 * * * cd ~/neural-farm && source .venv/bin/activate && python cluster_monitor.py --wake >> /tmp/neuralfarm_warmup.log 2>&1
```

---

**Note:** The farm (adapters + proxy) must already be running for warm-up to do anything. Start the farm with `./dev_farm.sh` or `./start_farm.sh` before 8am, or run warm-up manually after starting.
