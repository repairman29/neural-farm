# Neural Farm — Step-by-step guide

**Use this as your single checklist.** The project is already set up; follow the steps below where **you** need to act.

---

## What’s already done (no action needed)

- **Project folder** `neural-farm` with config, monitor script, and Cursor rules
- **`config.yaml`** — LiteLLM config (you’ll only add your phone IPs)
- **`cluster_monitor.py`** — Health check for iPhone and Pixel
- **`.cursorrules`** — Cursor is briefed as the farm orchestrator for Echeo/Olive
- **`requirements.txt`** — Python deps listed

---

## Your steps (in order)

### Step 1 — Install tools on your MacBook

**1.1** Open Terminal and go to the project:

```bash
cd /Users/jeffadkins/neural-farm
```

**1.2** Create a virtual environment (recommended) and install Python deps:

```bash
python3 -m venv .venv
source .venv/activate
pip install -r requirements.txt
```

**1.3** Install ngrok if you don’t have it:

- Option A: `brew install ngrok`  
- Option B: Download from [ngrok.com](https://ngrok.com) and put `ngrok` in your PATH  

**Check:** Run `ngrok version` — it should print a version.

---

### Step 2 — Get your phones’ IP addresses

**2.1** Put both phones on the **same Wi‑Fi** as your MacBook.

**2.2** Find each device’s local IP:

- **iPhone:** Settings → Wi‑Fi → tap (i) next to your network → IP Address (e.g. `192.168.1.42`)
- **Pixel:** Settings → Network & internet → Internet → your Wi‑Fi → IP address

**2.3** Edit `config.yaml` in this project and replace the placeholders:

- Replace `192.168.1.PHONE_IP` with the iPhone IP (e.g. `192.168.1.42`)
- Replace `192.168.1.PIXEL_IP` with the Pixel IP (e.g. `192.168.1.55`)

If your network uses a different subnet (e.g. `10.0.0.x`), use that instead of `192.168.1.x`.

**Check:** Run `python check_ready.py` — it should say config IPs are set (or tell you what’s missing).

---

### Step 3 — Start the LLM servers on the phones

**3.1** On each phone, open the app that serves the local LLM (e.g. “PocketPal AI”, “Local LLM Server”, or whatever exposes an OpenAI-compatible API on port **8080**).

**3.2** Start the server in the app (often a “Start server” or similar).

**3.3** Enable **Guided Access** (iPhone) or equivalent “keep screen on” (Pixel) so the device doesn’t sleep and kill the server.

**Check (from MacBook):** In the project folder, run:

```bash
python cluster_monitor.py
```

You want to see at least one node as `[UP]`. If both show `[DOWN]`, the phones aren’t reachable or the server isn’t on port 8080 — double-check IPs and app settings.

---

### Step 4 — Start the LiteLLM proxy on your MacBook

**4.1** In Terminal, in the project folder with the venv activated:

```bash
cd /Users/jeffadkins/neural-farm
source .venv/activate
litellm --config config.yaml --port 4000
```

Leave this running. You should see LiteLLM start and listen on port 4000.

---

### Step 5 — Start the ngrok tunnel (second terminal)

**5.1** Open a **second** Terminal window/tab.

**5.2** Run:

```bash
ngrok http 4000
```

**5.3** In the ngrok output, find the **HTTPS** URL, e.g.:

`https://abc123.ngrok-free.app`

Copy that URL (without any path). You’ll use it in Cursor as:

`https://abc123.ngrok-free.app/v1`

Leave ngrok running.

---

### Step 6 — Point Cursor at your farm

**6.1** In Cursor: open **Settings** (Cmd+,).

**6.2** Go to **Models** (or search for “OpenAI”).

**6.3** Find **OpenAI API Key** → click **Configure** (or “Override”).

**6.4** Set:

- **Override Base URL:** `https://YOUR-NGROK-URL/v1` (e.g. `https://abc123.ngrok-free.app/v1`)
- **API Key:** `sk-local-farm` (or any string; LiteLLM doesn’t validate it)

**6.5** Save. Use a model that matches your proxy (e.g. the model name you use in LiteLLM, like `cluster-model` if you use that).

**Check:** In Cursor, start a chat that uses this model; a request should hit your MacBook → LiteLLM → one of the phones.

---

### Step 7 — (Optional) Watch cluster health

In a **third** terminal, from the project folder:

```bash
source .venv/activate
python cluster_monitor.py --watch
```

This prints a health line for each phone every 30 seconds. Ctrl+C to stop.

---

## Quick reference — what runs where

| Where        | What to run |
|-------------|-------------|
| **iPhone**  | Local LLM app, server on port 8080, Guided Access on |
| **Pixel**   | Local LLM app, server on port 8080, keep screen on |
| **MacBook terminal 1** | `litellm --config config.yaml --port 4000` |
| **MacBook terminal 2** | `ngrok http 4000` |
| **MacBook terminal 3 (optional)** | `python cluster_monitor.py --watch` |

---

## If something doesn’t work

- **cluster_monitor shows DOWN:** Phones and Mac on same Wi‑Fi? Correct IPs in `config.yaml`? LLM server actually running on 8080?
- **Cursor gets errors:** Base URL must end with `/v1`. ngrok and LiteLLM must both be running.
- **LiteLLM won’t start:** Run `pip install -r requirements.txt` again; confirm `config.yaml` has valid IPs (no `PHONE_IP` / `PIXEL_IP` left).
- **ngrok asks for signup:** Free signup at ngrok.com; then `ngrok config add-authtoken YOUR_TOKEN`.

When in doubt, run `python check_ready.py` and follow the messages.
