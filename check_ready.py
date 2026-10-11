#!/usr/bin/env python3
"""
Neural Farm, "What do I do next?" checker.

Run from the project folder:  python check_ready.py

Checks: Python deps, config IPs, ngrok, and suggests the next step.
"""

import os
import shutil
import sys
from pathlib import Path

def main():
    base = Path(__file__).resolve().parent
    os.chdir(base)
    issues = []
    next_steps = []

    # 1. Python deps
    try:
        import requests
        import yaml
    except ImportError:
        issues.append("Python deps missing. Run: python3 -m pip install -r requirements.txt")
        next_steps.append("In project folder: python3 -m pip install -r requirements.txt")
    else:
        print("[OK] Python deps (requests, yaml)")

    # 2. Config and IPs
    config_path = base / "config.yaml"
    if not config_path.exists():
        issues.append("config.yaml not found")
        next_steps.append("Ensure you're in the neural-farm folder.")
    else:
        raw = config_path.read_text()
        if "PHONE_IP" in raw or "PIXEL_IP" in raw:
            issues.append("config.yaml still has placeholders PHONE_IP / PIXEL_IP")
            next_steps.append("Edit config.yaml: replace PHONE_IP and PIXEL_IP with your phones' local IPs.")
        else:
            print("[OK] config.yaml has IPs set")

    # 3. ngrok
    if shutil.which("ngrok"):
        print("[OK] ngrok in PATH")
    else:
        issues.append("ngrok not found in PATH")
        next_steps.append("Install ngrok: brew install ngrok  or download from ngrok.com")

    # 4. LiteLLM (optional but useful)
    try:
        import litellm
        print("[OK] litellm installed")
    except ImportError:
        issues.append("litellm not installed")
        next_steps.append("Run: python3 -m pip install -r requirements.txt")

    # Summary
    print()
    if issues:
        print("Issues:")
        for i in issues:
            print("  -", i)
        print()
        print("Next step:", next_steps[0] if next_steps else "Fix the issues above.")
        return 1
    else:
        print("All checks passed. Next steps:")
        print("  1. Start LLM servers on iPhone and Pixel (port 8080, same Wi-Fi).")
        print("  2. Run: litellm --config config.yaml --port 4000")
        print("  3. In another terminal: ngrok http 4000")
        print("  4. In Cursor: set Override Base URL to https://YOUR-NGROK-URL/v1")
        return 0

if __name__ == "__main__":
    sys.exit(main())
