# Get Cursor Talking to the Neural Farm

Use Cursor’s chat/completions against your local Pixel (and iPhone when you add it) via the MacBook proxy.

---

## Prerequisites

- **Pixel:** PocketPal running, server on **port 8080**, same Wi‑Fi as MacBook (you’re good).
- **MacBook:** In `neural-farm`, venv with deps and ngrok installed.

---

## Step 1, Start the farm on the MacBook

**Terminal 1, LiteLLM proxy**

```bash
cd ~/neural-farm
source .venv/bin/activate
litellm --config config.yaml --port 4000
```

Leave this running. You should see LiteLLM start and listen on 4000.

**Terminal 2, ngrok tunnel**

```bash
ngrok http 4000
```

Leave this running. In the ngrok output, copy the **HTTPS** URL, e.g.:

`https://abc123xyz.ngrok-free.app`

Your Cursor base URL will be that + `/v1`, e.g. `https://abc123xyz.ngrok-free.app/v1`.

---

## Step 2, Point Cursor at the farm

1. In **Cursor:** open **Settings** (Cmd + ,).
2. Go to **Models** (or search “Models” / “OpenAI”).
3. Find **OpenAI API Key** (or “OpenAI”) → **Configure** / **Override**.
4. Set:
   - **Override Base URL:** `https://YOUR-NGROK-URL/v1`  
     Example: `https://abc123xyz.ngrok-free.app/v1`
   - **API Key:** `sk-local-farm` (any value is fine; LiteLLM doesn’t validate it)
5. Save.

---

## Step 3, Use the farm model in Cursor

- In chat or completions, choose a model that uses this endpoint (e.g. the one you configured to use the Override Base URL).
- Your requests will go: **Cursor → ngrok → MacBook (LiteLLM:4000) → Pixel (PocketPal:8080)**.

**Quick check:** Send a simple prompt in Cursor. If the farm is up, you’ll get a response from the Pixel. If you see connection/504 errors, ensure both terminals (LiteLLM + ngrok) are running and the Pixel’s PocketPal server is on.

---

## Optional, Health check before using Cursor

```bash
cd ~/neural-farm
source .venv/bin/activate
python cluster_monitor.py
```

You want at least one node `[UP]`. Then start LiteLLM and ngrok.

---

## Summary

| Where        | What runs |
|-------------|-----------|
| **Pixel**   | PocketPal, server on 8080, same Wi‑Fi |
| **MacBook** | Terminal 1: `litellm --config config.yaml --port 4000` |
| **MacBook** | Terminal 2: `ngrok http 4000` |
| **Cursor**  | Settings → Models → Override Base URL = `https://YOUR-NGROK-URL/v1`, API Key = `sk-local-farm` |

After that, Cursor is talking to the farm.
