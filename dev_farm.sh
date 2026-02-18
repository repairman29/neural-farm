#!/usr/bin/env bash
# Dev-optimized farm: start adapters + proxy, warm models, print ready + test.
# Usage: ./dev_farm.sh   (foreground: proxy in foreground, adapters in background)
#        ./dev_farm.sh --bg   (all in background, then warm-up and exit)
#
# With --bg, only one instance can run at a time (lock file). Prevents cron, LaunchAgent,
# and manual runs from stepping on each other.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

LOCKFILE="${NEURAL_FARM_LOCKFILE:-/tmp/neural-farm-start.lock}"
LOCKFD=200

# --bg: acquire lock so only one "start farm" runs at a time; skip if another is running
if [ "$1" = "--bg" ]; then
  eval "exec ${LOCKFD}>\"$LOCKFILE\""
  if ! flock -n $LOCKFD 2>/dev/null; then
    echo "=== Neural Farm (dev) ==="
    echo "  Another start already in progress (lock held). Exiting."
    exit 0
  fi
fi

# Optional: load .env (PIXEL_URL, IPHONE_IP, FARM_DEV) — see NEW_NETWORK.md for new Wi‑Fi
[ -f .env ] && set -a && source .env && set +a
# iPhone IP from file if not set
[ -z "$IPHONE_IP" ] && [ -f .iphone_ip ] && export IPHONE_IP=$(cat .iphone_ip)
export FARM_DEV=1

echo "=== Neural Farm (dev) ==="

# 1. Pixel adapter (PIXEL_URL from .env so it reaches the right device)
if ! curl -s -m 2 http://127.0.0.1:8888/health >/dev/null 2>&1; then
  echo "Starting Pixel adapter (8888)..."
  export PIXEL_URL="${PIXEL_URL:-http://10.1.10.50:8889}"
  FARM_DEV=1 nohup python3 -u inferrlm_adapter.py >> /tmp/inferrlm_adapter.log 2>&1 &
  sleep 2
fi
curl -s -m 2 http://127.0.0.1:8888/health >/dev/null 2>&1 && echo "  Pixel adapter: up" || echo "  Pixel adapter: failed"

# 2. iPhone adapter (if IPHONE_IP set)
if [ -n "$IPHONE_IP" ]; then
  if ! curl -s -m 2 http://127.0.0.1:8887/health >/dev/null 2>&1; then
    echo "Starting iPhone adapter (8887 → ${IPHONE_IP}:8889)..."
    PIXEL_URL="http://${IPHONE_IP}:8889" ADAPTER_PORT=8887 FARM_DEV=1 nohup python3 -u inferrlm_adapter.py >> /tmp/inferrlm_adapter_iphone.log 2>&1 &
    sleep 2
  fi
  curl -s -m 2 http://127.0.0.1:8887/health >/dev/null 2>&1 && echo "  iPhone adapter: up" || echo "  iPhone adapter: down (check IP)"
else
  echo "  iPhone: skip (set IPHONE_IP or .iphone_ip)"
fi

# 3. Proxy (use Pixel-only config when iPhone not in use so proxy doesn't try 8887 and get connection refused)
LITELLM_CONFIG="config.yaml"
if [ -z "$IPHONE_IP" ] || [ -n "${FARM_PIXEL_ONLY:-}" ]; then
  LITELLM_CONFIG="config-dev-pixel-only.yaml"
  [ -z "$IPHONE_IP" ] && echo "  Proxy: using Pixel-only config (no iPhone)."
fi
if curl -s -m 1 http://127.0.0.1:4000/health >/dev/null 2>&1; then
  echo "  Proxy already on 4000."
  [ "$1" != "--bg" ] && echo "  Cursor: http://localhost:4000/v1  Key: sk-local-farm" && exit 0
else
  pkill -f "litellm --config" 2>/dev/null || true
  sleep 1
  echo "Starting proxy (4000)..."
  source .venv/bin/activate
  if [ "$1" = "--bg" ]; then
    nohup litellm --config "$LITELLM_CONFIG" --port 4000 >> /tmp/litellm.log 2>&1 &
    sleep 4
  else
    # Warm-up before handing over to proxy (so first Cursor request isn't cold)
    echo "Warming models (one short request per node)..."
    (curl -s -m 15 -X POST http://127.0.0.1:8888/v1/chat/completions -H "Content-Type: application/json" \
      -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":2}' >/dev/null 2>&1 && echo "  Pixel: warm") || true
    [ -n "$IPHONE_IP" ] && (curl -s -m 15 -X POST http://127.0.0.1:8887/v1/chat/completions -H "Content-Type: application/json" \
      -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":2}' >/dev/null 2>&1 && echo "  iPhone: warm") || true
    echo ""
    echo "Ready. Proxy starting (Ctrl+C to stop)."
    echo "  Cursor: Base URL = http://localhost:4000/v1  API Key = sk-local-farm  Model = gpt-4o-mini"
    echo "  Test:  curl -s -X POST http://localhost:4000/v1/chat/completions -H 'Content-Type: application/json' -d '{\"model\":\"gpt-4o-mini\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_tokens\":10}'"
    exec litellm --config "$LITELLM_CONFIG" --port 4000
  fi
fi

if [ "$1" = "--bg" ]; then
  echo "Warming models..."
  sleep 2
  curl -s -m 20 -X POST http://127.0.0.1:4000/v1/chat/completions -H "Content-Type: application/json" \
    -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"hi"}],"max_tokens":2}' >/dev/null 2>&1 && echo "  Farm: warm" || echo "  Farm: first request may be slow"
  echo ""
  echo "Farm running in background."
  echo "  Cursor: Base URL = http://localhost:4000/v1  API Key = sk-local-farm"
  echo "  Logs: tail -f /tmp/inferrlm_adapter.log /tmp/litellm.log"
fi
