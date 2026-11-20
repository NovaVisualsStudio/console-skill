#!/usr/bin/env python3
"""Create a licence-aware SHA-256 manifest for a Nova mocap research artifact."""
import argparse
import datetime
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path

PIPELINE_REPO = "https://github.com/s0ck3t/VideoIntoBlenderModel"
PIPELINE_COMMIT = "c1f1fa8f01524d60197c4d65306349e266d339cb"
OUTPUTS = {
    "nova_mocap_candidate.glb": "mobile skeletal-animation candidate",
    "nova_mocap_candidate.optimize.json": "mobile optimization report",
    "nova_mocap_candidate_face_preserved.glb": "face-preserved research candidate",
    "nova_mocap_candidate_face_preserved.optimize.json": "face-preserved optimization report",
    "nova_mocap_candidate.run.json": "capture and retarget report",
}
OPT_FIELDS = (
    "input_bytes", "output_bytes", "saved_bytes", "removed_morph_targets",
    "removed_weight_channels", "morph_target_count", "weight_channel_count",
    "morph_targets_preserved", "bone_count", "animation_count", "animation_channels",
)
CAPTURE_FIELDS = (
    "capture_face", "fps", "n_frames", "framing", "rest_fk_error",
    "rest_skin_error_cm", "twist_events", "quat_sign_flips",
)


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def record(path, role):
    path = Path(path)
    if not path.is_file():
        raise FileNotFoundError("Missing provenance file: %s" % path.name)
    return {"file": path.name, "role": role, "size_bytes": path.stat().st_size, "sha256": sha256(path)}


def read_json(path):
    with Path(path).open("r", encoding="utf-8") as handle:
        value = json.load(handle)
    if not isinstance(value, dict):
        raise ValueError("Expected JSON object: %s" % Path(path).name)
    return value


def versions():
    names = ("v2bm", "numpy", "opencv-python", "mediapipe", "scipy")
    result = {}
    for name in names:
        try:
            result[name] = importlib.metadata.version(name)
        except importlib.metadata.PackageNotFoundError:
            result[name] = None
    return result


def build_manifest(a):
    video, rig = Path(a.video), Path(a.rig)
    pipeline = Path(a.pipeline_root)
    output = Path(a.output_dir)
    license_file, asset_register = pipeline / "LICENSE", pipeline / "assets" / "LICENCES.md"
    if not video.is_file() or not rig.is_file():
        raise FileNotFoundError("Motion-capture input video or rig is missing")
    if not license_file.is_file() or not asset_register.is_file():
        raise FileNotFoundError("Pinned pipeline license evidence is missing")
    files = [record(output / name, role) for name, role in OUTPUTS.items()]
    run = read_json(output / "nova_mocap_candidate.run.json")
    mobile = read_json(output / "nova_mocap_candidate.optimize.json")
    face = read_json(output / "nova_mocap_candidate_face_preserved.optimize.json")
    now = datetime.datetime.now(datetime.timezone.utc).replace(microsecond=0).isoformat()
    video_cleared = a.video_license.strip() == "CC0-1.0"
    rig_cleared = a.rig_license.strip() == "CC0-1.0"
    return {
        "schema_version": 1,
        "project": "Nova Ancient Warrior",
        "generated_at_utc": now,
        "repository": a.repository or None,
        "source_commit": a.source_commit or None,
        "workflow_run_id": a.workflow_run_id or None,
        "pipeline": {
            "name": "VideoIntoBlenderModel", "repository": PIPELINE_REPO,
            "commit": a.pipeline_commit, "code_license": "Apache-2.0",
            "license_file": {"path": "LICENSE", "source_url": "%s/blob/%s/LICENSE" % (PIPELINE_REPO, a.pipeline_commit), "sha256": sha256(license_file)},
            "asset_license_register": {"path": "assets/LICENCES.md", "source_url": "%s/blob/%s/assets/LICENCES.md" % (PIPELINE_REPO, a.pipeline_commit), "sha256": sha256(asset_register)},
            "package_versions": versions(),
        },
        "inputs": {
            "video": {"label": a.video_label, "source_id": a.video_source_id, "creator": a.video_creator or None,
                      "source_url": a.video_source_url or None, "license": a.video_license,
                      "commercial_use_verified": video_cleared, "size_bytes": video.stat().st_size, "sha256": sha256(video)},
            "rig": {"profile": a.rig_profile, "source_url": a.rig_source_url or None, "license": a.rig_license,
                    "commercial_use_verified": rig_cleared, "size_bytes": rig.stat().st_size, "sha256": sha256(rig)},
        },
        "capture": {key: run.get(key) for key in CAPTURE_FIELDS},
        "optimization": {
            "mobile_candidate": {key: mobile.get(key) for key in OPT_FIELDS},
            "face_preserved_candidate": {key: face.get(key) for key in OPT_FIELDS},
        },
        "outputs": files,
        "integration": {"status": "research_candidate_not_integrated", "integrated_into_live_hero": False,
                        "note": "Visual, retargeting and Android performance review is required before production use."},
    }


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--video", required=True)
    p.add_argument("--video-label", required=True)
    p.add_argument("--video-source-id", required=True)
    p.add_argument("--video-license", required=True)
    p.add_argument("--video-source-url", default="")
    p.add_argument("--video-creator", default="")
    p.add_argument("--rig", required=True)
    p.add_argument("--rig-profile", required=True)
    p.add_argument("--rig-license", default="CC0-1.0")
    p.add_argument("--rig-source-url", required=True)
    p.add_argument("--pipeline-root", default=".v2bm")
    p.add_argument("--pipeline-commit", default=PIPELINE_COMMIT)
    p.add_argument("--output-dir", default="nova-ancient-warrior/assets/characters")
    p.add_argument("--repository", default=os.getenv("GITHUB_REPOSITORY", ""))
    p.add_argument("--source-commit", default=os.getenv("GITHUB_SHA", ""))
    p.add_argument("--workflow-run-id", default=os.getenv("GITHUB_RUN_ID", ""))
    a = p.parse_args()
    manifest = build_manifest(a)
    target = Path(a.output_dir) / "nova_mocap_candidate.provenance.json"
    target.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("Wrote mocap provenance manifest: %s" % target)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
