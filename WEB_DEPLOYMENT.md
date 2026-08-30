# Web Deployment

IsoCastle's supported browser build is the official Godot 4.7.1 single-threaded Web export using the GL Compatibility renderer and WebGL 2. It does not require SharedArrayBuffer or cross-origin isolation. The threaded template is not the supported baseline.

## Build and package

    PATH=/home/epi13/.local/bin:$PATH ./tools/build/export_web.sh

Deploy `builds/web/IsoCastle-web.zip` after extraction, or copy every generated file from `builds/web` except the ZIP itself. `index.html` must remain at the site root relative to its generated `.js`, `.wasm`, `.pck`, worklet, image, and icon files. Do not rename individual generated files.

Production hosting must return successful responses and at least these MIME types:

- `.wasm`: `application/wasm`
- `.pck`: `application/octet-stream`
- `.js`: a JavaScript content type

The single-threaded build does not need COOP/COEP headers. Serve over HTTP(S), not `file://`. The repository helper is local development infrastructure, not a hardened public server.

## Browser expectations

Automated desktop coverage currently uses Playwright-managed Chromium 149.0.7827.55 and Firefox 151.0 at 1280×720. Both completed title/new-game startup, keyboard and mouse input, remapping, save/settings reload, audio activation, and literal inventory drag-and-drop. Mobile layout and physical gamepad hardware remain best-effort rather than release-gating browser coverage.

Godot's Web audio context may remain suspended until a click or key press. IsoCastle loads without audio and requests music after intentional interaction; autoplay blocking must not prevent gameplay. Music/effects/master controls, including mute, remain available and persist when browser storage works.

Arrow, movement, and space input is consumed by the focused game canvas so it does not scroll the surrounding page. Clicking the canvas restores game focus. Fullscreen is optional and initiated only from its Settings toggle; browsers may deny fullscreen based on their user-gesture or embedding policies. Browser-reserved shortcuts are not dependable game bindings.

## Browser storage

Godot maps `user://` to browser storage when available. IsoCastle keeps settings and versioned save slots separate, verifies temporary files before atomic-style replacement, preserves the previous valid file as a backup, and explicitly requests a Web filesystem sync. The browser flush is asynchronous; tests allow the synchronization interval before reloading. A corrupted primary save falls back to the previous verified backup.

Durability is subject to browser policy. Private/incognito sessions, blocked storage, embedded third-party contexts, storage quotas, and user-cleared site data may make persistence temporary or unavailable. `OS.is_userfs_persistent()` is reported to diagnostics but can itself be optimistic on some browsers. Failed writes return actionable in-game/log diagnostics and must not crash gameplay; the game does not promise survival after site-data clearing.

## CI and publication

Ordinary CI builds and validates the Web ZIP, runs Chromium, and uploads the ZIP as a workflow artifact. It does not publish GitHub Pages. Any public deployment or Pages workflow requires an intentional separate manual/release trigger and explicit owner authorization.

## Official references

- Godot 4.7.1 downloads: https://godotengine.org/download/archive/4.7.1-stable/
- Godot Web export and hosting requirements: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html
- Godot `JavaScriptBridge` filesystem synchronization: https://docs.godotengine.org/en/stable/classes/class_javascriptbridge.html
