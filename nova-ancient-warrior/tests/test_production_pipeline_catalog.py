import json
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "tools" / "research" / "production_pipeline_catalog.json"


class ProductionPipelineCatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
        cls.items = {item["id"]: item for item in cls.catalog["candidates"]}

    def test_candidate_ids_are_unique_and_expected(self):
        self.assertEqual(len(self.items), len(self.catalog["candidates"]))
        self.assertEqual(set(self.items), {
            "video-into-blender-model",
            "godot-learning-cc0",
            "open-mocap-blender",
        })

    def test_v2bm_is_not_promoted_to_a_runtime_dependency(self):
        item = self.items["video-into-blender-model"]
        self.assertEqual(item["code_license"], "Apache-2.0")
        self.assertEqual(item["status"], "candidate_requires_isolated_validation")
        self.assertTrue(any("immutable upstream commit" in step for step in item["integration_gate"]))
        self.assertTrue(any("actual Nova skeleton" in step for step in item["integration_gate"]))
        self.assertTrue(any("personal video" in note for note in item["safety_notes"]))

    def test_cc0_library_is_limited_to_prototype_evaluation(self):
        item = self.items["godot-learning-cc0"]
        self.assertEqual(item["status"], "approved_for_prototype_evaluation_not_final_art")
        self.assertTrue(any("LICENSE.txt" in step for step in item["integration_gate"]))
        self.assertTrue(any("greybox" in note.lower() for note in item["safety_notes"]))

    def test_incompatible_mocap_tool_is_not_enabled(self):
        item = self.items["open-mocap-blender"]
        self.assertEqual(item["code_license"], "MIT")
        self.assertEqual(item["status"], "not_compatible_with_current_blender_pipeline")
        self.assertTrue(any("Blender 4.2+" in step for step in item["integration_gate"]))


if __name__ == "__main__":
    unittest.main()
