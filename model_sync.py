#!/usr/bin/env python3
"""
Neural Farm, sync GGUF models to the Pixel and verify the API.

Uses adb (project .android-tools or system PATH) to list/push files.
Optionally checks the Pixel's /v1/models endpoint.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

# Defaults (override with env or args)
SCRIPT_DIR = Path(__file__).resolve().parent
ADB_PROJECT = SCRIPT_DIR / ".android-tools" / "platform-tools" / "adb"
PIXEL_IP = os.environ.get("PIXEL_IP", "10.1.10.50")
PIXEL_PORT = int(os.environ.get("PIXEL_PORT", "8889"))
REMOTE_DIR = "/sdcard/Download"
LOCAL_DOWNLOADS = Path.home() / "Downloads"


def get_adb() -> Path | None:
    if ADB_PROJECT.is_file() and os.access(ADB_PROJECT, os.X_OK):
        return ADB_PROJECT
    which = shutil.which("adb")
    return Path(which) if which else None


def run_adb(adb: Path, *args: str, device: str | None = None, timeout: int = 60) -> subprocess.CompletedProcess[str]:
    cmd = [str(adb)]
    if device:
        cmd.extend(["-s", device])
    cmd.extend(args)
    return subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)


def list_gguf_on_device(adb: Path, device: str | None = None) -> list[str]:
    """List .gguf files in REMOTE_DIR on the device."""
    out = run_adb(adb, "shell", "ls", REMOTE_DIR, device=device)
    if out.returncode != 0:
        return []
    lines = (out.stdout or "").strip().splitlines()
    return [line.strip() for line in lines if line.strip().endswith(".gguf")]


def sync_gguf_to_device(adb: Path, device: str | None = None) -> list[str]:
    """Push *.gguf from LOCAL_DOWNLOADS to REMOTE_DIR. Returns list of pushed filenames."""
    if not LOCAL_DOWNLOADS.is_dir():
        return []
    pushed = []
    for f in LOCAL_DOWNLOADS.glob("*.gguf"):
        dest = f"{REMOTE_DIR}/{f.name}"
        r = run_adb(adb, "push", str(f), dest, device=device, timeout=600)
        if r.returncode == 0:
            pushed.append(f.name)
    return pushed


def verify_models_endpoint() -> dict | None:
    """GET PIXEL_IP:PIXEL_PORT/v1/models and return parsed JSON or None."""
    try:
        import urllib.request
        url = f"http://{PIXEL_IP}:{PIXEL_PORT}/v1/models"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode())
    except Exception:
        return None


def main() -> int:
    adb_path = get_adb()
    if not adb_path:
        print("model_sync.py: adb not found. Install platform-tools or set PATH.", file=sys.stderr)
        return 1

    parser = argparse.ArgumentParser(description="List/sync GGUF on Pixel and verify /v1/models")
    parser.add_argument("--list", action="store_true", help="List .gguf files on device")
    parser.add_argument("--sync", action="store_true", help="Push ~/Downloads/*.gguf to device")
    parser.add_argument("--verify", action="store_true", help="GET Pixel /v1/models and print result")
    parser.add_argument("-s", "--device", default=None, help="adb device serial (e.g. for wireless)")
    args = parser.parse_args()

    if not (args.list or args.sync or args.verify):
        parser.print_help()
        return 0

    adb = Path(adb_path)

    if args.list:
        files = list_gguf_on_device(adb, args.device)
        if not files:
            print("No .gguf files found in", REMOTE_DIR)
        else:
            for f in files:
                print(f)

    if args.sync:
        pushed = sync_gguf_to_device(adb, args.device)
        if not pushed:
            print("No .gguf files in", LOCAL_DOWNLOADS, "or push failed.")
        else:
            print("Pushed:", ", ".join(pushed))

    if args.verify:
        data = verify_models_endpoint()
        if data is None:
            print("Verify failed: could not reach", f"http://{PIXEL_IP}:{PIXEL_PORT}/v1/models")
            return 1
        print(json.dumps(data, indent=2))
        models = data.get("data") or []
        if not models:
            print("(No models listed; is InferrLM server running with a model loaded?)")

    return 0


if __name__ == "__main__":
    sys.exit(main())
