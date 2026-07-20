# Worklog

## 2026-07-19

### Post-v0.9 recovery and baseline

- Recovered the clean checkout on `codex/full-isometric-game` at `52bfc323949a762703a7057ef38cc044fbf38e1b`; no modified, staged, or untracked files and no interrupted Git operation were present.
- Verified local `main`, `origin/main`, `origin/codex/full-isometric-game`, and annotated `v0.9.0` all resolve to the release-record commit after `git fetch origin --prune --tags`; the tag was not changed.
- Verified GitHub access with `gh auth status`, `gh repo view epi13/IsoCastle`, `git ls-remote origin`, and the authenticated fetch.
- Confirmed Godot `4.7.1.stable.official.a13da4feb`, Python `3.14.6`, Git `2.55.0`, and GitHub CLI `2.94.0` on Fedora 44.
- Ran the untouched baseline with `PATH=/home/epi13/.local/bin:$PATH ./tools/test_all.sh`: content generation/schema validation, 364-art validation, 310-audio validation, Godot import, 573 assertions, interaction smoke, and campaign playthrough all passed and reported `ALL ISOCASTLE TESTS PASSED`.
- Ran the additional startup check `PATH=/home/epi13/.local/bin:$PATH godot --headless --path . --quit-after 3`; it exited successfully without script or engine errors.
- Inspected native-Windows options. No Windows host, VM, configured Windows runner, or owner-approved remote execution path is available; native execution remains externally blocked and Wine is not being represented as native testing.
- Found the installed Godot 4.7.1 export templates contain Linux and Windows templates but no Web templates. Matching official Web templates are required for this milestone.
- Created `codex/post-v0.9-inventory-input-wasm` directly from verified `origin/main` for the inventory, input-remapping, and browser-support work.

### Transactional inventory drag-and-drop milestone

- Added transactional domain operations for bounded add, move, reorder, swap, compatible merge, metadata-safe split, equip, equipment replacement, unequip, equipment-slot movement, destination validation, and cancellation. Failed operations return explicit reasons without partially mutating state.
- Changed equipment ownership from duplicate item-ID references to metadata-preserving stack records and advanced save schema 3 to 4 with migration that extracts previously equipped items from legacy inventory exactly once.
- Added a literal Godot drag-and-drop inventory surface using `_get_drag_data`, `_can_drop_data`, `_drop_data`, and `set_drag_preview`, with valid/invalid destination tinting, a drag ghost, tooltip details, right-click split amount selection, keyboard/controller activation, and focus restoration.
- Added player-facing InputMap actions for prepared casting, ranged attack, and quick item use, replacing their direct physical-key checks.
- Extended tests from 573 to 599 assertions for inventory operations, requirement and slot rejection, capacity, cancellation, metadata, weight, save/load, schema migration, duplication, and loss. Extended the interaction smoke path to invoke UI drag, equipment replacement, and cancellation through the slot controls.
- Ran `PATH=/home/epi13/.local/bin:$PATH godot --headless --path . --import`, the unit runner, and the smoke runner successfully during implementation.
- Ran `PATH=/home/epi13/.local/bin:$PATH ./tools/test_all.sh`; all content/art/audio validation, Godot import, 599 assertions, inventory interaction smoke, and campaign playthrough passed with `ALL ISOCASTLE TESTS PASSED`.

### Versioned input-remapping milestone

