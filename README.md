# IsoCastle

IsoCastle is an original, single-player isometric fantasy role-playing game built with Godot 4.7. You return to the remote harbor of Greywake just as an impossible aurora wakes the buried Bell Below. Explore a compact northern wilderness, descend through changing procedural vaults, master eight magical practices, and decide what the bell should become.

The game is inspired by the spirit of classic shareware-era fantasy RPGs, including Castle of the Winds. It uses no code, assets, names, maps, text, audio, or extracted resources from those games.

## Quick start

    godot --editor --path .
    godot --path .

Run all validation and headless tests with:

    ./tools/test_all.sh

Generate deterministic content, art, and audio with:

    python3 tools/generate_content.py
    python3 tools/art_pipeline/generate_art.py
    python3 tools/audio_pipeline/generate_audio.py

See BUILDING.md and TESTING.md for full instructions.

## Status

Active development takes place on codex/full-isometric-game. WORKLOG.md records verified progress and NEXT_STEPS.md is the exact continuation point.
