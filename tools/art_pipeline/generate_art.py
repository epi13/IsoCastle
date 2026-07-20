#!/usr/bin/env python3
"""Generate IsoCastle's original deterministic painted-isometric raster assets."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[2]
SEED = 130713
FRAME = (64, 80)
PIVOT = [32, 68]
PLAYER_ANIMATIONS = [
    "idle", "walk", "run", "melee_attack", "ranged_attack", "cast",
    "hit", "block", "use_item", "interact", "death", "victory",
]
ENEMY_ANIMATIONS = ["idle", "move", "attack", "hit", "special", "death"]
DIRECTIONS_8 = ["s", "sw", "w", "nw", "n", "ne", "e", "se"]
DIRECTIONS_4 = ["s", "w", "n", "e"]


def read_json(relative: str) -> list[dict]:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def rng_for(asset_id: str) -> random.Random:
    digest = hashlib.sha256(f"{SEED}:{asset_id}".encode()).digest()
    return random.Random(int.from_bytes(digest[:8], "big"))


def ensure_parent(relative: str) -> Path:
    path = ROOT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    return path


def save_png(image: Image.Image, relative: str, manifest: list[dict], kind: str, metadata: dict | None = None) -> None:
    path = ensure_parent(relative)
    image.save(path, "PNG", optimize=False, compress_level=6)
    record = {
        "id": relative.removesuffix(".png").replace("/", "_"),
        "path": f"res://{relative}",
        "kind": kind,
        "width": image.width,
        "height": image.height,
        "mode": image.mode,
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
    }
    if metadata:
        record.update(metadata)
    manifest.append(record)


def paper_texture(size: tuple[int, int], asset_id: str, base: tuple[int, int, int]) -> Image.Image:
    rnd = rng_for(asset_id)
    image = Image.new("RGB", size, base)
    pixels = image.load()
    for y in range(size[1]):
        for x in range(size[0]):
            vignette = int(20 * math.hypot(x - size[0] / 2, y - size[1] / 2) / max(size))
            noise = rnd.randint(-8, 8) - vignette
            pixels[x, y] = tuple(max(0, min(255, channel + noise)) for channel in base)
    return image


def palette(asset_id: str) -> list[tuple[int, int, int, int]]:
    rnd = rng_for(asset_id)
    hue = rnd.random()
    colors = []
    for offset, saturation, value in [(0, 0.52, 0.72), (0.08, 0.38, 0.9), (0.52, 0.44, 0.48), (0.15, 0.18, 0.96)]:
        h = (hue + offset) % 1.0
        c = value * saturation
        segment = h * 6
        x = c * (1 - abs(segment % 2 - 1))
        if segment < 1: rgb = (c, x, 0)
        elif segment < 2: rgb = (x, c, 0)
        elif segment < 3: rgb = (0, c, x)
        elif segment < 4: rgb = (0, x, c)
        elif segment < 5: rgb = (x, 0, c)
        else: rgb = (c, 0, x)
        m = value - c
        colors.append(tuple(int((v + m) * 255) for v in rgb) + (255,))
    return colors


def item_icon(item: dict) -> Image.Image:
    rnd = rng_for(item["id"])
    colors = palette(item["id"])
    image = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((2, 2, 61, 61), radius=9, fill=(20, 27, 34, 245), outline=(120, 100, 68, 255), width=2)
    draw.rounded_rectangle((7, 7, 56, 56), radius=6, fill=(35, 43, 49, 255), outline=(58, 70, 74, 255))
    category = item.get("category", "utility")
    if category == "weapon":
        draw.line((19, 48, 43, 17), fill=colors[1], width=6)
        draw.line((17, 46, 46, 17), fill=(220, 226, 215, 255), width=2)
        draw.polygon([(40, 14), (50, 11), (46, 21)], fill=colors[3])
        draw.line((16, 42, 24, 50), fill=(122, 83, 52, 255), width=5)
    elif category == "armor":
        draw.polygon([(21, 17), (32, 12), (43, 17), (48, 47), (32, 54), (16, 47)], fill=colors[0], outline=colors[1])
        draw.line((32, 15, 32, 51), fill=colors[2], width=2)
        draw.arc((19, 20, 45, 43), 15, 165, fill=colors[3], width=2)
    elif category in {"jewelry", "accessory"}:
        draw.ellipse((16, 15, 48, 49), outline=colors[1], width=7)
        draw.ellipse((25, 24, 39, 38), fill=(18, 24, 29, 255))
        draw.polygon([(32, 11), (38, 18), (32, 25), (26, 18)], fill=colors[0], outline=colors[3])
    elif category == "consumable":
        draw.rounded_rectangle((22, 23, 43, 51), radius=7, fill=colors[0], outline=colors[3], width=2)
        draw.rectangle((26, 14, 39, 25), fill=(147, 104, 62, 255))
        draw.line((25, 36, 41, 31), fill=colors[1], width=2)
        for _ in range(4):
            x, y = rnd.randint(25, 40), rnd.randint(29, 46)
            draw.ellipse((x, y, x + 2, y + 2), fill=colors[3])
    elif category == "quest":
        draw.polygon([(17, 16), (47, 16), (42, 49), (32, 55), (22, 49)], fill=colors[2], outline=colors[1])
        draw.arc((23, 23, 41, 42), 20, 330, fill=colors[3], width=3)
    else:
        draw.rectangle((16, 19, 48, 50), fill=(113, 83, 52, 255), outline=colors[1], width=2)
        draw.line((20, 25, 44, 44), fill=colors[3], width=2)
        draw.line((44, 25, 20, 44), fill=colors[3], width=2)
    draw.arc((5, 5, 58, 58), 205, 328, fill=(225, 196, 133, 110), width=2)
    return image


def effect_sheet(spell: dict) -> Image.Image:
    colors = palette(spell["discipline"])
    image = Image.new("RGBA", (256, 64), (0, 0, 0, 0))
    for frame in range(4):
        draw = ImageDraw.Draw(image)
        ox = frame * 64
        pulse = 12 + frame * 3
        for ring in range(4, 0, -1):
            radius = pulse * ring / 4
            alpha = 35 + ring * 32
            draw.ellipse((ox + 32 - radius, 32 - radius, ox + 32 + radius, 32 + radius),
                         outline=colors[ring % len(colors)][:3] + (alpha,), width=2 + ring // 2)
        points = []
        for i in range(12):
            angle = i * math.tau / 12 + frame * 0.21
            radius = pulse * (1.0 if i % 2 else 0.42)
            points.append((ox + 32 + math.cos(angle) * radius, 32 + math.sin(angle) * radius))
        draw.polygon(points, fill=colors[0][:3] + (150,), outline=colors[1])
    return image.filter(ImageFilter.GaussianBlur(0.35))


def actor_frame(asset_id: str, direction: int, animation: str, frame: int, important: bool) -> Image.Image:
    rnd = rng_for(asset_id)
    colors = palette(asset_id)
    image = Image.new("RGBA", FRAME, (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    phase = frame / 4 * math.tau
    bounce = round(math.sin(phase) * (2 if animation in {"walk", "move", "run"} else 1))
    if animation == "death":
        bounce = min(14, frame * 5)
    cx, foot = 32, 68 + bounce
    facing = math.sin(direction * math.tau / (8 if important else 4))
    draw.ellipse((18, 64, 47, 73), fill=(5, 8, 12, 90))
    if animation == "death":
        draw.ellipse((12, 57 + bounce, 51, 70 + bounce), fill=colors[2], outline=(25, 28, 32, 255))
        return image
    cloak = [
        (cx - 12, foot - 9), (cx - 8 + facing * 2, foot - 39), (cx, foot - 47),
        (cx + 9 + facing * 2, foot - 38), (cx + 13, foot - 8), (cx, foot - 3),
    ]
    draw.polygon(cloak, fill=colors[0], outline=(18, 24, 29, 255))
    draw.polygon([(cx - 8, foot - 38), (cx, foot - 48), (cx + 9, foot - 37), (cx, foot - 29)],
                 fill=colors[2], outline=colors[1])
    draw.ellipse((cx - 7 + facing * 2, foot - 57, cx + 7 + facing * 2, foot - 43),
                 fill=(176 + rnd.randint(-10, 10), 142, 111, 255), outline=(31, 29, 31, 255))
    draw.arc((cx - 7 + facing * 2, foot - 58, cx + 7 + facing * 2, foot - 42), 180, 350, fill=colors[3], width=3)
    arm_swing = round(math.sin(phase) * 5)
    if animation in {"attack", "melee_attack"}:
        arm_swing = 10 + frame * 4
        draw.line((cx + 5, foot - 36, cx + 8 + arm_swing, foot - 27 - frame * 2), fill=colors[1], width=4)
        draw.line((cx + 8 + arm_swing, foot - 27 - frame * 2, cx + 15 + arm_swing, foot - 42 - frame),
                  fill=(214, 218, 211, 255), width=3)
    elif animation in {"cast", "special"}:
        draw.line((cx - 5, foot - 35, cx - 18, foot - 47), fill=colors[1], width=4)
        draw.ellipse((cx - 24, foot - 56, cx - 12, foot - 44), fill=colors[3], outline=colors[1], width=2)
    elif animation == "ranged_attack":
        draw.arc((cx + 2, foot - 48, cx + 29, foot - 18), 90, 270, fill=(157, 107, 61, 255), width=3)
        draw.line((cx + 15, foot - 47, cx + 15, foot - 18), fill=colors[3], width=1)
    elif animation == "hit":
        draw.line((cx - 5, foot - 33, cx - 12, foot - 28), fill=colors[1], width=4)
    else:
        draw.line((cx - 5, foot - 34, cx - 11 + arm_swing, foot - 18), fill=colors[1], width=4)
        draw.line((cx + 5, foot - 34, cx + 11 - arm_swing, foot - 18), fill=colors[1], width=4)
    step = round(math.sin(phase) * (6 if animation in {"walk", "move", "run"} else 1))
    draw.line((cx - 4, foot - 10, cx - 6 + step, foot), fill=(42, 43, 42, 255), width=5)
    draw.line((cx + 4, foot - 10, cx + 6 - step, foot), fill=(42, 43, 42, 255), width=5)
    if animation in {"victory", "interact"}:
        draw.line((cx + 5, foot - 34, cx + 17, foot - 51), fill=colors[1], width=4)
    return image


def actor_sheet(asset_id: str, animations: list[str], directions: list[str]) -> tuple[Image.Image, dict]:
    important = len(directions) == 8
    columns = len(directions) * 4
    sheet = Image.new("RGBA", (columns * FRAME[0], len(animations) * FRAME[1]), (0, 0, 0, 0))
    animation_meta = {}
    for row, animation in enumerate(animations):
        frames = []
        for direction_index, direction in enumerate(directions):
            for frame in range(4):
                x = (direction_index * 4 + frame) * FRAME[0]
                y = row * FRAME[1]
                sheet.alpha_composite(actor_frame(asset_id, direction_index, animation, frame, important), (x, y))
                frames.append({"direction": direction, "frame": frame, "rect": [x, y, FRAME[0], FRAME[1]]})
        animation_meta[animation] = frames
    return sheet, {
        "frame_width": FRAME[0], "frame_height": FRAME[1], "pivot": PIVOT,
        "directions": directions, "animations": animation_meta, "frames_per_direction": 4,
    }


def portrait(asset_id: str) -> Image.Image:
    colors = palette(asset_id)
    rnd = rng_for(asset_id)
    image = paper_texture((192, 240), asset_id, (25, 36, 45)).convert("RGBA")
    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle((8, 8, 183, 231), radius=12, outline=(143, 115, 72, 255), width=4)
    draw.ellipse((38, 48, 154, 192), fill=colors[0], outline=(13, 18, 23, 255), width=4)
    draw.ellipse((57, 46, 137, 138), fill=(177 + rnd.randint(-12, 12), 139, 106, 255), outline=(23, 26, 29, 255), width=3)
    draw.polygon([(48, 83), (65, 39), (128, 35), (148, 89), (128, 72), (75, 72)], fill=colors[2], outline=colors[1])
    eye_y = 91 + rnd.randint(-2, 2)
    draw.line((75, eye_y, 88, eye_y - 1), fill=(31, 28, 26, 255), width=3)
    draw.line((108, eye_y - 1, 121, eye_y), fill=(31, 28, 26, 255), width=3)
    draw.line((92, 119, 108, 119 + rnd.randint(-2, 2)), fill=(83, 47, 42, 255), width=2)
    draw.polygon([(45, 205), (58, 148), (96, 169), (137, 148), (151, 207)], fill=colors[0], outline=colors[1])
    draw.arc((18, 18, 174, 225), 205, 338, fill=(231, 205, 147, 100), width=3)
    return image


def tile_images(theme: dict) -> tuple[Image.Image, Image.Image]:
    colors = palette(theme["id"])
    rnd = rng_for(theme["id"])
    floor = Image.new("RGBA", (96, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(floor)
    diamond = [(48, 1), (94, 23), (48, 46), (2, 23)]
    draw.polygon(diamond, fill=colors[2], outline=colors[1])
    for _ in range(18):
        x, y = rnd.randint(15, 80), rnd.randint(10, 36)
        if abs(x - 48) / 46 + abs(y - 23) / 22 < 0.9:
            draw.line((x, y, x + rnd.randint(2, 9), y + rnd.randint(-2, 2)), fill=colors[0], width=1)
    wall = Image.new("RGBA", (96, 96), (0, 0, 0, 0))
    wall.alpha_composite(floor, (0, 0))
    wd = ImageDraw.Draw(wall)
    wd.polygon([(2, 23), (48, 46), (48, 92), (2, 69)], fill=colors[2], outline=colors[0])
    wd.polygon([(48, 46), (94, 23), (94, 69), (48, 92)], fill=tuple(max(0, c - 24) for c in colors[2][:3]) + (255,), outline=colors[0])
    for y in (53, 68, 83):
        wd.line((5, y - 23, 48, y), fill=colors[0], width=1)
        wd.line((48, y, 92, y - 23), fill=colors[0], width=1)
    return floor, wall


def title_art() -> Image.Image:
    rnd = rng_for("title")
    image = paper_texture((1280, 720), "title", (7, 18, 30)).convert("RGBA")
    draw = ImageDraw.Draw(image, "RGBA")
    for band in range(7):
        points = [(0, 80 + band * 24)]
        for x in range(0, 1281, 80):
            y = 95 + band * 20 + math.sin(x / 140 + band) * 24 + rnd.randint(-10, 10)
            points.append((x, y))
        points += [(1280, 330), (0, 330)]
        color = [(73, 177, 154, 26), (90, 145, 193, 24), (146, 87, 164, 20)][band % 3]
        draw.polygon(points, fill=color)
    draw.ellipse((920, 82, 1080, 242), fill=(213, 226, 221, 210))
    for layer in range(5):
        base_y = 390 + layer * 52
        points = [(0, 720)]
        for x in range(0, 1281, 90):
            peak = base_y - rnd.randint(45, 150)
            points.extend([(x, base_y), (x + 45, peak), (x + 90, base_y)])
        points.append((1280, 720))
        draw.polygon(points, fill=(18 + layer * 5, 31 + layer * 6, 43 + layer * 7, 255))
    draw.polygon([(620, 440), (820, 535), (620, 635), (420, 535)], fill=(32, 44, 49, 255), outline=(102, 90, 68, 255))
    draw.rectangle((604, 342, 636, 500), fill=(33, 38, 42, 255), outline=(128, 104, 68, 255), width=3)
    draw.ellipse((578, 305, 662, 375), outline=(185, 148, 78, 255), width=6)
    for _ in range(55):
        x, y = rnd.randint(0, 1279), rnd.randint(260, 690)
        draw.ellipse((x, y, x + 2, y + 5), fill=(210, 225, 229, rnd.randint(60, 150)))
    return image.filter(ImageFilter.GaussianBlur(0.25))


def logo_image() -> Image.Image:
    image = Image.new("RGBA", (720, 220), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    try:
        font = ImageFont.truetype("/usr/share/fonts/dejavu-sans-fonts/DejaVuSerifCondensed-Bold.ttf", 96)
    except OSError:
        font = ImageFont.load_default(size=72)
    text = "ISOCASTLE"
    bounds = draw.textbbox((0, 0), text, font=font, stroke_width=2)
    x = (720 - (bounds[2] - bounds[0])) // 2
    draw.text((x + 4, 54), text, font=font, fill=(8, 12, 16, 170), stroke_width=4, stroke_fill=(8, 12, 16, 190))
    draw.text((x, 48), text, font=font, fill=(231, 220, 190, 255), stroke_width=2, stroke_fill=(143, 111, 62, 255))
    draw.line((92, 166, 628, 166), fill=(147, 112, 60, 255), width=3)
    draw.ellipse((346, 153, 374, 181), outline=(205, 177, 105, 255), width=3)
    return image


def loading_illustration(theme: dict, index: int) -> Image.Image:
    colors = palette(theme["id"])
    image = paper_texture((640, 360), f"loading:{theme['id']}", colors[2][:3]).convert("RGBA")
    draw = ImageDraw.Draw(image, "RGBA")
    draw.polygon([(0, 270), (150, 120), (290, 270)], fill=(21, 32, 39, 230))
    draw.polygon([(180, 290), (390, 70), (600, 290)], fill=(28, 40, 49, 240))
    draw.polygon([(430, 280), (555, 140), (640, 240), (640, 360), (420, 360)], fill=(17, 27, 35, 245))
    for step in range(7):
        y = 310 - step * 22
        draw.polygon([(320, y), (365, y - 12), (410, y), (365, y + 12)], fill=colors[0][:3] + (210,))
    draw.ellipse((70 + index * 17 % 400, 48, 150 + index * 17 % 400, 128), fill=colors[3][:3] + (110,))
    return image


def object_sheet(object_id: str) -> tuple[Image.Image, dict]:
    colors = palette(object_id)
    image = Image.new("RGBA", (256, 80), (0, 0, 0, 0))
    for frame in range(4):
        draw = ImageDraw.Draw(image)
        ox = frame * 64
        draw.ellipse((ox + 14, 64, ox + 52, 73), fill=(0, 0, 0, 80))
        if object_id == "door":
            draw.polygon([(ox + 17, 14), (ox + 48, 9 + frame * 2), (ox + 48, 66), (ox + 17, 69)], fill=colors[0], outline=colors[1])
        elif object_id == "chest":
            lid_y = 30 - frame * 5
            draw.rectangle((ox + 15, 36, ox + 50, 63), fill=colors[2], outline=colors[1])
            draw.polygon([(ox + 15, 36), (ox + 20, lid_y), (ox + 46, lid_y), (ox + 50, 36)], fill=colors[0], outline=colors[1])
        elif object_id in {"fire", "portal", "fountain", "shrine", "magic"}:
            radius = 10 + frame * 2
            draw.ellipse((ox + 32 - radius, 38 - radius, ox + 32 + radius, 38 + radius), fill=colors[frame % 4][:3] + (180,))
            draw.polygon([(ox + 32, 10 + frame), (ox + 46, 54), (ox + 18, 54)], outline=colors[1], fill=colors[0][:3] + (120,))
        else:
            draw.polygon([(ox + 11, 61), (ox + 22, 33 - frame * 2), (ox + 32, 59), (ox + 44, 27 + frame), (ox + 54, 61)], fill=colors[0], outline=colors[1])
    return image, {
        "frame_width": 64, "frame_height": 80, "pivot": PIVOT,
        "directions": ["state"], "frames_per_direction": 4,
        "animations": {"animate": [{"direction": "state", "frame": i, "rect": [i * 64, 0, 64, 80]} for i in range(4)]},
    }


def generate() -> list[dict]:
    manifest: list[dict] = []
    items = read_json("content/items/items.json")
    spells = read_json("content/spells/spells.json")
    enemies = read_json("content/enemies/enemies.json")
    npcs = read_json("content/actors/npcs.json")
    themes = read_json("content/world/themes.json")

    for item in items:
        relative = item["icon"].removeprefix("res://")
        save_png(item_icon(item), relative, manifest, "item_icon", {"content_id": item["id"], "pivot": [32, 32]})
    for spell in spells:
        relative = spell["vfx"].removeprefix("res://")
        save_png(effect_sheet(spell), relative, manifest, "spell_effect", {
            "content_id": spell["id"], "frame_width": 64, "frame_height": 64,
            "pivot": [32, 32], "directions": ["effect"], "frames_per_direction": 4,
            "animations": {"cast": [{"direction": "effect", "frame": i, "rect": [i * 64, 0, 64, 64]} for i in range(4)]},
        })
    for enemy in enemies:
        directions = DIRECTIONS_8 if int(enemy["directions"]) == 8 else DIRECTIONS_4
        sheet, metadata = actor_sheet(enemy["id"], ENEMY_ANIMATIONS, directions)
        save_png(sheet, enemy["sprite"].removeprefix("res://"), manifest, "enemy_sheet", {"content_id": enemy["id"], **metadata})
    for npc in npcs:
        sheet, metadata = actor_sheet(npc["id"], ["idle", "walk", "interact", "sleep"], DIRECTIONS_8)
        save_png(sheet, npc["sprite"].removeprefix("res://"), manifest, "npc_sheet", {"content_id": npc["id"], **metadata})
        save_png(portrait(npc["id"]), npc["portrait"].removeprefix("res://"), manifest, "portrait", {"content_id": npc["id"], "pivot": [96, 220]})
    for presentation in ["aurora", "ember", "reed", "rime", "stone", "moth"]:
        sheet, metadata = actor_sheet(f"player_{presentation}", PLAYER_ANIMATIONS, DIRECTIONS_8)
        save_png(sheet, f"assets/sprites/player/player_{presentation}.png", manifest, "player_sheet", {"content_id": f"player_{presentation}", **metadata})
        save_png(portrait(f"player_{presentation}"), f"assets/portraits/player_{presentation}.png", manifest, "portrait", {"content_id": f"player_{presentation}", "pivot": [96, 220]})
    for index, theme in enumerate(themes):
        floor, wall = tile_images(theme)
        save_png(floor, theme["floor_tile"].removeprefix("res://"), manifest, "floor_tile", {"content_id": theme["id"], "pivot": [48, 24]})
        save_png(wall, theme["wall_tile"].removeprefix("res://"), manifest, "wall_tile", {"content_id": theme["id"], "pivot": [48, 92]})
        save_png(loading_illustration(theme, index), f"assets/environments/loading_{index:02d}.png", manifest, "loading_art", {"content_id": theme["id"], "pivot": [320, 180]})
    for object_id in ["door", "chest", "trap", "portal", "shrine", "fountain", "fire", "magic", "ice_hazard", "lava_hazard"]:
        sheet, metadata = object_sheet(object_id)
        save_png(sheet, f"assets/sprites/objects/{object_id}.png", manifest, "object_sheet", {"content_id": object_id, **metadata})
    save_png(title_art(), "assets/ui/title_background.png", manifest, "title_art", {"pivot": [640, 360]})
    save_png(logo_image(), "assets/ui/logo.png", manifest, "logo", {"pivot": [360, 110]})
    manifest.sort(key=lambda entry: entry["path"])
    manifest_path = ensure_parent("assets/generated/art_manifest.json")
    manifest_path.write_text(json.dumps({"version": 1, "seed": SEED, "assets": manifest}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return manifest


def check() -> int:
    path = ROOT / "assets/generated/art_manifest.json"
    if not path.exists():
        print("Missing art manifest; run generator.", file=sys.stderr)
        return 1
    manifest = json.loads(path.read_text(encoding="utf-8"))
    errors = []
    for record in manifest.get("assets", []):
        asset = ROOT / record["path"].removeprefix("res://")
        if not asset.exists():
            errors.append(f"missing {record['path']}")
        elif hashlib.sha256(asset.read_bytes()).hexdigest() != record["sha256"]:
            errors.append(f"hash mismatch {record['path']}")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Art manifest verified: {len(manifest['assets'])} original raster assets")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.check:
        return check()
    manifest = generate()
    print(f"Generated {len(manifest)} original raster assets with seed {SEED}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

