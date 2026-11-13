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
    binary = b"".join(struct.pack("<f", float(i)) for i in range(7))
    document = {
        "asset": {"version": "2.0", "generator": "nova-mocap-regression-test"},
        "buffers": [{"byteLength": len(binary)}],
        "bufferViews": [
            {"buffer": 0, "byteOffset": i * 4, "byteLength": 4}
            for i in range(7)
        ],
        "accessors": [
            {"bufferView": i, "componentType": 5126, "count": 1, "type": "SCALAR"}
            for i in range(7)
        ],
        "meshes": [{
            "weights": [0.0],
            "extras": {"targetNames": ["face_smile"]},
            "primitives": [{
                "attributes": {"POSITION": 0},
                "indices": 1,
                "targets": [{"POSITION": 2, "NORMAL": 3}],
            }],
        }],
        "nodes": [{"mesh": 0, "weights": [0.0]}],
        "skins": [{"joints": [0], "inverseBindMatrices": 4}],
        "animations": [{
            "samplers": [{"input": 5, "output": 6}],
            "channels": [{
                "sampler": 0,
                "target": {"node": 0, "path": "weights"},
            }],
        }],
        "scene": 0,
        "scenes": [{"nodes": [0]}],
    }
    optimizer.write_glb(document, binary, path)


class MocapOptimizerMorphTests(unittest.TestCase):
    def test_face_preserved_mode_keeps_targets_weights_and_remapped_accessors(self):
        with tempfile.TemporaryDirectory() as tmp:
            source = Path(tmp) / "source.glb"
            output = Path(tmp) / "face-preserved.glb"
            make_fixture(source)
            document, binary = optimizer.read_glb(source)
            input_targets = optimizer.count_morph_targets(document)
            input_weight_channels = optimizer.count_weight_channels(document)
            binary = optimizer.repack(document, binary)
            optimizer.write_glb(document, binary, output)
            result, _ = optimizer.read_glb(output)

            self.assertEqual(input_targets, 1)
            self.assertEqual(input_weight_channels, 1)
            self.assertEqual(optimizer.count_morph_targets(result), input_targets)
            self.assertEqual(optimizer.count_weight_channels(result), input_weight_channels)
            primitive = result["meshes"][0]["primitives"][0]
            self.assertEqual(len(primitive["targets"]), 1)
            for accessor_id in primitive["targets"][0].values():
                self.assertGreaterEqual(accessor_id, 0)
                self.assertLess(accessor_id, len(result["accessors"]))
            weight_channel = result["animations"][0]["channels"][0]
            self.assertEqual(weight_channel["target"]["path"], "weights")
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
