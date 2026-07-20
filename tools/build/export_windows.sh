#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$project_root"
./tools/test_all.sh
mkdir -p builds/windows
godot_bin=/home/epi13/.local/bin/godot
if printenv GODOT_BIN >/dev/null; then
  godot_bin="$(printenv GODOT_BIN)"
fi
"$godot_bin" --headless --path . --export-release "Windows Desktop" builds/windows/IsoCastle.exe
test -f builds/windows/IsoCastle.exe
echo "Windows export ready: builds/windows/IsoCastle.exe"

