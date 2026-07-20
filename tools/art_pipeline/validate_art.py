#!/usr/bin/env python3
"""Validate generated sprite coverage, dimensions, alpha, pivots, and references."""

from __future__ import annotations

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "assets/generated/art_manifest.json"
PLAYER_REQUIRED = {
    "idle", "walk", "run", "melee_attack", "ranged_attack", "cast",
    "hit", "block", "use_item", "interact", "death", "victory",
}
ENEMY_REQUIRED = {"idle", "move", "attack", "hit", "special", "death"}


def main() -> int:
    errors: list[str] = []
    if not MANIFEST_PATH.exists():
        print("ART VALIDATION FAILED: missing manifest")
        return 1
    payload = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    records = payload.get("assets", [])
    paths: set[str] = set()
    ids: set[str] = set()
    for record in records:
        path_string = record.get("path", "")
        if path_string in paths:
            errors.append(f"duplicate asset path {path_string}")
        paths.add(path_string)
        if record.get("id") in ids:
            errors.append(f"duplicate sprite id {record.get('id')}")
        ids.add(record.get("id"))
        path = ROOT / path_string.removeprefix("res://")
        if not path.exists():
            errors.append(f"missing file {path_string}")
            continue
        if hashlib.sha256(path.read_bytes()).hexdigest() != record.get("sha256"):
            errors.append(f"hash mismatch {path_string}")
        try:
            with Image.open(path) as image:
                if image.size != (record.get("width"), record.get("height")):
                    errors.append(f"dimension mismatch {path_string}")
                if image.mode != "RGBA":
                    errors.append(f"missing RGBA mode {path_string}")
                elif image.getchannel("A").getbbox() is None:
                    errors.append(f"empty alpha bounds {path_string}")
        except OSError as exc:
            errors.append(f"broken PNG {path_string}: {exc}")
        if "frame_width" in record:
            if record["width"] % record["frame_width"] or record["height"] % record["frame_height"]:
                errors.append(f"incorrect frame dimensions {path_string}")
            pivot = record.get("pivot", [])
            if len(pivot) != 2 or not (0 <= pivot[0] <= record["frame_width"] and 0 <= pivot[1] <= record["frame_height"]):
                errors.append(f"pivot outside frame {path_string}")
            animations = set(record.get("animations", {}))
            if record["kind"] == "player_sheet":
                missing = PLAYER_REQUIRED - animations
                if missing:
                    errors.append(f"player sheet missing animations {path_string}: {sorted(missing)}")
                if len(record.get("directions", [])) != 8:
                    errors.append(f"player sheet lacks eight directions {path_string}")
            elif record["kind"] == "enemy_sheet":
                missing = ENEMY_REQUIRED - animations
                if missing:
                    errors.append(f"enemy sheet missing animations {path_string}: {sorted(missing)}")
                if len(record.get("directions", [])) not in {4, 8}:
                    errors.append(f"enemy direction coverage invalid {path_string}")
            for animation, frames in record.get("animations", {}).items():
                if not frames:
                    errors.append(f"missing frames {path_string}:{animation}")
                for frame in frames:
                    x, y, width, height = frame["rect"]
                    if x < 0 or y < 0 or x + width > record["width"] or y + height > record["height"]:
                        errors.append(f"broken atlas reference {path_string}:{animation}")
    referenced: set[str] = set()
    for catalog_path, fields in [
        ("content/items/items.json", ["icon"]), ("content/spells/spells.json", ["vfx"]),
        ("content/enemies/enemies.json", ["sprite"]), ("content/actors/npcs.json", ["sprite", "portrait"]),
        ("content/world/themes.json", ["floor_tile", "wall_tile"]),
    ]:
        for entry in json.loads((ROOT / catalog_path).read_text(encoding="utf-8")):
            for field in fields:
                referenced.add(entry[field])
                if entry[field] not in paths:
                    errors.append(f"unmanifested reference {catalog_path}:{entry['id']}:{entry[field]}")
    for png in ROOT.glob("assets/**/*.png"):
        resource = "res://" + png.relative_to(ROOT).as_posix()
        if resource not in paths:
            errors.append(f"unreferenced generated asset {resource}")
    if errors:
        print(f"ART VALIDATION FAILED ({len(errors)} errors)")
        for error in errors:
            print(" -", error)
        return 1
    counts: dict[str, int] = {}
    for record in records:
        counts[record["kind"]] = counts.get(record["kind"], 0) + 1
    print(f"ART VALIDATION PASSED: {len(records)} assets")
    for kind, count in sorted(counts.items()):
        print(f"  {kind}: {count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

