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

The required coverage includes unique IDs, schema and resource paths, sprite metadata and required animations, dialogue/quest/item/spell/enemy/loot references, floor connectivity and lock solvability, save round trips and migration, deterministic combat, statuses, AI transitions, pathfinding, inventory/equipment/merchant rules, player death, level transitions, menu/new-game loading, and the scripted campaign interaction path.

Every failing check returns a nonzero exit code. CI uploads logs and validation summaries when a run fails.
