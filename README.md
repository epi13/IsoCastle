# IsoCastle

IsoCastle is an original, single-player isometric fantasy role-playing game built with Godot 4.7.1 for Linux, Windows, and WebAssembly browsers. You return to the remote harbor of Greywake just as an impossible aurora wakes the buried Bell Below. Explore a compact northern wilderness, descend through changing procedural vaults, master eight magical practices, and decide what the bell should become.

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

Build and serve the single-threaded WebAssembly release with:

    PATH=/home/epi13/.local/bin:$PATH ./tools/build/export_web.sh
    ./tools/build/serve_web.sh 8060

Then open `http://127.0.0.1:8060/index.html`; a Web export cannot be tested correctly through `file://`. See [CONTROLS.md](CONTROLS.md) for inventory and remapping controls and [WEB_DEPLOYMENT.md](WEB_DEPLOYMENT.md) for hosting and browser-storage constraints.

## Status

The unchanged `v0.9.0` pre-release milestone is merged to `main`. The post-v0.9 inventory, input-remapping, and supported WebAssembly milestone is developed on `codex/post-v0.9-inventory-input-wasm`. WORKLOG.md records verified progress and NEXT_STEPS.md is the exact continuation point. Native Windows execution is still required before promotion beyond pre-release.
