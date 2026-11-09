#!/usr/bin/env python3
"""Fetch free CC0 realistic humanoid, outfit and animation assets."""
from pathlib import Path
from urllib.request import Request, urlopen
import hashlib
import struct
import os
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
CHARACTER_DEST = ROOT / "assets" / "characters"
ANIMATION_DEST = ROOT / "assets" / "animations"
CHARACTER_DEST.mkdir(parents=True, exist_ok=True)
ANIMATION_DEST.mkdir(parents=True, exist_ok=True)

# Both URLs are pinned to immutable public source commits; no account or payment is required.
CHARACTER_BASE = "https://raw.githubusercontent.com/glanderness/BeefTV/035003e2acb4f7e47599f8cf7b9792042c24eeb5/web/public/canvas/models/"
ANIMATION_BASE = "https://raw.githubusercontent.com/lluancarlo/ReadyToStrategize/1a9c05693f705cd7ebe0dd7af022d6b9e250d5c5/"
CHARACTERCREATOR_BASE = "https://raw.githubusercontent.com/kblood/CharacterCreator/852e48f316b90a0937234886630e4fb4cdfd1f78/output/"
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

# CharacterCreator generated outputs are CC0 even though its generator source is GPL-3.0.
# Only the generated GLB assets are used; no generator source code is bundled.
body = fetch(CHARACTERCREATOR_BASE, "base_body.glb", CHARACTER_DEST, "charactercreator-base-body.glb")
validate_glb(body, "CharacterCreator realistic base body", 5_000_000)
for source_name, output_name, minimum_size in [
    ("clothing_tshirt.glb", "charactercreator-tshirt.glb", 100_000),
    ("clothing_jeans.glb", "charactercreator-jeans.glb", 100_000),
    ("clothing_boots.glb", "charactercreator-boots.glb", 200_000),
    ("clothing_trenchcoat.glb", "charactercreator-trenchcoat.glb", 500_000),
    ("hair_short02.glb", "charactercreator-hair-short02.glb", 300_000),
]:
    clothing = fetch(CHARACTERCREATOR_BASE, source_name, CHARACTER_DEST, output_name)
    validate_glb(clothing, output_name, minimum_size)

character_license = fetch(CHARACTER_BASE, "quaternius-standard-male.LICENSE.md", CHARACTER_DEST, "QUATERNIUS-CC0-LICENSE.md")
(CHARACTER_DEST / "QUATERNIUS-CC0-LICENSE.md").write_text(character_license.decode("utf-8").replace("\u2014", "-"), encoding="utf-8")

animation = fetch(ANIMATION_BASE, ANIMATION_PACK + "Unreal-Godot/UAL2_Standard.glb", ANIMATION_DEST, "UAL2_Standard.glb")
validate_glb(animation, "Quaternius UAL2 Standard", 1_000_000)
fetch(ANIMATION_BASE, ANIMATION_PACK + "License.txt", ANIMATION_DEST, "LICENSE-UAL2-CC0.txt")

# Normalize every GLB for Godot: expand sparse accessors and remove quantized vertex attributes.
normalizer = ROOT / "tools" / "gltf-normalizer" / "normalize.mjs"
if not normalizer.is_file():
    raise SystemExit("Missing the glTF sparse-accessor normalizer.")
if shutil.which("node") is None or shutil.which("gltf-transform") is None:
    raise SystemExit("Missing Node.js or gltf-transform validation CLI.")
assets_to_normalize = [CHARACTER_DEST / "quaternius-standard-male.glb"]
assets_to_normalize += sorted(CHARACTER_DEST.glob("charactercreator-*.glb"))
assets_to_normalize += [ANIMATION_DEST / "UAL2_Standard.glb"]
for asset_path in assets_to_normalize:
    converted_path = asset_path.with_name(asset_path.stem + ".normalized.glb")
    subprocess.run(["node", str(normalizer), str(asset_path), str(converted_path)], check=True)
    subprocess.run(["gltf-transform", "validate", str(converted_path)], check=True)
    os.replace(converted_path, asset_path)
    validate_glb(asset_path.read_bytes(), asset_path.name, 100_000)
    print("Sparse-free, dequantized GLB validated:", asset_path.name)

print("CC0 skinned humanoid and animation assets are ready for Godot import.")