- Added an explicit immutable default-binding catalog for 23 player-facing actions: eight-direction movement, wait, interact, search, inventory, spellbook, journal, map, ranged attack, prepared spell, quick item, quick save/load, pause/cancel, overlay, and screenshot mode.
- Added stable binding serialization for physical keyboard keys, mouse buttons, controller buttons, and signed controller axes; no runtime object dumps are persisted.
- Added format-2 migration for renamed actions, safe handling for removed/unknown actions, default inheritance for new actions, controller-axis deadzones/noise rejection, browser-reserved shortcut rejection, conflict detection, explicit conflict movement, and protection for the final pause/cancel binding.
- Extended `SettingsService` with atomic settings replacement, separate input persistence, runtime `InputMap` restoration during startup, clear/reset-one/reset-all operations, and human-readable current binding labels.
- Added the full settings editor with capture overlay, cancellation, conflict confirmation, mouse navigation, focusable keyboard/controller controls, per-binding clear/replace, add-binding, per-action reset, and reset-all confirmation.
- Replaced remaining remappable gameplay physical-key checks and updated in-game help, stairs, spellbook, inventory, and game-over prompts to read active bindings.
- Extended the headless suite to 624 assertions, including defaults, every supported event type, conflicts, conflict resolution, capture no-op, clear/reset, persistence, migration, renamed/unknown actions, protected cancel, new-action defaults, and browser-safe behavior.
- Ran `PATH=/home/epi13/.local/bin:$PATH ./tools/test_all.sh`; all validation, Godot import, 624 assertions, input-editor/inventory interaction smoke, and campaign playthrough passed with `ALL ISOCASTLE TESTS PASSED`.

### Supported WebAssembly/browser milestone

- Installed the official matching Godot 4.7.1 `web_nothreads_debug.zip` and `web_nothreads_release.zip` templates. SHA-256: `eb6ca0ca168c405e73b20a4439d6dc048d74ae65eb31cc7675b6bc3cf7ad1815` (debug) and `b7b7d7da29fc6cc2f4934fdd26cc571a40e7af57f716ea3eb7e18da720dae28a` (release).
- The official complete 1.19 GiB template archive download stalled twice at 188,006,400 bytes in this environment. Resolution: fetched the two exact non-threaded Web ZIP entries by HTTP range from the official Godot archive and verified both nested ZIPs with `unzip -t`; no engine compilation or unofficial template was used.
- Added the `Web` preset using Compatibility/WebGL 2 and the official single-threaded template. Hardened export filters against builds, browser dependencies/artifacts, tools, tests, source generators, documentation, and desktop-only development files.
- Added `tools/build/export_web.sh`, `validate_web_export.sh`, `serve_web.sh`, and a local-only MIME-aware Python server. The exporter validates first, exports to an external temporary directory, replaces only `builds/web`, verifies non-empty HTML/JavaScript/Wasm/PCK files, normalizes archive timestamps, and validates a root-layout ZIP.
- The first ZIP attempt failed because `mktemp` left an empty file that `zip` treated as a corrupt existing archive; the script now removes that exact temporary file before archive creation. A direct in-project repeat export also grew `index.pck` from about 15.2 MB to 40.8 MB by ingesting `node_modules` and earlier outputs; exporting outside the project and explicit exclusions restored the expected payload. Parent `.gdignore` files keep generated browser screenshots and Web icons out of Godot's import scan.
- Verified the server with HTTP requests: `index.html` returned `200 text/html`, `.wasm` returned `200 application/wasm`, and `.pck` returned `200 application/octet-stream`.
- Added a feature-gated Web diagnostics bridge for deterministic automation state without putting gameplay logic in JavaScript. Added user-initiated Web fullscreen behavior and explicit browser-storage status/synchronization after verified save/settings replacement.
- The first immediate Chromium save reload found that a successful `user://` write had not yet reached IndexedDB. Resolution: call `JavaScriptBridge.force_fs_sync()` after successful replacement and allow the asynchronous Web filesystem interval before reload. Settings, remapping, save-slot metadata, save load, and equipped-item state subsequently persisted across reloads. Added headless corruption recovery coverage showing an interrupted/corrupt primary load falls back to the prior valid backup.
- Installed project-local Playwright 1.61.1 with a locked dependency graph. Fedora is not an officially identified Playwright host, so it reported its Ubuntu 24.04 fallback browser build; browser binaries remain untracked.
- Ran `npx playwright test --project=chromium`: passed the full browser flow in Chrome for Testing/Chromium `149.0.7827.55`. Ran `npx playwright test --project=firefox`: passed the identical flow in Firefox `151.0`. Both verified successful Wasm/PCK responses, title and new game, intentional audio activation, mouse settings controls, volume/remap persistence, remapped keyboard gameplay input, reset defaults, save/load, focus/page behavior, real mouse inventory drag with visible drag ghost, unchanged total item count, equipment persistence, and no fatal console/page/network failures.
- Final nonfatal browser diagnostics contained Chromium GPU-stall warnings from WebGL `readPixels` and Firefox warnings that the official template's legacy Wasm exception-handling `try` instruction is deprecated. An earlier exploratory Chromium launch also reported a transient `CONTEXT_LOST_WEBGL`; it recovered. Final runs had zero console errors, page exceptions, or failed requests in both browsers.
- Extended GitHub Actions to install matching templates, run the entire validation suite through the Web exporter, install Node 22/locked Playwright, run Chromium, upload `IsoCastle-web.zip`, and preserve browser artifacts on failure. No Pages publication was added.
- Current measured Web release output: `index.html` 5,443 bytes; JavaScript bootstrap/worklets 290,086 bytes total; `index.wasm` 39,513,091 bytes; `index.pck` 15,230,392 bytes; icons/images 39,087 bytes; 55,078,099 bytes total uncompressed. `builds/web/IsoCastle-web.zip` is 21,227,295 bytes and contains `index.html` at its root.
- Native Windows availability was rechecked and remains externally blocked: no Windows host, VM, configured Windows runner, or approved remote test mechanism is present. The `v0.9.0` tag remains unchanged and the project remains pre-release.

