#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
port="${1:-8060}"
if [[ ! "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
  echo "Port must be an integer from 1 through 65535." >&2
  exit 2
fi
url="http://127.0.0.1:$port/"
echo "Serving only $project_root/builds/web"
echo "Open $url"
echo "This helper is for local testing, not production hosting."
exec python3 "$project_root/tools/build/web_server.py" --root "$project_root/builds/web" --host 127.0.0.1 --port "$port"
