# Cursor + Neural Farm, Do This Now

The LiteLLM proxy is running on port 4000. Finish the setup so Cursor uses the farm.

---

## 1. Start ngrok (you must add your authtoken first)

If you haven’t already:

```bash
ngrok config add-authtoken YOUR_TOKEN
```

Get your token: https://dashboard.ngrok.com/get-started/your-authtoken

Then in a **second terminal**:

```bash
ngrok http 4000
```

Copy the **HTTPS** URL it shows, e.g. `https://abc123.ngrok-free.app`.

Your Cursor base URL = that URL + `/v1`, e.g. `https://abc123.ngrok-free.app/v1`.

---

## 2. Point Cursor at the farm (manual, Cursor doesn’t store this in settings.json)

1. In **Cursor:** **Settings** (Cmd + ,) → **Models**.
2. Find **OpenAI** → **Configure** / **Override**.
3. Set:
   - **Override Base URL:** `https://YOUR-NGROK-URL/v1`
   - **API Key:** `sk-local-farm`
4. Save.

Use a model that uses this endpoint; requests will go: Cursor → ngrok → MacBook (4000) → Pixel (8080).

---

## Summary

| Step | Action |
|------|--------|
| 1 | `ngrok config add-authtoken YOUR_TOKEN` (once) |
| 2 | `ngrok http 4000` (leave running) |
| 3 | Cursor → Settings → Models → Override Base URL = `https://XXXX.ngrok-free.app/v1`, API Key = `sk-local-farm` |

Done.
