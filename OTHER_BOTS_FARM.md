# Point Other Bots / Apps at the Neural Farm

Any client that can call an **OpenAI-compatible API** can use your Neural Farm: Cursor, other Cursor bots/agents, IDEs, Discord/Slack bots, LangChain, CLI tools, etc. One endpoint, one key, same models.

---

## Quick reference (copy everywhere)

| Setting | Value |
|--------|--------|
| **Base URL** | `http://localhost:4000/v1` (same Mac) or `http://MACBOOK_IP:4000/v1` (same Wi‑Fi) or `https://YOUR-NGROK-URL/v1` (from internet) |
| **API Key** | `sk-local-farm` |
| **Model** | `gpt-4o-mini` or `gpt-4o` or `gpt-3.5-turbo` or `cluster-model` (all route to the farm) |

Anything that lets you set a **custom OpenAI base URL** (or “endpoint”) can use the farm: set the base URL and key above, then pick one of those model names.

---

## 1. Start the farm (once)

On the **MacBook**:

```bash
cd /Users/jeffadkins/neural-farm && ./start_farm.sh
```

That starts the InferrLM adapter + LiteLLM proxy on port **4000**. Leave it running. No ngrok needed for bots on the same Mac or same Wi‑Fi.

- **Same Mac:** Base URL = `http://localhost:4000/v1`
- **Same Wi‑Fi (other device):** Base URL = `http://10.1.10.237:4000/v1` (or your Mac’s LAN IP)
- **From the internet:** Run `ngrok http 4000` and use `https://YOUR-NGROK-URL/v1`

**Farm on a Pixel (Gemma):** If the farm runs on a Pixel with Gemma, use the Pixel’s LAN IP: Base URL = `http://PIXEL_IP:4000/v1` from other devices on the same Wi‑Fi. JARVIS: set `NEURAL_FARM_BASE_URL` in `~/.clawdbot/.env` and see JARVIS repo `docs/JARVIS_NEURAL_FARM.md` § Farm on Pixel.

---

## 2. Cursor bots and other Cursor instances

Every Cursor window/workspace that uses the farm needs the **same** settings:

- **Settings → Models** (or search “Models” / “OpenAI”).
- **Override Base URL:** `http://localhost:4000/v1`
- **API Key:** `sk-local-farm`
- When chatting or using Composer, **pick a model that uses this endpoint** (e.g. **GPT-4o mini**), not Cursor Pro / Claude.

There’s no “per-bot” config—Cursor’s Models settings apply to that Cursor instance. So every Cursor window where you want the farm: set the override and key once, then always choose the farm model (GPT-4o mini, etc.) in the model dropdown.

For **MCP servers, agents, or scripts** that Cursor (or another app) runs and that call an LLM: point them at the same base URL and key (e.g. via env vars below).

---

## 3. Environment variables (any tool that reads them)

Many tools and SDKs use **environment variables** for the OpenAI endpoint. Set these and they’ll use the farm with no code changes:

```bash
export OPENAI_API_BASE="http://localhost:4000/v1"
export OPENAI_API_KEY="sk-local-farm"
```

Then run your bot, script, or CLI. Examples:

- **LangChain:** Uses `OPENAI_API_BASE` and `OPENAI_API_KEY` by default.
- **LlamaIndex:** Same.
- **CLI tools** (e.g. `aider`, `openai` CLI): Same.
- **Your own Python/Node** that uses `os.environ.get("OPENAI_API_KEY")`: Just set the env and use `gpt-4o-mini` (or another farm model) as the model name.

---

## 4. Examples by client type

### A. OpenAI Python / Node (custom code)

**Python (openai package):**

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:4000/v1",
    api_key="sk-local-farm",
)
r = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": "Say hello in one word."}],
)
print(r.choices[0].message.content)
```

**Node (openai package):**

```ts
import OpenAI from "openai";

const client = new OpenAI({
  baseURL: "http://localhost:4000/v1",
  apiKey: "sk-local-farm",
});
const r = await client.chat.completions.create({
  model: "gpt-4o-mini",
  messages: [{ role: "user", content: "Say hello in one word." }],
});
console.log(r.choices[0].message.content);
```

Use `http://MACBOOK_IP:4000/v1` or `https://YOUR-NGROK-URL/v1` if the code runs on another machine.

---

### B. Claude Code / Windsurf / other “Cursor-like” IDEs

- Open **Settings** (or Preferences).
- Find **AI / Models / OpenAI** (or “Custom LLM” / “OpenAI-compatible”).
- Set **Custom endpoint** or **Base URL** to `http://localhost:4000/v1` (or ngrok URL if remote).
- Set **API Key** to `sk-local-farm`.
- Set **Model** to `gpt-4o-mini` (or whatever the UI shows for the selected endpoint).
- Save and use chat/completions as usual.

---

### C. Discord / Slack / Telegram bots

- Use an OpenAI-compatible SDK (e.g. Python `openai`, Node `openai`).
- Set `base_url="http://localhost:4000/v1"` and `api_key="sk-local-farm"` (or use env vars).
- Call `client.chat.completions.create(..., model="gpt-4o-mini")` and reply with the response.
- If the bot runs on another machine (e.g. a server), use your Mac’s LAN IP or ngrok URL as the base.

---

### D. LangChain / LlamaIndex / other frameworks

- Use the framework’s **OpenAI** integration.
- Set **OPENAI_API_BASE** = `http://localhost:4000/v1` and **OPENAI_API_KEY** = `sk-local-farm` (env vars or in code).
- Use **model** = `gpt-4o-mini` (or `cluster-model`). Requests go to the farm.

---

### E. curl (quick test)

```bash
curl -s http://localhost:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-local-farm" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Hello"}],"max_tokens":50}'
```

---

## 5. Checklist for “any bot”

1. **Farm running:** `./start_farm.sh` (adapter + proxy on 4000).
2. **Base URL:** `http://localhost:4000/v1` (same Mac) or `http://MACBOOK_IP:4000/v1` (same Wi‑Fi) or `https://YOUR-NGROK-URL/v1` (from internet).
3. **API Key:** `sk-local-farm`.
4. **Model:** `gpt-4o-mini`, `gpt-4o`, `gpt-3.5-turbo`, or `cluster-model`.
5. **Cursor / IDEs:** In the model dropdown, pick the model that uses the custom endpoint (e.g. GPT-4o mini), not a premium built-in model.

---

## 6. BEAST-MODE (InferrLM per device)

**BEAST-MODE** (agent missions / dogfood) can call each device’s **InferrLM server on port 8889** directly (no proxy). Each device has **one model** (see `config.yaml`: Pixel → Gemma, iPhone → Llama). In BEAST-MODE’s `website/.env.local` set:

- **Easiest:** **`INFERRLM_TAILSCALE_DISCOVER=1`** — discovers devices via Tailscale (probes each peer at `:8889/api/tags`). No manual URLs.
- Or **`INFERRLM_DEVICE_MODELS`** = `url|model,url|model`, e.g.  
  `http://PIXEL_IP:8889|gemma-3-4b-it-Q4_K_M.gguf,http://IPHONE_IP:8889|Llama-3.2-3B-Instruct-Q4_K_M.gguf`  
  Use the same URLs as this repo’s `.env` (PIXEL_URL / IPHONE_IP); model names from each device’s `http://DEVICE:8889/api/tags`. See BEAST-MODE **RUNBOOK.md** and **docs/DOGFOOD_SOUP_TO_NUTS.md**.
