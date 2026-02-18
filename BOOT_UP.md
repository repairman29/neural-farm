# How to boot up the Neural Farm

**One doc:** from zero to “farm is running and I can use it in Cursor (or ngrok).” Use this when you sit down to work or after a reboot.

---

## Prerequisites (one-time)

| Step | What to do |
|------|------------|
| **1. Clone the repo** | `git clone https://github.com/repairman29/neural-farm.git && cd neural-farm` (or you already have it). |
| **2. Install Python deps** | `python3 -m pip install -r requirements.txt` (or use the project venv). |
| **3. Phones** | On **Pixel** (and **iPhone** if you use it): install InferrLM (or your LLM server). Ensure it serves an **OpenAI-compatible API on port 8889**. Run it in **Guided Access** so the screen doesn’t sleep. |
| **4. Device IPs** | Create `.env` in the repo root (see `.env.example`). Set `PIXEL_URL=http://YOUR_PIXEL_IP:8889` and optionally `IPHONE_IP=...`. **Finding IPs:** run `./sniff_devices.sh` (or `--write` to update `.env`). On a **new network**, see [NEW_NETWORK.md](NEW_NETWORK.md). |
| **5. Config** | Default `config.yaml` is fine. For Pixel-only dev you can use `config-dev-pixel-only.yaml` (see [DEV.md](DEV.md)). |

---

## Every time you boot the farm

| Step | Command / action |
|------|-------------------|
| **1. Start the farm** | From the repo: `./dev_farm.sh` (leave the terminal open) or `./dev_farm.sh --bg` (runs in background and exits). |
| **2. Confirm it’s up** | `./farm status` or `./status.sh`. You want **Pixel (8888): up** and **Proxy (4000): up**. Optional: `./farm dashboard` → open http://127.0.0.1:9999. |
| **3. (Optional) Tunnel for remote Cursor** | In a second terminal: `ngrok http 4000`. Use the `https://...ngrok-free.app` URL as Base URL in Cursor (with `/v1`), e.g. `https://xxx.ngrok-free.app/v1`. |
| **4. Use it** | **Local Cursor:** Base URL `http://localhost:4000/v1`, API Key `sk-local-farm`, model e.g. **gpt-4o-mini**. **Remote:** use the ngrok URL from step 3. See [ONBOARDING_CURSOR.md](ONBOARDING_CURSOR.md) for Cursor settings. |

---

## One-line “I just want to start it”

```bash
cd /path/to/neural-farm && ./dev_farm.sh
```

Leave that terminal open. Then in Cursor: Base URL `http://localhost:4000/v1`, API Key `sk-local-farm`, pick the farm model (e.g. gpt-4o-mini).

---

## If something’s wrong

| Symptom | What to do |
|---------|------------|
| **Connection refused / proxy down** | Restart: `pkill -f inferrlm_adapter; pkill -f "litellm --config config.yaml"; ./dev_farm.sh` |
| **502 / Host is down** | Device IPs changed. Run `./sniff_devices.sh --write`, then restart the farm (see above). |
| **First request very slow** | Normal (cold model load). Use `./dev_farm.sh` (it warms once) or `python cluster_monitor.py --wake`. After that, ~2–5s. |
| **New Wi‑Fi / new network** | Update IPs: [NEW_NETWORK.md](NEW_NETWORK.md). Then `./sniff_devices.sh --write` and restart. |

More: [KEEP_RUNNING.md](KEEP_RUNNING.md), [ONBOARDING_CURSOR.md](ONBOARDING_CURSOR.md) (“How do we know if it’s working?”).

---

## Optional: start the farm automatically

- **Scheduled (e.g. 8am):** [docs/SCHEDULED_WARMUP.md](docs/SCHEDULED_WARMUP.md) (launchd or cron).
- **Single starter (no double start):** [ONE_STARTER.md](ONE_STARTER.md) — e.g. only cron runs `./dev_farm.sh --bg`; LaunchAgent unloaded.

---

## Doc map (where to read more)

| Doc | When to use it |
|-----|----------------|
| **[README.md](README.md)** | Overview, quick start, project layout, latency, use cases. |
| **[BOOT_UP.md](BOOT_UP.md)** | **This doc** — full “how to boot up” checklist. |
| **[DEV.md](DEV.md)** | Dev mode: one command, background, timeouts, quick test. |
| **[ONBOARDING_CURSOR.md](ONBOARDING_CURSOR.md)** | Cursor: start farm, set Base URL/key, pick model, verify. |
| **[KEEP_RUNNING.md](KEEP_RUNNING.md)** | Keeping farm up: IPs, InferrLM on devices, restart. |
| **[NEW_NETWORK.md](NEW_NETWORK.md)** | New network: update Pixel/iPhone IPs and restart. |
| **[CURSOR_FARM.md](CURSOR_FARM.md)** | Step-by-step Cursor + LiteLLM + ngrok. |
| **[PIXEL_INFERRLM.md](PIXEL_INFERRLM.md)** | InferrLM on Pixel, port 8889, adapter. |
| **[docs/SCHEDULED_WARMUP.md](docs/SCHEDULED_WARMUP.md)** | Optional launchd/cron warm-up. |
