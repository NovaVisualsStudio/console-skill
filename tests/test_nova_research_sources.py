import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "nova-ancient-warrior" / "tools" / "research" / "source_catalog.json"


class NovaResearchSourceCatalogTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = json.loads(CATALOG.read_text(encoding="utf-8"))
        cls.sources = {item["id"]: item for item in cls.catalog["sources"]}

    def test_all_six_supplied_repositories_are_registered(self):
        self.assertEqual(
            set(self.sources),
            {
                "fly-dangerous",
                "clutch-unity-racing",
                "adventure-mode-godot",
                "goat-godot",
                "lee-reilly-games-index",
                "kavex-gamedev-resources",
            },
        )

    def test_every_source_has_a_full_reviewed_commit(self):
        for source in self.sources.values():
            self.assertRegex(source["reviewed_commit"], re.compile(r"^[0-9a-f]{40}$"))
            self.assertTrue(source["url"].startswith("https://github.com/"))

    def test_code_and_asset_license_scopes_are_separate(self):
        adventure = self.sources["adventure-mode-godot"]
        self.assertEqual(adventure["code_license"], "MIT")
        self.assertEqual(adventure["assets_license"], "CC-BY-4.0")

        goat = self.sources["goat-godot"]
        self.assertEqual(goat["code_license"], "MIT")
        self.assertIn("CC-BY-NC-4.0", goat["assets_license"])

    def test_gpl_code_is_not_approved_for_default_nova_integration(self):
        source = self.sources["fly-dangerous"]
        self.assertEqual(source["code_license"], "GPL-3.0")
        self.assertEqual(source["status"], "reference_only")
        self.assertIn("gpl", source["reuse_policy"])

    def test_unlicensed_clutch_is_permission_required(self):
        source = self.sources["clutch-unity-racing"]
        self.assertEqual(source["code_license"], "NOASSERTION")
        self.assertEqual(source["status"], "permission_required")
        self.assertIn("without_permission", source["reuse_policy"])

    def test_discovery_lists_are_not_treated_as_code_licenses(self):
        for source_id in ("lee-reilly-games-index", "kavex-gamedev-resources"):
            source = self.sources[source_id]
            self.assertEqual(source["status"], "archived_index" if source_id.startswith("lee-") else "discovery_index")
            self.assertTrue(source["reuse_policy"].startswith("discovery_index_only"))

    def test_policy_disables_automatic_code_execution(self):
        policy = self.catalog["policy"]
        self.assertTrue(policy["require_file_level_review"])
        self.assertTrue(policy["require_license_and_provenance"])
        self.assertTrue(policy["prohibit_copy_without_license"])


if __name__ == "__main__":
    unittest.main()
