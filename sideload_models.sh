#!/usr/bin/env bash
#
# Neural Farm — Sideload GGUF models to iPhone (PocketPal AI) and Pixel (PocketPal Android)
# Run: ./sideload_models.sh
# Optional: ./sideload_models.sh --download  (download missing models to ~/Downloads)
#

set -e
DOWNLOADS="$HOME/Downloads"
LLAMA_GGUF="Llama-3.2-3B-Instruct-Q4_K_M.gguf"
GEMMA_GGUF="gemma-3-4b-it-Q4_K_M.gguf"
LLAMA_URL="https://huggingface.co/bartowski/Llama-3.2-3B-Instruct-GGUF/resolve/main/Llama-3.2-3B-Instruct-Q4_K_M.gguf"
GEMMA_URL="https://huggingface.co/ggml-org/gemma-3-4b-it-GGUF/resolve/main/gemma-3-4b-it-Q4_K_M.gguf"

do_download=false
[[ "${1:-}" == "--download" ]] && do_download=true

echo "=============================================="
echo "  Neural Farm — Sideload GGUF Models"
echo "=============================================="
echo ""

# ---- Check required files in ~/Downloads ----
llama_path="$DOWNLOADS/$LLAMA_GGUF"
gemma_path="$DOWNLOADS/$GEMMA_GGUF"
missing=()

[[ ! -f "$llama_path" ]] && missing+=("$LLAMA_GGUF (iPhone)")
[[ ! -f "$gemma_path" ]] && missing+=("$GEMMA_GGUF (Pixel)")

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Required files in $DOWNLOADS:"
  [[ -f "$llama_path" ]] && echo "  [OK] $LLAMA_GGUF" || echo "  [MISSING] $LLAMA_GGUF"
  [[ -f "$gemma_path" ]] && echo "  [OK] $GEMMA_GGUF" || echo "  [MISSING] $GEMMA_GGUF"
  echo ""
  if [[ "$do_download" == true ]]; then
    for f in "${missing[@]}"; do
      name="${f%% *}"
      if [[ "$name" == "$LLAMA_GGUF" ]]; then
        echo "Downloading $LLAMA_GGUF to $DOWNLOADS ..."
        curl -L -o "$llama_path" "$LLAMA_URL" || { echo "Download failed."; exit 1; }
      elif [[ "$name" == "$GEMMA_GGUF" ]]; then
        echo "Downloading $GEMMA_GGUF to $DOWNLOADS ..."
        curl -L -o "$gemma_path" "$GEMMA_URL" || { echo "Download failed."; exit 1; }
      fi
    done
    echo "Download(s) complete."
  else
    echo "Download the missing file(s) to $DOWNLOADS, or run:"
    echo "  $0 --download"
    echo ""
    echo "Direct links:"
    echo "  iPhone (Llama): $LLAMA_URL"
    echo "  Pixel (Gemma):  $GEMMA_URL"
    echo ""
  fi
else
  echo "[OK] Both GGUF files found in $DOWNLOADS"
fi
echo ""

# ---- iPhone (USB) ----
echo "--- iPhone 15 Pro Max (PocketPal AI) ---"
if system_profiler SPUSBDataType 2>/dev/null | grep -qi "iPhone"; then
  echo "[OK] iPhone detected via USB."
  echo ""
  echo "iOS does not expose app folders to the command line. Use Finder:"
  echo "  1. Open Finder."
  echo "  2. Select your iPhone in the sidebar."
  echo "  3. Click the 'Files' tab (or 'Files' under the device)."
  echo "  4. Find 'PocketPal AI' in the app list."
  echo "  5. Drag this file into that folder:"
  echo "     $llama_path"
  echo ""
  if [[ -f "$llama_path" ]]; then
    echo "Opening Finder and Downloads folder..."
    open "$DOWNLOADS"
    open -R "$llama_path" 2>/dev/null || true
  fi
else
  echo "[--] No iPhone detected via USB. Connect the iPhone and unlock it, then run again."
fi
echo ""

# ---- Android (USB + adb) ----
echo "--- Pixel 8 Pro (PocketPal Android) ---"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADB="${SCRIPT_DIR}/.android-tools/platform-tools/adb"
[[ -x "$ADB" ]] || ADB="$(command -v adb 2>/dev/null)" || ADB=""
if [[ -n "$ADB" ]]; then
  adb_devices=$("$ADB" devices 2>/dev/null | grep -v "List" | grep "device$" | wc -l | tr -d ' ')
  if [[ "$adb_devices" -gt 0 ]]; then
    echo "[OK] Android device(s) detected via adb."
    if [[ -f "$gemma_path" ]]; then
      echo "Pushing $GEMMA_GGUF to device Download folder..."
      if "$ADB" push "$gemma_path" /sdcard/Download/"$GEMMA_GGUF"; then
        echo "[OK] File pushed. On the Pixel: open PocketPal → + → Import from Local Storage → choose from Download."
      else
        echo "[!!] adb push failed. Use manual transfer: enable File Transfer (MTP), then copy file to device Download folder."
      fi
    else
      echo "Put $GEMMA_GGUF in $DOWNLOADS and run this script again (or use --download)."
    fi
  else
    echo "[--] No Android device in adb. On Pixel: Settings → Developer options → enable USB debugging. Connect USB, tap 'Allow' on the phone, then run this script again."
    echo "     Or use manual: set USB to 'File transfer', then in Finder copy $GEMMA_GGUF to the device Download folder. In PocketPal: + → Import from Local Storage."
  fi
else
  echo "[--] adb not found. Run from neural-farm folder (script will use .android-tools if present), or: brew install android-platform-tools"
  echo ""
  echo "Manual: Set Pixel to 'File transfer', then in Finder copy $GEMMA_GGUF to device Download. In PocketPal: + → Import from Local Storage."
fi
echo ""

# ---- Final steps reminder ----
echo "=============================================="
echo "After files are on the devices:"
echo "  • In each app: Models → Add / + → select the .gguf file."
echo "  • Set chat template: Llama 3 (iPhone), Gemma (Pixel)."
echo "=============================================="
