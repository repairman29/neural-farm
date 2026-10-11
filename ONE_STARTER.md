# One starter for the farm

Only **one** thing should start the neural farm, so multiple bots/scripts don’t fight over adapters and the proxy.

---

## How it works

- **`./dev_farm.sh --bg`** uses a **lock file** (`/tmp/neural-farm-start.lock`). If another start is already running, a second call exits immediately with “Another start already in progress.”
- **Single starter:** The **hourly cron** (in your JARVIS crontab) runs `dev_farm.sh --bg`. That is the only scheduled starter.
- The **farm LaunchAgent** (`com.jarvis.neural-farm`) is **unloaded** so it does not start the farm at login. Only the cron starts the farm.

Result: one process (cron at the top of each hour) starts or refreshes the farm; no LaunchAgent, no duplicate manual runs, no “Address already in use.”

---

## If you want the farm at login again

1. Load the LaunchAgent:  
   `launchctl load ~/Library/LaunchAgents/com.jarvis.neural-farm.plist`
2. **Remove** the farm keeper cron line from crontab so only the LaunchAgent starts the farm (one starter).
3. Or keep both: the lock ensures only one `dev_farm.sh --bg` runs at a time, so cron and LaunchAgent would not run concurrently; the second would exit immediately.

---

## Manual start (interactive)

- **Foreground (one terminal):** `./dev_farm.sh`, proxy runs in that terminal; adapters in background.
- **Background:** `./dev_farm.sh --bg`, if cron (or another run) is already starting the farm, this exits; otherwise it starts and holds the lock until done.
