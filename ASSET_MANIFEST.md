# Asset Manifest and Provenance

All project-specific visual and audio assets are original and generated for IsoCastle.

## Deterministic visual assets

- Generator: tools/art_pipeline/generate_art.py
- Seed: 130713
- Dependencies: Python 3 and Pillow
- Outputs: title art, portraits, item icons, terrain, prop sheets, actor sheets, enemy sheets, effects, UI ornaments, map symbols, and loading illustrations
- Manifest: assets/generated/art_manifest.json, containing dimensions, modes, hashes, pivots, directions, and animation coverage

## Deterministic audio assets

- Generator: tools/audio_pipeline/generate_audio.py
- Seed: 44117
- Dependencies: Python standard library
- Outputs: original PCM WAV score, ambience, UI, weapon, creature, environment, and spell sounds
- Manifest: assets/generated/audio_manifest.json, containing format, duration, peak, category, and hash

## Fonts and third-party material

The runtime uses Godot's built-in system font fallback until an original bundled font is generated or a redistributable font is explicitly approved and documented. No third-party art, icons, music, sound libraries, samples, or game resources are included.

The repository's Apache-2.0 LICENSE existed in the initial remote commit. RIGHTS.md records the owner's requested temporary rights notice for original project assets without altering that existing file.

