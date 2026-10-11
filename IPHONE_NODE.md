# Add Your iPhone as a Neural Farm Node

Same idea as the Pixel: run **InferrLM** on the iPhone with **Server** on, then the Mac routes requests to it via an adapter.

---

## 1. On the iPhone

1. **Install InferrLM** (App Store or [GitHub](https://github.com/sbhjt-gr/InferrLM)).
2. **Import your model** (e.g. Llama 3.2 3B GGUF) from Files/Downloads.
3. **Server tab** → Port **8889** → **Allow all devices on Wi‑Fi** → turn **Server** **ON**.
4. Note the URL shown, e.g. `http://10.1.10.55:8889` or `http://169.254.136.118:8889`, that’s your **iPhone IP** and port (8889).

---

## 2. On the MacBook

1. **Get the iPhone IP** (from the app, or iPhone **Settings → Wi‑Fi → tap (i) → IP Address**).
2. **Start the farm with the iPhone:**
   ```bash
   cd ~/neural-farm
   export IPHONE_IP=169.254.136.118   # use your iPhone’s IP (or 10.1.10.x if on Wi‑Fi)
   ./start_farm.sh
   ```
   That starts the Pixel adapter (8888), the **iPhone adapter** (8887), and the proxy (4000). LiteLLM will use both nodes (load‑balance / failover).

3. **Quick check** (optional):
   ```bash
   curl -s http://127.0.0.1:8887/health && echo " iPhone adapter"
   curl -s "http://YOUR_IPHONE_IP:8889/api/tags"
   ```

---

## 3. Summary

| Node   | Adapter port | Device URL        |
|--------|----------------|-------------------|
| Pixel  | 8888          | 10.1.10.50:8889   |
| iPhone | 8887          | YOUR_IPHONE_IP:8889 |

Set **IPHONE_IP** whenever you start the farm and the iPhone will be included. Cursor and other bots keep using **http://localhost:4000/v1**; the proxy sends requests to Pixel and/or iPhone.
