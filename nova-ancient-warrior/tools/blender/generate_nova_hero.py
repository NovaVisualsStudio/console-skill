"""Generate an original low-poly skinned Nova hero and animation library in Blender 4.2+.

Usage:
  blender -b --python generate_nova_hero.py -- --output ../assets/characters/nova_hero.glb
All geometry, materials, rigging and animation are generated procedurally; no external assets.
"""
from __future__ import annotations

import argparse
import math
import os
import sys

import bpy


def arguments():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="nova_hero.glb")
    return parser.parse_args(args)


def _make_pbr_images(name, color, roughness, size=512):
    """Create seamless colour, roughness and tangent-space normal maps from deterministic math."""
    import numpy as np

    angle = np.linspace(0.0, math.tau, size, endpoint=False, dtype=np.float32)
    u, v = np.meshgrid(angle, angle)
    field = (
        0.44 * np.sin(2.0 * u + 0.35) * np.cos(3.0 * v - 0.65)
        + 0.24 * np.sin(7.0 * u + 2.0 * v)
        + 0.18 * np.cos(11.0 * v - 3.0 * u)
        + 0.14 * np.sin(17.0 * u) * np.cos(19.0 * v)
    )
    height = np.clip(0.5 + field * 0.27, 0.0, 1.0)
    variation = np.clip(0.84 + height * 0.22, 0.76, 1.08)

    colour_pixels = np.ones((size, size, 4), dtype=np.float32)
    for channel in range(3):
        colour_pixels[:, :, channel] = np.clip(float(color[channel]) * variation, 0.0, 1.0)

    rough_value = np.clip(float(roughness) + (height - 0.5) * 0.18, 0.04, 0.98)
    rough_pixels = np.ones((size, size, 4), dtype=np.float32)
    rough_pixels[:, :, :3] = rough_value[:, :, None]

    grad_y, grad_x = np.gradient(height.astype(np.float32))
    normal_x = -grad_x * 30.0
    normal_y = -grad_y * 30.0
    normal_z = np.ones_like(normal_x)
    length = np.sqrt(normal_x * normal_x + normal_y * normal_y + normal_z * normal_z)
    normal_pixels = np.ones((size, size, 4), dtype=np.float32)
    normal_pixels[:, :, 0] = normal_x / length * 0.5 + 0.5
    normal_pixels[:, :, 1] = normal_y / length * 0.5 + 0.5
    normal_pixels[:, :, 2] = normal_z / length * 0.5 + 0.5

    def make_image(suffix, pixels, non_colour=False):
        image = bpy.data.images.new(
            name + "_" + suffix, width=size, height=size, alpha=True, float_buffer=False
        )
        if non_colour:
            image.colorspace_settings.name = "Non-Color"
        image.pixels.foreach_set(pixels.reshape(-1))
        image.pack()
        return image

    return (
        make_image("Albedo", colour_pixels),
        make_image("Roughness", rough_pixels, True),
        make_image("Normal", normal_pixels, True),
    )


def material(name, color, metallic=0.0, roughness=0.7):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1.0)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()

    output = nodes.new("ShaderNodeOutputMaterial")
    output.location = (620, 40)
    principled = nodes.new("ShaderNodeBsdfPrincipled")
    principled.location = (350, 40)
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    links.new(principled.outputs["BSDF"], output.inputs["Surface"])

    albedo_image, roughness_image, normal_image = _make_pbr_images(name, color, roughness)
    albedo_node = nodes.new("ShaderNodeTexImage")
    albedo_node.image = albedo_image
    albedo_node.interpolation = "Linear"
    albedo_node.location = (-500, 220)
    links.new(albedo_node.outputs["Color"], principled.inputs["Base Color"])

    roughness_node = nodes.new("ShaderNodeTexImage")
    roughness_node.image = roughness_image
    roughness_node.interpolation = "Linear"
    roughness_node.location = (-500, -10)
    links.new(roughness_node.outputs["Color"], principled.inputs["Roughness"])

    normal_texture_node = nodes.new("ShaderNodeTexImage")
    normal_texture_node.image = normal_image
    normal_texture_node.image.colorspace_settings.name = "Non-Color"
    normal_texture_node.interpolation = "Linear"
    normal_texture_node.location = (-500, -250)
    normal_node = nodes.new("ShaderNodeNormalMap")
    normal_node.inputs["Strength"].default_value = 0.22
    normal_node.location = (-180, -220)
    links.new(normal_texture_node.outputs["Color"], normal_node.inputs["Color"])
    links.new(normal_node.outputs["Normal"], principled.inputs["Normal"])
    return mat


