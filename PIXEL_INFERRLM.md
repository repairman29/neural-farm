# Pixel 8 Pro as a Neural Farm Node: InferrLM (Server Mode)

PocketPal runs models locally but **does not expose an API**-nothing listens on port 8080. To turn your Pixel into a real network node, use an app that has **Server Mode** with an OpenAI-compatible API.

**InferrLM** (formerly Inferra) is the recommended replacement for the Pixel side: free, open-source, and built for this use case.

---

## Why InferrLM

- **Cost:** $0 (open-source).
- **Server Mode:** Toggle on in the app; it listens on port **8080** (or your choice) with a full **OpenAI-compatible** API.
- **Same models:** Point it at the **Gemma 3 GGUF** you already have (e.g. in `/sdcard/Download/`). No need to re-download.
- **Lighter than PocketPal:** React Native + Expo; more RAM for the model, device runs cooler.

---

## Setup

### 1. Get InferrLM

- **APK:** [InferrLM on GitHub](https://github.com/sbhjt-gr/InferrLM), download the latest release APK and sideload, or install from the store if listed.
- **Model:** Use the same **Gemma 3 4B GGUF** you pushed for PocketPal (e.g. `gemma-3-4b-it-Q4_K_M.gguf` in `Download`). In the app, import from local storage (e.g. **Download** folder).

### 2. Start the server on the Pixel

1. Open **InferrLM** and load your Gemma model.
2. Go to the **Server** tab (or **Settings → Server**).
3. InferrLM’s **default port is 8889** (you can change it to 8080 in the app if you prefer; then update `config.yaml` to match).
4. Turn the **Server** switch **ON**.
5. Confirm the message, e.g. `Server running at http://10.1.10.50:8889`.

### 3. Test from the MacBook (native InferrLM API)

```bash
curl http://10.1.10.50:8889/api/tags
```

If you see your model listed, the Pixel node is live. InferrLM uses **`/api/chat`** and **`/api/tags`**, not OpenAI’s `/v1/...`. So we run an **adapter** on the Mac that translates OpenAI format ↔ InferrLM.

### 4. Start the farm (adapter + proxy)

On the Mac, from the project folder:

```bash
./start_farm.sh
```

That starts the **InferrLM adapter** (port 8888) and the **LiteLLM proxy** (port 4000). Cursor uses `http://localhost:4000/v1`; the proxy talks to the adapter, which talks to the Pixel.

---

## Optional: Sync and verify from the Mac

Use **model_sync.py** in this repo to:

- List GGUF files on the Pixel (via `adb`).
- Sync `~/Downloads/*.gguf` to the device.
- Verify the Pixel’s `/v1/models` endpoint returns the expected model.

```bash
cd ~/neural-farm
source .venv/bin/activate
python model_sync.py --list
python model_sync.py --sync
python model_sync.py --verify
```
(`model_sync.py` defaults to port 8889. To use 8080 instead, run `PIXEL_PORT=8080 python model_sync.py --verify`.)

---

## Summary

| Before (PocketPal)     | After (InferrLM)        |
|------------------------|-------------------------|
| Chat only, no API      | Server on port 8889 (or 8080) |
| Mac proxy → connection refused | Mac proxy → Pixel responds |
| Neural Farm blocked   | Pixel is a real node    |

### Optional: Warm up the node (model loaded in RAM)

InferrLM lazy-loads: the first request can be slow. To “wake” the model before sending real work:

```bash
python cluster_monitor.py --wake
```

This hits each up node with a tiny completion so the model is loaded. Use before routing Echeo/Olive tasks.

Once InferrLM is running in Server Mode, the “Not Working” part of the [status update](README.md#summary) is resolved: something is listening on 8080, and Cursor can use the farm.
