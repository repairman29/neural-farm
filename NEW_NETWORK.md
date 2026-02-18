# New network — update device IPs

On a **new Wi‑Fi network**, your Pixel and iPhone get new IPs. The farm uses the **old** IPs until you update them.

---

## Quick check

```bash
cd /path/to/neural-farm
./farm status          # localhost: adapters + proxy
./sniff_devices.sh     # find Pixel/iPhone on your current Wi‑Fi (InferrLM port 8889)
./sniff_devices.sh --all   # also scan other attached networks (guest Wi‑Fi, 192.168.87.x, 10.x, etc.)
# Optional: ./sniff_devices.sh --write   # update .env with found IPs (add --all to include other nets)
```

If ping fails, you're on a different network — update IPs below and restart the farm.

**Other Wi‑Fi attached to your router (guest, mesh, 5G SSID):**  
If your Pixel or iPhone is on a different SSID that’s still part of your setup (e.g. guest network), run:

```bash
./sniff_devices.sh --all
```

That scans every subnet your Mac is on **plus** common “other” subnets (e.g. 192.168.87.x, 192.168.1.x, 10.0.0.x) if they’re reachable from the Mac. Use `--write` to write found IPs to `.env`.

---

## 1. Get the new IPs

**Pixel**

- On the Pixel: **Settings → Network & internet → Internet** (or **Wi‑Fi**), tap your network → **IP address** (e.g. `192.168.1.42`).
- Or start **InferrLM** and note the message: `Server running at http://192.168.1.42:8889`.

**iPhone**

- **Settings → Wi‑Fi** → tap (i) next to your network → **IP Address** (e.g. `192.168.1.43`).
- Or in **InferrLM**, the server screen shows the URL (e.g. `http://192.168.1.43:8889`).
- If the iPhone is connected to the Mac via **USB** and using “Connect via USB”, the IP may be link‑local (e.g. `169.254.x.x`); that’s fine as long as it’s the *current* link‑local address.

---

## 2. Tell the farm the new IPs

**Option A — environment (recommended)**

Create or edit `.env` in the neural-farm folder:

```bash
# Use your actual IPs from step 1
PIXEL_URL=http://YOUR_PIXEL_IP:8889
IPHONE_IP=YOUR_IPHONE_IP
```

Example:

```bash
PIXEL_URL=http://192.168.1.42:8889
IPHONE_IP=192.168.1.43
```

**Option B — one-time export**

```bash
export PIXEL_URL=http://192.168.1.42:8889
export IPHONE_IP=192.168.1.43
./dev_farm.sh
```

**iPhone only (no .env):**  
Put the iPhone IP in `.iphone_ip` (one line, no port):

```bash
echo "192.168.1.43" > .iphone_ip
```

`dev_farm.sh` and `start_farm.sh` read `IPHONE_IP` from `.iphone_ip` if it’s not set.  
For the **Pixel**, you must set `PIXEL_URL` (in `.env` or `export`) because the adapter defaults to `http://10.1.10.50:8889`.

---

## 3. Restart the farm

Kill any old adapters/proxy, then start with the new IPs:

```bash
cd /path/to/neural-farm
pkill -f inferrlm_adapter 2>/dev/null
pkill -f "litellm --config config.yaml" 2>/dev/null
./dev_farm.sh          # foreground
# or
./dev_farm.sh --bg     # background
```

Then:

```bash
./farm status
```

You should see Pixel (8888) and (if iPhone is set) iPhone (8887) **up**, and Proxy (4000) **up**.

---

## Summary

| Step | Action |
|------|--------|
| 1 | Get new Pixel IP and (if used) iPhone IP from device Wi‑Fi or InferrLM. |
| 2 | Set `PIXEL_URL=http://PIXEL_IP:8889` and `IPHONE_IP=...` in `.env` (or export / `.iphone_ip`). |
| 3 | Restart the farm: `./dev_farm.sh` or `./dev_farm.sh --bg`. |
| 4 | Check: `./farm status`. |

**Cursor** keeps using **http://localhost:4000/v1** — only the Mac needs to know the new device IPs.
