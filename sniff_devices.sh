#!/usr/bin/env bash
# Sniff the local network(s) for devices running InferrLM (port 8889).
# Usage:
#   ./sniff_devices.sh              # scan subnets attached to this Mac
#   ./sniff_devices.sh --all        # also try common "other" subnets (guest Wi‑Fi, etc.)
#   ./sniff_devices.sh --write      # write found IPs to .env
#   ./sniff_devices.sh --all --write

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- Discover subnets ---
# 1) From every interface with an inet address (your Mac's networks)
SUBNETS=""
while IFS= read -r line; do
  # line is like "192.168.86.208" - take first three octets
  if [[ "$line" =~ ^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+$ ]]; then
    s="${BASH_REMATCH[1]}"
    [[ "$SUBNETS" =~ (^| )"$s"( |$) ]] || SUBNETS="$SUBNETS $s"
  fi
done < <(ifconfig 2>/dev/null | awk '/inet / && !/127.0.0.1/{print $2}')

# 2) If we have no interface subnet, use default gateway
if [ -z "$SUBNETS" ]; then
  GATEWAY=$(route -n get default 2>/dev/null | awk '/gateway:/{print $2}')
  [ -n "$GATEWAY" ] && SUBNET=$(echo "$GATEWAY" | sed -E 's/^([0-9]+\.[0-9]+\.[0-9]+)\.[0-9]+$/\1/') && SUBNETS=" $SUBNET"
fi

# 3) With --all: add common "other" subnets (guest Wi‑Fi, alternate LAN)
TRY_OTHER=""
for arg in "$@"; do [ "$arg" = "--all" ] && TRY_OTHER=1 && break; done
if [ -n "$TRY_OTHER" ]; then
  for other in 192.168.87 192.168.1 192.168.0 10.0.0 10.1.1; do
    [[ " $SUBNETS " = *" $other "* ]] && continue
    ping -c 1 -t 1 "${other}.1" &>/dev/null && SUBNETS="$SUBNETS $other"
  done
fi

SUBNETS=$(echo "$SUBNETS" | xargs)
[ -z "$SUBNETS" ] && { echo "Could not discover any subnet."; exit 1; }

echo "Subnets to scan: $SUBNETS"
[ -n "$TRY_OTHER" ] && echo "(Including reachable 'other' networks, e.g. guest Wi‑Fi)"
echo ""

PIXEL_IP=""
IPHONE_IP=""

scan_one() {
  local subnet="$1"
  local i
  for i in $(seq 1 254); do
    ip="${subnet}.${i}"
    resp=$(curl -s -m 1 "http://${ip}:8889/api/tags" 2>/dev/null)
    if echo "$resp" | grep -q '"models"'; then
      models=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); m=d.get('models',[]); print(' '.join([x.get('name','') or x.get('id','') for x in m]))" 2>/dev/null || echo "?")
      if echo "$models" | grep -qi gemma; then
        echo "Pixel (Gemma)  → $ip  ($models)"
        [ -z "$PIXEL_IP" ] && PIXEL_IP="$ip"
      elif echo "$models" | grep -qi llama; then
        echo "iPhone (Llama) → $ip  ($models)"
        [ -z "$IPHONE_IP" ] && IPHONE_IP="$ip"
      else
        echo "InferrLM       → $ip  ($models)"
        [ -z "$PIXEL_IP" ] && PIXEL_IP="$ip"
      fi
    fi
  done
}

for sub in $SUBNETS; do
  echo "Scanning ${sub}.0/24 ..."
  scan_one "$sub"
done

echo ""
if [ -n "$PIXEL_IP" ] || [ -n "$IPHONE_IP" ]; then
  echo "--- Add to .env (then run ./dev_farm.sh) ---"
  [ -n "$PIXEL_IP" ] && echo "PIXEL_URL=http://${PIXEL_IP}:8889"
  [ -n "$IPHONE_IP" ] && echo "IPHONE_IP=${IPHONE_IP}"
  for arg in "$@"; do
    if [ "$arg" = "--write" ]; then
      touch .env
      if [ -n "$PIXEL_IP" ]; then
        if grep -q "PIXEL_URL=" .env 2>/dev/null; then
          sed -i.bak "s|PIXEL_URL=.*|PIXEL_URL=http://${PIXEL_IP}:8889|" .env
        else
          echo "PIXEL_URL=http://${PIXEL_IP}:8889" >> .env
        fi
      fi
      if [ -n "$IPHONE_IP" ]; then
        if grep -q "IPHONE_IP=" .env 2>/dev/null; then
          sed -i.bak "s|IPHONE_IP=.*|IPHONE_IP=${IPHONE_IP}|" .env
        else
          echo "IPHONE_IP=${IPHONE_IP}" >> .env
        fi
      fi
      echo ""
      echo "Wrote to .env. Run: ./dev_farm.sh"
      break
    fi
  done
else
  echo "No InferrLM devices found."
  echo "Tips: Phones on same Wi‑Fi? InferrLM Server on? Try: ./sniff_devices.sh --all"
fi
