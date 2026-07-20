# Worklog

## 2026-07-19

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
