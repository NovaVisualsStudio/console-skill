#!/usr/bin/env python3
"""Remove unused facial morph-target data from a GLB while preserving skin and bone animation."""
import argparse
import json
import struct
from pathlib import Path

JSON_CHUNK = b"JSON"
BIN_CHUNK = b"BIN\0"


def read_glb(path):
    data = path.read_bytes()
    if len(data) < 12:
        raise ValueError("GLB header is truncated")
    magic, version, total = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or total != len(data):
        raise ValueError("Invalid GLB 2.0 header")
    offset, chunks = 12, []
    while offset < len(data):
        size, kind = struct.unpack_from("<I4s", data, offset)
        offset += 8
        chunk = data[offset:offset + size]
        if len(chunk) != size:
            raise ValueError("Truncated GLB chunk")
        chunks.append((kind, chunk))
        offset += size
    json_chunks = [value for kind, value in chunks if kind == JSON_CHUNK]
    bin_chunks = [value for kind, value in chunks if kind == BIN_CHUNK]
    if len(json_chunks) != 1 or len(bin_chunks) != 1:
        raise ValueError("Expected one JSON and one BIN chunk")
    document = json.loads(json_chunks[0].decode("utf-8").rstrip(" \t\r\n\0"))
    return document, bin_chunks[0]


def remove_morph_targets(document):
    removed_targets = 0
    for mesh in document.get("meshes", []):
        mesh.pop("weights", None)
        extras = mesh.get("extras")
        if isinstance(extras, dict):
            extras.pop("targetNames", None)
            if not extras:
                mesh.pop("extras", None)
        for primitive in mesh.get("primitives", []):
            removed_targets += len(primitive.pop("targets", []))
    for node in document.get("nodes", []):
        node.pop("weights", None)
    removed_channels = 0
    for animation in document.get("animations", []):
        samplers = animation.get("samplers", [])
        keep = []
        sampler_ids = set()
        for channel in animation.get("channels", []):
            if channel.get("target", {}).get("path") == "weights":
                removed_channels += 1
                continue
            keep.append(channel)
            sampler_ids.add(channel["sampler"])
        remap, new_samplers = {}, []
        for old_id, sampler in enumerate(samplers):
            if old_id in sampler_ids:
                remap[old_id] = len(new_samplers)
                new_samplers.append(sampler)
        for channel in keep:
            channel["sampler"] = remap[channel["sampler"]]
        animation["samplers"], animation["channels"] = new_samplers, keep
    return removed_targets, removed_channels


