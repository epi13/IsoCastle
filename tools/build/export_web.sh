#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$project_root"

if command -v godot >/dev/null 2>&1; then
  godot_bin="$(command -v godot)"
elif [[ -x /home/epi13/.local/bin/godot ]]; then
  godot_bin=/home/epi13/.local/bin/godot
else
  echo "Godot 4.7.1 is required." >&2
  exit 2
fi

godot_version="$($godot_bin --version)"
echo "Godot version: $godot_version"
if [[ "$godot_version" != 4.7.1.* ]]; then
  echo "Expected Godot 4.7.1, found $godot_version" >&2
  exit 2
fi

./tools/test_all.sh

web_dir="$project_root/builds/web"
mkdir -p "$web_dir"
if [[ "$web_dir" != "$project_root/builds/web" ]]; then
  echo "Refusing to replace unexpected Web output path: $web_dir" >&2
  exit 2
fi
find "$web_dir" -mindepth 1 -depth -delete

export_temp="$(mktemp -d /tmp/IsoCastle-web-export.XXXXXX)"
archive_temp=""
trap 'if [[ -d "$export_temp" ]]; then find "$export_temp" -depth -delete; fi; if [[ -n "$archive_temp" ]]; then rm -f "$archive_temp"; fi' EXIT
"$godot_bin" --headless --path . --export-release Web "$export_temp/index.html"
find "$export_temp" -mindepth 1 -maxdepth 1 -exec mv -t "$web_dir" -- {} +
./tools/build/validate_web_export.sh

archive_temp="$(mktemp /tmp/IsoCastle-web.XXXXXX.zip)"
rm -f "$archive_temp"
export TZ=UTC
find "$web_dir" -maxdepth 1 -type f -exec touch -d '@1307130000' {} +
(
  cd "$web_dir"
  zip -X -q -r "$archive_temp" . -x 'IsoCastle-web.zip'
)
mv "$archive_temp" "$web_dir/IsoCastle-web.zip"
rmdir "$export_temp"
trap - EXIT

archive_listing="$(zipinfo -1 "$web_dir/IsoCastle-web.zip")"
if ! grep -qx 'index.html' <<<"$archive_listing"; then
  echo "Web archive does not contain index.html at its root." >&2
  exit 1
fi
if grep -q '^builds/web/' <<<"$archive_listing"; then
  echo "Web archive contains an unwanted builds/web parent directory." >&2
  exit 1
fi
echo "Web archive: builds/web/IsoCastle-web.zip $(stat -c '%s' "$web_dir/IsoCastle-web.zip") bytes"
