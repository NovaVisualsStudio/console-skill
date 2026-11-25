import hashlib
import json
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace

TOOLS = Path(__file__).resolve().parents[1] / "tools" / "blender"
sys.path.insert(0, str(TOOLS))
from write_mocap_provenance import build_manifest


class MocapProvenanceTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        root = Path(self.tmp.name)
        self.pipeline = root / "pipeline"
        (self.pipeline / "assets").mkdir(parents=True)
        weights = self.pipeline / "weights" / "mediapipe"
        weights.mkdir(parents=True)
        (weights / "pose_landmarker_full.task").write_bytes(b"pose-model-weights")
        (weights / "face_landmarker.task").write_bytes(b"face-model-weights")
        (self.pipeline / "LICENSE").write_text("Apache License Version 2.0\n", encoding="utf-8")
        (self.pipeline / "assets" / "LICENCES.md").write_text("video CC0-1.0; rig CC0-1.0\n", encoding="utf-8")
        self.output = root / "output"
        self.output.mkdir()
        self.video, self.rig = root / "source.mp4", root / "rig.fbx"
        self.video.write_bytes(b"video-bytes")
        self.rig.write_bytes(b"rig-bytes")
        (self.output / "nova_mocap_candidate.glb").write_bytes(b"mobile-glb")
        (self.output / "nova_mocap_candidate.optimize.json").write_text(json.dumps({"bone_count": 61, "morph_target_count": 0}), encoding="utf-8")
        (self.output / "nova_mocap_candidate_face_preserved.glb").write_bytes(b"face-glb")
        (self.output / "nova_mocap_candidate_face_preserved.optimize.json").write_text(json.dumps({"bone_count": 61, "morph_target_count": 52}), encoding="utf-8")
        (self.output / "nova_mocap_candidate.run.json").write_text(json.dumps({"fps": 29.97, "n_frames": 149}), encoding="utf-8")
        self.args = SimpleNamespace(
            video=self.video, video_label="demo", video_source_id="video_kung_fu_haikou",
            video_license="CC0-1.0", video_source_url="https://commons.wikimedia.org/wiki/File:Kung_fu_at_Haikou_People%27s_Park.ogv",
            video_creator="Anna Frodesiak", rig=self.rig, rig_profile="humanoid_articulated",
            rig_license="CC0-1.0", rig_source_url="https://github.com/s0ck3t/VideoIntoBlenderModel/blob/pinned/assets/rigs/humanoid_articulated.fbx",
            pipeline_root=self.pipeline, pipeline_commit="c1f1fa8f01524d60197c4d65306349e266d339cb",
            output_dir=self.output, repository="NovaVisualsStudio/console-skill", source_commit="a" * 40, workflow_run_id="12345",
        )

    def tearDown(self):
        self.tmp.cleanup()

    def test_manifest_records_input_output_and_license_hashes(self):
        data = build_manifest(self.args)
        self.assertEqual(data["inputs"]["video"]["sha256"], hashlib.sha256(b"video-bytes").hexdigest())
        self.assertEqual(data["inputs"]["rig"]["sha256"], hashlib.sha256(b"rig-bytes").hexdigest())
        outputs = {item["file"]: item for item in data["outputs"]}
        self.assertEqual(outputs["nova_mocap_candidate.glb"]["sha256"], hashlib.sha256(b"mobile-glb").hexdigest())
        self.assertEqual(data["pipeline"]["code_license"], "Apache-2.0")
        self.assertEqual(data["pipeline"]["license_file"]["sha256"], hashlib.sha256(b"Apache License Version 2.0\n").hexdigest())
        self.assertEqual(data["pipeline"]["asset_license_register"]["sha256"], hashlib.sha256(b"video CC0-1.0; rig CC0-1.0\n").hexdigest())
        self.assertFalse(data["integration"]["integrated_into_live_hero"])

    def test_manifest_records_model_weight_hashes_and_licenses(self):
        data = build_manifest(self.args)
        weights = {item["path"]: item for item in data["pipeline"]["model_weights"]}
        pose_path = "weights/mediapipe/pose_landmarker_full.task"
        face_path = "weights/mediapipe/face_landmarker.task"
        self.assertEqual(data["schema_version"], 2)
        self.assertEqual(weights[pose_path]["license"], "Apache-2.0")
        self.assertEqual(weights[pose_path]["sha256"], hashlib.sha256(b"pose-model-weights").hexdigest())
        self.assertEqual(weights[face_path]["license"], "Apache-2.0")
        self.assertEqual(weights[face_path]["sha256"], hashlib.sha256(b"face-model-weights").hexdigest())
        self.assertEqual(weights[face_path]["license_evidence"]["path"], "assets/LICENCES.md")
        self.assertEqual(weights[face_path]["license_evidence"]["sha256"], hashlib.sha256(b"video CC0-1.0; rig CC0-1.0\\n").hexdigest())

    def test_missing_model_weight_fails_closed(self):
        (self.pipeline / "weights" / "mediapipe" / "face_landmarker.task").unlink()
        with self.assertRaisesRegex(FileNotFoundError, "Missing provenance model weight"):
            build_manifest(self.args)

    def test_user_video_is_not_marked_commercially_cleared(self):
        self.args.video_license = "user-supplied; confirm performer rights before commercial release"
        self.args.video_source_url = ""
        self.args.video_creator= ""
        self.args.video_source_id = "user_supplied"
        data = build_manifest(self.args)["inputs"]["video"]
        self.assertIsNone(data["source_url"])
        self.assertIsNone(data["creator"])
        self.assertFalse(data["commercial_use_verified"])

    def test_missing_output_fails_closed(self):
        (self.output / "nova_mocap_candidate.glb").unlink()
        with self.assertRaises(FileNotFoundError):
            build_manifest(self.args)


    def test_workflow_records_pull_request_head_not_merge_commit(self):
        workflow_path = Path(__file__).resolve().parents[2] / ".github" / "workflows" / "nova-mocap-character.yml"
        workflow = workflow_path.read_text(encoding="utf-8")
        self.assertIn("SOURCE_COMMIT: ${{ github.event.pull_request.head.sha || github.sha }}", workflow)
        self.assertIn('--source-commit "$SOURCE_COMMIT"', workflow)
        self.assertNotIn('--source-commit "$GITHUB_SHA"', workflow)


if __name__ == "__main__":
    unittest.main()
