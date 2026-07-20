# Changelog

All notable changes are documented here. Versions follow semantic versioning while the game is in pre-release.

## Unreleased

- Added transactional, metadata-preserving inventory ownership and literal mouse drag-and-drop for reorder, swap, stack merge/split, equip, replacement, unequip, destination feedback, cancellation, and keyboard/controller alternatives.
- Advanced saves to schema 4 so legacy equipment references migrate to single item ownership without duplication.
- Added a complete versioned input-remapping editor for keyboard, mouse, and controller events with explicit conflict handling, protected cancel access, per-action/all-default resets, and startup persistence.
- Established original setting, campaign structure, design pillars, and technical architecture.
- Selected Godot 4.7.1 with typed GDScript and deterministic Python content/art/audio pipelines.
- Began full implementation on codex/full-isometric-game.
- Added a playable 12-depth, three-act isometric campaign with deterministic movement, combat, AI, loot, dialogue, merchants, quests, saves, act transitions, three endings, and post-game.
- Added character creation, progression, inventory/equipment, eight magical Practices, settings/accessibility, multi-slot persistence and recovery, debug/performance overlay, screenshot mode, and credits.
- Generated 364 original visual assets and 310 original audio assets through reproducible local pipelines.
- Added 573 deterministic assertions, interactive smoke automation, campaign playthrough automation, and content/art/audio manifest validation.
- Prepared and verified Linux and Windows desktop exports; smoke-tested the Linux export.
- Completed the release usability pass for ranged combat, quick items, spell preparation/unlocks, difficulty rules, locks, keys, and secret doors.
