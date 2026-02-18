# Make Cursor Use the Neural Farm (Not Paid Models)

Cursor will use **paid** models unless you point it at your local proxy and **choose a model that uses that endpoint**.

---

## 1. Set the override (once)

1. Open **Cursor** → **Settings** (Cmd + ,).
2. Go to **Models** (or search "Models" / "OpenAI").
3. Find **OpenAI** (or "OpenAI API Key" / "Custom OpenAI").
4. Set:
   - **Override Base URL:** `http://localhost:4000/v1`
   - **API Key:** `sk-local-farm`
5. Save.

---

## 2. Choose the right model when you chat

After setting the override, you **must pick a model that uses it**. If you pick "Cursor Pro," "Claude," or another built-in model, Cursor uses its paid backend and will ask you to pay.

- In **Chat** or **Composer**, open the **model selector** (dropdown where you pick the model).
- Choose one that uses your **OpenAI-compatible** / **Override** endpoint, for example:
  - **GPT-4o mini**, or
  - **GPT-3.5 Turbo**, or
  - **OpenAI** (if listed)

Those names are configured in your proxy to route to the Pixel. The label in Cursor may say "OpenAI" or show the model name; what matters is that the model is the one **associated with the Override Base URL** you set.

- **Do not** select:
  - Cursor Pro
  - Claude / Anthropic
  - Any model that doesn’t say it uses your custom/OpenAI endpoint

---

## 3. If Cursor still says "pay" or uses a paid model

- Confirm **Override Base URL** is exactly `http://localhost:4000/v1` (no trailing slash, port 4000).
- Confirm you’re **not** picking a premium Cursor/Claude model in the model dropdown.
- Restart Cursor and try again.
- Ensure the LiteLLM proxy is running:  
  `cd /Users/jeffadkins/neural-farm && source .venv/bin/activate && litellm --config config.yaml --port 4000`

---

## Summary

| Do this | Don’t do this |
|--------|----------------|
| Set Override Base URL = `http://localhost:4000/v1` | Leave default OpenAI URL |
| Pick "GPT-4o mini" / "OpenAI" (the one using override) | Pick "Cursor Pro" or "Claude" |
| Keep proxy running on port 4000 | Expect farm to work with proxy stopped |

Once the right model is selected, Cursor sends requests to localhost:4000 → proxy → Pixel (free).
