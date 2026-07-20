#!/usr/bin/env python3
"""Validate IsoCastle content schemas, references, scale, and runtime paths."""

from __future__ import annotations

import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
LOCALIZATION_PATTERN = re.compile(r"^[a-z][a-z0-9_.]*$")
CATALOG_PATHS = {
    "items": "content/items/items.json",
    "affixes": "content/items/affixes.json",
    "spells": "content/spells/spells.json",
    "enemies": "content/enemies/enemies.json",
    "npcs": "content/actors/npcs.json",
    "quests": "content/quests/quests.json",
    "dialogue": "content/dialogue/dialogue.json",
    "lore": "content/dialogue/lore.json",
    "themes": "content/world/themes.json",
    "loot": "content/loot/loot_tables.json",
    "localization": "content/localization/en.json",
}


class Validator:
    def __init__(self) -> None:
        self.errors: list[str] = []
        self.catalogs: dict[str, list[dict]] = {}
        self.index: dict[str, dict[str, dict]] = {}

    def error(self, message: str) -> None:
        self.errors.append(message)

    def load(self) -> None:
        for name, relative in CATALOG_PATHS.items():
            path = ROOT / relative
            if not path.exists():
                self.error(f"missing catalog {relative}")
                continue
            try:
                value = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError) as exc:
                self.error(f"cannot parse {relative}: {exc}")
                continue
            if not isinstance(value, list):
                self.error(f"{relative} must contain an array")
                continue
            self.catalogs[name] = value
            entries: dict[str, dict] = {}
            for position, entry in enumerate(value):
                if not isinstance(entry, dict):
                    self.error(f"{name}[{position}] is not an object")
                    continue
                entry_id = entry.get("id", "")
                pattern = LOCALIZATION_PATTERN if name == "localization" else ID_PATTERN
                if not isinstance(entry_id, str) or not pattern.fullmatch(entry_id):
                    self.error(f"{name}[{position}] has invalid id {entry_id!r}")
                elif entry_id in entries:
                    self.error(f"{name} duplicate id {entry_id}")
                else:
                    entries[entry_id] = entry
            self.index[name] = entries

    def require_fields(self) -> None:
        required = {
            "items": ("id", "name", "description", "category", "icon", "weight", "stack_limit"),
            "spells": ("id", "name", "discipline", "mana_cost", "action_cost", "shape", "vfx", "sfx"),
            "enemies": ("id", "name", "stats", "ai_archetype", "territory", "loot_table", "sprite", "animations"),
            "npcs": ("id", "name", "role", "voice", "portrait", "sprite", "schedule"),
            "quests": ("id", "name", "summary", "giver", "stages", "dialogue_root"),
            "dialogue": ("id", "speaker", "text", "choices"),
            "lore": ("id", "title", "body", "location"),
            "themes": ("id", "name", "biome", "hazard", "floor_tile", "wall_tile"),
            "loot": ("id", "entries"),
        }
        for catalog, fields in required.items():
            for entry in self.catalogs.get(catalog, []):
                for field in fields:
                    if field not in entry:
                        self.error(f"{catalog}:{entry.get('id')} missing {field}")

    def check_counts(self) -> None:
        schema = json.loads((ROOT / "content/schema_version.json").read_text(encoding="utf-8"))
        for catalog, minimum in schema["minimum_counts"].items():
            actual = len(self.catalogs.get(catalog, []))
            if actual < minimum:
                self.error(f"{catalog} count {actual} below minimum {minimum}")
        items = self.catalogs.get("items", [])
        if len({x.get("family") for x in items if "melee" in x.get("tags", [])}) < 20:
            self.error("fewer than 20 melee weapon families")
        if len({x.get("family") for x in items if "ranged" in x.get("tags", [])}) < 8:
            self.error("fewer than 8 ranged weapon families")
        if sum(x.get("category") == "armor" and x.get("slot") == "body" for x in items) < 35:
            self.error("fewer than 35 body armor pieces")
        if sum(x.get("category") == "consumable" for x in items) < 20:
            self.error("fewer than 20 consumables")
        if sum(x.get("rarity") == "artifact" for x in items) < 12:
            self.error("fewer than 12 artifacts")
        spell_disciplines = Counter(x.get("discipline") for x in self.catalogs.get("spells", []))
        if len(spell_disciplines) < 8 or any(count < 6 for count in spell_disciplines.values()):
            self.error(f"spell discipline coverage invalid: {dict(spell_disciplines)}")
        enemies = self.catalogs.get("enemies", [])
        if len({x.get("ai_archetype") for x in enemies}) < 12:
            self.error("fewer than 12 enemy AI archetypes")
        if sum(bool(x.get("boss")) for x in enemies) < 6:
            self.error("fewer than 6 bosses")

    def check_references(self) -> None:
        ids = {name: set(index) for name, index in self.index.items()}
        for enemy in self.catalogs.get("enemies", []):
            if enemy.get("territory") not in ids["themes"]:
                self.error(f"enemy {enemy['id']} has missing territory {enemy.get('territory')}")
            if enemy.get("loot_table") not in ids["loot"]:
                self.error(f"enemy {enemy['id']} has missing loot table {enemy.get('loot_table')}")
            missing = {"idle", "move", "attack", "hit", "special", "death"} - set(enemy.get("animations", []))
            if missing:
                self.error(f"enemy {enemy['id']} missing animations {sorted(missing)}")
        for table in self.catalogs.get("loot", []):
            if not table.get("entries"):
                self.error(f"loot table {table['id']} is empty")
            for entry in table.get("entries", []):
                if entry.get("item") not in ids["items"]:
                    self.error(f"loot table {table['id']} has missing item {entry.get('item')}")
        for quest in self.catalogs.get("quests", []):
            if quest.get("giver") not in ids["npcs"]:
                self.error(f"quest {quest['id']} has missing giver {quest.get('giver')}")
            if quest.get("dialogue_root") not in ids["dialogue"]:
                self.error(f"quest {quest['id']} has missing dialogue root {quest.get('dialogue_root')}")
            for requirement in quest.get("prerequisites", []):
                if requirement not in ids["quests"]:
                    self.error(f"quest {quest['id']} has missing prerequisite {requirement}")
            next_quest = quest.get("next_quest")
            if next_quest and next_quest not in ids["quests"]:
                self.error(f"quest {quest['id']} has missing next quest {next_quest}")
        for node in self.catalogs.get("dialogue", []):
            if node.get("speaker") not in ids["npcs"]:
                self.error(f"dialogue {node['id']} has missing speaker {node.get('speaker')}")
            for choice in node.get("choices", []):
                next_node = choice.get("next")
                if next_node and next_node not in ids["dialogue"]:
                    self.error(f"dialogue {node['id']} has missing next node {next_node}")

    def check_resource_paths(self, require_files: bool = False) -> None:
        fields = {
            "items": ("icon",), "spells": ("vfx", "sfx"),
            "enemies": ("sprite",), "npcs": ("portrait", "sprite"),
            "themes": ("floor_tile", "wall_tile", "ambient_track"),
        }
        for catalog, names in fields.items():
            for entry in self.catalogs.get(catalog, []):
                for field in names:
                    resource = entry.get(field, "")
                    if not isinstance(resource, str) or not resource.startswith("res://"):
                        self.error(f"{catalog}:{entry.get('id')} invalid resource path {field}={resource!r}")
                    elif require_files and not (ROOT / resource.removeprefix("res://")).exists():
                        self.error(f"{catalog}:{entry.get('id')} missing resource file {resource}")
        for enemy in self.catalogs.get("enemies", []):
            for resource in enemy.get("sounds", {}).values():
                if require_files and not (ROOT / resource.removeprefix("res://")).exists():
                    self.error(f"enemy {enemy['id']} missing sound file {resource}")

    def run(self) -> int:
        self.load()
        self.require_fields()
        self.check_counts()
        self.check_references()
        require_assets = (ROOT / "assets/generated/art_manifest.json").exists()
        self.check_resource_paths(require_files=require_assets)
        if self.errors:
            print(f"CONTENT VALIDATION FAILED ({len(self.errors)} errors)")
            for message in self.errors:
                print(f" - {message}")
            return 1
        print("CONTENT VALIDATION PASSED")
        for name in ("items", "affixes", "spells", "enemies", "npcs", "quests", "dialogue", "lore", "themes"):
            print(f"  {name}: {len(self.catalogs.get(name, []))}")
        return 0


if __name__ == "__main__":
    raise SystemExit(Validator().run())
