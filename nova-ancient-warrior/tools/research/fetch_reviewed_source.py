#!/usr/bin/env python3
"""Fetch explicitly selected, MIT-licensed source files into a review cache.

The tool only permits exact candidate paths recorded in source_catalog.json.
It pins every request to the reviewed commit, stores the upstream license and
provenance, and never imports or executes retrieved source code.
"""
import argparse
import datetime
import hashlib
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Dict, List, Optional

CATALOG_PATH = Path(__file__).with_name("source_catalog.json")
DEFAULT_OUTPUT = Path("docs/research-source-cache")
MAX_FILE_BYTES = 2 * 1024 * 1024
APPROVED_STATUS = "approved_for_selective_code_review"


class FetchSourceError(Exception):
    """Raised when a requested source file cannot be safely retrieved."""


def load_catalog(path: Path = CATALOG_PATH) -> Dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8") as handle:
            catalog = json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        raise FetchSourceError("Cannot read source catalog: %s" % exc)
    if not isinstance(catalog.get("sources"), list):
        raise FetchSourceError("Catalog has no sources array")
    return catalog


def select_source(catalog: Dict[str, Any], source_id: str) -> Dict[str, Any]:
    for source in catalog["sources"]:
        if source.get("id") == source_id:
            if source.get("status") != APPROVED_STATUS:
                raise FetchSourceError(
                    "Source %s is not approved for code retrieval (status=%s)"
                    % (source_id, source.get("status"))
                )
            if source.get("code_license") != "MIT":
                raise FetchSourceError(
                    "Only MIT-licensed code sources are enabled in this tool"
                )
            if not source.get("code_license_file"):
                raise FetchSourceError("No code license file is recorded for this source")
            return source
    raise FetchSourceError("Unknown source id: %s" % source_id)


def validate_candidate_paths(source: Dict[str, Any], requested: List[str]) -> List[str]:
    allowed = set(source.get("candidate_paths", []))
    if not requested:
        raise FetchSourceError("Select at least one exact candidate file with --file")
    normalized = []
    for item in requested:
        path = Path(item)
        if path.is_absolute() or not item or ".." in path.parts:
            raise FetchSourceError("Unsafe relative path: %s" % item)
        if item not in allowed:
            raise FetchSourceError(
                "File is not in the reviewed allowlist for %s: %s"
                % (source["id"], item)
            )
        if item not in normalized:
            normalized.append(item)
    return normalized


def fetch_text_file(repository: str, commit: str, relative_path: str, timeout: int) -> str:
    encoded_path = urllib.parse.quote(relative_path, safe="/")
    url = "https://raw.githubusercontent.com/%s/%s/%s" % (
        repository,
        commit,
        encoded_path,
    )
    headers = {"User-Agent": "Nova-Reviewed-Source-Fetcher/1.0"}
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = "Bearer " + token
    request = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = response.read(MAX_FILE_BYTES + 1)
    except urllib.error.HTTPError as exc:
        raise FetchSourceError("HTTP %s while fetching %s" % (exc.code, relative_path))
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        raise FetchSourceError("Could not fetch %s: %s" % (relative_path, exc))
    if len(payload) > MAX_FILE_BYTES:
        raise FetchSourceError("File exceeds %s bytes: %s" % (MAX_FILE_BYTES, relative_path))
    try:
        return payload.decode("utf-8")
    except UnicodeDecodeError:
        raise FetchSourceError("Only UTF-8 text files can be staged: %s" % relative_path)


def safe_write(root: Path, relative_path: str, content: str) -> Path:
    relative = Path(relative_path)
    if relative.is_absolute() or ".." in relative.parts:
        raise FetchSourceError("Unsafe output path: %s" % relative_path)
    destination = root / relative
    destination.parent.mkdir(parents=True, exist_ok=True)
    destination.write_text(content, encoding="utf-8")
    return destination


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Stage reviewed MIT source files for inspection. No code is executed."
    )
    parser.add_argument("--source", required=True, help="Source id from source_catalog.json")
    parser.add_argument(
        "--file",
        action="append",
        required=True,
        help="Exact candidate path from the catalog. Repeat for multiple files.",
    )
    parser.add_argument(
        "--accept-mit",
        action="store_true",
        help="Confirm that the MIT notice and attribution will be retained.",
    )
    parser.add_argument(
        "--output-dir",
        default=str(DEFAULT_OUTPUT),
        help="Review-cache root (default: docs/research-source-cache).",
    )
    parser.add_argument("--timeout", type=int, default=20)
    parser.add_argument("--force", action="store_true", help="Allow replacing an existing cache.")
    args = parser.parse_args(argv)
    if not args.accept_mit:
        parser.error("pass --accept-mit after reviewing the source's MIT license")
    if args.timeout < 1:
        parser.error("--timeout must be at least 1")

    try:
        catalog = load_catalog()
        source = select_source(catalog, args.source)
        selected = validate_candidate_paths(source, args.file)
        output_root = Path(args.output_dir) / source["id"]
        if output_root.exists() and any(output_root.iterdir()) and not args.force:
            raise FetchSourceError(
                "Review cache already exists: %s (use --force to replace it)" % output_root
            )

        commit = source["reviewed_commit"]
        staged = []
        for relative_path in selected:
            content = fetch_text_file(source["repository"], commit, relative_path, args.timeout)
            target = safe_write(output_root, relative_path, content)
            staged.append({
                "upstream_path": relative_path,
                "staged_path": str(target),
                "sha256": hashlib.sha256(content.encode("utf-8")).hexdigest(),
                "url": "https://github.com/%s/blob/%s/%s" % (
                    source["repository"],
                    commit,
                    urllib.parse.quote(relative_path, safe="/"),
                ),
            })

        license_path = source["code_license_file"]
        license_text = fetch_text_file(source["repository"], commit, license_path, args.timeout)
        license_target = safe_write(output_root, "UPSTREAM_LICENSE/" + Path(license_path).name, license_text)
        manifest = {
            "source_id": source["id"],
            "repository": source["repository"],
            "reviewed_commit": commit,
            "code_license": source["code_license"],
            "license_file": license_path,
            "license_copy": str(license_target),
            "staged_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            "files": staged,
            "safety_note": (
                "Review cache only. Files were not imported into the game, executed, or tested. "
                "Keep the upstream MIT notice and attribution."
            ),
        }
        safe_write(
            output_root,
            "SOURCE_PROVENANCE.json",
            json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        )
    except FetchSourceError as exc:
        print("SOURCE FETCH ERROR: %s" % exc, file=sys.stderr)
        return 1

    print("Staged %s reviewed files from %s at %s" % (
        len(staged), source["repository"], commit
    ))
    print("Review cache: %s" % output_root)
    print("No code was imported or executed. Review and adapt before production use.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
