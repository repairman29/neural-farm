#!/usr/bin/env bash
# Start the Neural Farm: InferrLM adapters (Pixel + optional iPhone) + LiteLLM proxy.
# Run from neural-farm. Keep this running (Ctrl+C to stop).
#
# iPhone: set your iPhone's IP then run, e.g.:
#   export IPHONE_IP=169.254.136.118
#   ./start_farm.sh
# Or: export IPHONE_IP=$(cat .iphone_ip 2>/dev/null); ./start_farm.sh
# New network: put PIXEL_URL and IPHONE_IP in .env (see NEW_NETWORK.md).

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

[ -f .env ] && set -a && source .env && set +a
[ -z "$IPHONE_IP" ] && [ -f .iphone_ip ] && export IPHONE_IP=$(cat .iphone_ip)

# 1. Pixel adapter (port 8888 → PIXEL_URL or default 10.1.10.50:8889)
if ! curl -s -m 2 http://127.0.0.1:8888/health >/dev/null 2>&1; then
  echo "Starting Pixel adapter on port 8888..."
  nohup python3 -u inferrlm_adapter.py >> /tmp/inferrlm_adapter.log 2>&1 &
  sleep 3
  if ! curl -s -m 3 http://127.0.0.1:8888/health >/dev/null 2>&1; then
    echo "Pixel adapter failed to start. Check /tmp/inferrlm_adapter.log"
    exit 1
  fi
  echo "  Pixel adapter OK."
else
  echo "Pixel adapter already running on 8888."
fi

# 2. iPhone adapter (port 8887 → IPHONE_IP:8889) if IPHONE_IP is set
if [ -n "$IPHONE_IP" ]; then
  if ! curl -s -m 2 http://127.0.0.1:8887/health >/dev/null 2>&1; then
    echo "Starting iPhone adapter on port 8887 (→ ${IPHONE_IP}:8889)..."
    PIXEL_URL="http://${IPHONE_IP}:8889" ADAPTER_PORT=8887 nohup python3 -u inferrlm_adapter.py >> /tmp/inferrlm_adapter_iphone.log 2>&1 &
    sleep 3
    if curl -s -m 3 http://127.0.0.1:8887/health >/dev/null 2>&1; then
      echo "  iPhone adapter OK."
    else
      echo "  iPhone adapter may have failed (is InferrLM running on iPhone at ${IPHONE_IP}:8889?). Check /tmp/inferrlm_adapter_iphone.log"
    fi
  else
    echo "iPhone adapter already running on 8887."
  fi
else
  echo "Tip: set IPHONE_IP to your iPhone's IP to start the iPhone node (e.g. export IPHONE_IP=10.1.10.55)."
fi

# 3. Start LiteLLM proxy
echo "Starting LiteLLM proxy on port 4000..."
source .venv/bin/activate
exec litellm --config config.yaml --port 4000
