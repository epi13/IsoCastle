# Building and Exporting

## Prerequisites

- Godot 4.7.1 stable, standard build
- Python 3.12 or newer
- Pillow 12 or newer for deterministic raster generation
- FFmpeg is optional for inspection; committed runtime audio is PCM WAV

Godot is locally available at /home/epi13/.local/bin/godot on the original Fedora workstation.

## Development

    PATH=/home/epi13/.local/bin:$PATH godot --editor --path .
    PATH=/home/epi13/.local/bin:$PATH godot --path .

## Regenerate and validate

    python3 tools/generate_content.py
    python3 tools/art_pipeline/generate_art.py
    python3 tools/audio_pipeline/generate_audio.py
    PATH=/home/epi13/.local/bin:$PATH ./tools/test_all.sh

## Linux export

Install matching Godot 4.7.1 export templates, then run:

    ./tools/build/export_linux.sh

The output is builds/linux/IsoCastle.x86_64. The script refuses to export when required validation fails.

Verified on Fedora 44 with Godot 4.7.1: 85 MB ELF x86-64 export, clean headless startup.

## Windows export

Install matching templates and run:

    ./tools/build/export_windows.sh

The prepared output is builds/windows/IsoCastle.exe. Cross-export does not require Wine, though a Windows smoke run must be performed before a production release.

Verified cross-export output: 119 MB PE32+ x86-64 executable. A native Windows runtime test remains required for a production (non-pre-release) build.
