# Neural Farm — MacBook + iPhone + Pixel

Use your MacBook as the **orchestrator** for a local "Neural Farm": iPhone 15 Pro Max (MLX/summarization) and Pixel 8 Pro (vision), exposed as a single API to Cursor via LiteLLM + ngrok.

## Quick start

1. **Config**  
   `config.yaml` is set for Pixel at 10.1.10.50. Add iPhone when ready (see comments in file).

2. **Install deps (MacBook)**  
   ```bash
   cd neural-farm
   python3 -m pip install -r requirements.txt
   ```
   **Note:** On Python 3.14+, the proxy uses the asyncio event loop (uvloop is not yet compatible). This is applied automatically in the venv.

3. **On each phone**  
   Run your local LLM server (e.g. “PocketPal AI” or “Local LLM Server”) in **Guided Access** so the screen doesn’t sleep. Ensure it serves an OpenAI-compatible API on port 8080.

4. **Start the farm (MacBook)**  
   **Dev (recommended):** `./dev_farm.sh` — adapters + proxy, warms models, 120s timeouts. See [DEV.md](DEV.md).  
   **Standard:** `./start_farm.sh` — same, no warm-up.  
   (Pixel/iPhone use InferrLM; adapters on Mac translate OpenAI `/v1/*` ↔ InferrLM `/api/chat`.)

5. **Tunnel to Cursor (MacBook, second terminal)**  
   ```bash
   ngrok http 4000
   ```  
   Copy the `https://...ngrok-free.app` URL.

6. **Cursor**  
   - **Settings → Models → OpenAI API Key → Configure**  
   - **Override Base URL:** `https://...ngrok-free.app/v1`  
   - **API Key:** e.g. `sk-local-farm`

7. **Check cluster health (MacBook)**  
   ```bash
   ./farm status      # or ./status.sh — adapters + proxy up/down
   ./farm dashboard   # open http://127.0.0.1:9999 for a quick health page
   python cluster_monitor.py           # one-shot
   python cluster_monitor.py --watch  # every 30s until Ctrl+C
   ```

## Expanded farm: Pixel + iPhone

The farm can run **two nodes** at once:

| Node   | Adapter (Mac) | Device        | Model (InferrLM) |
|--------|----------------|---------------|------------------|
| **Pixel**  | localhost:8888 | 10.1.10.50:8889 | Gemma (GGUF)     |
| **iPhone** | localhost:8887 | IPHONE_IP:8889  | Llama 3.2 (GGUF) |

**config.yaml** lists both: each model name (e.g. `gpt-4o-mini`, `cluster-model`) has two entries — one for Pixel, one for iPhone. **LiteLLM load-balances** across them (same model name → requests distributed across both nodes). Start with iPhone: `export IPHONE_IP=your_iphone_ip && ./start_farm.sh`. See [IPHONE_NODE.md](IPHONE_NODE.md) and [MAKE_IT_HAPPEN.md](MAKE_IT_HAPPEN.md).

---

## Guides

| Doc | Purpose |
|-----|--------|
| **[MAKE_IT_HAPPEN.md](MAKE_IT_HAPPEN.md)** | End-to-end: Pixel (Gemma) → farm → JARVIS. |
| **[ONBOARDING_CURSOR.md](ONBOARDING_CURSOR.md)** | **Start here:** New project onboarding — start farm, set Cursor, pick model. |
| **[CURSOR_FARM.md](CURSOR_FARM.md)** | Step-by-step: get Cursor using the farm (LiteLLM + ngrok + Cursor settings). |
| **[PIXEL_INFERRLM.md](PIXEL_INFERRLM.md)** | Use **InferrLM** on the Pixel (port 8889). Adapter on Mac translates OpenAI ↔ InferrLM. |
| **[IPHONE_NODE.md](IPHONE_NODE.md)** | Add iPhone as a second node: set **IPHONE_IP**, run `./start_farm.sh`. |
| **[DEV.md](DEV.md)** | Dev-optimized: `./dev_farm.sh`, timeouts, warm-up, `.env`. |
| **[OTHER_BOTS_FARM.md](OTHER_BOTS_FARM.md)** | How to point any OpenAI-compatible bot or app at the farm (Python, Node, Discord, LangChain, etc.). |
| **[ROADMAP_FEB2026.md](ROADMAP_FEB2026.md)** | Feb 2026: ideas to improve value (streaming, status, use cases, 2026 stack). |
| **[USE_CASES.md](USE_CASES.md)** | Use cases, cost framing, privacy/speed pitch. |
| **[KEEP_RUNNING.md](KEEP_RUNNING.md)** | **Keeping the system up:** start farm, keep IPs in .env, keep InferrLM running on devices. |
| **[NEW_NETWORK.md](NEW_NETWORK.md)** | New network: update Pixel/iPhone IPs and restart the farm. |
| **[docs/SCHEDULED_WARMUP.md](docs/SCHEDULED_WARMUP.md)** | Optional launchd/cron warm-up (e.g. 8am). |

## Project layout

| File | Purpose |
|------|--------|
| `config.yaml` | LiteLLM model list; routes to adapter at localhost:8888 (adapter → Pixel 8889) |
| `inferrlm_adapter.py` | Translates OpenAI `/v1/*` ↔ InferrLM `/api/chat` and `/api/tags` |
| `start_farm.sh` | Start adapter + LiteLLM proxy in one go |
| `farm` | CLI: `farm status` \| `farm start` \| `farm start-bg` \| `farm warmup` \| `farm dashboard` |
| `status.sh` | Quick check: adapters + proxy up/down; suggests `./dev_farm.sh` if down |
| `sniff_devices.sh` | Scan Wi‑Fi for Pixel/iPhone (InferrLM :8889); `--all` = other subnets (guest); `--write` updates .env |
| `config-dev-pixel-only.yaml` | Pixel-only proxy config for predictable single-node dev |
| `health_dashboard.py` | Minimal health page at http://127.0.0.1:9999 (`./farm dashboard`) |
| `templates/` | `NEW_PROJECT_FARM.md`, `cursorrules_farm_snippet.txt` for new projects |
| `cluster_monitor.py` | Health check for each node; run from MacBook |
| `model_sync.py` | List/sync GGUF on Pixel via adb (see [PIXEL_INFERRLM.md](PIXEL_INFERRLM.md)) |
| `.cursorrules` | Brief for Cursor so the bot knows it’s orchestrating the farm |
| `requirements.txt` | `litellm[proxy]`, `requests`, `PyYAML` |

## Latency expectations

**Typical:** Pixel ~5–15s first reply (cold model load), then ~2–5s. iPhone similar. Use `./dev_farm.sh` to warm models and reduce first-request delay.

---

## Use cases

- **Cursor** — Coding, chat, Composer; use farm model (e.g. gpt-4o-mini) for free on-device inference.
- **Other bots** — Discord, Slack, scripts, LangChain; point at `http://localhost:4000/v1` + `sk-local-farm`.
- **Echeo / Olive** — Vision and product flows; farm as backend (e.g. receipt analysis on Pixel).
- **Privacy & speed** — No code or prompts leave your devices; first reply ~5–15s (cold), then ~2–5s.

## Summary

- **Phones:** Local LLM server + Guided Access.
- **MacBook:** LiteLLM proxy (`litellm --config config.yaml --port 4000`) + ngrok tunnel.
- **Cursor:** Single “virtual” endpoint via the ngrok URL; the bot is briefed via `.cursorrules` for Echeo/Olive and device roles (iPhone = summarization/MLX, Pixel = vision).
