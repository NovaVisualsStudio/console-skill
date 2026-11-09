#!/usr/bin/env python3
"""Fetch verified CC0 PBR maps at configurable 2K/4K quality for NOVA."""

from __future__ import annotations

import hashlib
import json
import os
import re
import sys
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "assets" / "textures"
API_BASE = "https://api.polyhaven.com/files/"
USER_AGENT = "NovaAncientWarrior-CC0AssetFetcher/1.0"
TEXTURE_TIER = os.environ.get("NOVA_TEXTURE_TIER", "2k").lower()
if TEXTURE_TIER not in {"2k", "4k"}:
    raise RuntimeError("NOVA_TEXTURE_TIER must be 2k or 4k")
MAX_FILE_BYTES = 28 * 1024 * 1024

ASSETS = {
    "stone_wall": {
        "maps": {
            "diff": (f"_diff_{TEXTURE_TIER}.jpg", f"_diffuse_{TEXTURE_TIER}.jpg"),
            "nor_gl": (f"_nor_gl_{TEXTURE_TIER}.jpg",),
            "rough": (f"_rough_{TEXTURE_TIER}.jpg",),
        },
    },
    "rock_tile_floor": {
        "maps": {
            "diff": (f"_diff_{TEXTURE_TIER}.jpg", f"_diffuse_{TEXTURE_TIER}.jpg"),
            "nor_gl": (f"_nor_gl_{TEXTURE_TIER}.jpg",),
            "rough": (f"_rough_{TEXTURE_TIER}.jpg",),
        },
    },
    "metal_plate": {
        "maps": {
            "diff": (f"_diff_{TEXTURE_TIER}.jpg", f"_diffuse_{TEXTURE_TIER}.jpg"),
            "nor_gl": (f"_nor_gl_{TEXTURE_TIER}.jpg",),
            "rough": (f"_rough_{TEXTURE_TIER}.jpg",),
            "metal": (f"_metal_{TEXTURE_TIER}.jpg",),
        },
    },
    "leather_red_02": {
        "maps": {
            "diff": (f"_coll2_{TEXTURE_TIER}.jpg", f"_diff_{TEXTURE_TIER}.jpg", f"_diffuse_{TEXTURE_TIER}.jpg"),
            "nor_gl": (f"_nor_gl_{TEXTURE_TIER}.jpg",),
            "rough": (f"_rough_{TEXTURE_TIER}.jpg",),
        },
    },
}


def request_bytes(url: str, limit: int | None = None) -> bytes:
    request = Request(url, headers={"User-Agent": USER_AGENT, "Accept": "application/json, image/jpeg"})
    with urlopen(request, timeout=90) as response:
        if response.status != 200:
            raise RuntimeError(f"HTTP {response.status} while fetching {url}")
        payload = response.read((limit + 1) if limit is not None else -1)
    if limit is not None and len(payload) > limit:
        raise RuntimeError(f"Downloaded file exceeds {limit} bytes: {url}")
    return payload


def iter_file_records(node, path=()):
    if isinstance(node, dict):
        if isinstance(node.get("url"), str) and isinstance(node.get("md5"), str):
            yield path, node
            return
        for key, value in node.items():
            yield from iter_file_records(value, path + (str(key),))
    elif isinstance(node, list):
        for index, value in enumerate(node):
            yield from iter_file_records(value, path + (str(index),))


def select_map(files: dict, asset_id: str, map_name: str, suffixes: tuple[str, ...]) -> dict:
    matches = []
    for _, record in iter_file_records(files):
        url = record["url"]
        parsed = urlparse(url)
        filename = Path(parsed.path).name.lower()
        if parsed.scheme != "https" or parsed.netloc != "dl.polyhaven.org":
            continue
        if not parsed.path.startswith(f"/file/ph-assets/Textures/jpg/{TEXTURE_TIER}/"):
            continue
        if not filename.startswith(asset_id + "_") or not filename.endswith(".jpg"):
            continue
        if any(filename.endswith(suffix) for suffix in suffixes):
            matches.append(record)
    if len(matches) != 1:
        available = [
            Path(urlparse(record["url"]).path).name
            for _, record in iter_file_records(files)
            if isinstance(record.get("url"), str)
        ]
        raise RuntimeError(
            f"Expected exactly one {TEXTURE_TIER.upper()} JPG {map_name} map for {asset_id}; "
            f"found {len(matches)}. Available files: {available[:30]}"
        )
    return matches[0]


def write_import_settings(destination: Path, map_name: str) -> Path:
    """Pin mobile-friendly import settings before Godot's first texture import."""
    params = {
        "compress/mode": "2",  # VRAM Compressed (ETC2 on the Android compatibility renderer).
        "mipmaps/generate": "true",
        "mipmaps/limit": "-1",
        "process/size_limit": str(2048 if TEXTURE_TIER == "2k" else 4096),
        "process/normal_map_invert_y": "false",  # Poly Haven nor_gl maps use OpenGL Y+.
    }
    if map_name == "nor_gl":
        params["compress/normal_map"] = "1"  # Enable RGTC-style normal-map compression.

    lines = [
        "[remap]",
        'importer="texture"',
        "",
        "[params]",
    ]
    lines.extend(f"{key}={value}" for key, value in params.items())
    sidecar = Path(str(destination) + ".import")
    sidecar.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return sidecar


def download_asset(asset_id: str, map_name: str, record: dict) -> tuple[Path, str, int]:
    url = record["url"]
    expected_md5 = record["md5"].lower()
    if not re.fullmatch(r"[0-9a-f]{32}", expected_md5):
        raise RuntimeError(f"Invalid MD5 metadata for {asset_id}/{map_name}")
    size = int(record.get("size", record.get("size_bytes", 0)) or 0)
    if size > MAX_FILE_BYTES:
        raise RuntimeError(f"Asset file too large for Android {TEXTURE_TIER.upper()} budget ({size} bytes): {url}")
    payload = request_bytes(url, MAX_FILE_BYTES)
    if not payload.startswith(b"\xff\xd8\xff"):
        raise RuntimeError(f"Expected a JPEG image, got invalid bytes: {url}")
    actual_md5 = hashlib.md5(payload).hexdigest()
    if actual_md5 != expected_md5:
        raise RuntimeError(f"MD5 mismatch for {asset_id}/{map_name}: {actual_md5} != {expected_md5}")
    filename = f"{asset_id}_{map_name}_{TEXTURE_TIER}.jpg"
    destination = OUTPUT / filename
    destination.write_bytes(payload)
    import_sidecar = write_import_settings(destination, map_name)
    print(f"Godot mobile import profile OK: {import_sidecar.name}")
    return destination, actual_md5, len(payload)


def main() -> int:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    total_bytes = 0
    map_count = sum(len(metadata["maps"]) for metadata in ASSETS.values())
    for asset_id, metadata in ASSETS.items():
        api_payload = request_bytes(API_BASE + asset_id)
        try:
            files = json.loads(api_payload.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise RuntimeError(f"Invalid Poly Haven files metadata for {asset_id}") from exc
        for map_name, suffixes in metadata["maps"].items():
            record = select_map(files, asset_id, map_name, suffixes)
            destination, digest, size = download_asset(asset_id, map_name, record)
            total_bytes += size
            print(f"CC0 PBR OK: {destination.name} ({size:,} bytes, md5={digest})")
    print(f"Downloaded and verified {map_count} {TEXTURE_TIER.upper()} JPG maps ({total_bytes:,} bytes total).")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"CC0 texture fetch failed: {exc}", file=sys.stderr)
        raise
