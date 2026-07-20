# Testing

## Full local suite

    PATH=/home/epi13/.local/bin:$PATH ./tools/test_all.sh

The wrapper runs deterministic content regeneration checks, Python schema/reference/manifest tests, a Godot import, GDScript unit tests, and the automated gameplay smoke path.

## Individual checks

    python3 tools/content_validation/validate_content.py
    python3 tools/art_pipeline/validate_art.py
    python3 tools/audio_pipeline/validate_audio.py
    godot --headless --path . --script res://game/tests/test_runner.gd
    godot --headless --path . --script res://game/tests/smoke_test.gd
    godot --headless --path . --script res://game/tests/campaign_test.gd
    godot --headless --path . --quit-after 3

The required coverage includes unique IDs, schema and resource paths, sprite metadata and required animations, dialogue/quest/item/spell/enemy/loot references, floor connectivity and lock solvability, save round trips, backup recovery and migration, deterministic combat, statuses, AI transitions, pathfinding, transactional inventory/equipment/merchant rules, input serialization/migration/conflicts, player death, level transitions, menu/new-game loading, and the scripted campaign interaction path.

Every failing check returns a nonzero exit code.

## Web export and browsers

Create and validate the release export before testing:

    PATH=/home/epi13/.local/bin:$PATH ./tools/build/export_web.sh
    npm ci
    npx playwright install chromium firefox
    npm run test:web

The repository pins Playwright 1.61.1. Browser binaries and dependency caches are not committed. On unsupported Linux distributions Playwright may use its matching Ubuntu fallback build; the exact warning and tested browser versions belong in WORKLOG.md.

The automated test starts the local HTTP helper and fails on missing/failed `.wasm` or `.pck` requests, uncaught JavaScript exceptions, fatal startup console errors, or failed network requests. In each browser it verifies the canvas and title, intentional audio activation, mouse settings navigation, volume persistence, temporary physical-key remapping, the remapped gameplay action, reset to default, save creation/load after reload, surrounding-page scroll suppression, focus recovery, a literal mouse inventory drag to equipment, no item count change, and inventory/equipment persistence through another save and reload.

Run one engine while diagnosing:

    npm run test:web:chromium
    npm run test:web:firefox

Screenshots, traces, and browser diagnostics are written under ignored `artifacts/browser/test-results`. A browser pass does not constitute a native Windows runtime pass.

## Desktop exports

After gameplay changes, run:

    PATH=/home/epi13/.local/bin:$PATH ./tools/build/export_linux.sh
    PATH=/home/epi13/.local/bin:$PATH ./tools/build/export_windows.sh

Smoke-run the Linux executable where practical. A Fedora cross-export and PE inspection verify production of the Windows binary, not native Windows execution.
