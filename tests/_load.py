"""Load a script from a skill folder (the folder names have hyphens)."""

import importlib.util
import os
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load(folder, name):
    path = os.path.join(ROOT, folder, name + ".py")
    spec = importlib.util.spec_from_file_location(
        "console_" + folder.replace("-", "_") + "_" + name, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def tracked_paths():
    """Return repository-relative Git-index paths, or source-archive files without Git."""
    try:
        raw = subprocess.check_output(
            ["git", "-C", ROOT, "ls-files", "-z"],
            stderr=subprocess.DEVNULL,
        )
    except (OSError, subprocess.CalledProcessError):
        paths = []
        for base, dirs, files in os.walk(ROOT):
            dirs[:] = [d for d in dirs if d not in (".git", "__pycache__")]
            for filename in files:
                paths.append(os.path.relpath(os.path.join(base, filename), ROOT))
        return sorted(paths)
    return sorted(os.fsdecode(path) for path in raw.split(b"\0") if path)


def tracked_files_in(directory, recursive=True):
    """Return absolute paths indexed by Git under directory, never workspace-only files."""
    relative = os.path.relpath(directory, ROOT)
    prefix = "" if relative == "." else relative.replace(os.sep, "/").rstrip("/") + "/"
    result = []
    for path in tracked_paths():
        if not path.startswith(prefix):
            continue
        remainder = path[len(prefix):]
        if not recursive and "/" in remainder:
            continue
        result.append(os.path.join(ROOT, *path.split("/")))
    return sorted(result)
