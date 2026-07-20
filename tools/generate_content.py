#!/usr/bin/env python3
"""Generate IsoCastle's original, localization-ready gameplay catalogs."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def slug(text: str) -> str:
    return "".join(c if c.isalnum() else "_" for c in text.lower()).strip("_").replace("__", "_")


def write_catalog(relative: str, value: list[dict], check: bool) -> bool:
    path = ROOT / relative
    rendered = json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n"
    if check:
        return path.exists() and path.read_text(encoding="utf-8") == rendered
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(rendered, encoding="utf-8")
    return True


def make_items() -> list[dict]:
    items: list[dict] = []
    melee = [
        ("Ashwood Cudgel", "club", 4, "crush"), ("Fisher's Dirk", "dagger", 5, "pierce"),
        ("Peat Knife", "knife", 5, "slash"), ("Greywake Seax", "seax", 7, "slash"),
        ("Bracken Spear", "spear", 8, "pierce"), ("Ironleaf Axe", "axe", 9, "slash"),
        ("Hearth Hammer", "hammer", 9, "crush"), ("Oath Mace", "mace", 10, "crush"),
        ("Reed Glaive", "glaive", 11, "slash"), ("Longshore Sword", "sword", 11, "slash"),
        ("Tarn Falchion", "falchion", 12, "slash"), ("Ledger Pick", "war_pick", 12, "pierce"),
        ("Mourning Flail", "flail", 13, "crush"), ("Gate Halberd", "halberd", 14, "slash"),
        ("Rime Maul", "maul", 15, "crush"), ("Bellsteel Brand", "greatsword", 16, "slash"),
        ("Root Scythe", "scythe", 14, "slash"), ("Quiet Staff", "staff", 8, "spirit"),
        ("Windhook", "polearm", 13, "pierce"), ("Crownbreaker", "warhammer", 17, "crush"),
    ]
    for tier, (name, family, power, damage) in enumerate(melee, 1):
        items.append({
            "id": f"weapon_{family}", "name": name, "name_key": f"item.weapon_{family}.name",
            "description": f"A {family.replace('_', ' ')} made in the northern reaches; balanced for deliberate close work.",
            "category": "weapon", "slot": "main_hand", "family": family, "value": 7 + tier * 8,
            "weight": round(0.7 + power * 0.18, 2), "damage": [max(1, power - 3), power + 2],
            "damage_type": damage, "range": 2 if family in {"spear", "glaive", "halberd", "polearm"} else 1,
            "requirements": {"might": max(0, (power - 8) // 2)}, "icon": f"res://assets/ui/items/weapon_{family}.png",
            "rarity": "common" if tier < 9 else "uncommon", "stack_limit": 1, "tags": ["melee", family],
        })
    ranged = [
        ("Yew Shortbow", "shortbow", 7, 7), ("March Longbow", "longbow", 10, 9),
        ("Goat-Horn Bow", "hornbow", 9, 8), ("Windlass Crossbow", "crossbow", 13, 8),
        ("Cranequin Arbalest", "arbalest", 17, 9), ("Slingstaff", "sling", 6, 6),
        ("Iron Dart Fan", "dart", 8, 5), ("Whaler's Harpoon", "harpoon", 14, 6),
    ]
    for i, (name, family, power, reach) in enumerate(ranged):
        items.append({
            "id": f"weapon_{family}", "name": name, "name_key": f"item.weapon_{family}.name",
            "description": f"A practical {family} adapted to harsh crosswinds.", "category": "weapon",
            "slot": "ranged", "family": family, "value": 25 + i * 17, "weight": 1.1 + i * 0.25,
            "damage": [max(2, power - 4), power + 2], "damage_type": "pierce", "range": reach,
            "requirements": {"finesse": i // 3}, "icon": f"res://assets/ui/items/weapon_{family}.png",
            "rarity": "common" if i < 4 else "uncommon", "stack_limit": 1, "tags": ["ranged", family],
        })
    armor_roots = [
        ("Wool Undertunic", "cloth"), ("Tarred Workcoat", "cloth"), ("Reedweave Jerkin", "cloth"),
        ("Pilgrim Robe", "cloth"), ("Ember-Scribe Vestment", "cloth"), ("Rimekeeper Mantle", "cloth"),
        ("Weathered Hide", "leather"), ("Boiled Leather Jack", "leather"), ("Moss-Stitched Coat", "leather"),
        ("Marshwarden Cuirass", "leather"), ("Foxfur Brigandine", "leather"), ("Nightglass Leathers", "leather"),
        ("Iron-Ring Hauberk", "mail"), ("Short Mail Byrnie", "mail"), ("Saltblack Hauberk", "mail"),
        ("Ledger Chain", "mail"), ("Frost-Riveted Mail", "mail"), ("Gale-Link Hauberk", "mail"),
        ("Bronze Scale Vest", "scale"), ("Bog-Iron Lamellar", "scale"), ("Stoneward Scale", "scale"),
        ("Blue-Ice Lamellar", "scale"), ("Choirscale Harness", "scale"), ("Crown Scale", "scale"),
        ("Grey Plate Cuirass", "plate"), ("Bellfounder's Plate", "plate"), ("Rime Plate", "plate"),
        ("Citadel Half-Plate", "plate"), ("Orrenfast Plate", "plate"), ("Last Gate Harness", "plate"),
        ("Dawnwarden Surcoat", "hybrid"), ("Quiet Sentinel Coat", "hybrid"), ("Rootbound Harness", "hybrid"),
        ("Storm Pilgrim Shell", "hybrid"), ("Maelin's Field Coat", "hybrid"),
    ]
    material_armor = {"cloth": 1, "leather": 2, "mail": 4, "scale": 5, "plate": 7, "hybrid": 4}
    for i, (name, material) in enumerate(armor_roots):
        armor = material_armor[material] + i // 10
        item_id = f"armor_{slug(name)}"
        items.append({
            "id": item_id, "name": name, "name_key": f"item.{item_id}.name",
            "description": f"{material.title()} protection shaped for cold rain and narrow vaults.",
            "category": "armor", "slot": "body", "material": material, "armor": armor,
            "evasion": max(-4, 2 - armor), "value": 12 + i * 13, "weight": round(0.8 + armor * 1.05, 2),
            "requirements": {"might": max(0, armor - 3)}, "icon": f"res://assets/ui/items/{item_id}.png",
            "rarity": ["common", "common", "uncommon", "rare"][min(3, i // 10)], "stack_limit": 1,
            "tags": ["armor", material],
        })
    gear_names = [
        ("Driftwood Buckler", "off_hand"), ("Hide Roundshield", "off_hand"), ("Iron Kite Shield", "off_hand"),
        ("Bellmetal Pavise", "off_hand"), ("Reedwalker Hood", "head"), ("Iron-Rim Helm", "head"),
        ("Antlered Warcap", "head"), ("Rimeglass Visor", "head"), ("Dockhand Gloves", "hands"),
        ("Lockwright Gloves", "hands"), ("Stonegrip Gauntlets", "hands"), ("Embermitts", "hands"),
        ("Mudfast Boots", "feet"), ("Snowshoe Boots", "feet"), ("Gale-Step Boots", "feet"),
        ("Quiet Slippers", "feet"), ("Ropework Belt", "waist"), ("Potioner's Belt", "waist"),
        ("Mourner's Cloak", "back"), ("Aurora Cloak", "back"),
    ]
    for i, (name, slot_name) in enumerate(gear_names):
        item_id = f"gear_{slug(name)}"
        items.append({
            "id": item_id, "name": name, "name_key": f"item.{item_id}.name",
            "description": f"Purpose-made {slot_name.replace('_', ' ')} gear from the north.",
            "category": "armor" if slot_name in {"off_hand", "head"} else "accessory", "slot": slot_name,
            "armor": 1 + i // 7, "value": 18 + i * 11, "weight": round(0.25 + (i % 5) * 0.35, 2),
            "requirements": {}, "icon": f"res://assets/ui/items/{item_id}.png",
            "rarity": "uncommon" if i > 9 else "common", "stack_limit": 1, "tags": [slot_name],
        })
    jewelry = [
        ("Ring of Banked Coals", "fire_resist"), ("Rime-Marked Band", "frost_resist"),
        ("Stormcoil Ring", "speed"), ("Deepstone Signet", "armor"), ("Dawnthread Loop", "healing"),
        ("Veiled Copper Ring", "stealth"), ("Echo-Speaker Band", "summoning"),
        ("Knot of Fortunate Rain", "critical"), ("Saltglass Amulet", "spirit_resist"),
        ("Moth-Eye Pendant", "perception"), ("Hearth-Locket", "vitality"),
        ("Whisperbone Torc", "mana"), ("Compass Rose Amulet", "accuracy"),
        ("Little Ash's Token", "fate"), ("Unstruck Bell", "silence_resist"),
    ]
    for i, (name, effect) in enumerate(jewelry):
        item_id = f"jewel_{slug(name)}"
        items.append({
            "id": item_id, "name": name, "name_key": f"item.{item_id}.name",
            "description": f"A small northern charm that strengthens {effect.replace('_', ' ')}.",
            "category": "jewelry", "slot": "ring" if "Ring" in name or "Band" in name or "Loop" in name else "neck",
            "effect": {"stat": effect, "amount": 2 + i // 5}, "value": 75 + i * 24, "weight": 0.08,
            "requirements": {}, "icon": f"res://assets/ui/items/{item_id}.png",
            "rarity": "rare" if i >= 10 else "uncommon", "stack_limit": 1, "tags": ["jewelry"],
        })
    consumables = [
        ("Redroot Draught", "heal", 18), ("Bluecap Tonic", "mana", 14), ("Warming Cordial", "fire_resist", 4),
        ("Stillwater Flask", "frost_resist", 4), ("Stormmint Tea", "speed", 3), ("Stonebroth", "armor", 3),
        ("Sunleaf Infusion", "cleanse", 1), ("Mothmilk", "invisibility", 3), ("Ghostsalt Phial", "spirit_damage", 12),
        ("Fateberry Preserve", "critical", 3), ("Black Bread", "satiety", 12), ("Smoked Char", "satiety", 16),
        ("Cloudberry Cake", "morale", 5), ("Goat Cheese", "satiety", 14), ("Juniper Stew", "heal", 10),
        ("Antidote Mash", "poison_cleanse", 1), ("Bright-Eye Drops", "perception", 5),
        ("Lockoil", "lockpick", 4), ("Ember Vial", "fire_bomb", 14), ("Rime Jar", "frost_bomb", 14),
    ]
    for i, (name, effect, amount) in enumerate(consumables):
        item_id = f"consumable_{slug(name)}"
        items.append({
            "id": item_id, "name": name, "name_key": f"item.{item_id}.name",
            "description": f"A prepared consumable providing {effect.replace('_', ' ')}.",
            "category": "consumable", "slot": "", "effect": {"type": effect, "amount": amount},
            "value": 6 + i * 3, "weight": 0.2 + (i % 3) * 0.1, "requirements": {},
            "icon": f"res://assets/ui/items/{item_id}.png", "rarity": "common",
            "stack_limit": 10, "tags": ["consumable", effect],
        })
    utility = [
        ("Orrenfast Map", "map"), ("Brass Lockpicks", "tool"), ("Trap Chalk", "tool"),
        ("Hooded Lantern", "light"), ("Climbing Line", "tool"), ("Surveyor's Compass", "tool"),
        ("Maelin's Sealed Letter", "readable"), ("Ledger of Names", "readable"),
        ("Winter Road Journal", "readable"), ("Bone-Flute Manual", "readable"),
        ("Greywake Warding Key", "key"), ("Floodgate Key", "key"), ("Rime-Crown Sigil", "key"),
        ("Blank Spellleaf", "scroll"), ("Camp Kit", "tool"), ("Repair Tongs", "tool"),
        ("Appraiser's Lens", "tool"), ("Quiet Bell Scroll", "scroll"), ("Waystone Shard", "travel"),
        ("Choir Tuning Fork", "quest"),
    ]
    for i, (name, kind) in enumerate(utility):
        item_id = f"utility_{slug(name)}"
        items.append({
            "id": item_id, "name": name, "name_key": f"item.{item_id}.name",
            "description": f"A {kind} with a practical or story-bound use.",
            "category": "quest" if kind in {"key", "quest"} else "utility", "slot": "",
            "utility_type": kind, "value": 0 if kind in {"key", "quest"} else 12 + i * 4,
            "weight": 0.15 + (i % 4) * 0.2, "requirements": {},
            "icon": f"res://assets/ui/items/{item_id}.png", "rarity": "quest" if kind in {"key", "quest"} else "common",
            "stack_limit": 5 if kind in {"scroll", "tool"} else 1, "tags": ["utility", kind],
        })
    artifacts = [
        ("Brand of the First Hearth", "weapon", "main_hand", "flame_wave"),
        ("Axe That Remembers Trees", "weapon", "main_hand", "root_bind"),
        ("Mirrorbow of Lorn", "weapon", "ranged", "split_shot"),
        ("The Patient Shield", "armor", "off_hand", "guard_aura"),
        ("Coat of Borrowed Footsteps", "armor", "body", "afterimage"),
        ("Crownless Helm", "armor", "head", "fear_immunity"),
        ("Maelin's Northless Compass", "accessory", "neck", "secret_sense"),
        ("Ring of the Ninth Answer", "jewelry", "ring", "reroll"),
        ("Cup of Returning Rain", "device", "", "group_heal"),
        ("The Hush Lantern", "device", "off_hand", "silence_field"),
        ("Little Ash's Bellbone", "device", "", "echo_summon"),
        ("Rime-Crown Counterweight", "quest", "", "ending_choice"),
    ]
    for i, (name, category, slot_name, power) in enumerate(artifacts):
        item_id = f"artifact_{slug(name)}"
        items.append({
            "id": item_id, "name": name, "name_key": f"item.{item_id}.name",
            "description": "A unique relic whose history and power change how the Bell Below can be answered.",
            "category": category, "slot": slot_name, "unique": True, "artifact_power": power,
            "value": 450 + i * 80, "weight": 0.4 + (i % 4) * 0.6, "requirements": {"resolve": 3 + i // 4},
            "icon": f"res://assets/ui/items/{item_id}.png", "rarity": "artifact", "stack_limit": 1,
            "tags": ["artifact", power],
        })
    return items


def make_affixes() -> list[dict]:
    roots = [
        ("hearthlit", "fire_damage", 3), ("rimebound", "frost_damage", 3), ("stormdrawn", "shock_damage", 3),
        ("stonefast", "armor", 2), ("sunmended", "healing", 3), ("mothveiled", "stealth", 2),
        ("echoing", "spirit_damage", 3), ("fateknotted", "critical", 2), ("keen", "accuracy", 3),
        ("stalwart", "vitality", 5), ("clear", "mana", 5), ("swift", "speed", 2), ("weighted", "knockback", 2),
        ("quiet", "noise_reduction", 3), ("seeking", "perception", 3), ("warded", "resistance", 2),
        ("leeching", "life_steal", 2), ("patient", "block", 3), ("vigilant", "reaction", 2),
        ("wayfaring", "move_cost", -5), ("of embers", "burn_chance", 8), ("of still water", "slow_chance", 8),
        ("of high thunder", "stun_chance", 5), ("of deep roots", "immovable", 1),
        ("of daybreak", "cleanse_chance", 5), ("of soft wings", "evasion", 3),
        ("of old voices", "summon_power", 3), ("of the crossed thread", "loot_luck", 4),
        ("of honest iron", "curse_resist", 5), ("of the last road", "death_save", 1),
    ]
    return [{"id": f"affix_{slug(name)}", "name": name.title(), "stat": stat, "amount": amount,
             "allowed": ["weapon", "armor", "accessory", "jewelry"]} for name, stat, amount in roots]


def make_spells() -> list[dict]:
    disciplines = {
        "cinderweave": [("Coal Spark", "projectile", "fire"), ("Hearth Ring", "aura", "fire"),
                        ("Ashen Shape", "buff", "fire"), ("Cinder Road", "line", "fire"),
                        ("Kindle Iron", "weapon_buff", "fire"), ("Phoenix Debt", "revive", "fire")],
        "rimekeeping": [("Rime Needle", "projectile", "frost"), ("Stillwater", "ground", "frost"),
                        ("White Wall", "wall", "frost"), ("Winter's Hand", "cone", "frost"),
                        ("Preserve Breath", "buff", "frost"), ("Lake Without Ripples", "burst", "frost")],
        "galebinding": [("Crosswind", "line", "shock"), ("Thunder Knot", "chain", "shock"),
                        ("Borrowed Step", "travel", "air"), ("Gale Mantle", "aura", "air"),
                        ("Skyhook", "pull", "air"), ("Tempest Answer", "burst", "shock")],
        "deepstone": [("Pebble Oath", "projectile", "crush"), ("Rooted Stance", "buff", "earth"),
                      ("Stone Door", "wall", "earth"), ("Fault Line", "line", "crush"),
                      ("Burden of Hills", "debuff", "earth"), ("Walking Cairn", "summon", "earth")],
        "dawnmending": [("Warm Palm", "heal", "radiant"), ("Lantern Ray", "line", "radiant"),
                        ("Second Morning", "cleanse", "radiant"), ("Dawn Ward", "aura", "radiant"),
                        ("Shared Breath", "chain_heal", "radiant"), ("Noon Without Shadow", "burst", "radiant")],
        "veilcraft": [("Moth Step", "travel", "shadow"), ("Dim the Name", "stealth", "shadow"),
                      ("Night Thread", "projectile", "shadow"), ("Borrowed Face", "charm", "shadow"),
                      ("Unseen Door", "utility", "shadow"), ("Moonless Room", "ground", "shadow")],
        "echocalling": [("Ancestor's Tap", "projectile", "spirit"), ("Call Reed-Wisp", "summon", "spirit"),
                        ("Speak With Ash", "utility", "spirit"), ("Choir Guard", "summon", "spirit"),
                        ("Return the Cry", "reflect", "spirit"), ("Many-Voiced Guest", "summon", "spirit")],
        "threadseeing": [("Find the Seam", "detect", "fate"), ("Foretold Miss", "buff", "fate"),
                         ("Crossed Chances", "debuff", "fate"), ("Walk the Near Road", "travel", "fate"),
                         ("Unmake Accident", "heal", "fate"), ("Ninth Answer", "burst", "fate")],
    }
    spells: list[dict] = []
    for discipline, entries in disciplines.items():
        for rank, (name, shape, damage_type) in enumerate(entries, 1):
            spell_id = f"spell_{slug(name)}"
            hostile = shape not in {"buff", "revive", "travel", "weapon_buff", "heal", "cleanse",
                                    "aura", "chain_heal", "utility", "stealth", "detect"}
            spells.append({
                "id": spell_id, "name": name, "name_key": f"spell.{spell_id}.name",
                "description": f"A {discipline.replace('_', ' ')} working shaped as {shape.replace('_', ' ')}.",
                "discipline": discipline, "rank": rank, "mana_cost": 3 + rank * 2,
                "action_cost": 100 + (rank // 4) * 25, "range": 2 + rank,
                "shape": shape, "radius": 0 if shape in {"projectile", "buff", "heal"} else 1 + rank // 4,
                "power": 4 + rank * 4, "scaling": {"resolve": 0.6, "discipline": 0.8},
                "damage_type": damage_type, "hostile": hostile,
                "status": "" if rank % 2 == 0 else f"{damage_type}_touched",
                "vfx": f"res://assets/effects/{spell_id}.png",
                "sfx": f"res://assets/sounds/spells/{spell_id}.wav",
                "ai_tags": [shape, "danger" if hostile else "support"],
                "learning": ["teacher", "spellbook", "shrine", "quest_reward"][rank % 4],
            })
    return spells


def make_themes() -> list[dict]:
    themes = [
        ("Mosswake Barrows", "burial", "moss", "spirit"), ("Sundered Delvings", "mine", "rubble", "crush"),
        ("Drowned Footings", "flooded", "water", "frost"), ("Lorn Ice Vaults", "frozen", "ice", "frost"),
        ("Root-Caught Cloister", "roots", "vines", "poison"), ("Quiet Workshops", "workshop", "machinery", "shock"),
        ("Halls of Lent Voices", "haunted", "echo", "spirit"), ("Bluecap Hollows", "fungal", "spores", "poison"),
        ("Ember Underdeep", "volcanic", "lava", "fire"), ("Star-Wheel Rooms", "observatory", "crystal", "fate"),
        ("Wind-Carved Crown", "citadel", "wind", "shock"), ("The Unhoused Choir", "supernatural", "memory", "shadow"),
    ]
    return [{
        "id": f"theme_{slug(name)}", "name": name, "biome": biome, "hazard": hazard,
        "dominant_damage": damage, "floor_tile": f"res://assets/tiles/{slug(name)}_floor.png",
        "wall_tile": f"res://assets/tiles/{slug(name)}_wall.png",
        "ambient_track": f"res://assets/music/theme_{i % 12:02d}.wav",
        "room_weights": {"small": 4, "large": 2, "corridor": 3, "set_piece": 1},
        "depth_range": [i * 2, i * 2 + 5], "palette_index": i,
    } for i, (name, biome, hazard, damage) in enumerate(themes)]


def make_enemies(themes: list[dict]) -> list[dict]:
    archetypes = ["pack", "swarm", "guardian", "ambusher", "ranged", "caster",
                  "healer", "summoner", "skirmisher", "brute", "controller", "boss"]
    nouns = [
        "Mire Wolf", "Tallow Wight", "Bog Skulker", "Iron Beetle", "Drowned Novice",
        "Rubble Goat", "Rime Crow", "Root Hound", "Ledger Automaton", "Choir Shade",
        "Bluecap Bearer", "Ember Newt", "Starved Gargoyle", "Wind Revenant", "Memory Moth",
        "Salt Skeleton", "Bell Leech", "Frostbound Miner", "Marsh Hexer", "Cairn Walker",
        "Rain Hag", "Gale Archer", "Ash Pilgrim", "Glass Adder", "Echo Knight",
        "Spore Shepherd", "Cinder Boar", "Orrery Eye", "Crown Sentinel", "Unhoused Voice",
        "Peat Lurker", "Lantern Thief", "Rope Ghost", "Ice Mason", "Root Widow",
        "Quiet Surgeon", "Hall Singer", "Mold Giant", "Lava Husk", "Fate Vulture",
        "Sky Maw", "Grief Double", "Brine Troll", "Nail Witch", "Tuning Beast",
        "Gloam Fox", "Shard Monk", "Thunder Warden",
    ]
    bosses = [
        "Abbot of the Drowned Bell", "Mother Stillwater", "The Brass Woodsman",
        "Vey's Unfinished Double", "Warden of the Counterweight", "The Choir's Open Mouth",
    ]
    enemies: list[dict] = []
    for i, name in enumerate(nouns + bosses):
        boss = i >= len(nouns)
        archetype = "boss" if boss else archetypes[i % 11]
        enemy_id = f"enemy_{slug(name)}"
        level = 1 + i // 4
        theme_id = themes[i % len(themes)]["id"]
        enemies.append({
            "id": enemy_id, "name": name, "name_key": f"enemy.{enemy_id}.name",
            "description": "A distinct northern threat shaped by terrain, memory, and the Bell's waking note.",
            "level": level, "boss": boss, "ai_archetype": archetype,
            "stats": {"health": 12 + level * (7 if boss else 3), "mana": level * 2,
                      "might": 2 + level // 3, "finesse": 2 + (i % 5), "resolve": 2 + level // 4,
                      "speed": 85 + (i % 6) * 5, "accuracy": 62 + level, "evasion": 6 + i % 8},
            "resistances": {["fire", "frost", "shock", "spirit", "shadow"][i % 5]: 20},
            "vulnerabilities": {["frost", "fire", "crush", "radiant", "spirit"][i % 5]: 15},
            "territory": theme_id, "perception": {"vision": 5 + i % 4, "hearing": 4 + i % 5},
            "abilities": [f"basic_{archetype}", f"special_{i % 12}"] + (["phase_change"] if boss else []),
            "loot_table": f"loot_theme_{i % 12:02d}", "xp": 8 + level * (18 if boss else 4),
            "sprite": f"res://assets/sprites/enemies/{enemy_id}.png",
            "directions": 8 if boss or archetype in {"ranged", "caster"} else 4,
            "animations": ["idle", "move", "attack", "hit", "special", "death"],
            "sounds": {"move": f"res://assets/sounds/creatures/{enemy_id}_move.wav",
                       "attack": f"res://assets/sounds/creatures/{enemy_id}_attack.wav",
                       "death": f"res://assets/sounds/creatures/{enemy_id}_death.wav"},
        })
    return enemies


def make_npcs() -> list[dict]:
    entries = [
        ("Edda Varn", "innkeeper", "dry, observant, allergic to melodrama"),
        ("Senn Marr", "lore keeper", "precise, skeptical, unexpectedly kind"),
        ("Tovi Reed", "child messenger", "fearless, literal, entrepreneurial"),
        ("Bran Oc", "smith", "patient, economical, fond of bad puns"),
        ("Ylsa Fen", "healer", "warm, unsentimental, attentive"),
        ("Kerrit Bale", "merchant", "charming, anxious, scrupulously fair"),
        ("Maelin Vey", "missing artificer", "restless, loving, dangerously curious"),
        ("Orra Pike", "marsh keeper", "blunt, ecological, distrustful of easy answers"),
        ("Hollan Grey", "harbormaster", "formal, superstitious, civic-minded"),
        ("Nim Aster", "spell teacher", "playful, oblique, disciplined"),
        ("Jori Tern", "hunter", "quiet, competitive, loyal"),
        ("Pell Under", "miner representative", "booming, political, generous"),
        ("Ada Clasp", "lockwright", "fussy, brilliant, secretly sentimental"),
        ("Venn Soot", "cook", "gossipy, philosophical, perpetually busy"),
        ("Rusk Candle", "undertaker", "gentle, funny, impossible to shock"),
        ("Iven Snow", "traveler", "romantic, unreliable, well-read"),
        ("Sister Calve", "Orrenfast pilgrim", "penitent, practical, guarded"),
        ("Daro Flint", "faction envoy", "charismatic, ruthless, candid"),
        ("Mara Quill", "cartographer", "curious, absent-minded, brave"),
        ("Old Kest", "ferryman", "cryptic only because he is hard of hearing"),
        ("Little Ash", "coherent choir voice", "young-seeming, ancient, direct"),
        ("Torren Vale", "ice guide", "methodical, mournful, dependable"),
        ("Siva Rime", "rival delver", "ambitious, ethical under pressure"),
        ("Brother Olt", "bell historian", "vain, knowledgeable, redeemable"),
        ("Cera Wind", "citadel exile", "fierce, ceremonious, lonely"),
        ("The Tallyman", "memory custodian", "courteous, alien, bound by rules"),
    ]
    return [{
        "id": f"npc_{slug(name)}", "name": name, "name_key": f"npc.{slug(name)}.name",
        "role": role, "voice": voice, "portrait": f"res://assets/portraits/npc_{slug(name)}.png",
        "sprite": f"res://assets/sprites/npcs/npc_{slug(name)}.png",
        "home": ["greywake", "bracken_march", "orrenfast", "lorn_shelf", "rime_crown"][i % 5],
        "schedule": [{"start": 6, "activity": "work"}, {"start": 12, "activity": "eat"},
                     {"start": 14, "activity": "socialize"}, {"start": 21, "activity": "sleep"}],
        "services": [role] if role in {"smith", "healer", "merchant", "spell teacher", "lockwright"} else [],
        "faction": ["greywake", "marsh_keepers", "quiet_ledger"][i % 3],
    } for i, (name, role, voice) in enumerate(entries)]


def make_quests(npcs: list[dict]) -> list[dict]:
    main = [
        ("Homecoming in Iron", "Return to Maelin's workshop after the aurora rings."),
        ("The Northless Compass", "Follow Maelin's altered compass into the Bracken March."),
        ("Orrenfast Below", "Open the drowned monastery without harming its refugees."),
        ("Names in the Ledger", "Learn why the Quiet Ledger built the Bell Below."),
        ("Three Tuning Names", "Recover the resonator names from the Underbell tiers."),
        ("Winter Owes a Debt", "Cross the Lorn Shelf and find Maelin's expedition."),
        ("A Voice Called Ash", "Decide whether Little Ash can be trusted with a body."),
        ("Counterweight Road", "Reach the wind-carved Rime-Crown."),
        ("The Bell's Intention", "Confront the custodian and understand the machine."),
        ("Answer the Bell", "Choose silence, stewardship, or freedom for the Choir."),
    ]
    side = [
        ("Warding Iron", "Choose who receives Greywake's limited warding nails."),
        ("A Boat for No Water", "Help Old Kest repair a boat intended for a buried river."),
        ("Tovi's Very Legal Post", "Recover letters that Tovi absolutely had permission to carry."),
        ("Root and Rafter", "Settle a boundary dispute between Orra and Pell."),
        ("The Smith's Last Joke", "Find the punch line Bran left in an abandoned forge."),
        ("Bluecap Supper", "Collect safe mushrooms while avoiding the shepherd."),
        ("A Quiet Grave", "Return a revenant's name to Rusk Candle."),
        ("Maps That Move", "Verify Mara Quill's impossible new corridors."),
        ("Lock Without a Door", "Discover what Ada's inherited lock once protected."),
        ("Lanterns for the Lost", "Place lights along the winter road."),
        ("Rain in a Bottle", "Repair Ylsa's communal healing vessel."),
        ("The Rival's Rope", "Rescue or abandon Siva's stranded expedition."),
        ("Goat on the Roof", "Resolve a livestock emergency with dignity optional."),
        ("A Proper Haunting", "Teach an inept ghost how to be noticed."),
        ("Letters Never Sent", "Deliver Maelin's unsent apologies."),
        ("The Ninth Meal", "Cook a feast from ingredients found in eight themes."),
        ("Crown Exile", "Help Cera confront the custom that expelled her."),
        ("Tallyman's Exception", "Find a memory the custodian cannot categorize."),
        ("The Free Choir", "Build vessels for willing memories."),
        ("Olt's Footnotes", "Correct a historian without destroying his confidence."),
        ("Hearth-Reader's Price", "Gather materials for a character respec."),
        ("After the Answer", "Return to Greywake and hear what changed."),
    ]
    quests: list[dict] = []
    for i, (name, summary) in enumerate(main + side):
        quest_id = f"quest_{slug(name)}"
        quest_type = "main" if i < len(main) else "side"
        giver = npcs[i % len(npcs)]["id"]
        next_id = f"quest_{slug(main[i + 1][0])}" if i < len(main) - 1 else ""
        quests.append({
            "id": quest_id, "name": name, "name_key": f"quest.{quest_id}.name",
            "summary": summary, "type": quest_type, "act": 1 + min(2, i // 4) if quest_type == "main" else 1 + i % 3,
            "giver": giver, "prerequisites": [] if i == 0 or quest_type == "side" else [quests[i - 1]["id"]],
            "stages": [
                {"id": "start", "objective": summary, "target": 1},
                {"id": "resolve", "objective": "Choose an approach and live with its consequence.", "target": 1},
                {"id": "complete", "objective": "Report the outcome.", "target": 1},
            ],
            "rewards": {"xp": 60 + i * 15, "silver": 15 + (i % 7) * 8, "item": ""},
            "next_quest": next_id, "failure_allowed": quest_type == "side",
            "world_flags": [f"completed_{quest_id}"], "dialogue_root": f"dialogue_{giver}_00",
        })
    return quests


def make_dialogue(npcs: list[dict], quests: list[dict]) -> list[dict]:
    openings = [
        "You came back on the one night the iron learned to sing. Efficient.",
        "I know that look. It means a sensible plan has just lost an argument.",
        "The road is open, if by open you mean cold and disapproving.",
        "Keep your questions short. The dark has excellent hearing.",
        "Nobody here agrees about the Bell. That is our strongest qualification.",
    ]
    responses = [
        "Ask what changed after the aurora.", "Offer practical help.", "Question the old account.",
        "Mention Maelin's compass.", "Leave with a promise to return.",
    ]
    dialogue: list[dict] = []
    for npc_index, npc in enumerate(npcs):
        for node_index in range(5):
            node_id = f"dialogue_{npc['id']}_{node_index:02d}"
            next_node = f"dialogue_{npc['id']}_{node_index + 1:02d}" if node_index < 4 else ""
            dialogue.append({
                "id": node_id, "speaker": npc["id"],
                "text": f"{npc['name']}: {openings[(npc_index + node_index) % len(openings)]}",
                "text_key": f"dialogue.{node_id}.text",
                "conditions": [] if node_index == 0 else [{"flag": f"met_{npc['id']}", "equals": True}],
                "effects": [{"set_flag": f"met_{npc['id']}", "value": True}] if node_index == 0 else [],
                "choices": [{"text": responses[(node_index + j) % len(responses)], "next": next_node}
                            for j in range(2)] if next_node else [{"text": "Until next time.", "next": ""}],
                "bark_tags": [npc["role"], ["weather", "danger", "quest", "reputation", "time"][node_index]],
            })
    return dialogue


def make_lore() -> list[dict]:
    subjects = [
        "The First Warding", "A Recipe for Peat Ink", "Orrenfast Guest Book", "Miner's Margin Notes",
        "The Bellfounder's Refusal", "Weather of the Lorn Shelf", "On Grief as Material", "Children's Counting Rhyme",
        "Maelin's Workshop Ledger", "Letter Beneath a Floorboard", "The Quiet Ledger's Charter",
        "A Marsh Keeper's Map", "Bluecap Field Guide", "The Unfinished Hymn", "Counterweight Maintenance",
        "An Apology to a Ghost", "Rime-Crown Table Customs", "A Ferryman's Receipts", "The Ninth Answer",
        "Notes on Memory Moths", "Siva's Expedition Log", "Ada's Impossible Lock", "Bran's Joke Book",
        "Hearth-Reader's Prices", "The Tallyman's Categories", "A Choir Voice Interview", "Storm Burial Practice",
        "Orrery Calibration", "Free Vessel Sketches", "Greywake After the Ring", "Maelin's Last Unsent Letter",
        "Postscript in Little Ash's Hand",
    ]
    bodies = [
        "The writer treats memory as a duty shared by witnesses, not a possession to be mined.",
        "A practical instruction becomes stranger at the final line, where the ink is asked to remember rain.",
        "Several names have been carefully cut away. Their absence leaves deeper impressions than the surviving words.",
        "The page argues that a machine may obey perfectly and still enact a terrible misunderstanding.",
    ]
    return [{
        "id": f"lore_{slug(name)}", "title": name, "title_key": f"lore.{slug(name)}.title",
        "body": bodies[i % len(bodies)] + " " + bodies[(i + 1) % len(bodies)],
        "body_key": f"lore.{slug(name)}.body", "location": ["greywake", "bracken_march", "underbell", "lorn_shelf", "rime_crown"][i % 5],
        "skill_check": {"skill": ["lore", "perception", "craft", "spirit"][i % 4], "difficulty": 4 + i // 6},
    } for i, name in enumerate(subjects)]


def make_loot(items: list[dict]) -> list[dict]:
    usable = [item["id"] for item in items if item["category"] not in {"quest"}]
    tables = []
    for i in range(12):
        entries = []
        for j in range(8):
            entries.append({"item": usable[(i * 11 + j * 7) % len(usable)], "weight": 12 - j, "min": 1, "max": 1 + (j % 2)})
        tables.append({"id": f"loot_theme_{i:02d}", "rolls": 1 + i // 5, "nothing_weight": max(1, 8 - i // 2), "entries": entries})
    return tables


def make_localization(catalogs: dict[str, list[dict]]) -> list[dict]:
    entries = []
    for catalog in catalogs.values():
        for item in catalog:
            for key_field, value_field in (("name_key", "name"), ("title_key", "title"), ("text_key", "text"), ("body_key", "body")):
                if key_field in item and value_field in item:
                    entries.append({"id": item[key_field], "text": item[value_field]})
    seen: set[str] = set()
    return [entry for entry in entries if not (entry["id"] in seen or seen.add(entry["id"]))]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="fail if committed catalogs differ")
    args = parser.parse_args()

    items = make_items()
    affixes = make_affixes()
    spells = make_spells()
    themes = make_themes()
    enemies = make_enemies(themes)
    npcs = make_npcs()
    quests = make_quests(npcs)
    dialogue = make_dialogue(npcs, quests)
    lore = make_lore()
    loot = make_loot(items)
    catalogs = {
        "content/items/items.json": items,
        "content/items/affixes.json": affixes,
        "content/spells/spells.json": spells,
        "content/world/themes.json": themes,
        "content/enemies/enemies.json": enemies,
        "content/actors/npcs.json": npcs,
        "content/quests/quests.json": quests,
        "content/dialogue/dialogue.json": dialogue,
        "content/dialogue/lore.json": lore,
        "content/loot/loot_tables.json": loot,
    }
    catalogs["content/localization/en.json"] = make_localization(catalogs)
    failures = [path for path, value in catalogs.items() if not write_catalog(path, value, args.check)]
    if failures:
        print("Generated content differs or is missing:", file=sys.stderr)
        print("\n".join(failures), file=sys.stderr)
        return 1
    print("Content catalogs " + ("verified" if args.check else "generated") + ":")
    print(f"  {len(items)} items, {len(affixes)} affixes, {len(spells)} spells")
    print(f"  {len(enemies)} enemies, {len(npcs)} NPCs, {len(quests)} quests")
    print(f"  {len(dialogue)} dialogue nodes, {len(lore)} lore entries, {len(themes)} themes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

