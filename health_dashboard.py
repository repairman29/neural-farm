#!/usr/bin/env python3
"""
Minimal health dashboard: serves a single HTML page that shows farm status.
Run: python health_dashboard.py   then open http://127.0.0.1:9999
"""

import json
import urllib.request
from http.server import HTTPServer, BaseHTTPRequestHandler

PORT = 9999
ENDPOINTS = [
    ("Pixel (8888)", "http://127.0.0.1:8888/health"),
    ("iPhone (8887)", "http://127.0.0.1:8887/health"),
    ("Proxy (4000)", "http://127.0.0.1:4000/health"),
]


def check(url, timeout=2):
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status_code == 200, None
    except Exception as e:
        return False, str(e)


class Handler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass

    def do_GET(self):
        if self.path != "/" and self.path != "/health":
            self.send_error(404)
            return
        statuses = []
        for label, url in ENDPOINTS:
            ok, err = check(url)
            statuses.append({"label": label, "up": ok, "error": err})
        all_up = all(s["up"] for s in statuses)
        html = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Neural Farm</title>
<style>
  body {{ font-family: system-ui; max-width: 360px; margin: 2rem auto; padding: 0 1rem; }}
  h1 {{ font-size: 1.25rem; }}
  ul {{ list-style: none; padding: 0; }}
  li {{ padding: 0.5rem; margin: 0.25rem 0; border-radius: 6px; }}
  .up {{ background: #d4edda; color: #155724; }}
  .down {{ background: #f8d7da; color: #721c24; }}
  .status {{ font-weight: bold; }}
</style></head><body>
  <h1>Neural Farm</h1>
  <ul>
    {"".join(f'<li class="{"up" if s["up"] else "down"}"><span class="status">{"✓" if s["up"] else "✗"}</span> {s["label"]}' + (f' — {s["error"]}' if s.get("error") else '') + '</li>' for s in statuses)}
  </ul>
  <p>{"All up." if all_up else "Start: ./dev_farm.sh"}</p>
</body></html>"""
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.end_headers()
        self.wfile.write(html.encode("utf-8"))


def main():
    server = HTTPServer(("127.0.0.1", PORT), Handler)
    print(f"Health dashboard: http://127.0.0.1:{PORT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
