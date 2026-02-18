# Local device IPs (this machine)

Used by the adapters to reach the phones. Set in **`.env`** (and optionally **`.iphone_ip`** for iPhone). Restart the farm after changing.

| Device | URL / IP | Where it’s set |
|--------|----------|----------------|
| **Pixel** | `http://10.1.10.50:8889` | `.env` → `PIXEL_URL=http://10.1.10.50:8889` |
| **iPhone** | (optional) | `.env` → `IPHONE_IP=…` or `.iphone_ip` (one line, IP only) |

- **Pixel:** InferrLM Server on the Pixel must be ON; Mac and Pixel on same Wi‑Fi. If the Pixel’s IP changes, update `PIXEL_URL` in `.env` and restart (`./dev_farm.sh` or restart adapters).
- **iPhone:** Same idea: same Wi‑Fi, InferrLM Server ON. Get IP from iPhone **Settings → Wi‑Fi → (i) → IP Address**; put it in `IPHONE_IP` or `.iphone_ip`.

Quick check that the Pixel is reachable from the Mac:

```bash
curl -s -m 5 http://10.1.10.50:8889/api/tags
```

You should see JSON with `"models":[...]`. Then run `./test_farm.sh` to verify Pixel adapter + proxy.
