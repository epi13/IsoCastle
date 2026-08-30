#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
web_dir="$project_root/builds/web"

if [[ ! -s "$web_dir/index.html" ]]; then
  echo "Missing or empty Web entry point: $web_dir/index.html" >&2
  exit 1
fi

mapfile -d '' wasm_files < <(find "$web_dir" -maxdepth 1 -type f -name '*.wasm' -size +0c -print0)
mapfile -d '' pck_files < <(find "$web_dir" -maxdepth 1 -type f -name '*.pck' -size +0c -print0)
mapfile -d '' js_files < <(find "$web_dir" -maxdepth 1 -type f -name '*.js' -size +0c -print0)

if (( ${#wasm_files[@]} == 0 )); then
  echo "Web export has no non-empty .wasm module." >&2
  exit 1
fi
if (( ${#pck_files[@]} == 0 )); then
  echo "Web export has no non-empty .pck package." >&2
  exit 1
fi
if (( ${#js_files[@]} == 0 )); then
  echo "Web export has no non-empty JavaScript bootstrap." >&2
  exit 1
fi

echo "Validated Web export files:"
find "$web_dir" -maxdepth 1 -type f ! -name 'IsoCastle-web.zip' -printf '  %f %s bytes\n' | sort
total_size="$(find "$web_dir" -maxdepth 1 -type f ! -name 'IsoCastle-web.zip' -printf '%s\n' | awk '{total += $1} END {print total + 0}')"
echo "Total uncompressed size: $total_size bytes"
