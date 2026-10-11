# Neural Farm, Improve Value (Feb 2026)

Concrete ways to increase the value of your local farm and dev setup this month.

---

## 1. Developer experience

| Improvement | Why it helps |
|-------------|--------------|
| **Streaming in the adapter** | Cursor and other clients can use `stream: true` for faster perceived response (first token sooner). Today the adapter only does non-streaming. |
| **Project-level “use farm” hint** | Add a `.cursorrules` or `docs/NEURAL_FARM.md` snippet to **new** projects that says: “This project uses the Neural Farm; in Cursor use Base URL http://localhost:4000/v1 and model gpt-4o-mini.” Reduces repeat onboarding. |
| **One-command “farm ready?”** | A tiny script or alias (e.g. `farm status`) that checks adapters + proxy and prints OK or “Start with: ./dev_farm.sh”. |
| **Scheduled warm-up** | Use `launchd` (or cron) to run `cluster_monitor.py --wake` at 8am (or when you usually start work) so the first Cursor request isn’t cold. |

---

## 2. Visibility and reliability

| Improvement | Why it helps |
|-------------|--------------|
| **Latency notes** | In README or DEV.md, add one line: “Typical: Pixel ~5–15s first reply, then ~2–5s; iPhone similar.” Sets expectations. |
| **Node preference** | You already have Pixel first in config. Optionally add a “dev-only” config that **only** uses Pixel (no iPhone) for simpler debugging and more predictable latency. |
| **Health in status bar / dashboard** | Optional: a tiny local page (e.g. `python -m http.server 9999` serving a single HTML that fetches `localhost:4000/health` and adapter health) so you can see “farm up” at a glance. |

---

## 3. Use cases and positioning

| Improvement | Why it helps |
|-------------|--------------|
| **Use-case doc** | One-pager: “Neural Farm use cases, Cursor (coding), Olive (vision/receipts), Echeo (…), other bots (Discord, scripts).” Makes it easy to explain value to yourself or others. |
| **Cost framing** | Rough “tokens per day” or “equivalent API cost saved” (e.g. “~$X/month if this were OpenAI”) for stakeholder or personal motivation. |
| **Privacy / speed pitch** | One sentence: “All inference on your devices; no code or prompts leave the farm.” Useful for compliance or team buy-in. |

---

## 4. 2026 stack watch

| Thing to watch | Action |
|----------------|--------|
| **Google AI Edge / Gemini on Pixel** | If Google ships an API or “server mode” for the Gallery app, consider adding it as another backend (or swap) for better Tensor use. |
| **Apple Intelligence APIs** | If Apple exposes an on-device API on iPhone, add it as a node for summarization or Siri-style tasks. |
| **Cursor workspace models** | If Cursor adds workspace-level model settings, document “set farm once per workspace” to simplify onboarding. |
| **InferrLM updates** | Track releases for streaming, better cold-start, or new model support; update adapter if they add OpenAI-style streaming. |

---

## 5. Quick wins (done ✓)

1. **Streaming**, In `inferrlm_adapter.py`; when client sends `stream: true`, adapter returns SSE (one chunk + `[DONE]`).
2. **`farm status`**, `./farm status` (or `./status.sh`) curls adapter + proxy health.
3. **Use cases**, [USE_CASES.md](USE_CASES.md): Cursor, Olive, other bots, cost framing, privacy pitch.
4. **config-dev-pixel-only.yaml**, Pixel-only proxy for single-node dev.
5. **Health dashboard**, `./farm dashboard` serves http://127.0.0.1:9999.
6. **Project hint**, `templates/NEW_PROJECT_FARM.md` and `templates/cursorrules_farm_snippet.txt`.
7. **Scheduled warm-up**, [docs/SCHEDULED_WARMUP.md](docs/SCHEDULED_WARMUP.md) (launchd/cron).
8. **farm script**, `./farm {status|start|start-bg|warmup|dashboard}`.

---

## Summary

- **Feb 2026 value levers:** Better DX (streaming, project hint, status, warm-up), clearer expectations (latency, use cases, cost), and watching 2026 stack (Google/Apple/Cursor/InferrLM).
- **Quick wins (done):** Streaming, `farm` CLI, USE_CASES.md, config-dev-pixel-only, health dashboard, templates, scheduled warm-up.