def make_rig():
    bpy.ops.object.armature_add(enter_editmode=True)
    rig = bpy.context.object
    rig.name = "NovaHeroRig"
    rig.data.name = "NovaHeroSkeleton"
    edit = rig.data.edit_bones
    for bone in list(edit):
        edit.remove(bone)

    definitions = {
        "root": ((0, 0, 0.0), (0, 0, 0.22), None),
        "pelvis": ((0, 0, 0.88), (0, 0, 1.12), "root"),
        "spine": ((0, 0, 1.05), (0, 0, 1.52), "pelvis"),
        "chest": ((0, 0, 1.48), (0, 0, 1.88), "spine"),
        "neck": ((0, 0, 1.82), (0, 0, 2.06), "chest"),
        "head": ((0, 0, 2.02), (0, 0, 2.48), "neck"),
        "shoulder.L": ((-0.28, 0, 1.82), (-0.52, 0, 1.78), "chest"),
        "upper_arm.L": ((-0.48, 0, 1.78), (-0.68, 0, 1.48), "shoulder.L"),
        "forearm.L": ((-0.68, 0, 1.48), (-0.82, 0, 1.18), "upper_arm.L"),
        "hand.L": ((-0.82, 0, 1.18), (-0.88, 0, 1.04), "forearm.L"),
        "shoulder.R": ((0.28, 0, 1.82), (0.52, 0, 1.78), "chest"),
        "upper_arm.R": ((0.48, 0, 1.78), (0.68, 0, 1.48), "shoulder.R"),
        "forearm.R": ((0.68, 0, 1.48), (0.82, 0, 1.18), "upper_arm.R"),
        "hand.R": ((0.82, 0, 1.18), (0.88, 0, 1.04), "forearm.R"),
        "thigh.L": ((-0.19, 0, 0.98), (-0.20, 0, 0.54), "pelvis"),
        "shin.L": ((-0.20, 0, 0.54), (-0.20, 0, 0.16), "thigh.L"),
        "foot.L": ((-0.20, 0, 0.16), (-0.20, -0.28, 0.10), "shin.L"),
        "thigh.R": ((0.19, 0, 0.98), (0.20, 0, 0.54), "pelvis"),
        "shin.R": ((0.20, 0, 0.54), (0.20, 0, 0.16), "thigh.R"),
        "foot.R": ((0.20, 0, 0.16), (0.20, -0.28, 0.10), "shin.R"),
    }
    bones = {}
    for name, (head, tail, parent) in definitions.items():
        bone = edit.new(name)
        bone.head = head
        bone.tail = tail
        if parent:
            bone.parent = bones[parent]
        bones[name] = bone
    bpy.ops.object.mode_set(mode="OBJECT")
    rig.show_in_front = True
    rig.data.display_type = "OCTAHEDRAL"
    return rig, list(definitions)


def add_part(rig, bone_name, name, location, dimensions, mat, shape="sphere"):
    if shape == "cube":
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
    elif shape == "ico":
        bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1, radius=1.0, location=location)
    else:
        bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    if shape == "cube":
        bevel = obj.modifiers.new("Machined Armour Edge Bevel", "BEVEL")
        bevel.width = max(0.006, min(dimensions) * 0.045)
        bevel.segments = 2
        bevel.limit_method = "ANGLE"
    for polygon in obj.data.polygons:
        polygon.use_smooth = shape == "sphere"
    group = obj.vertex_groups.new(name=bone_name)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new("Nova Armature", "ARMATURE")
    modifier.object = rig
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    return obj


