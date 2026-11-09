#!/usr/bin/env python3
"""Fetch the free CC0 Quaternius Universal Animation Library 2 Standard GLB.

The character GLB is already vendored under assets/characters. This script fetches
only the animation pack from a pinned public GitHub commit; no account or payment
is required. Run from any working directory.
"""
from pathlib import Path
from urllib.request import Request, urlopen
import hashlib
import json
import struct

ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / "assets" / "animations"
DEST.mkdir(parents=True, exist_ok=True)

BASE = "https://raw.githubusercontent.com/lluancarlo/ReadyToStrategize/1a9c05693f705cd7ebe0dd7af022d6b9e250d5c5/"
PACK = "assets/quaternius/Universal%20Animation%20Library%202%5BStandard%5D/"
FILES = {
    "UAL2_Standard.glb": PACK + "Unreal-Godot/UAL2_Standard.glb",
    "LICENSE-UAL2-CC0.txt": PACK + "License.txt",
}

def fetch(name: str, relative_url: str) -> bytes:
    request = Request(BASE + relative_url, headers={"User-Agent": "NovaAncientWarrior-AssetSetup/1.0"})
    with urlopen(request, timeout=90) as response:
        data = response.read()
    if not data:
        raise RuntimeError(f"Empty response for {name}")
    path = DEST / name
    path.write_bytes(data)
    print(f"{name}: {len(data):,} bytes, sha256={hashlib.sha256(data).hexdigest()}")
    return data

glb = fetch("UAL2_Standard.glb", FILES["UAL2_Standard.glb"])
if len(glb) < 1_000_000 or glb[:4] != b"glTF":
    raise RuntimeError("Downloaded animation asset is not a valid GLB file")
version, total_length = struct.unpack_from("<II", glb, 4)
if version != 2 or total_length != len(glb):
    raise RuntimeError("GLB header/version/length validation failed")
fetch("LICENSE-UAL2-CC0.txt", FILES["LICENSE-UAL2-CC0.txt"])
print("CC0 humanoid animation pack ready for Godot import.")
