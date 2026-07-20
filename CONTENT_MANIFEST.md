# Content Manifest

This file records generated catalog targets and the latest verified counts.

| Catalog | Target | Runtime file |
| --- | ---: | --- |
| Items | 140+ / 150 verified | content/items/items.json |
| Magical affixes | 30+ / 30 verified | content/items/affixes.json |
| Learnable spells | 48+ / 48 across 8 Practices | content/spells/spells.json |
| Enemies | 50+ / 54 across 12 AI archetypes | content/enemies/enemies.json |
| Bosses or major elites | 6+ / 6 verified | content/enemies/enemies.json |
| Named NPCs | 25+ / 26 verified | content/actors/npcs.json |
| Main and side quests | 30+ / 32 verified | content/quests/quests.json |
| Dialogue exchanges | 100+ / 130 nodes | content/dialogue/dialogue.json |
| Readable lore | 30+ / 32 verified | content/dialogue/lore.json |
| Environments | 12+ / 12 verified | content/world/themes.json |
| Music cues | 12+ | assets/generated/audio_manifest.json |
| Sound and ambience files | 100+ | assets/generated/audio_manifest.json |

All IDs are lowercase snake_case, globally unique within their catalog, and immutable after release. Cross-catalog references are checked before runtime. Player-facing strings are stored as localization keys with English source text in content/localization/en.json.
