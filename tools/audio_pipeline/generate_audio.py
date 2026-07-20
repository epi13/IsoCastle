#!/usr/bin/env python3
"""Synthesize IsoCastle's original score, ambience, and sound effects."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import random
import sys
import wave
from array import array
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RATE = 44_100
SEED = 44_117
TAU = math.tau

MUSIC_CUES = [
    ("theme_00", "main_title", 0, 56),
    ("theme_01", "greywake_settlement", 5, 64),
    ("theme_02", "bracken_wilderness", 2, 72),
    ("theme_03", "underbell_moss", 1, 48),
    ("theme_04", "underbell_flood", 4, 52),
    ("theme_05", "turn_combat", 3, 96),
    ("theme_06", "major_boss", 0, 108),
    ("theme_07", "revelation", 6, 44),
    ("theme_08", "act_transition", 5, 60),
    ("theme_09", "rime_crown_final", 1, 78),
    ("theme_10", "ending_variations", 2, 58),
    ("theme_11", "credits", 5, 66),
]


def read_json(relative: str) -> list[dict]:
    return json.loads((ROOT / relative).read_text(encoding="utf-8"))


def rng_for(asset_id: str) -> random.Random:
    digest = hashlib.sha256(f"{SEED}:{asset_id}".encode()).digest()
    return random.Random(int.from_bytes(digest[:8], "big"))


def oscillator(phase: float, waveform: str) -> float:
    if waveform == "sine":
        return math.sin(phase)
    if waveform == "triangle":
        return 2.0 / math.pi * math.asin(math.sin(phase))
    if waveform == "soft_square":
        return math.tanh(math.sin(phase) * 2.1) * 0.72
    return math.sin(phase)


def write_wave(relative: str, samples: array, channels: int, category: str, cue_name: str, manifest: list[dict]) -> None:
    path = ROOT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    peak = max((abs(value) for value in samples), default=0)
    if peak > 31_000:
        scale = 31_000 / peak
        samples = array("h", (int(value * scale) for value in samples))
        peak = 31_000
    with wave.open(str(path), "wb") as output:
        output.setnchannels(channels)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(samples.tobytes())
    manifest.append({
        "id": relative.removesuffix(".wav").replace("/", "_"),
        "path": f"res://{relative}",
        "category": category,
        "cue": cue_name,
        "sample_rate": RATE,
        "channels": channels,
        "frames": len(samples) // channels,
        "duration": round((len(samples) // channels) / RATE, 4),
        "peak": round(peak / 32767, 6),
        "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
        "generator_seed": SEED,
    })


def synth_music(cue_id: str, mode: int, bpm: int, duration: float = 12.0) -> array:
    rnd = rng_for(cue_id)
    tonic = [98.0, 110.0, 123.47, 130.81][mode % 4]
    modes = [
        [0, 2, 3, 5, 7, 8, 10], [0, 2, 3, 5, 7, 9, 10],
        [0, 1, 3, 5, 7, 8, 10], [0, 2, 4, 5, 7, 9, 10],
        [0, 2, 3, 5, 7, 8, 11], [0, 2, 4, 7, 9, 10, 12],
        [0, 1, 5, 7, 8, 10, 12],
    ]
    scale = modes[mode % len(modes)]
    beat = 60.0 / bpm
    motif = [0, 4, 2, 5, 1, 3, 0, 6]
    samples = array("h")
    total = int(duration * RATE)
    wind_state_l = 0.0
    wind_state_r = 0.0
    for index in range(total):
        t = index / RATE
        step = int(t / beat) % len(motif)
        local = (t % beat) / beat
        degree = motif[step]
        frequency = tonic * 2 ** (scale[degree] / 12)
        drone = oscillator(TAU * tonic * 0.5 * t, "triangle") * 0.16
        drone += oscillator(TAU * tonic * 0.75 * t + 0.6, "sine") * 0.08
        pluck_env = math.exp(-local * 6.8)
        pluck = oscillator(TAU * frequency * t, "triangle") * pluck_env * 0.22
        pluck += oscillator(TAU * frequency * 2.01 * t, "sine") * pluck_env * 0.07
        phrase = int(t / (beat * 4)) % 4
        flute_freq = tonic * 2 ** ((scale[(degree + phrase) % 7] + 12) / 12)
        flute_env = 0.5 - 0.5 * math.cos(TAU * min(1.0, (t % (beat * 4)) / (beat * 4)))
        flute = oscillator(TAU * flute_freq * t + math.sin(t * 1.9) * 0.03, "sine") * flute_env * 0.08
        drum_phase = t % (beat * 2)
        drum = math.sin(TAU * (62 - drum_phase * 22) * drum_phase) * math.exp(-drum_phase * 13) * 0.16
        strike_phase = t % (beat * 8)
        bell = math.sin(TAU * 392 * strike_phase) * math.exp(-strike_phase * 2.8) * 0.055
        bell += math.sin(TAU * 587.3 * strike_phase) * math.exp(-strike_phase * 3.4) * 0.025
        noise = rnd.random() * 2 - 1
        wind_state_l = wind_state_l * 0.996 + noise * 0.004
        wind_state_r = wind_state_r * 0.995 + (rnd.random() * 2 - 1) * 0.005
        master = 0.78 * (0.86 + 0.14 * math.sin(math.pi * min(1, t / duration)))
        left = (drone + pluck * 0.82 + flute * 1.1 + drum + bell + wind_state_l * 0.2) * master
        right = (drone + pluck * 1.08 + flute * 0.82 + drum * 0.92 + bell * 1.1 + wind_state_r * 0.2) * master
        samples.append(int(max(-0.95, min(0.95, left)) * 32767))
        samples.append(int(max(-0.95, min(0.95, right)) * 32767))
    return samples


def synth_sfx(asset_id: str, category: str, duration: float) -> array:
    rnd = rng_for(asset_id)
    base = 70 + rnd.random() * 620
    samples = array("h")
    total = int(duration * RATE)
    noise_state = 0.0
    for index in range(total):
        t = index / RATE
        p = t / duration
        attack = min(1.0, p * 28)
        decay = (1.0 - p) ** (1.4 if category in {"spells", "portals"} else 2.6)
        envelope = attack * decay
        noise = rnd.random() * 2 - 1
        noise_state = noise_state * 0.82 + noise * 0.18
        if category == "footsteps":
            value = noise_state * envelope * 0.35 + math.sin(TAU * (base * 0.22) * t) * envelope * 0.18
        elif category in {"weapons", "armor"}:
            value = math.sin(TAU * base * t) * math.exp(-t * 18) * 0.42
            value += math.sin(TAU * base * 2.37 * t) * math.exp(-t * 24) * 0.22 + noise_state * envelope * 0.16
        elif category in {"spells", "portals"}:
            sweep = base * (0.55 + p * 2.1)
            value = math.sin(TAU * sweep * t + math.sin(t * 17) * 0.5) * envelope * 0.35
            value += math.sin(TAU * sweep * 1.51 * t) * envelope * 0.16 + noise_state * envelope * 0.08
        elif category == "creatures":
            sweep = base * (1.3 - p * 0.75)
            value = math.tanh(math.sin(TAU * sweep * t) * 2.4) * envelope * 0.28 + noise_state * envelope * 0.18
        elif category == "ui":
            value = math.sin(TAU * base * t) * math.exp(-t * 14) * 0.25
            value += math.sin(TAU * base * 1.5 * t) * math.exp(-t * 18) * 0.12
        else:
            value = noise_state * envelope * 0.28 + math.sin(TAU * base * t) * envelope * 0.12
        samples.append(int(max(-0.9, min(0.9, value)) * 32767))
    return samples


def synth_ambience(asset_id: str, flavor: int, duration: float = 6.0) -> array:
    rnd = rng_for(asset_id)
    samples = array("h")
    total = int(duration * RATE)
    state_a = 0.0
    state_b = 0.0
    for index in range(total):
        t = index / RATE
        fade = min(1.0, t / 0.6, (duration - t) / 0.6)
        state_a = state_a * 0.9985 + (rnd.random() * 2 - 1) * 0.0015
        state_b = state_b * 0.994 + (rnd.random() * 2 - 1) * 0.006
        tone = math.sin(TAU * (42 + flavor * 7) * t) * 0.055
        drip = math.sin(TAU * 940 * (t % 1.73)) * math.exp(-(t % 1.73) * 20) * (0.03 if flavor % 2 else 0)
        value = (state_a * 1.8 + state_b * 0.35 + tone + drip) * fade
        samples.append(int(max(-0.8, min(0.8, value)) * 32767))
    return samples


def generate() -> list[dict]:
    manifest: list[dict] = []
    for cue_id, cue_name, mode, bpm in MUSIC_CUES:
        write_wave(f"assets/music/{cue_id}.wav", synth_music(cue_id, mode, bpm), 2, "music", cue_name, manifest)

    spells = read_json("content/spells/spells.json")
    for spell in spells:
        path = spell["sfx"].removeprefix("res://")
        write_wave(path, synth_sfx(spell["id"], "spells", 0.62 + spell["rank"] * 0.035), 1, "spells", spell["name"], manifest)

    enemies = read_json("content/enemies/enemies.json")
    for enemy in enemies:
        for action, path in enemy["sounds"].items():
            duration = {"move": 0.22, "attack": 0.48, "death": 0.72}[action]
            write_wave(path.removeprefix("res://"), synth_sfx(f"{enemy['id']}:{action}", "creatures", duration),
                       1, "creatures", f"{enemy['name']} {action}", manifest)

    extra_groups = {
        "footsteps": [f"{surface}_{variant}" for surface in ["stone", "wood", "mud", "snow", "ice", "water", "moss", "metal"] for variant in range(3)],
        "weapons": [f"{weapon}_{action}" for weapon in ["blade", "axe", "hammer", "spear", "bow", "staff"] for action in ["swing", "hit", "block"]],
        "armor": [f"impact_{material}" for material in ["cloth", "leather", "mail", "scale", "plate", "bone"]],
        "ui": ["hover", "confirm", "cancel", "inventory_open", "inventory_close", "equip", "drop", "coins", "quest", "level_up", "save", "load"],
        "environment": ["door_open", "door_close", "chest_open", "trap_click", "trap_spike", "fire", "water", "wind", "rain", "snow", "machinery", "bridge", "rubble", "key", "potion"],
        "portals": ["open", "travel", "close", "shrine", "fountain"],
    }
    for category, names in extra_groups.items():
        for name in names:
            duration = 0.32 if category in {"footsteps", "ui"} else 0.58
            write_wave(f"assets/sounds/{category}/{name}.wav", synth_sfx(f"{category}:{name}", category, duration),
                       1, category, name.replace("_", " ").title(), manifest)
    for index, name in enumerate(["greywake", "wilderness", "barrows", "mines", "flooded", "frozen", "citadel", "choir"]):
        write_wave(f"assets/sounds/ambience/{name}.wav", synth_ambience(name, index), 1, "ambience", name.title(), manifest)

    manifest.sort(key=lambda entry: entry["path"])
    path = ROOT / "assets/generated/audio_manifest.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps({"version": 1, "seed": SEED, "assets": manifest}, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return manifest


def check() -> int:
    path = ROOT / "assets/generated/audio_manifest.json"
    if not path.exists():
        print("Missing audio manifest; run generator.", file=sys.stderr)
        return 1
    payload = json.loads(path.read_text(encoding="utf-8"))
    errors = []
    for record in payload.get("assets", []):
        asset = ROOT / record["path"].removeprefix("res://")
        if not asset.exists():
            errors.append(f"missing {record['path']}")
        elif hashlib.sha256(asset.read_bytes()).hexdigest() != record["sha256"]:
            errors.append(f"hash mismatch {record['path']}")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Audio manifest verified: {len(payload['assets'])} original WAV assets")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.check:
        return check()
    manifest = generate()
    music = sum(entry["category"] == "music" for entry in manifest)
    sounds = len(manifest) - music
    print(f"Generated {music} music cues and {sounds} sound/ambience files with seed {SEED}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

