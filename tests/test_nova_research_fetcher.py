import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RESEARCH_TOOLS = ROOT / "nova-ancient-warrior" / "tools" / "research"
sys.path.insert(0, str(RESEARCH_TOOLS))

import fetch_reviewed_source as fetcher


class ReviewedSourceFetcherTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = fetcher.load_catalog()

    def test_only_mit_reviewed_sources_can_be_fetched(self):
        adventure = fetcher.select_source(self.catalog, "adventure-mode-godot")
        goat = fetcher.select_source(self.catalog, "goat-godot")
        self.assertEqual(adventure["code_license"], "MIT")
        self.assertEqual(goat["code_license"], "MIT")

    def test_gpl_and_unlicensed_projects_are_blocked(self):
        for source_id in ("fly-dangerous", "clutch-unity-racing", "lee-reilly-games-index"):
            with self.subTest(source_id=source_id):
                with self.assertRaises(fetcher.FetchSourceError):
                    fetcher.select_source(self.catalog, source_id)

    def test_only_exact_allowlisted_files_are_accepted(self):
        source = fetcher.select_source(self.catalog, "adventure-mode-godot")
        requested = fetcher.validate_candidate_paths(
            source, ["Modular Mobility/mvpk_climb.gd", "scripts/camera_control.gd"]
        )
        self.assertEqual(len(requested), 2)
        with self.assertRaises(fetcher.FetchSourceError):
            fetcher.validate_candidate_paths(source, ["../project.godot"])
        with self.assertRaises(fetcher.FetchSourceError):
            fetcher.validate_candidate_paths(source, ["scripts/not-reviewed.gd"])

    def test_output_paths_cannot_escape_the_review_cache(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            with self.assertRaises(fetcher.FetchSourceError):
                fetcher.safe_write(root, "../escaped.txt", "not allowed")


if __name__ == "__main__":
    unittest.main()
