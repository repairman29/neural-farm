# Neural Farm, Use Cases & Value

What the farm is for and how to talk about it.

---

## Use cases

| Use case | How |
|----------|-----|
| **Cursor (coding)** | Base URL `http://localhost:4000/v1`, API Key `sk-local-farm`, model GPT-4o mini. Chat, Composer, and codegen run on your Pixel/iPhone. |
| **Other Cursor windows / bots** | Same settings in each Cursor instance; pick the farm model in the dropdown. |
| **Scripts & CLIs** | Set `OPENAI_API_BASE=http://localhost:4000/v1` and `OPENAI_API_KEY=sk-local-farm`; use model `gpt-4o-mini`. |
| **LangChain / LlamaIndex** | Point the OpenAI integration at the farm URL and key; same model names. |
| **Discord / Slack / Telegram bots** | Use the OpenAI-compatible client with base URL and key; route user messages through the farm. |
| **Echeo / Olive (product)** | Farm as backend for vision (e.g. receipt analysis on Pixel) or summarization (iPhone). |
| **Privacy-sensitive work** | No code or prompts leave your devices; all inference on Pixel/iPhone. |

---

## Cost framing (rough)

- **Farm:** $0 API cost; you pay electricity (negligible) and device wear.
- **Equivalent:** If the same usage were on OpenAI GPT-4o-mini (~$0.15/1M input, ~$0.60/1M output), even 1M tokens/month ≈ tens of dollars saved. Useful for “we’re not sending this to the cloud” or team buy-in.

---

## Privacy & speed pitch

- **Privacy:** “All inference runs on your devices. No code or prompts go to the cloud.”
- **Speed:** “First reply ~5–15s when the model loads; later replies ~2–5s. No network round-trip to a remote API.”
- **Control:** “You own the models and the stack; swap phones or add nodes without changing providers.”

---

## One-liner for stakeholders

**Neural Farm:** Local AI on your Pixel and iPhone, exposed as one API to Cursor and other tools-no cloud, no per-token cost, full control.
