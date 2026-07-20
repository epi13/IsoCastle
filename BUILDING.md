# Building and Exporting

## Prerequisites

- Godot 4.7.1 stable, standard build
- Python 3.12 or newer
- Pillow 12 or newer for deterministic raster generation
- Official Godot 4.7.1 export templates matching the editor version
- Node.js 22 and `npm ci` for browser automation
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

Verified on Fedora 44 with Godot 4.7.1: 88,700,664-byte ELF x86-64 export and clean headless startup.

## Windows export

Install matching templates and run:

    ./tools/build/export_windows.sh

The prepared output is builds/windows/IsoCastle.exe. Cross-export does not require Wine, though a Windows smoke run must be performed before a production release.

Verified cross-export output: 124,301,768-byte PE32+ x86-64 executable. A native Windows runtime test remains required for a production (non-pre-release) build.

## WebAssembly export

Install the official Godot 4.7.1 Web templates. The supported baseline is the official `web_nothreads_release.zip`: GL Compatibility, WebGL 2, single-threaded Wasm, no SharedArrayBuffer requirement, and no cross-origin-isolation requirement. Do not substitute a threaded template without documenting its stricter hosting requirements.

Run:

    PATH=/home/epi13/.local/bin:$PATH ./tools/build/export_web.sh

The script resolves Godot from `PATH` and falls back to `/home/epi13/.local/bin/godot`, checks for 4.7.1, runs the complete project validation, exports outside the project tree, replaces only `builds/web`, validates required files, and creates a reproducible archive. It is safe to rerun.

The generated entry point is `builds/web/index.html`. The directory also contains Godot's JavaScript bootstrap/worklets, `.wasm`, `.pck`, icons, and `builds/web/IsoCastle-web.zip`. The ZIP has `index.html` at its root and is deployable without renaming generated support files. Generated exports and ZIPs are intentionally ignored by Git.

Validate an existing export without rebuilding:

    ./tools/build/validate_web_export.sh

Serve it locally:

    ./tools/build/serve_web.sh 8060

The development helper binds only to `127.0.0.1`, serves `builds/web` rather than the repository, and sends `.wasm` as `application/wasm` and `.pck` as `application/octet-stream`. Open `http://127.0.0.1:8060/index.html`; `file://` does not provide the HTTP origin, MIME handling, or browser storage needed for a valid test. The helper is not a production server.

The current measured release payload is documented in WORKLOG.md. Production deployment requirements are in WEB_DEPLOYMENT.md.

## Continuous integration

`.github/workflows/ci.yml` pins Godot 4.7.1, Python 3.12, Pillow 12.3.0, Node 22, and the package-lock Playwright dependency. CI runs all content/art/audio/import/headless tests through `export_web.sh`, validates and archives the Web export, runs the Chromium browser smoke flow, uploads `IsoCastle-web.zip`, and uploads browser diagnostics on failure. It does not enable or deploy GitHub Pages.
