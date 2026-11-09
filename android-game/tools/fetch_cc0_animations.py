#!/usr/bin/env python3
"""Fetch the free CC0 Quaternius humanoid character and animation assets."""
from pathlib import Path
from urllib.request import Request, urlopen
import hashlib
import struct

ROOT = Path(__file__).resolve().parents[1]
CHARACTER_DEST = ROOT / "assets" / "characters"
ANIMATION_DEST = ROOT / "assets" / "animations"
CHARACTER_DEST.mkdir(parents=True, exist_ok=True)
ANIMATION_DEST.mkdir(parents=True, exist_ok=True)

# Both URLs are pinned to immutable public source commits; no account or payment is required.
CHARACTER_BASE = "https://raw.githubusercontent.com/glanderness/BeefTV/035003e2acb4f7e47599f8cf7b9792042c24eeb5/web/public/canvas/models/"
ANIMATION_BASE = "https://raw.githubusercontent.com/lluancarlo/ReadyToStrategize/1a9c05693f705cd7ebe0dd7af022d6b9e250d5c5/"
ANIMATION_PACK = "assets/quaternius/Universal%20Animation%20Library%202%5BStandard%5D/"

def fetch(base: str, relative_url: str, destination: Path, name: str) -> bytes:
    request = Request(base + relative_url, headers={"User-Agent": "NovaAncientWarrior-AssetSetup/1.0"})
    with urlopen(request, timeout=90) as response:
        data = response.read()
    if not data:
        raise RuntimeError(f"Empty response for {name}")
    (destination / name).write_bytes(data)
    print(f"{name}: {len(data):,} bytes, SHA-256 {hashlib.sha256(data).hexdigest()}")
    return data

def validate_glb(data: bytes, name: str, minimum_size: int) -> None:
    if len(data) < minimum_size or data[:4] != b"glTF":
        raise RuntimeError(f"{name} is not a valid GLB file")
    version, total_length = struct.unpack_from("<II", data, 4)
    if version != 2 or total_length != len(data):
        raise RuntimeError(f"{name} GLB header/version/length validation failed")

character = fetch(CHARACTER_BASE, "quaternius-standard-male.glb", CHARACTER_DEST, "quaternius-standard-male.glb")
validate_glb(character, "Quaternius humanoid", 500_000)
fetch(CHARACTER_BASE, "quaternius-standard-male.LICENSE.md", CHARACTER_DEST, "QUATERNIUS-CC0-LICENSE.md")

animation = fetch(ANIMATION_BASE, ANIMATION_PACK + "Unreal-Godot/UAL2_Standard.glb", ANIMATION_DEST, "UAL2_Standard.glb")
validate_glb(animation, "Quaternius UAL2 Standard", 1_000_000)
fetch(ANIMATION_BASE, ANIMATION_PACK + "License.txt", ANIMATION_DEST, "LICENSE-UAL2-CC0.txt")
print("CC0 skinned humanoid and animation assets are ready for Godot import.")
