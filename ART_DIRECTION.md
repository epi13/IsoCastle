# Art Direction

IsoCastle uses a hand-painted storybook silhouette rendered through deterministic 2D vector-and-raster generators. Slate, peat, bone, oxidized iron, faded wool, amber fire, pale cyan moonlight, lichen green, and restrained aurora magenta define the palette.

Isometric tiles are 96 by 48 pixels with 48-pixel elevation increments. Actors occupy consistent 96 by 112 frames with foot pivots at (48, 94). Important humanoids use eight directions; minor creatures use at least four. Shapes exaggerate shoulders, weapons, horns, and casting hands so state remains readable at gameplay scale.

Generated sprites combine layered painted polygons, controlled texture noise, rim light, contact shadows, and animation offsets. Inventory icons use a carved dark-stone frame and a category accent, never generic emoji or system icons. UI panels resemble charcoal timber and hammered bronze without overdecorating text areas.

The canonical source is tools/art_pipeline/generate_art.py plus content definitions and deterministic seed 130713. ASSET_MANIFEST.md records every output and hash. AI-generated key art, when used, is treated as an authored source reference and committed with its generation prompt and provenance; gameplay sprites remain deterministic.

