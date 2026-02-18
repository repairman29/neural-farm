# Neural Farm — Confirmed Working

**Date:** 2026-02-14

---

## Status

| Check | Result |
|-------|--------|
| Pixel adapter (8888 → 10.1.10.50:8889) | OK |
| iPhone adapter (8887 → 169.254.136.118:8889) | OK (when running) |
| LiteLLM proxy (4000) | OK |
| **Completion through proxy** | **OK** — model replied `"confirmed"` |

---

## Test

```bash
curl -s -X POST http://127.0.0.1:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Say exactly: confirmed"}],"max_tokens":15}'
```

Expected: JSON with `"content":"confirmed"` in `choices[0].message`.

---

## Use in Cursor / other bots

- **Base URL:** `http://localhost:4000/v1`
- **API Key:** `sk-local-farm`
- **Model:** e.g. `gpt-4o-mini` (routes to Pixel Gemma or iPhone Llama)

Farm is confirmed.
