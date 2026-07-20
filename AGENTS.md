# AGENTS.md

These instructions apply to the entire repository.

## Product rules

IsoCastle is an original Godot 4.7 game. Never import, trace, scrape, paraphrase, or reproduce protected material from Castle of the Winds or another game. All committed art, text, and audio must be original and reproducible from project scripts when practical. Do not introduce third-party assets without documenting provenance and redistribution terms in ASSET_MANIFEST.md. Preserve the repository's pre-existing Apache-2.0 LICENSE; RIGHTS.md explains the temporary asset-rights posture requested by the owner.

## Architecture and conventions

- Use typed GDScript wherever practical, tabs for GDScript indentation, snake_case files/functions, PascalCase classes, and stable string IDs for content.
- Keep gameplay state deterministic. Visual interpolation, particles, and audio must not change turn results.
- Keep definitions in content/*.json. Do not hard-code bulk item, spell, enemy, quest, or dialogue catalogs in gameplay scripts.
- Save data is versioned, migrated, atomically replaced, and separately stored from settings.
- Generated outputs live under assets/generated, assets/sprites, assets/tiles, assets/ui, assets/music, and assets/sounds. Source scripts and seeds live under tools and assets/source.
- Never commit .godot, local logs, exports, caches, or secrets.
- Preserve unrelated work. Use apply_patch for hand-authored text and code edits.

## Directory map

- game/autoload: global services and immutable catalogs
- game/core: turn state, rules, events, and shared types
- game/world and game/generation: maps, projection, visibility, paths, and procedural floors
- game/actors, game/ai, game/combat: actors, deterministic AI, and combat resolution
- game/inventory, game/items, game/spells: player build and possessions
- game/quests and game/dialogue: externally-authored narrative state
- game/ui: menus and in-game interface
- game/save: versioned persistence and migration
- content: localization-ready JSON definitions
- assets: original sources and generated runtime media
- tools: deterministic generators, validators, test and export wrappers
- tests and game/tests: Python/static and Godot/headless tests

## Dependable commands

    python3 tools/generate_content.py --check
    python3 tools/content_validation/validate_content.py
    python3 tools/art_pipeline/generate_art.py --check
    python3 tools/audio_pipeline/generate_audio.py --check
    godot --headless --path . --import
    godot --headless --path . --script res://game/tests/test_runner.gd
    godot --headless --path . --script res://game/tests/smoke_test.gd
    ./tools/test_all.sh
    ./tools/build/export_linux.sh

Use /home/epi13/.local/bin/godot if godot is not on PATH. Asset regeneration is deterministic under Python 3.12+ with Pillow.

## Completion criteria

Do not call the game complete unless the title, character creation, campaign path, tactical movement/combat, inventory/equipment, spellbook, quests/dialogue, merchant, procedural floors, AI, saves, settings, intro/endings/credits, original graphics/audio, validation, headless tests, Linux export, documentation, main merge, and pre-release tag are all verified. Update WORKLOG.md and NEXT_STEPS.md after every coherent milestone, including exact commands and failures.