### Final integrated verification for the post-v0.9 branch

- `PATH=/home/epi13/.local/bin:$PATH ./tools/test_all.sh` passed content generation/schema checks, 364-art validation, 310-audio validation, Godot import, 626 assertions, interaction smoke, and the 12-depth scripted campaign; final line: `ALL ISOCASTLE TESTS PASSED`.
- `PATH=/home/epi13/.local/bin:$PATH ./tools/build/export_web.sh` passed the same validation, created and validated every required Web file, and validated the deployable ZIP layout.
- `npm run test:web` ran both projects serially and reported `2 passed (1.2m)`. Final browser diagnostics record Chromium `149.0.7827.55` and Firefox `151.0`.
- `PATH=/home/epi13/.local/bin:$PATH ./tools/build/export_linux.sh` passed validation and produced `builds/linux/IsoCastle.x86_64`, 88,700,664 bytes, identified as ELF x86-64. `timeout 20s builds/linux/IsoCastle.x86_64 --headless --quit-after 3` exited successfully after Godot 4.7.1 startup.
- `PATH=/home/epi13/.local/bin:$PATH ./tools/build/export_windows.sh` passed validation and produced `builds/windows/IsoCastle.exe`, 124,301,768 bytes, identified as PE32+ x86-64. It was not executed because no genuine Windows environment is available.
- `./tools/build/validate_web_export.sh`, `zipinfo -1 builds/web/IsoCastle-web.zip`, `python3 -m py_compile tools/build/web_server.py`, `node --check tests/browser/web_smoke.spec.mjs`, `npm ls --depth=0`, and `git diff --check` all passed.
- Repeated `PATH=/home/epi13/.local/bin:$PATH ./tools/build/export_web.sh` without source changes. Both ZIPs had SHA-256 `8081f3568d12af9c9b29aaa6b69cd7519f9f869827a69b3545ab4aaefccf6b11`, confirming byte-for-byte reproducibility in the verified environment.
- Pushed only `codex/post-v0.9-inventory-input-wasm` and opened draft PR #2, `Add inventory remapping and WebAssembly support`: https://github.com/epi13/IsoCastle/pull/2. No merge was performed.
- GitHub Actions push run `29713329307` and PR run `29713344526` both passed. The PR run completed the full exporter and Chromium smoke job in 2m22s and uploaded the `IsoCastle-web` workflow artifact (GitHub wrapper size 21,184,950 bytes). The runner emitted one nonfatal platform annotation that older action majors targeting Node 20 were forced onto Node 24; no build or test step failed.

### Completed

