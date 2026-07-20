#!/usr/bin/env python3
"""Validate audio provenance, format, levels, coverage, and catalog references."""

from __future__ import annotations

import hashlib
import json
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def main() -> int:
    manifest_path = ROOT / "assets/generated/audio_manifest.json"
    if not manifest_path.exists():
        print("AUDIO VALIDATION FAILED: missing manifest")
        return 1
    payload = json.loads(manifest_path.read_text(encoding="utf-8"))
    records = payload.get("assets", [])
    errors: list[str] = []
    paths: set[str] = set()
    music = 0
    sounds = 0
    for record in records:
        resource = record["path"]
        if resource in paths:
            errors.append(f"duplicate audio path {resource}")
        paths.add(resource)
        path = ROOT / resource.removeprefix("res://")
        if not path.exists():
            errors.append(f"missing audio {resource}")
            continue
        if hashlib.sha256(path.read_bytes()).hexdigest() != record["sha256"]:
            errors.append(f"hash mismatch {resource}")
        try:
            with wave.open(str(path), "rb") as stream:
                if stream.getframerate() != 44_100:
                    errors.append(f"sample rate is not 44.1 kHz {resource}")
                if stream.getsampwidth() != 2:
                    errors.append(f"sample width is not PCM16 {resource}")
                if stream.getnchannels() != record["channels"]:
                    errors.append(f"channel mismatch {resource}")
                if stream.getnframes() != record["frames"]:
                    errors.append(f"frame mismatch {resource}")
        except (OSError, wave.Error) as exc:
            errors.append(f"broken WAV {resource}: {exc}")
        if record["peak"] > 0.96:
            errors.append(f"unsafe peak level {resource}: {record['peak']}")
        if record["duration"] <= 0.1:
            errors.append(f"audio too short {resource}")
        if record["category"] == "music":
            music += 1
            if record["channels"] != 2 or record["duration"] < 10:
                errors.append(f"music cue not substantial stereo {resource}")
        else:
            sounds += 1
    if music < 12:
        errors.append(f"only {music} music cues")
    if sounds < 100:
        errors.append(f"only {sounds} sound files")

    referenced: set[str] = set()
    for spell in json.loads((ROOT / "content/spells/spells.json").read_text(encoding="utf-8")):
        referenced.add(spell["sfx"])
    for enemy in json.loads((ROOT / "content/enemies/enemies.json").read_text(encoding="utf-8")):
        referenced.update(enemy["sounds"].values())
    for theme in json.loads((ROOT / "content/world/themes.json").read_text(encoding="utf-8")):
        referenced.add(theme["ambient_track"])
    for resource in referenced:
        if resource not in paths:
            errors.append(f"catalog references unmanifested audio {resource}")
    for wav in ROOT.glob("assets/**/*.wav"):
        resource = "res://" + wav.relative_to(ROOT).as_posix()
        if resource not in paths:
            errors.append(f"unreferenced generated audio {resource}")

    if errors:
        print(f"AUDIO VALIDATION FAILED ({len(errors)} errors)")
        for error in errors:
            print(" -", error)
        return 1
    print(f"AUDIO VALIDATION PASSED: {music} music cues, {sounds} sounds/ambiences")
    categories: dict[str, int] = {}
    for record in records:
        categories[record["category"]] = categories.get(record["category"], 0) + 1
    for category, count in sorted(categories.items()):
        print(f"  {category}: {count}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

