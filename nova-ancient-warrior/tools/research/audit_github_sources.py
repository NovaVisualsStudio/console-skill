#!/usr/bin/env python3
"""Check GitHub metadata for the external game-development sources.

This tool deliberately does not clone repositories, download source files,
execute third-party code, or approve license compatibility. It only reports
repository metadata and default-branch revisions for human review.
"""
import argparse
import datetime
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any, Dict, List, Optional

CATALOG_PATH = Path(__file__).with_name("source_catalog.json")
API_ROOT = "https://api.github.com"


class AuditError(Exception):
    """Raised when GitHub metadata cannot be retrieved or parsed."""


def load_catalog(path: Path = CATALOG_PATH) -> Dict[str, Any]:
    try:
        with path.open("r", encoding="utf-8") as handle:
            catalog = json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        raise AuditError("Cannot read source catalog: %s" % exc)
    sources = catalog.get("sources")
    if not isinstance(sources, list) or not sources:
        raise AuditError("Catalog must contain a non-empty sources array")
    seen = set()
    for source in sources:
        if not isinstance(source, dict):
            raise AuditError("Each source must be a JSON object")
        for key in ("id", "repository", "branch", "reviewed_commit", "reuse_policy"):
            if not source.get(key):
                raise AuditError("Source is missing required field: %s" % key)
        if source["id"] in seen:
            raise AuditError("Duplicate source id: %s" % source["id"])
        seen.add(source["id"])
        if len(source["reviewed_commit"]) != 40:
            raise AuditError("Expected a full 40-character reviewed commit for %s" % source["id"])
    return catalog


def github_get(url: str, timeout: int) -> Dict[str, Any]:
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "Nova-Ancient-Warrior-Source-Audit/1.0",
        "X-GitHub-Api-Version": "2022-11-28",
    }
    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = "Bearer " + token
    request = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")[:500]
        raise AuditError("GitHub API HTTP %s for %s: %s" % (exc.code, url, detail))
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        raise AuditError("GitHub API request failed for %s: %s" % (url, exc))
    try:
        data = json.loads(payload)
    except json.JSONDecodeError as exc:
        raise AuditError("GitHub API returned invalid JSON for %s: %s" % (url, exc))
    if not isinstance(data, dict):
        raise AuditError("GitHub API returned an unexpected response for %s" % url)
    return data


def audit_source(source: Dict[str, Any], timeout: int) -> Dict[str, Any]:
    repo_name = source["repository"]
    repo_url = API_ROOT + "/repos/" + repo_name
    report: Dict[str, Any] = {
        "id": source["id"],
        "repository": repo_name,
        "url": source.get("url"),
        "reviewed_commit": source["reviewed_commit"],
        "reuse_policy": source["reuse_policy"],
        "priority": source.get("priority", "unspecified"),
        "errors": [],
        "warnings": [],
    }
    try:
        repository = github_get(repo_url, timeout)
        default_branch = repository.get("default_branch") or source["branch"]
        branch_url = repo_url + "/branches/" + urllib.parse.quote(default_branch, safe="")
        branch_data = github_get(branch_url, timeout)
        current_commit = (branch_data.get("commit") or {}).get("sha")
        if not current_commit:
            raise AuditError("Default branch response did not include a commit SHA")
        commit_meta = (branch_data.get("commit") or {}).get("commit") or {}
        license_data = repository.get("license") or {}
        current_license = license_data.get("spdx_id") or "NOASSERTION"

        report.update({
            "available": True,
            "default_branch": default_branch,
            "current_commit": current_commit,
            "current_commit_date": (commit_meta.get("committer") or {}).get("date"),
            "pushed_at": repository.get("pushed_at"),
            "updated_at": repository.get("updated_at"),
            "archived": bool(repository.get("archived")),
            "github_license_spdx": current_license,
            "stars": repository.get("stargazers_count"),
            "forks": repository.get("forks_count"),
            "revision_status": (
                "unchanged_since_review"
                if current_commit == source["reviewed_commit"]
                else "new_revision_requires_review"
            ),
        })
        if report["revision_status"] != "unchanged_since_review":
            report["warnings"].append(
                "The default branch moved since review. Review the new diff before copying code."
            )
        if report["archived"]:
            report["warnings"].append(
                "Repository is archived. Use it as a historical reference and verify dependencies."
            )
        if current_license == "NOASSERTION":
            report["warnings"].append(
                "GitHub reports no recognized top-level license. Do not copy code without permission."
            )
        expected_spdx = source.get("github_license_spdx")
        if expected_spdx and current_license != expected_spdx:
            report["warnings"].append(
                "GitHub license metadata differs from the reviewed catalog entry."
            )
        report["manual_license_review"] = {
            "code_license": source.get("code_license"),
            "assets_license": source.get("assets_license"),
            "reuse_policy": source["reuse_policy"],
        }
    except AuditError as exc:
        report["available"] = False
        report["errors"].append(str(exc))
    return report


def main(argv: Optional[List[str]] = None) -> int:
    parser = argparse.ArgumentParser(
        description="Audit GitHub metadata for Nova's external game-development sources."
    )
    parser.add_argument(
        "--output",
        help="Optional path to write the JSON report.",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=20,
        help="HTTP timeout in seconds for each GitHub API request (default: 20).",
    )
    parser.add_argument(
        "--catalog",
        default=str(CATALOG_PATH),
        help="Path to a source_catalog.json file.",
    )
    args = parser.parse_args(argv)
    if args.timeout < 1:
        parser.error("--timeout must be at least 1")

    try:
        catalog = load_catalog(Path(args.catalog))
    except AuditError as exc:
        print("SOURCE AUDIT ERROR: %s" % exc, file=sys.stderr)
        return 2

    results = [audit_source(source, args.timeout) for source in catalog["sources"]]
    report = {
        "schema_version": 1,
        "generated_at_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "project": catalog.get("project", "Unknown project"),
        "catalog_reviewed_on": catalog.get("reviewed_on"),
        "source_count": len(results),
        "available_count": sum(1 for item in results if item.get("available")),
        "unavailable_count": sum(1 for item in results if not item.get("available")),
        "revision_review_required_count": sum(
            1 for item in results
            if item.get("revision_status") == "new_revision_requires_review"
        ),
        "sources": results,
        "safety_note": (
            "Metadata only. This report does not download or execute code and is not legal advice."
        ),
    }
    rendered = json.dumps(report, indent=2, ensure_ascii=False) + "\n"

    if args.output:
        output_path = Path(args.output)
        try:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_text(rendered, encoding="utf-8")
        except OSError as exc:
            print("SOURCE AUDIT ERROR: cannot write report: %s" % exc, file=sys.stderr)
            return 2

    print(
        "Audited %(source_count)s repositories: %(available_count)s available, "
        "%(unavailable_count)s unavailable, %(revision_review_required_count)s new "
        "revisions requiring review." % report
    )
    if report["unavailable_count"]:
        print(rendered, file=sys.stderr)
        return 1
    if args.output:
        print("Report written to %s" % args.output)
    else:
        print(rendered)
    return 0


if __name__ == "__main__":
    sys.exit(main())