- Confirmed Fedora 44 host and exact workspace path.
- Cloned the remote to /home/epi13/Documents/Projects/IsoCastle.
- Inspected and preserved remote commit 2eb9acd and its Apache-2.0 LICENSE.
- Created codex/full-isometric-game.
- Installed Godot 4.7.1 and GitHub CLI 2.94.0 under /home/epi13/.local without sudo.
- Established design, architecture, art, audio, campaign, testing, build, rights, and continuation documents.
- Created a runnable Godot 4.7 title scene with six menu actions, settings/audio/input foundations, and versioned atomic save services.
- Generated and validated 150 items, 30 affixes, 48 spells, 54 enemies, 26 NPCs, 32 quests, 130 dialogue nodes, 32 lore entries, 12 environments, and 12 loot tables.
- Added deterministic content generation, schema and cross-reference validation, 464 headless Godot checks, smoke testing, and GitHub Actions.
- Implemented eight-direction grid pathfinding, line of sight, fog of war, deterministic rooms/corridors, connectivity/key-order checks, traps, chests, stairs, and 12 themed campaign depths.
- Implemented deterministic melee/spell combat, damage/armor/resistance/critical rules, status ticks, energy scheduling, alert/investigate/search/return/retreat AI, progression, inventory stacking/splitting/weight, equipment requirements, consumables, merchant prices and trade.
- Completed character creation, intro, title, settings/accessibility, five save slots, pause/load/game-over, inventory/equipment, spellbook, journal, map legend, external-data dialogue, NPC services, act transitions, three endings, credits, developer metrics, screenshot mode, and post-game state.
- Generated and validated 364 original raster assets from deterministic source: 150 icons, 48 VFX sheets, 54 enemy sheets, 26 NPC sheets, 6 player sheets, 32 portraits, 24 terrain tiles, 12 loading illustrations, 10 object sheets, title art, and logo.
- Generated and validated 310 original WAV assets: 12 stereo music cues and 298 effects/ambiences. Every spell and enemy audio reference is present.
- Expanded headless coverage to 573 rule/content assertions, full interaction smoke, and a scripted 12-theme campaign playthrough.
- Installed official Godot 4.7.1 Linux/Windows export templates locally, exported both desktop targets, and smoke-ran the Linux export.

### Current work

- v0.9.0 pre-release published; native Windows execution and post-release polish remain.

### Tests and failures

- git ls-remote and clone succeeded.
- Initial GitHub HTTPS dry-run and SSH authentication checks failed, and `gh auth status` remains unauthenticated.
- Resolution: the configured Git HTTPS credential path proved functional; all milestone branch pushes succeeded. GitHub merged PR #1 remotely as a non-conflicting merge commit, which was preserved and fast-forwarded locally.
- Content validation passed with all catalog targets.
- Godot import and main-menu startup passed without parser or resource errors.
- Headless unit test runner passed 464 checks.
- Automated title-screen smoke test passed with six menu controls.
- Full suite passed after art/audio integration: 573 assertions plus interaction and campaign smoke modes.
- Art validation passed for 364 assets; audio validation passed for 310 assets.
- Linux export: builds/linux/IsoCastle.x86_64, 85 MB ELF x86-64, headless startup clean.
- Windows export: builds/windows/IsoCastle.exe, 119 MB PE32+ x86-64. Configuration and binary production verified; native Windows runtime test remains external.

### Last successful command

    PATH=/home/epi13/.local/bin:$PATH ./tools/test_all.sh

Reported ALL ISOCASTLE TESTS PASSED.

### Commits

- 2eb9acd Initial commit (pre-existing main)
- f5c2fd1 Establish Godot foundation and validated content catalogs
- eb6ebb3 Build playable campaign and reproducible media pipelines
- fcb207d Complete release gameplay usability pass
- a8f7462 Merge pull request #1 from epi13/codex/full-isometric-game

### Final usability pass

- Added ranged combat, quick consumables, prepared-spell selection, six-rank Practice unlock progression, difficulty-sensitive enemy counts/damage/recovery, floor keys and locks, and searchable secret doors.
- Re-ran the complete suite successfully after the pass.

### Release state

- `codex/full-isometric-game` was pushed through `fcb207d`.
- GitHub merged the development branch to `main` in PR #1 as `a8f7462`; local `main` was safely fast-forwarded to preserve that remote work.
- Final exports were produced from gameplay commit `fcb207d`; this release-record-only commit does not alter runtime content.
- The annotated `v0.9.0` pre-release tag is published from the finalized release record.
