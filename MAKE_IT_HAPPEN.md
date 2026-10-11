# Make It Happen: Pixel (Gemma) → Farm → JARVIS

End-to-end steps so the Neural Farm runs with Gemma on the Pixel and JARVIS uses it.

---

## Overview

- **Pixel:** Runs **InferrLM** with a **Gemma** GGUF model and exposes **Server Mode** on port **8889**.
- **Mac:** Runs the **InferrLM adapter** (OpenAI ↔ InferrLM) and **LiteLLM** on port **4000**. The adapter calls the Pixel; LiteLLM is the single “farm” endpoint.
- **JARVIS:** Gateway on the Mac points at **http://localhost:4000/v1** and uses the farm as its LLM.

So: **Pixel = Gemma brain, Mac = adapter + proxy, JARVIS = same Mac, talks to localhost:4000.**

---

## Step 1: Pixel, InferrLM + Gemma + Server Mode

### 1.1 Get InferrLM and a Gemma model on the Pixel

- **InferrLM:** [InferrLM on GitHub](https://github.com/sbhjt-gr/InferrLM), download the latest APK and install (sideload or store).
- **Gemma GGUF:** Put a Gemma 3 GGUF on the Pixel (e.g. `gemma-3-4b-it-Q4_K_M.gguf`) in **Download** or a folder InferrLM can see. You can push from the Mac:
  ```bash
  cd ~/neural-farm
  source .venv/bin/activate
  python model_sync.py --sync   # syncs ~/Downloads/*.gguf to Pixel (uses adb)
  ```

### 1.2 Open InferrLM and load the model

- Open **InferrLM** → import/load the Gemma GGUF from local storage (e.g. Download).
- Wait until the model is loaded (ready for chat).

### 1.3 Turn on Server Mode

- In InferrLM go to **Server** (or **Settings → Server**).
- Port is usually **8889** (or 8080 if you changed it; we’ll use 8889 below).
- Turn the **Server** switch **ON**.
- Note the message, e.g. `Server running at http://10.1.10.50:8889`.
- **Note your Pixel’s IP** (e.g. **10.1.10.50**). If you don’t know it: on the Pixel, Wi‑Fi → tap the network → IP address. The Mac and Pixel must be on the **same Wi‑Fi**.

### 1.4 Test from the Mac

```bash
curl http://10.1.10.50:8889/api/tags
```

You should see your model listed. If not, check: same Wi‑Fi, InferrLM server ON, firewall/network allows port 8889.

---

## Step 2: Mac, Start the farm (adapter + LiteLLM)

### 2.1 Set the Pixel URL (if your Pixel IP is not 10.1.10.50)

The adapter defaults to `http://10.1.10.50:8889`. If your Pixel has a different IP:

```bash
export PIXEL_URL=http://YOUR_PIXEL_IP:8889
```

(e.g. `export PIXEL_URL=http://192.168.1.42:8889`)

### 2.2 Install deps and start the farm (once per session)

```bash
cd ~/neural-farm
pip install -r requirements.txt   # first time only
./start_farm.sh
```

Leave this running. It starts:

- **InferrLM adapter** on port **8888** (forwards to Pixel 8889, translates OpenAI ↔ InferrLM).
- **LiteLLM proxy** on port **4000** (what Cursor/JARVIS call).

### 2.3 Optional: warm up the Pixel (first request can be slow)

```bash
cd ~/neural-farm
source .venv/bin/activate
python cluster_monitor.py --wake
```

### 2.4 Quick test that the farm answers

```bash
curl -s http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-local-farm" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Say hi in one word."}],"max_tokens":20}'
```

You should get JSON with a reply from Gemma.

---

## Step 3: JARVIS, Point at the farm

### 3.1 Point JARVIS at the farm (localhost:4000 on the Mac)

On the **JARVIS** repo (Mac):

```bash
cd /path/to/JARVIS
node scripts/set-primary-neural-farm.js
```

This sets the gateway’s LLM to the farm at **http://localhost:4000/v1** (and key `sk-local-farm`). If you had set `NEURAL_FARM_BASE_URL` for a remote farm before, unset it or set it to `http://localhost:4000/v1` so the script uses the local farm.

### 3.2 Restart the JARVIS gateway

```bash
node scripts/start-gateway-with-vault.js
```

(or your usual gateway start command).

### 3.3 Use JARVIS

- **Web UI:** `cd apps/jarvis-ui && npm run dev` → open http://localhost:3001.
- **Discord / Cursor MCP / CLI:** Same as usual; they all use the gateway, which now uses the farm (Pixel Gemma).

---

## Checklist

| Step | Where | Action |
|------|--------|--------|
| 1 | Pixel | Install InferrLM, load Gemma GGUF, turn Server ON (port 8889), note Pixel IP |
| 2 | Mac | `cd neural-farm && ./start_farm.sh` (set `PIXEL_URL` if IP ≠ 10.1.10.50) |
| 3 | Mac | `curl http://PIXEL_IP:8889/api/tags` and `curl localhost:4000/v1/chat/completions ...` to confirm |
| 4 | JARVIS | `node scripts/set-primary-neural-farm.js` then restart gateway |
| 5 |, | Use JARVIS (UI, Discord, MCP); completions come from Gemma on the Pixel |

---

## If the Pixel IP changes

- Update **PIXEL_URL** when starting the farm: `PIXEL_URL=http://NEW_IP:8889 ./start_farm.sh`.
- Or edit **inferrlm_adapter.py** default or set `PIXEL_URL` in your shell profile. Then restart the farm (Ctrl+C `start_farm.sh`, run it again).

JARVIS always points at **localhost:4000** on the Mac; only the Mac’s adapter needs the correct Pixel IP.
