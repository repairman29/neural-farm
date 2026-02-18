#!/usr/bin/env bash
#
# Push Gemma to Pixel over WiFi (no USB prompt needed).
# On Pixel: Developer options → Wireless debugging → On → "Pair device with pairing code".
# Then run: ./push_pixel_wireless.sh PAIRING_IP:PAIR_PORT  (e.g. 10.1.10.93:37829)
# Enter the 6-digit code when prompted. Then the script will connect and push the file.
#

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADB="${SCRIPT_DIR}/.android-tools/platform-tools/adb"
GEMMA="gemma-3-4b-it-Q4_K_M.gguf"
SRC="$HOME/Downloads/$GEMMA"
DEST="/sdcard/Download/$GEMMA"

if [[ ! -x "$ADB" ]]; then
  echo "adb not found at $ADB"
  exit 1
fi

if [[ ! -f "$SRC" ]]; then
  echo "Missing $SRC — run sideload_models.sh --download first."
  exit 1
fi

if [[ -z "$1" ]]; then
  echo "Usage: $0 PAIRING_IP:PAIR_PORT"
  echo ""
  echo "On your Pixel:"
  echo "  1. Settings → System → Developer options → Wireless debugging → Turn On"
  echo "  2. Tap 'Pair device with pairing code'"
  echo "  3. Note the IP and port (e.g. 10.1.10.93:37829) and the 6-digit code"
  echo ""
  echo "Then run: $0 10.1.10.93:37829"
  echo "Enter the code when adb asks. After pairing, script will connect and push $GEMMA."
  exit 0
fi

PAIR="$1"
CODE="${2:-}"
if [[ -n "$CODE" ]]; then
  echo "Pairing with $PAIR (code provided)..."
  echo "$CODE" | "$ADB" pair "$PAIR"
else
  echo "Pairing with $PAIR — enter the 6-digit code from your Pixel when prompted."
  "$ADB" pair "$PAIR"
fi
echo "Pairing done. Connecting..."
# Wireless debugging usually uses port 5555 for the connection after pairing
CONNECT_IP="${PAIR%%:*}"
"$ADB" connect "${CONNECT_IP}:5555"
sleep 2
if "$ADB" devices | grep -q "${CONNECT_IP}:5555.*device$"; then
  echo "Pushing $GEMMA to Pixel Download folder..."
  "$ADB" push "$SRC" "$DEST"
  echo "Done. On Pixel: Open PocketPal → + → Import from Local Storage → Download → $GEMMA. Set chat template to Gemma."
else
  echo "Device not connected. On Pixel, check Wireless debugging is still on and try: $ADB connect ${CONNECT_IP}:5555"
fi
