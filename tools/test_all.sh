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
python3 tools/art_pipeline/generate_art.py --check
python3 tools/audio_pipeline/generate_audio.py --check
python3 tools/content_validation/validate_content.py
python3 tools/art_pipeline/validate_art.py
python3 tools/audio_pipeline/validate_audio.py

test_log="$(mktemp)"
trap 'rm -f "$test_log"' EXIT

run_godot_checked() {
  : > "$test_log"
  "$godot_bin" "$@" 2>&1 | tee "$test_log"
  if rg -q 'SCRIPT ERROR|Parse Error|ERROR:' "$test_log"; then
    echo "Godot reported an engine or script error." >&2
    return 1
  fi
}

run_godot_checked --headless --path . --import
run_godot_checked --headless --path . --script res://game/tests/test_runner.gd
run_godot_checked --headless --path . --script res://game/tests/smoke_test.gd
run_godot_checked --headless --path . --script res://game/tests/campaign_test.gd
echo "ALL ISOCASTLE TESTS PASSED"
