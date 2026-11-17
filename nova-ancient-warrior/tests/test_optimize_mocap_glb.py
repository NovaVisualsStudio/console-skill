#!/usr/bin/env python3
"""Regression tests for the mobile GLB morph-target optimizer."""
import tempfile
import unittest
from pathlib import Path

from optimize_mocap_glb import read_glb, remove_morph_targets, repack, write_glb


class OptimizeMocapGlbTests(unittest.TestCase):
    def make_fixture(self):
        views = []
        accessors = []
        chunks = []
        offset = 0
        for size in (12, 12, 12, 4, 4, 64):
            chunks.append(bytes([len(chunks) + 1]) * size)
            views.append({"buffer": 0, "byteOffset": offset, "byteLength": size})
            accessors.append({"bufferView": len(accessors), "componentType": 5126, "count": 1, "type": "VEC3"})
            offset += size
        binary = b"".join(chunks)
        document = {
            "asset": {"version": "2.0"},
            "buffers": [{"byteLength": len(binary)}],
            "bufferViews": views,
            "accessors": accessors,
            "meshes": [{"primitives": [{
                "attributes": {"POSITION": 0, "NORMAL": 1},
                "targets": [{"POSITION": 2}],
            }], "weights": [0.0], "extras": {"targetNames": ["smile"]}}],
            "nodes": [{"mesh": 0, "weights": [0.0]}],
            "skins": [{"joints": [0], "inverseBindMatrices": 5}],
            "animations": [{"samplers": [{"input": 3, "output": 4}], "channels": [
                {"sampler": 0, "target": {"node": 0, "path": "weights"}}
            ]}],
        }
        return document, binary

    def test_removes_morph_targets_and_weight_channels(self):
        document, binary = self.make_fixture()
        removed_targets, removed_channels = remove_morph_targets(document)
        self.assertEqual(removed_targets, 1)
        self.assertEqual(removed_channels, 1)
        self.assertNotIn("targets", document["meshes"][0]["primitives"][0])
        self.assertNotIn("weights", document["meshes"][0])
        self.assertNotIn("weights", document["nodes"][0])
        self.assertEqual(document["animations"][0]["channels"], [])
        self.assertEqual(document["animations"][0]["samplers"], [])
        optimized = repack(document, binary)
        self.assertEqual(len(optimized), 88)
        self.assertEqual(document["meshes"][0]["primitives"][0]["attributes"], {"POSITION": 0, "NORMAL": 1})
        self.assertEqual(document["skins"][0]["inverseBindMatrices"], 2)

    def test_glb_round_trip_preserves_skeleton_geometry(self):
        document, binary = self.make_fixture()
        remove_morph_targets(document)
        optimized = repack(document, binary)
        with tempfile.TemporaryDirectory() as temp_dir:
            output = Path(temp_dir) / "optimized.glb"
            write_glb(document, optimized, output)
            loaded_document, loaded_binary = read_glb(output)
        self.assertEqual(loaded_document["asset"]["version"], "2.0")
        self.assertEqual(len(loaded_document["skins"][0]["joints"]), 1)
        self.assertEqual(len(loaded_document["meshes"][0]["primitives"][0]["attributes"]), 2)
        self.assertEqual(len(loaded_binary), 88)


if __name__ == "__main__":
    unittest.main()
