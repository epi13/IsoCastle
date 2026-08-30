#!/usr/bin/env python3
"""Local-only static server for an exported IsoCastle Web build."""

from __future__ import annotations

import argparse
import functools
import http.server
import mimetypes
from pathlib import Path


class WebExportHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
        ".js": "text/javascript; charset=utf-8",
    }

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        super().end_headers()


def main() -> None:
    parser = argparse.ArgumentParser(description="Serve an IsoCastle Web export for local testing only.")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8060)
    parser.add_argument("--root", type=Path, required=True)
    args = parser.parse_args()
    root = args.root.resolve(strict=True)
    if not (root / "index.html").is_file():
        raise SystemExit(f"No index.html found under {root}")
    mimetypes.add_type("application/wasm", ".wasm")
    mimetypes.add_type("application/octet-stream", ".pck")
    handler = functools.partial(WebExportHandler, directory=str(root))
    server = http.server.ThreadingHTTPServer((args.host, args.port), handler)
    print(f"Local test server (not for production): http://{args.host}:{args.port}/", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
