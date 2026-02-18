#!/usr/bin/env bash
# Quick farm status: adapters + proxy. Run from neural-farm or with FARM_DIR set.
# Note: Adapters are single-threaded. If one is busy on a long completion, /health
# may not get a reply in time and show "down" even though the process is running.
set -e
FARM_DIR="${FARM_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
cd "$FARM_DIR" 2>/dev/null || true
TIMEOUT=5

echo -n "Pixel (8888): "
curl -s -m $TIMEOUT http://127.0.0.1:8888/health >/dev/null 2>&1 && echo "up" || echo "down"
echo -n "iPhone (8887): "
curl -s -m $TIMEOUT http://127.0.0.1:8887/health >/dev/null 2>&1 && echo "up" || echo "down"
echo -n "Proxy (4000): "
# Use GET / (quick); LiteLLM /health runs full backend checks and can timeout
curl -s -m $TIMEOUT http://127.0.0.1:4000/ -o /dev/null 2>&1 && echo "up" || echo "down"
echo ""
if ! curl -s -m $TIMEOUT http://127.0.0.1:4000/ -o /dev/null 2>&1; then
  echo "→ Start farm: cd $FARM_DIR && ./dev_farm.sh"
fi
