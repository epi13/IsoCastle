#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if command -v godot >/dev/null 2>&1; then
  godot_bin="$(command -v godot)"
elif [[ -x /home/epi13/.local/bin/godot ]]; then
  godot_bin=/home/epi13/.local/bin/godot
else
  echo "Godot 4.7.1 is required." >&2
  exit 2
fi

python3 tools/generate_content.py --check
python3 tools/content_validation/validate_content.py
"$godot_bin" --headless --path . --import
"$godot_bin" --headless --path . --script res://game/tests/test_runner.gd
"$godot_bin" --headless --path . --script res://game/tests/smoke_test.gd
echo "ALL ISOCASTLE TESTS PASSED"
