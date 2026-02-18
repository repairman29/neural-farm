#!/usr/bin/env python3
"""
Neural Farm — Cluster Monitor

Checks health of each phone/node in the farm and reports status to the terminal.
Run from your MacBook while LiteLLM proxy and devices are on the network.

Usage:
  python cluster_monitor.py              # one-shot report
  python cluster_monitor.py --watch      # continuous every 30s
  python cluster_monitor.py --wake       # health check + send tiny completion to load model (InferrLM)
  python cluster_monitor.py --config config.yaml   # use custom config
"""

import argparse
import sys
import time
from pathlib import Path

try:
    import requests
    import yaml
except ImportError:
    print("Install deps: pip install -r requirements.txt")
    sys.exit(1)


def load_endpoints(config_path: str) -> list[dict]:
    """Parse LiteLLM config.yaml and extract api_base URLs and model names."""
    path = Path(config_path)
    if not path.exists():
        print(f"Config not found: {config_path}")
        return []
    with path.open() as f:
        data = yaml.safe_load(f)
    model_list = data.get("model_list") or []
    seen = set()
    endpoints = []
    for entry in model_list:
        base = entry.get("litellm_params", {}).get("api_base")
        model = entry.get("litellm_params", {}).get("model", "unknown")
        if base and base not in seen:
            seen.add(base)
            # normalize: ensure we have base URL without /v1 for health
            health_base = base.rstrip("/").replace("/v1", "") or base
            endpoints.append({"api_base": base, "health_base": health_base, "model": model})
    return endpoints


def check_node(health_base: str, model: str, timeout: float = 5.0) -> dict:
    """
    Probe a node. Tries /v1/models first (OpenAI-compatible), then /health.
    Returns dict with status, latency_ms, models list, and optional error/message.
    """
    result = {"model": model, "health_base": health_base, "status": "unknown", "latency_ms": None, "models": [], "error": None}
    start = time.perf_counter()
    for path in ["/v1/models", "/health", "/"]:
        url = f"{health_base.rstrip('/')}{path}"
        try:
            r = requests.get(url, timeout=timeout)
            result["latency_ms"] = round((time.perf_counter() - start) * 1000)
            result["status"] = "up" if r.status_code < 500 else "degraded"
            if path == "/v1/models" and r.status_code == 200:
                try:
                    result["models"] = [m.get("id", "") for m in r.json().get("data", [])]
                except Exception:
                    pass
            return result
        except requests.RequestException as e:
            result["error"] = str(e)
    result["status"] = "down"
    result["latency_ms"] = round((time.perf_counter() - start) * 1000)
    return result


def wake_up_node(health_base: str, model_id: str = "gemma-3-4b", timeout: float = 30.0) -> bool:
    """
    Send a tiny completion request to force InferrLM (or similar) to load the model into RAM.
    Call this before routing real work if you want the node "hot".
    """
    url = f"{health_base.rstrip('/')}/v1/chat/completions"
    payload = {"model": model_id, "messages": [{"role": "user", "content": "hi"}], "max_tokens": 1}
    try:
        r = requests.post(url, json=payload, timeout=timeout)
        return r.status_code == 200
    except requests.RequestException:
        return False


def report_one(node: dict) -> str:
    """Format a single node result for terminal output."""
    status = node["status"]
    model = node["model"]
    base = node["health_base"]
    latency = node["latency_ms"]
    err = node.get("error")
    models = node.get("models") or []
    if status == "up":
        line = f"  [{status.upper():7}] {model:24} {base:40} {latency}ms"
        if models:
            line += f"  models={models}"
    else:
        line = f"  [{status.upper():7}] {model:24} {base:40} {latency or '—'}ms"
        if err:
            line += f"  — {err}"
    return line


def run_report(config_path: str, wake: bool = False, wake_model: str = "gemma-3-4b") -> bool:
    """Run one health check and print report. If wake=True, send wake-up to each up node. Returns True if at least one node is up."""
    endpoints = load_endpoints(config_path)
    if not endpoints:
        return False
    print(f"\nNeural Farm — Health Check ({config_path})")
    print("  " + "-" * 80)
    any_up = False
    for ep in endpoints:
        node = check_node(ep["health_base"], ep["model"])
        print(report_one(node))
        if node["status"] == "up":
            any_up = True
            if wake:
                print(f"  ☕ Wake-up {ep['health_base']} ({wake_model})...", end=" ", flush=True)
                if wake_up_node(ep["health_base"], model_id=wake_model):
                    print("OK (model loading/loaded)")
                else:
                    print("failed or timeout")
    print("  " + "-" * 80 + "\n")
    return any_up


def main():
    ap = argparse.ArgumentParser(description="Neural Farm cluster health monitor")
    ap.add_argument("--config", default="config.yaml", help="Path to LiteLLM config.yaml")
    ap.add_argument("--watch", action="store_true", help="Run every 30s until Ctrl+C")
    ap.add_argument("--interval", type=float, default=30, help="Seconds between checks in --watch mode")
    ap.add_argument("--wake", action="store_true", help="Send a tiny completion to each up node to load model (InferrLM lazy load)")
    ap.add_argument("--wake-model", default="gemma-3-4b", help="Model id for --wake (default: gemma-3-4b)")
    args = ap.parse_args()
    if args.watch:
        try:
            while True:
                run_report(args.config, wake=args.wake, wake_model=args.wake_model)
                time.sleep(args.interval)
        except KeyboardInterrupt:
            print("\nStopped.")
    else:
        run_report(args.config, wake=args.wake, wake_model=args.wake_model)


if __name__ == "__main__":
    main()