def make_character(rig):
    bronze = material("Aged bronze", (0.48, 0.25, 0.09), 0.72, 0.32)
    bright_gold = material("Gold trim", (0.82, 0.58, 0.20), 0.78, 0.25)
    steel = material("Forged steel", (0.48, 0.58, 0.66), 0.82, 0.24)
    dark_steel = material("Dark steel", (0.075, 0.095, 0.12), 0.68, 0.38)
    leather = material("Ox-blood leather", (0.22, 0.045, 0.035), 0.0, 0.86)
    skin = material("Warm skin", (0.42, 0.22, 0.14), 0.0, 0.78)
    cloth = material("War mantle", (0.12, 0.025, 0.035), 0.0, 0.92)
    bone = material("Ivory inlay", (0.72, 0.63, 0.43), 0.18, 0.62)
    dark_leather = material("Dark harness leather", (0.065, 0.035, 0.025), 0.02, 0.9)
    eye_material = material("Warm amber eyes", (0.42, 0.20, 0.055), 0.12, 0.38)
    cloth_trim = material("Crimson cloth trim", (0.28, 0.035, 0.025), 0.0, 0.9)

    parts = [
        ("pelvis", "Armoured cuirass", (0, 0, 1.48), (0.62, 0.38, 0.68), leather, "sphere"),
        ("chest", "Breastplate", (0, -0.205, 1.68), (0.68, 0.16, 0.48), bronze, "cube"),
        ("pelvis", "Waist fauld", (0, -0.02, 1.12), (0.62, 0.42, 0.22), dark_steel, "cube"),
        ("pelvis", "Gold belt", (0, -0.235, 1.19), (0.64, 0.055, 0.10), bright_gold, "cube"),
        ("head", "Face", (0, 0, 2.24), (0.34, 0.30, 0.43), skin, "sphere"),
        ("head", "Closed war helm", (0, 0.01, 2.42), (0.39, 0.36, 0.30), bronze, "ico"),
        ("head", "Nasal guard", (0, -0.19, 2.25), (0.09, 0.10, 0.32), steel, "cube"),
        ("chest", "Back mantle", (0, 0.22, 1.34), (0.52, 0.10, 0.92), cloth, "cube"),
        ("chest", "Chest sigil", (0, -0.30, 1.65), (0.12, 0.035, 0.25), bright_gold, "ico"),
    ]
    for side, suffix in [(-1, ".L"), (1, ".R")]:
        parts.extend([
            ("shoulder" + suffix, "Shoulder pauldron" + suffix, (side * 0.49, 0, 1.82), (0.38, 0.40, 0.28), bronze, "ico"),
            ("upper_arm" + suffix, "Upper arm" + suffix, (side * 0.57, 0, 1.62), (0.23, 0.25, 0.40), leather, "sphere"),
            ("forearm" + suffix, "Armoured vambrace" + suffix, (side * 0.75, -0.01, 1.34), (0.22, 0.25, 0.39), steel, "ico"),
            ("hand" + suffix, "Gauntlet" + suffix, (side * 0.84, -0.02, 1.13), (0.19, 0.20, 0.19), dark_steel, "sphere"),
            ("thigh" + suffix, "Thigh armour" + suffix, (side * 0.20, 0, 0.78), (0.29, 0.34, 0.48), leather, "sphere"),
            ("shin" + suffix, "Greave" + suffix, (side * 0.20, -0.08, 0.39), (0.30, 0.36, 0.39), steel, "cube"),
            ("foot" + suffix, "War boot" + suffix, (side * 0.20, -0.12, 0.12), (0.34, 0.50, 0.20), dark_steel, "cube"),
        ])
    # Layered, bevelled armour plates, facial features, straps and equipment details.
    parts.extend([
        ("chest", "Cuirass Upper Gold Rim", (0.0, -0.292, 1.91), (0.68, 0.055, 0.065), bright_gold, "cube"),
        ("chest", "Cuirass Central Ridge", (0.0, -0.302, 1.68), (0.055, 0.045, 0.38), steel, "cube"),
        ("chest", "Left Rib Plate", (-0.22, -0.292, 1.49), (0.19, 0.045, 0.15), dark_steel, "cube"),
        ("chest", "Right Rib Plate", (0.22, -0.292, 1.49), (0.19, 0.045, 0.15), dark_steel, "cube"),
        ("spine", "Upper Back Harness", (0.0, 0.285, 1.72), (0.12, 0.045, 0.44), dark_leather, "cube"),
        ("pelvis", "Left Fauld Plate", (-0.22, -0.255, 1.02), (0.19, 0.07, 0.34), bronze, "cube"),
        ("pelvis", "Right Fauld Plate", (0.22, -0.255, 1.02), (0.19, 0.07, 0.34), bronze, "cube"),
        ("pelvis", "Front Belt Pouch", (0.36, -0.275, 1.12), (0.16, 0.11, 0.17), dark_leather, "cube"),
        ("pelvis", "Side Belt Pouch", (-0.36, -0.245, 1.12), (0.16, 0.13, 0.18), dark_leather, "cube"),
        ("pelvis", "Crimson Tasset Edge", (0.0, -0.285, 0.83), (0.46, 0.035, 0.055), cloth_trim, "cube"),
        ("head", "Left Eye", (-0.078, -0.151, 2.30), (0.046, 0.035, 0.028), eye_material, "sphere"),
        ("head", "Right Eye", (0.078, -0.151, 2.30), (0.046, 0.035, 0.028), eye_material, "sphere"),
        ("head", "Left Brow Guard", (-0.08, -0.171, 2.355), (0.105, 0.035, 0.035), dark_steel, "cube"),
        ("head", "Right Brow Guard", (0.08, -0.171, 2.355), (0.105, 0.035, 0.035), dark_steel, "cube"),
        ("head", "Nasal Bridge Inlay", (0.0, -0.177, 2.23), (0.055, 0.035, 0.19), bright_gold, "cube"),
        ("head", "Left Helmet Rivet", (-0.17, -0.19, 2.44), (0.038, 0.025, 0.038), bone, "sphere"),
        ("head", "Right Helmet Rivet", (0.17, -0.19, 2.44), (0.038, 0.025, 0.038), bone, "sphere"),
        ("head", "Left Cheek Guard", (-0.18, -0.015, 2.18), (0.10, 0.22, 0.22), bronze, "cube"),
        ("head", "Right Cheek Guard", (0.18, -0.015, 2.18), (0.10, 0.22, 0.22), bronze, "cube"),
        ("hand.R", "Sword Blade Fuller", (0.91, -0.112, 0.60), (0.026, 0.018, 0.67), bright_gold, "cube"),
        ("hand.R", "Sword Pommel Inlay", (0.88, -0.095, 1.20), (0.065, 0.025, 0.065), bone, "sphere"),
        ("hand.L", "Shield Boss Inlay", (-0.94, -0.195, 1.13), (0.09, 0.035, 0.09), bone, "sphere"),
    ])
    for side, suffix in [(-1, ".L"), (1, ".R")]:
        parts.extend([
            ("shoulder" + suffix, "Pauldron Gold Rim" + suffix, (side * 0.49, -0.205, 1.85), (0.31, 0.055, 0.055), bright_gold, "cube"),
            ("upper_arm" + suffix, "Upper Arm Harness" + suffix, (side * 0.58, -0.12, 1.62), (0.22, 0.045, 0.075), dark_leather, "cube"),
            ("forearm" + suffix, "Vambrace Upper Rim" + suffix, (side * 0.75, -0.17, 1.50), (0.22, 0.045, 0.045), bright_gold, "cube"),
            ("forearm" + suffix, "Vambrace Lower Rim" + suffix, (side * 0.78, -0.17, 1.24), (0.21, 0.045, 0.045), bright_gold, "cube"),
            ("thigh" + suffix, "Thigh Front Plate" + suffix, (side * 0.20, -0.19, 0.79), (0.22, 0.065, 0.28), bronze, "cube"),
            ("shin" + suffix, "Greave Centre Ridge" + suffix, (side * 0.20, -0.275, 0.38), (0.045, 0.035, 0.27), bright_gold, "cube"),
            ("foot" + suffix, "Boot Toe Cap" + suffix, (side * 0.20, -0.31, 0.12), (0.29, 0.055, 0.09), steel, "cube"),
        ])

    for bone, name, loc, dims, mat, shape in parts:
        add_part(rig, bone, name, loc, dims, mat, shape)

    # A distinctive hand-held sword and shield are skinned to the hands.
    add_part(rig, "hand.R", "Nova greatsword blade", (0.91, -0.04, 0.60), (0.11, 0.13, 0.86), steel, "cube")
    add_part(rig, "hand.R", "Nova greatsword crossguard", (0.90, -0.04, 1.03), (0.38, 0.10, 0.10), bright_gold, "cube")
    add_part(rig, "hand.R", "Nova greatsword grip", (0.88, -0.04, 1.17), (0.09, 0.10, 0.22), leather, "cube")
    add_part(rig, "hand.L", "Round shield", (-0.94, -0.04, 1.13), (0.48, 0.16, 0.58), dark_steel, "ico")
    add_part(rig, "hand.L", "Shield boss", (-0.94, -0.14, 1.13), (0.18, 0.08, 0.18), bright_gold, "ico")


