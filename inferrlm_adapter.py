#!/usr/bin/env python3
"""
InferrLM → OpenAI-compatible adapter.

InferrLM uses /api/tags and /api/chat, not /v1/models and /v1/chat/completions.
This script runs a small server that accepts OpenAI-format requests and
forwards them to the Pixel's InferrLM server, translating request/response.

Usage:
  PIXEL_URL=http://10.1.10.50:8889 python inferrlm_adapter.py
  Then point LiteLLM config at http://localhost:8888/v1 (adapter port 8888).
"""

import json
import os
import sys
import time
import urllib.request
import urllib.error
from http.server import HTTPServer, BaseHTTPRequestHandler

PIXEL_URL = os.environ.get("PIXEL_URL", "http://10.1.10.50:8889").rstrip("/")
ADAPTER_PORT = int(os.environ.get("ADAPTER_PORT", "8888"))
CHAT_TIMEOUT = int(os.environ.get("CHAT_TIMEOUT", "600"))
FARM_DEV = os.environ.get("FARM_DEV", "").lower() in ("1", "true", "yes")
# Model name InferrLM returns in /api/tags (we'll use first if multiple)
INFERRLM_MODEL = os.environ.get("INFERRLM_MODEL", "")


def fetch_tags():
    req = urllib.request.Request(f"{PIXEL_URL}/api/tags")
    with urllib.request.urlopen(req, timeout=15) as r:
        data = json.loads(r.read().decode())
    return data.get("models") or []


def openai_models_from_tags():
    models = fetch_tags()
    # Use first model id for completions if not set
    names = [m.get("name") or m.get("id", "") for m in models]
    return {
        "data": [
            {"id": n, "object": "model", "created": int(time.time()) - 86400, "owned_by": "inferrlm"}
            for n in names
        ],
        "object": "list",
    }, (names[0] if names and not INFERRLM_MODEL else INFERRLM_MODEL or (names[0] if names else ""))


def post_chat(body: dict):
    models, default_id = openai_models_from_tags()
    model_id = (body.get("model") or "").strip()
    # If client sent gpt-4o-mini etc., use the actual InferrLM model name
    ids = [m["id"] for m in models["data"]]
    if not model_id or model_id not in ids:
        model_id = default_id or (ids[0] if ids else "gemma-3-4b-it-Q4_K_M.gguf")
    messages = body.get("messages") or []
    stream = body.get("stream", False)
    payload = {
        "model": model_id,
        "messages": messages,
        "stream": stream,
    }
    if "max_tokens" in body:
        payload["max_tokens"] = body["max_tokens"]
    data = json.dumps(payload).encode()
    req = urllib.request.Request(
        f"{PIXEL_URL}/api/chat",
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    t0 = time.perf_counter()
    with urllib.request.urlopen(req, timeout=CHAT_TIMEOUT) as r:
        out = json.loads(r.read().decode())
    if FARM_DEV:
        print(f"[adapter] completion {round((time.perf_counter() - t0) * 1000)}ms", flush=True)
    # InferrLM returns {"response": "...", "done": true, "model": "..."}
    content = out.get("response", "")
    if stream:
        return ("stream", content, model_id)
    return ("json", {
        "id": "chatcmpl-inferrlm-1",
        "object": "chat.completion",
        "created": int(time.time()),
        "model": model_id,
        "choices": [
            {"index": 0, "message": {"role": "assistant", "content": content}, "finish_reason": "stop"}
        ],
        "usage": {"prompt_tokens": 0, "completion_tokens": 0, "total_tokens": 0},
    })


class AdapterHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        print(f"[adapter] {args[0]}")

    def do_GET(self):
        if self.path in ("/", "/health", "/health/"):
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"ok")
            return
        if self.path.rstrip("/") == "/v1/models" or self.path.rstrip("/") == "/v1/models/":
            try:
                data, _ = openai_models_from_tags()
                self.send_response(200)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps(data).encode())
            except Exception as e:
                self.send_response(502)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"error": str(e)}).encode())
            return
        self.send_response(404)
        self.end_headers()

    def do_POST(self):
        if self.path.rstrip("/") == "/v1/chat/completions" or self.path.rstrip("/") == "/v1/chat/completions/":
            try:
                length = int(self.headers.get("Content-Length", 0))
                body = json.loads(self.rfile.read(length).decode()) if length else {}
                result = post_chat(body)
                if result[0] == "stream":
                    _, content, model_id = result
                    self.send_response(200)
                    self.send_header("Content-Type", "text/event-stream")
                    self.send_header("Cache-Control", "no-cache")
                    self.send_header("Connection", "keep-alive")
                    self.end_headers()
                    # OpenAI-style SSE: one chunk with full content (InferrLM returns full; we simulate stream)
                    chunk = {"id": "chatcmpl-inferrlm-1", "object": "chat.completion.chunk", "created": int(time.time()), "model": model_id, "choices": [{"index": 0, "delta": {"content": content}, "finish_reason": None}]}
                    self.wfile.write(f"data: {json.dumps(chunk)}\n\n".encode())
                    self.wfile.write(b"data: [DONE]\n\n")
                    self.wfile.flush()
                else:
                    data = result[1]
                    self.send_response(200)
                    self.send_header("Content-Type", "application/json")
                    self.end_headers()
                    self.wfile.write(json.dumps(data).encode())
            except urllib.error.HTTPError as e:
                self.send_response(e.code)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                try:
                    err_body = e.read().decode()
                except Exception:
                    err_body = str(e)
                self.wfile.write(json.dumps({"error": {"message": err_body}}).encode())
            except Exception as e:
                self.send_response(502)
                self.send_header("Content-Type", "application/json")
                self.end_headers()
                self.wfile.write(json.dumps({"error": {"message": str(e)}}).encode())
            return
        self.send_response(404)
        self.end_headers()


def main():
    server = HTTPServer(("127.0.0.1", ADAPTER_PORT), AdapterHandler)
    print(f"InferrLM adapter: http://127.0.0.1:{ADAPTER_PORT} → {PIXEL_URL}", flush=True)
    print(f"Use in config: api_base = http://localhost:{ADAPTER_PORT}/v1", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nStopped.")
        sys.exit(0)


if __name__ == "__main__":
    main()
