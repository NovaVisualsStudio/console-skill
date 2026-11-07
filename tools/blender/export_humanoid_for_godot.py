#!/usr/bin/env python3
"""Validate a licensed humanoid FBX/GLB and package it for Godot 4.

Run:
  blender --background --python tools/blender/export_humanoid_for_godot.py -- \
    --input hero.fbx --output nova-hero.glb \
    --asset-source "https://..." --asset-license "CC0-1.0" --strict
"""
import argparse
import json
import os
import re
import sys

import bpy


REQUIRED_BONES = {
    "hips", "spine", "head",
    "leftupperarm", "leftlowerarm", "rightupperarm", "rightlowerarm",
    "leftupperleg", "leftlowerleg", "rightupperleg", "rightlowerleg",
}
EXPECTED_CLIPS = [
    "idle", "walk", "run", "jump", "dodge",
    "attack_1", "attack_2", "attack_3", "hit", "death",
]


def parse_args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--report", default="")
    parser.add_argument("--asset-source", required=True)
    parser.add_argument("--asset-license", required=True)
    parser.add_argument("--strict", action="store_true")
    return parser.parse_args(argv)


def normalized_bone_name(name):
    value = name.lower().split(":")[-1]
    value = re.sub(r"[^a-z0-9]", "", value)
    aliases = {
        "leftarm": "leftupperarm",
        "rightarm": "rightupperarm",
        "leftforearm": "leftlowerarm",
        "rightforearm": "rightlowerarm",
        "leftupleg": "leftupperleg",
        "rightupleg": "rightupperleg",
        "leftleg": "leftlowerleg",
        "rightleg": "rightlowerleg",
    }
    return aliases.get(value, value)


def import_source(path):
    extension = os.path.splitext(path)[1].lower()
    if extension == ".fbx":
        bpy.ops.import_scene.fbx(filepath=path)
    elif extension in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=path)
    else:
        raise RuntimeError("Only FBX, GLB and glTF inputs are supported")


def main():
    args = parse_args()
    source = os.path.abspath(args.input)
    output = os.path.abspath(args.output)
    if not os.path.isfile(source):
        raise FileNotFoundError(source)
    if not args.asset_source.strip() or not args.asset_license.strip():
        raise RuntimeError("Asset provenance is mandatory; provide source URL and exact licence")
    os.makedirs(os.path.dirname(output), exist_ok=True)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    import_source(source)

    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not armatures or not meshes:
        raise RuntimeError("Input must contain at least one humanoid armature and one mesh")
    armature = max(armatures, key=lambda item: len(item.data.bones))
    normalized = {normalized_bone_name(bone.name) for bone in armature.data.bones}
    missing = sorted(REQUIRED_BONES - normalized)

    weighted_vertices = 0
    total_vertices = 0
    skinned_meshes = []
    for mesh in meshes:
        total_vertices += len(mesh.data.vertices)
        modifier_targets = {
            modifier.object for modifier in mesh.modifiers
            if modifier.type == "ARMATURE" and modifier.object is not None
        }
        if armature in modifier_targets or mesh.parent == armature:
            skinned_meshes.append(mesh)
        for vertex in mesh.data.vertices:
            if any(group.weight > 0.0 for group in vertex.groups):
                weighted_vertices += 1
    weight_ratio = weighted_vertices / max(total_vertices, 1)
    actions = sorted({action.name for action in bpy.data.actions})
    missing_clips = [clip for clip in EXPECTED_CLIPS if clip not in {name.lower() for name in actions}]

    report = {
        "input": os.path.basename(source),
        "output": os.path.basename(output),
        "armature": armature.name,
        "bone_count": len(armature.data.bones),
        "mesh_count": len(meshes),
        "skinned_mesh_count": len(skinned_meshes),
        "weighted_vertex_ratio": round(weight_ratio, 5),
        "animation_actions": actions,
        "missing_recommended_clips": missing_clips,
        "missing_required_humanoid_bones": missing,
        "asset_source": args.asset_source,
        "asset_license": args.asset_license,
        "strict": args.strict,
    }
    failures = []
    if missing:
        failures.append("missing required humanoid bones: " + ", ".join(missing))
    if not skinned_meshes:
        failures.append("no mesh is bound to the selected armature")
    if weight_ratio < 0.90:
        failures.append("less than 90% of mesh vertices have skin weights")
    if args.strict and len(actions) < 3:
        failures.append("strict mode requires at least three imported animation actions")

    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.context.scene.objects:
        if obj.type in {"ARMATURE", "MESH"}:
            obj.select_set(True)
    bpy.context.view_layer.objects.active = armature
    bpy.ops.export_scene.gltf(
        filepath=output,
        export_format="GLB",
        use_selection=True,
        export_animations=True,
        export_nla_strips=True,
        export_apply=True,
    )
    if not os.path.isfile(output) or os.path.getsize(output) < 1024:
        raise RuntimeError("Godot GLB export is missing or unexpectedly small")
    report["output_bytes"] = os.path.getsize(output)
    report["passed"] = not failures
    report["failures"] = failures
    report_path = os.path.abspath(args.report) if args.report else output + ".report.json"
    os.makedirs(os.path.dirname(report_path) or ".", exist_ok=True)
    with open(report_path, "w", encoding="utf-8") as handle:
        json.dump(report, handle, indent=2)
        handle.write("\n")
    print(json.dumps(report, indent=2))
    if failures:
        raise SystemExit(2)


if __name__ == "__main__":
    main()