def make_animations(rig, bone_names):
    rig.animation_data_create()
    animations = {
        "Idle": [
            (1, {}),
            (16, {"chest": (0, 0, 0.025), "head": (0, 0, -0.02)}),
            (32, {}),
        ],
        "Walk": [
            (1, {"thigh.L": (0.34, 0, 0), "thigh.R": (-0.34, 0, 0), "upper_arm.L": (-0.22, 0, 0), "upper_arm.R": (0.22, 0, 0)}),
            (9, {"thigh.L": (-0.34, 0, 0), "thigh.R": (0.34, 0, 0), "upper_arm.L": (0.22, 0, 0), "upper_arm.R": (-0.22, 0, 0)}),
            (17, {"thigh.L": (0.34, 0, 0), "thigh.R": (-0.34, 0, 0), "upper_arm.L": (-0.22, 0, 0), "upper_arm.R": (0.22, 0, 0)}),
        ],
        "Run": [
            (1, {"thigh.L": (0.72, 0, 0), "thigh.R": (-0.72, 0, 0), "upper_arm.L": (-0.55, 0, 0), "upper_arm.R": (0.55, 0, 0)}),
            (7, {"thigh.L": (-0.72, 0, 0), "thigh.R": (0.72, 0, 0), "upper_arm.L": (0.55, 0, 0), "upper_arm.R": (-0.55, 0, 0)}),
            (13, {"thigh.L": (0.72, 0, 0), "thigh.R": (-0.72, 0, 0), "upper_arm.L": (-0.55, 0, 0), "upper_arm.R": (0.55, 0, 0)}),
        ],
        "LightAttack": [
            (1, {"chest": (0, 0.0, -0.18), "upper_arm.R": (0.15, 0, -0.35)}),
            (6, {"chest": (0, 0.0, 0.28), "upper_arm.R": (-0.45, 0, 1.10), "forearm.R": (-0.25, 0, 0.45)}),
            (12, {}),
        ],
        "HeavyAttack": [
            (1, {"chest": (0, 0, -0.38), "upper_arm.R": (0.4, 0, -0.9)}),
            (8, {"chest": (0, 0, 0.42), "upper_arm.R": (-0.9, 0, 1.3), "forearm.R": (-0.55, 0, 0.3)}),
            (18, {}),
        ],
        "Dodge": [
            (1, {"pelvis": (0.35, 0, 0), "spine": (-0.35, 0, 0)}),
            (7, {"pelvis": (-0.25, 0, 0), "spine": (0.25, 0, 0)}),
            (13, {}),
        ],
        "Block": [
            (1, {"upper_arm.L": (-0.75, 0, -0.35), "forearm.L": (-0.55, 0, 0)}),
            (12, {"upper_arm.L": (-0.75, 0, -0.35), "forearm.L": (-0.55, 0, 0)}),
        ],
        "Parry": [
            (1, {"upper_arm.L": (-0.9, 0, -0.55)}),
            (6, {"upper_arm.L": (-1.2, 0, -0.75), "chest": (0, 0, 0.12)}),
            (12, {}),
        ],
        "HitReact": [
            (1, {"chest": (0.0, 0.0, -0.3), "head": (0.25, 0, 0)}),
            (8, {"chest": (0.0, 0.0, 0.12)}),
            (14, {}),
        ],
        "Death": [
            (1, {}),
            (16, {"pelvis": (0.85, 0, 0), "spine": (0.5, 0, 0), "head": (0.25, 0, 0)}),
            (30, {"pelvis": (1.25, 0, 0), "spine": (0.85, 0, 0), "head": (0.4, 0, 0)}),
        ],
    }
    for name, keys in animations.items():
        action = bpy.data.actions.new(name)
        rig.animation_data.action = action
        for frame, overrides in keys:
            bpy.context.scene.frame_set(frame)
            for bone_name in bone_names:
                pose = rig.pose.bones.get(bone_name)
                if pose is None:
                    continue
                pose.rotation_mode = "XYZ"
                pose.rotation_euler = overrides.get(bone_name, (0.0, 0.0, 0.0))
                pose.keyframe_insert(data_path="rotation_euler", frame=frame, group=bone_name)
        track = rig.animation_data.nla_tracks.new()
        track.name = name
        strip = track.strips.new(name, 1, action)
        strip.name = name
        rig.animation_data.action = None
    rig.animation_data.action = None
    rig.animation_data.use_nla = True


def main():
    options = arguments()
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    rig, bone_names = make_rig()
    make_character(rig)
    make_animations(rig, bone_names)
    bpy.context.scene.frame_end = 32
    bpy.context.view_layer.objects.active = rig
    rig.select_set(True)
    output = os.path.abspath(options.output)
    os.makedirs(os.path.dirname(output), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=output,
        export_format="GLB",
        export_animations=True,
        export_nla_strips=True,
        export_skins=True,
        export_apply=True,
        export_draco_mesh_compression_enable=False,
    )
    if not os.path.isfile(output) or os.path.getsize(output) < 10000:
        raise RuntimeError("Nova hero GLB export is missing or unexpectedly small")
    print("NOVA_HERO_EXPORT_OK", output, os.path.getsize(output))


if __name__ == "__main__":
    main()
