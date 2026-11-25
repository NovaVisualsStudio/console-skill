#!/usr/bin/env python3
"""Regression tests for the Nova GLB optimizer's facial morph handling."""
import importlib.util
import struct
import tempfile
import unittest
from pathlib import Path


GAME_ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = GAME_ROOT / "tools" / "blender" / "optimize_mocap_glb.py"
SPEC = importlib.util.spec_from_file_location("optimize_mocap_glb", MODULE_PATH)
optimizer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(optimizer)


def make_fixture(path):
    binary = bytearray()
    views = []
    accessors = []

    def add_accessor(data, component_type, count, accessor_type):
        while len(binary) % 4:
            binary.append(0)
        view_id = len(views)
        views.append({"buffer": 0, "byteOffset": len(binary), "byteLength": len(data)})
        accessor_id = len(accessors)
        accessors.append({
            "bufferView": view_id,
            "componentType": component_type,
            "count": count,
            "type": accessor_type,
        })
        binary.extend(data)
        return accessor_id

    position_a = add_accessor(bytes(12), 5126, 1, "VEC3")
    indices_a = add_accessor(bytes(2), 5123, 1, "SCALAR")
    position_b = add_accessor(bytes(12), 5126, 1, "VEC3")
    indices_b = add_accessor(bytes(2), 5123, 1, "SCALAR")
    target_position = add_accessor(bytes(12), 5126, 1, "VEC3")
    inverse_bind = add_accessor(bytes(64), 5126, 1, "MAT4")
    animation_input = add_accessor(struct.pack("<f", 0.0), 5126, 1, "SCALAR")
    animation_output = add_accessor(struct.pack("<f", 0.0), 5126, 1, "SCALAR")

    document = {
        "asset": {"version": "2.0", "generator": "nova-mocap-regression-test"},
        "buffers": [{"byteLength": len(binary)}],
        "bufferViews": views,
        "accessors": accessors,
        "meshes": [{
            "weights": [0.0],
            "extras": {"targetNames": ["face_smile"]},
            "primitives": [
                {"attributes": {"POSITION": position_a}, "indices": indices_a},
                {
                    "attributes": {"POSITION": position_b},
                    "indices": indices_b,
                    "targets": [{"POSITION": target_position}],
                },
            ],
        }],
        "nodes": [{"mesh": 0, "weights": [0.0]}],
        "skins": [{"joints": [0], "inverseBindMatrices": inverse_bind}],
        "animations": [{
            "samplers": [{"input": animation_input, "output": animation_output}],
            "channels": [{
                "sampler": 0,
                "target": {"node": 0, "path": "weights"},
            }],
        }],
        "scene": 0,
        "scenes": [{"nodes": [0]}],
    }
    optimizer.write_glb(document, bytes(binary), path)


class MocapOptimizerMorphTests(unittest.TestCase):
    def test_face_preserved_mode_pads_targetless_primitives_and_keeps_weight_tracks(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "source.glb"
            output = Path(tmp) / "face-preserved.glb"
            make_fixture(source)
            document, binary = optimizer.read_glb(source)
            input_targets = optimizer.count_morph_targets(document)
            input_weight_channels = optimizer.count_weight_channels(document)
            binary, padded_sets = optimizer.pad_morph_targets(document, binary)
            self.assertEqual(padded_sets, 1)
            self.assertEqual(
                [len(p.get("targets", [])) for p in document["meshes"][0]["primitives"]],
                [1, 1],
            )
            binary = optimizer.repack(document, binary)
            optimizer.write_glb(document, binary, output)
            result, result_binary = optimizer.read_glb(output)

            self.assertEqual(input_targets, 1)
            self.assertEqual(input_weight_channels, 1)
            self.assertEqual(optimizer.count_morph_targets(result), input_targets)
            self.assertEqual(optimizer.count_weight_channels(result), input_weight_channels)
            primitive = result["meshes"][0]["primitives"][0]
            self.assertEqual(len(primitive["targets"]), 1)
            accessor_id = primitive["targets"][0]["POSITION"]
            accessor = result["accessors"][accessor_id]
            view = result["bufferViews"][accessor["bufferView"]]
            start = view.get("byteOffset", 0)
            self.assertEqual(result_binary[start:start + view["byteLength"]], bytes(view["byteLength"]))
            for target_primitive in result["meshes"][0]["primitives"]:
                for target in target_primitive["targets"]:
                    for target_accessor in target.values():
                        self.assertGreaterEqual(target_accessor, 0)
                        self.assertLess(target_accessor, len(result["accessors"]))
            self.assertEqual(result["animations"][0]["channels"][0]["target"]["path"], "weights")
            self.assertIn("weights", result["meshes"][0])
            self.assertIn("weights", result["nodes"][0])

    def test_android_mode_removes_targets_and_weight_channels_cleanly(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "source.glb"
            output = Path(tmp) / "android.glb"
            make_fixture(source)
            document, binary = optimizer.read_glb(source)
            removed_targets, removed_channels = optimizer.remove_morph_targets(document)
            binary = optimizer.repack(document, binary)
            optimizer.write_glb(document, binary, output)
            result, _ = optimizer.read_glb(output)

            self.assertEqual((removed_targets, removed_channels), (1, 1))
            self.assertEqual(optimizer.count_morph_targets(result), 0)
            self.assertEqual(optimizer.count_weight_channels(result), 0)
            self.assertNotIn("weights", result["meshes"][0])
            self.assertNotIn("weights", result["nodes"][0])
            self.assertEqual(result["animations"][0]["channels"], [])


if __name__ == "__main__":
    unittest.main()