def repack(document, source_bin):
    accessors, views = document.get("accessors", []), document.get("bufferViews", [])
    used_accessors = set()

    def add_mapping(mapping):
        if isinstance(mapping, dict):
            used_accessors.update(v for v in mapping.values() if isinstance(v, int))

    for mesh in document.get("meshes", []):
        for primitive in mesh.get("primitives", []):
            add_mapping(primitive.get("attributes"))
            if isinstance(primitive.get("indices"), int):
                used_accessors.add(primitive["indices"])
    for skin in document.get("skins", []):
        if isinstance(skin.get("inverseBindMatrices"), int):
            used_accessors.add(skin["inverseBindMatrices"])
    for animation in document.get("animations", []):
        for sampler in animation.get("samplers", []):
            used_accessors.update(sampler[k] for k in ("input", "output"))
    used_views = set()
    vertex_attribute_accessors = set()
    for mesh in document.get("meshes", []):
        for primitive in mesh.get("primitives", []):
            for accessor_index in primitive.get("attributes", {}).values():
                if isinstance(accessor_index, int):
                    vertex_attribute_accessors.add(accessor_index)

    view_accessor_users = {}
    non_vertex_view_references = set()
    for index in used_accessors:
        accessor = accessors[index]
        if isinstance(accessor.get("bufferView"), int):
            view_index = accessor["bufferView"]
            used_views.add(view_index)
            view_accessor_users.setdefault(view_index, set()).add(index)
        # Sparse indices/values are independent bufferViews and must survive
        # repacking even when they are not referenced by an accessor.bufferView.
        sparse = accessor.get("sparse") or {}
        for key in ("indices", "values"):
            sparse_view = sparse.get(key, {}).get("bufferView")
            if isinstance(sparse_view, int):
                used_views.add(sparse_view)
                non_vertex_view_references.add(sparse_view)
    for image in document.get("images", []):
        image_view = image.get("bufferView")
        if isinstance(image_view, int):
            used_views.add(image_view)
            non_vertex_view_references.add(image_view)

    output_bin, view_remap, new_views = bytearray(), {}, []
    for old_index in sorted(used_views):
        view = views[old_index]
        if view.get("buffer", 0) != 0:
            raise ValueError("Only one embedded GLB buffer is supported")
        start = int(view.get("byteOffset", 0))
        length = int(view["byteLength"])
        if start < 0 or length < 0 or start + length > len(source_bin):
            raise ValueError("bufferView points outside BIN chunk")
        while len(output_bin) % 4:
            output_bin.append(0)
        new_view = dict(view)
        new_view["buffer"] = 0
        new_view["byteOffset"] = len(output_bin)

        # Godot's glTF importer expects an explicit stride for vertex data.
        # Add it only when this bufferView belongs to exactly one tightly-packed
        # vertex accessor; never guess for interleaved/shared bufferViews.
        users = view_accessor_users.get(old_index, set())
        if len(users) == 1:
            accessor_index = next(iter(users))
            accessor = accessors[accessor_index]
            if accessor_index in vertex_attribute_accessors and old_index not in non_vertex_view_references and "sparse" not in accessor:
                component_bytes = {5120: 1, 5121: 1, 5122: 2, 5123: 2, 5125: 4, 5126: 4}.get(accessor.get("componentType"))
                component_counts = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT2": 4, "MAT3": 9, "MAT4": 16}
                component_count = component_counts.get(accessor.get("type"))
                if component_bytes is not None and component_count is not None:
                    packed_stride = component_bytes * component_count
                    if 4 <= packed_stride <= 252 and packed_stride % 4 == 0:
                        new_view["byteStride"] = packed_stride
        view_remap[old_index] = len(new_views)
        new_views.append(new_view)
        output_bin.extend(source_bin[start:start + length])

    accessor_remap, new_accessors = {}, []
    for old_index in sorted(used_accessors):
        accessor = dict(accessors[old_index])
        if isinstance(accessor.get("bufferView"), int):
            accessor["bufferView"] = view_remap[accessor["bufferView"]]
        if isinstance(accessor.get("sparse"), dict):
            sparse = dict(accessor["sparse"])
            for key in ("indices", "values"):
                if isinstance(sparse.get(key, {}).get("bufferView"), int):
                    entry = dict(sparse[key])
                    entry["bufferView"] = view_remap[entry["bufferView"]]
                    sparse[key] = entry
            accessor["sparse"] = sparse
        accessor_remap[old_index] = len(new_accessors)
        new_accessors.append(accessor)

    for mesh in document.get("meshes", []):
        for primitive in mesh.get("primitives", []):
            primitive["attributes"] = {k: accessor_remap[v] for k, v in primitive.get("attributes", {}).items()}
            if isinstance(primitive.get("indices"), int):
                primitive["indices"] = accessor_remap[primitive["indices"]]
    for skin in document.get("skins", []):
        if isinstance(skin.get("inverseBindMatrices"), int):
            skin["inverseBindMatrices"] = accessor_remap[skin["inverseBindMatrices"]]
    for animation in document.get("animations", []):
        for sampler in animation.get("samplers", []):
            sampler["input"] = accessor_remap[sampler["input"]]
            sampler["output"] = accessor_remap[sampler["output"]]
    for image in document.get("images", []):
        if isinstance(image.get("bufferView"), int):
            image["bufferView"] = view_remap[image["bufferView"]]
    document["accessors"], document["bufferViews"] = new_accessors, new_views
    document["buffers"] = [{"byteLength": len(output_bin)}]
    return bytes(output_bin)


def write_glb(document, binary, output):
    while len(binary) % 4:
        binary += b"\0"
    document["buffers"][0]["byteLength"] = len(binary)
    json_data = json.dumps(document, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    json_data += b" " * ((-len(json_data)) % 4)
    total = 12 + 8 + len(json_data) + 8 + len(binary)
    output.write_bytes(
        struct.pack("<4sII", b"glTF", 2, total)
        + struct.pack("<I4s", len(json_data), JSON_CHUNK) + json_data
        + struct.pack("<I4s", len(binary), BIN_CHUNK) + binary
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--max-mb", type=float, default=12.0)
    args = parser.parse_args()
    document, binary = read_glb(args.input)
    removed_targets, removed_channels = remove_morph_targets(document)
    binary = repack(document, binary)
    write_glb(document, binary, args.output)
    if args.output.stat().st_size > args.max_mb * 1024 * 1024:
        raise SystemExit("Optimized GLB exceeds configured Android size budget")
    bone_count = len(document.get("skins", [{}])[0].get("joints", []))
    channels = [c for a in document.get("animations", []) for c in a.get("channels", [])]
    if bone_count < 20 or not channels or any(c.get("target", {}).get("path") == "weights" for c in channels):
        raise SystemExit("Optimized GLB failed skeleton/animation validation")
    print(json.dumps({
        "input_bytes": args.input.stat().st_size,
        "output_bytes": args.output.stat().st_size,
        "saved_bytes": args.input.stat().st_size - args.output.stat().st_size,
        "removed_morph_targets": removed_targets,
        "removed_weight_channels": removed_channels,
        "bone_count": bone_count,
        "animation_count": len(document.get("animations", [])),
        "animation_channels": len(channels),
    }, indent=2))


if __name__ == "__main__":
    main()
