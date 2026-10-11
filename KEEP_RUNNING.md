# Keeping the Neural Farm up and running

What you need to do so the farm stays reliable.

---

## 1. Start the farm (each time you need it)

The farm does **not** run as a system service by default. Start it when you sit down to work:

```bash
cd ~/neural-farm
./dev_farm.sh
```

Leave that terminal open. Or run `./dev_farm.sh --bg` to start everything in the background and close the terminal.

**Optional, keep it running across reboots/sleep:** Use [docs/SCHEDULED_WARMUP.md](docs/SCHEDULED_WARMUP.md) or a launchd plist to start the farm at login. For most use, starting it manually when you need it is enough.

---

## 2. Keep device IPs correct in `.env`

The farm talks to your Pixel (and iPhone) using IPs in **`.env`**. If those IPs change, the farm will get 502 / “Host is down” until you update `.env` and restart.

**When IPs can change:**

- Router gave the device a new DHCP address
- You switched network (e.g. new location)
- Device reconnected and got a different IP

**What to do:**

1. **Update `.env`** with the current IPs. Either:
   - Run `./sniff_devices.sh` to see found devices, then edit `.env` by hand, or  
   - Run `./sniff_devices.sh --write` to overwrite `PIXEL_URL` and `IPHONE_IP` in `.env` with what was found.
2. **Restart the farm** so the adapters pick up the new values:
   ```bash
   pkill -f inferrlm_adapter
   pkill -f "litellm --config config.yaml"
   ./dev_farm.sh
   ```
   (Or `./dev_farm.sh --bg`.)

**Optional:** In your router, set **DHCP reservations** for the Pixel and iPhone so they always get the same IP and you rarely need to touch `.env`.

---

## 3. Keep InferrLM running on the devices

The **Pixel** (and **iPhone** if you use it) must have **InferrLM** (or your LLM server app) running and serving on port **8889**. If the app is closed or the OS kills it, the farm will get timeouts or “Host is down.”

- Open the app and start the server (port 8889).
- If the device sleeps or the app is backgrounded, some OSes may suspend it; you may need to keep the app in foreground or adjust power/sleep settings if you want it always ready.

---

## 4. If something stops working

1. **Restart the farm**  
   `pkill -f inferrlm_adapter; pkill -f "litellm --config config.yaml"; ./dev_farm.sh`
2. **Check IPs**  
   `./sniff_devices.sh`, if your devices don’t show up, fix network/app, then update `.env` and restart again.
3. **Check status**  
   `./status.sh`, if you see “down,” remember the adapters are single-threaded; they can show “down” while busy. Try the completion test in [ONBOARDING_CURSOR.md](ONBOARDING_CURSOR.md) (“How do we know if it’s working?”).

---

## Summary

| To keep the system up | Action |
|------------------------|--------|
| **Farm process** | Start with `./dev_farm.sh` (or `--bg`) when you need it; restart if it dies. |
| **Device IPs** | Keep `PIXEL_URL` and `IPHONE_IP` in `.env` correct; run `./sniff_devices.sh --write` and restart the farm when IPs change. |
| **Devices** | Keep InferrLM (or your server app) running on port 8889 on each device. |
