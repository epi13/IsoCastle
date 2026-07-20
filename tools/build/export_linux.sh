#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$project_root"
./tools/test_all.sh
mkdir -p builds/linux
godot_bin=/home/epi13/.local/bin/godot
if printenv GODOT_BIN >/dev/null; then
  godot_bin="$(printenv GODOT_BIN)"
fi
"$godot_bin" --headless --path . --export-release Linux builds/linux/IsoCastle.x86_64
test -x builds/linux/IsoCastle.x86_64
echo "Linux export ready: builds/linux/IsoCastle.x86_64"

