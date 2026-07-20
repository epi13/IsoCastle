# Architecture

## Runtime

Godot 4.7.1 runs a single root scene whose ScreenRouter owns menu and campaign screens. GameSession owns serializable campaign state. ContentDB loads validated JSON catalogs. TurnEngine resolves commands into immutable result records, while WorldView animates those results. This separation keeps headless simulation deterministic.

## Service graph

ContentDB provides definitions to GameSession, WorldGenerator, CombatRules, AIPlanner, QuestEngine, and UI. GameSession is persisted by SaveService. SettingsService is independent. AudioDirector and PresentationSettings consume events but never mutate rules state.

## Data and saves

JSON content uses stable IDs and explicit cross-references. Save schema version 3 contains metadata, seed, player, world, quest, faction, and journal state. SaveService writes a temporary file, validates it, rotates the old file to .bak, then renames atomically. Migration functions are monotonic and covered by round-trip fixtures.

## World representation

Logical maps are integer-coordinate square grids rendered through an isometric projection: screen_x=(x-y)*tile_width/2 and screen_y=(x+y)*tile_height/2-height. Actors and props sort by projected foot position. Occluding roofs and tall walls fade based on the player corridor.

## Procedural generation

A local RandomNumberGenerator seeded from the campaign seed creates room-chain layouts, adds theme rules and set pieces, then validates flood-fill connectivity, critical exits, and key-before-lock reachability. Failed generations retry with a derived seed and record the accepted attempt.

## Testing seams

Rules accept plain dictionaries and seeded RNG state. Python validates catalogs and manifests; headless Godot tests runtime parsing, rules, save migration, generation, pathfinding, and smoke navigation. CI uses the same tools/test_all.sh entrypoint.

