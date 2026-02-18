# Neural Farm — Optimized for Development

Quick setup and tips for using the farm while coding.

---

## One command (recommended)

```bash
cd /Users/jeffadkins/neural-farm
./dev_farm.sh
```

- Starts Pixel (+ optional iPhone) adapters with **FARM_DEV=1** (logs completion latency).
- Starts the proxy with **120s timeouts** (no early drop on slow phone).
- **Warms** one short request per node so the first Cursor request isn’t cold.
- Prints Cursor settings and a test `curl`.

Leave that terminal open. Use Cursor with **Base URL** `http://localhost:4000/v1`, **API Key** `sk-local-farm`, **Model** `gpt-4o-mini`.

**Latency:** Pixel ~5–15s first reply (cold), then ~2–5s; iPhone similar. Warm-up reduces the first delay.

---

## Background mode

```bash
./dev_farm.sh --bg
```

Starts everything in the background, runs one warm-up request, then exits. Good for “start once and forget.” Logs: `tail -f /tmp/inferrlm_adapter.log /tmp/litellm.log`.

---

## Optional: .env

Create `.env` in the project root (don’t commit secrets):

```bash
# Optional overrides
IPHONE_IP=169.254.136.118
FARM_DEV=1
```

`dev_farm.sh` sources `.env` if present. Use `.iphone_ip` (one line: IP) if you prefer not to use `.env`.

---

## Timeouts (dev-friendly)

- **config.yaml:** `request_timeout: 120` and per-model `timeout: 120` so the proxy doesn’t kill long-running phone inference.
- **Adapter:** `CHAT_TIMEOUT` (default 120s). Override: `CHAT_TIMEOUT=180 python3 inferrlm_adapter.py`.

---

## Pixel-first routing

Models are listed with **Pixel** first, then iPhone. LiteLLM will try Pixel before iPhone, which is usually faster for dev.

---

## Quick test

```bash
./test_farm.sh
```

Runs status (Pixel/iPhone adapters + proxy) and one completion through the proxy. Or status only: `./test_farm.sh --quick`. Raw curl:

```bash
curl -s -X POST http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hello"}],"max_tokens":20}'
```

Device IPs (e.g. Pixel `10.1.10.50:8889`) are in **.env**; see **LOCAL_DEVICE_IPS.md**.

---

## If the first request is slow

Phones load the model on first use. Either:

- Run `./dev_farm.sh` (it warms once), or  
- Run `python cluster_monitor.py --wake` after starting the farm.

After that, Cursor and other bots should see faster replies.
