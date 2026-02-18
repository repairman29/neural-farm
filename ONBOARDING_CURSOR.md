# Neural Farm — Onboarding for Cursor (New Project)

Use your local Neural Farm (Pixel + optional iPhone) from Cursor in any project. Do this once per Cursor install; then in every new project you only need to pick the farm model.

---

## 1. Start the farm (once per session)

In a terminal, from the farm repo:

```bash
cd /Users/jeffadkins/neural-farm
./dev_farm.sh
```

Leave that terminal open. You should see something like:

- `Pixel adapter: up`
- `Proxy starting`
- **Ready. Cursor: Base URL = http://localhost:4000/v1 …**

If the farm is already running (e.g. from another terminal), you can skip this step.

**Background option:** `./dev_farm.sh --bg` — starts everything in the background and exits.

---

## 2. Configure Cursor (once per Cursor install)

1. **Cursor** → **Settings** (Cmd + ,).
2. Search or go to **Models** (OpenAI / API).
3. Set:
   - **Override Base URL:** `http://localhost:4000/v1`
   - **API Key:** `sk-local-farm`
4. Save.

You only need to do this once per Cursor install; it applies to every project.

---

## 3. In every project / chat

When you open a **new project** or a new chat:

1. Open the **model dropdown** (Chat or Composer).
2. Choose a model that uses your **custom endpoint**, e.g. **GPT-4o mini** or **GPT-3.5 Turbo**.
3. Do **not** choose Cursor Pro, Claude, or other premium models — those ignore the override and use paid APIs.

That’s it. Requests go: **Cursor → localhost:4000 → your Pixel (and iPhone if configured)**.

---

## Quick test (any project)

In a terminal (farm can be on another machine, but Cursor and this terminal on same Mac):

```bash
curl -s -X POST http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hello"}],"max_tokens":20}'
```

You should get JSON with an assistant reply. If you get connection refused, start the farm (step 1).

---

## How do we know if it’s working?

**1. Farm status (adapters + proxy)**

From the neural-farm folder:

```bash
cd /Users/jeffadkins/neural-farm
./status.sh
```

You want to see `Pixel (8888): up`, and `Proxy (4000): up`.

**Test both Pixel and proxy (one completion):**

```bash
./test_farm.sh
```

This runs status, checks the Pixel device URL from `.env`, and sends one short completion through the proxy. Use `./test_farm.sh --quick` for status only. Device IPs are noted in **LOCAL_DEVICE_IPS.md** (e.g. Pixel at `10.1.10.50:8889` in `.env`). If the iPhone is configured, `iPhone (8887): up` too. “Up” means the process is running and answering `/health`; it does **not** guarantee the **phone** is reachable (see step 2).

**If status shows “down” but you know the farm is running:** The adapters are single-threaded. While one is handling a long completion (e.g. talking to the Pixel for 30+ seconds), it can’t answer `/health`, so status may report “down” until that request finishes. Run status again when the farm is idle, or rely on the completion test (step 2) to confirm it’s working.

**2. Real completion (farm actually talking to the device)**

Run the same quick test as above — but this time you care about the **response body**:

```bash
curl -s -X POST http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Say OK"}],"max_tokens":5}'
```

- **Working:** JSON with `"choices":[{"message":{"content":"…"}}]` and some short text (e.g. “OK” or “Okay”). The first run can take 1–3+ minutes; later ones are faster.
- **Not working:** Empty output, `connection refused`, or JSON with `"error"` (e.g. 502, timeout, “Host is down”). Then the proxy can’t reach the device: check `.env` has the right `PIXEL_URL` (and `IPHONE_IP` if used), restart the farm so adapters pick it up, and that InferrLM is running on the device.

**3. Blog updater (Peak Vinyl Club)**

When you run `npm run blog:update-with-farm` from the website:

- **While it runs:** Watch the terminal. You’ll see `[1/35] Title → updated` or `→ error: …`. Each post can take 3–5+ minutes.
- **After it runs:** In **Admin → Blog** (Peak Vinyl Club), open a post that showed `→ updated`. The **body** and **Updated** time should have changed. Or in Firestore, check `posts` and look at `updatedAt` and `body` for recent changes.

---

## Checklist

| Step | Action |
|------|--------|
| 1 | `cd /Users/jeffadkins/neural-farm && ./dev_farm.sh` (leave running) |
| 2 | Cursor Settings → Models → Base URL `http://localhost:4000/v1`, API Key `sk-local-farm` |
| 3 | In Chat/Composer, pick **GPT-4o mini** (or another farm model), not Cursor Pro/Claude |

---

## Add farm hint to a new project (optional)

Copy into the project so others (or future you) know to use the farm:

- **Markdown:** Use [templates/NEW_PROJECT_FARM.md](templates/NEW_PROJECT_FARM.md) as `docs/NEURAL_FARM.md` or similar.
- **Cursor rules:** Paste [templates/cursorrules_farm_snippet.txt](templates/cursorrules_farm_snippet.txt) into `.cursorrules` or your rules doc.

---

## Troubleshooting

- **“Pay” or paid model:** You’re still on a premium model. Change the dropdown to **GPT-4o mini** (or the model tied to your Override Base URL).
- **Connection error / no response:** Farm not running. Run `./dev_farm.sh` from the neural-farm folder.
- **502 / “Host is down” / timeout:** Usually wrong or stale device IPs. Update `PIXEL_URL` (and `IPHONE_IP` if used) in `.env`, then restart the farm (`pkill -f inferrlm_adapter; pkill -f "litellm --config"; ./dev_farm.sh`). Optional: run `./sniff_devices.sh --write` to rediscover IPs.
- **502 / "Connection refused":** Proxy may be trying the iPhone adapter (8887) and nothing is listening. Use only the Pixel: run `FARM_PIXEL_ONLY=1 ./dev_farm.sh`, or remove `IPHONE_IP` from `.env`/`.iphone_ip` and restart.
- **First reply slow:** Normal; the phone loads the model on first use. Later replies are faster. Use `./dev_farm.sh` (it warms the models) to reduce this.

For more: [DEV.md](DEV.md), [CURSOR_USE_FARM.md](CURSOR_USE_FARM.md), [OTHER_BOTS_FARM.md](OTHER_BOTS_FARM.md).  
**Keeping the system up:** [KEEP_RUNNING.md](KEEP_RUNNING.md).
