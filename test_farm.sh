#!/usr/bin/env bash
# Test Pixel adapter + proxy (and optional iPhone). Run from neural-farm.
# Usage: ./test_farm.sh   (status + one completion through proxy)
#        ./test_farm.sh --quick   (status only, no completion)
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
[ -f .env ] && set -a && source .env && set +a
[ -z "$IPHONE_IP" ] && [ -f .iphone_ip ] && export IPHONE_IP=$(cat .iphone_ip)

TIMEOUT=5
PROXY_TIMEOUT=60

echo "=== Farm status ==="
echo -n "  Pixel adapter (8888): "
curl -s -m $TIMEOUT http://127.0.0.1:8888/health >/dev/null 2>&1 && echo "up" || echo "down"
echo -n "  iPhone adapter (8887): "
curl -s -m $TIMEOUT http://127.0.0.1:8887/health >/dev/null 2>&1 && echo "up" || echo "down"
echo -n "  Proxy (4000): "
curl -s -m $TIMEOUT http://127.0.0.1:4000/ -o /dev/null 2>&1 && echo "up" || echo "down"
echo ""

# Optional: direct device check (Pixel URL from .env)
if [ -n "$PIXEL_URL" ]; then
  echo -n "  Pixel device ($PIXEL_URL): "
  curl -s -m 3 "$PIXEL_URL/api/tags" 2>/dev/null | grep -q '"models"' && echo "reachable" || echo "unreachable"
  echo ""
fi

if [ "$1" = "--quick" ]; then
  echo "Done (--quick: no completion test)."
  exit 0
fi

echo "=== Completion test (proxy → Pixel/iPhone) ==="
echo "  Sending one short request to http://127.0.0.1:4000/v1 ..."
resp=$(curl -s -m $PROXY_TIMEOUT -X POST http://127.0.0.1:4000/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":"Say hi in one word"}],"max_tokens":5}' 2>/dev/null) || true

if echo "$resp" | grep -q '"choices"'; then
  content=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); c=d.get('choices',[{}])[0].get('message',{}).get('content',''); print(c.strip())" 2>/dev/null || echo "?")
  echo "  OK — reply: \"$content\""
else
  echo "  FAIL — no choices in response (timeout or error)."
  echo "$resp" | head -c 300
  echo ""
  exit 1
fi

echo ""
echo "Pixel + proxy are working. See LOCAL_DEVICE_IPS.md for device URLs."
