import json
import os
import re
import subprocess
import tempfile
import sys
import unittest

from _load import ROOT, tracked_paths, tracked_files_in

# the eleven folders the reel's repo card shows
SKILLS = ["console-reverse", "console-graphics", "console-backend", "console-controller",
          "console-mod", "console-levels", "console-sound", "console-physics", "console-saves",
          "console-anywhere", "console-tester"]
ABOUT = ("11 Claude skills that port PlayStation 2 games you own to PC: reverse engineer the code, "
         "rebuild the graphics and backend, any controller, play it anywhere, then mod it however "
         "you want.")
README_ABOUT = ("11 agent skills for Claude and Codex that port PlayStation 2 games you own to PC: "
                "reverse engineer the code, rebuild the graphics and backend, any controller, play it "
                "anywhere, then mod it however you want.")
# never in this repo: disc images, game binaries, Sony manuals
GAME_EXT = (".iso", ".bin", ".img", ".mdf", ".mds", ".nrg", ".chd", ".cso", ".zso", ".elf",
            ".irx", ".tm2", ".vag", ".ps2", ".mcd", ".psu", ".pdf", ".pnach")
MAX_FILE = 512 * 1024


def frontmatter(path):
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    return (m.group(1) if m else ""), text


def every_file():
    for path in tracked_files_in(ROOT):
        if os.path.isfile(path):
            yield path


def every_text_file():
    for p in every_file():
        if p.endswith((".md", ".py", ".json", ".txt", ".toml", ".cpp", ".h", ".sh", ".csv",
                       ".pnach.example")) or os.path.basename(p) == "LICENSE":
            yield p


def tools(skill):
    return sorted(os.path.basename(path) for path in
                  tracked_files_in(os.path.join(ROOT, skill), recursive=False)
                  if path.endswith(".py") and not os.path.basename(path).startswith("_"))


class Repo(unittest.TestCase):
    def test_eleven_skill_folders_at_the_root(self):
        found = sorted(path[:-len("/SKILL.md")] for path in tracked_paths()
                       if path.endswith("/SKILL.md") and path.count("/") == 1)
        self.assertEqual(found, sorted(SKILLS))

    def test_root_matches_the_reel(self):
        # Check the published Git tree, not arbitrary local workspace files.
        root = set()
        for relpath in tracked_paths():
            top = relpath.split("/", 1)[0]
            if not top.startswith(".git"):
                root.add(top)
        expected_root = [
            ".agents", ".claude-plugin", ".github", "LICENSE", "README.md",
            "docs", "nova-ancient-warrior", "ps2-game", "tests",
        ] + SKILLS
        self.assertEqual(sorted(root), sorted(expected_root))

    def test_frontmatter_name_description_hint(self):
        for s in SKILLS:
            fm, text = frontmatter(os.path.join(ROOT, s, "SKILL.md"))
            self.assertIn("name: %s\n" % s, fm + "\n", s)
            self.assertRegex(fm, r"description: ", s)
            self.assertRegex(fm, r"argument-hint: ", s)
            self.assertGreater(len(fm), 300, "%s description is too thin" % s)
            self.assertIn("# %s" % s, text, s)

    def test_every_path_a_skill_names_exists(self):
        pat = re.compile(r"\$\{CLAUDE_SKILL_DIR\}/([A-Za-z0-9_./-]+)")
        rel = re.compile(r"(?<![\w/.-])((?:reference|templates)/[A-Za-z0-9_./-]+\.[a-z]+)")
        for s in SKILLS:
            _, text = frontmatter(os.path.join(ROOT, s, "SKILL.md"))
            names = set(m.group(1).rstrip(".") for m in pat.finditer(text))
            names |= set(m.group(1).rstrip(".") for m in rel.finditer(text))
            for n in names:
                self.assertTrue(os.path.exists(os.path.join(ROOT, s, n)),
                                "%s/SKILL.md names %s, which does not exist" % (s, n))

    def test_every_reference_file_is_linked(self):
        for s in SKILLS:
            _, text = frontmatter(os.path.join(ROOT, s, "SKILL.md"))
            for sub in ("reference", "templates"):
                d = os.path.join(ROOT, s, sub)
                if not os.path.isdir(d):
                    continue
                for path in tracked_files_in(d, recursive=False):
                    f = os.path.basename(path)
                    self.assertIn("%s/%s" % (sub, f), text,
                                  "%s/%s/%s is never mentioned in SKILL.md" % (s, sub, f))

    def test_every_skill_has_a_tool_and_the_skill_names_it(self):
        for s in SKILLS:
            ts = tools(s)
            self.assertTrue(ts, "%s has no tool" % s)
            _, text = frontmatter(os.path.join(ROOT, s, "SKILL.md"))
            for t in ts:
                self.assertIn(t, text, "%s/SKILL.md never mentions %s" % (s, t))

    def test_every_tool_prints_help(self):
        for s in SKILLS:
            for t in tools(s):
                r = subprocess.run([sys.executable, os.path.join(ROOT, s, t), "--help"],
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30)
                self.assertEqual(r.returncode, 0, "%s/%s --help: %s" % (s, t, r.stderr[-400:]))
                self.assertIn(b"usage", r.stdout.lower(), "%s/%s" % (s, t))

    def test_no_tool_reaches_into_another_skill(self):
        for s in SKILLS:
            for t in tools(s):
                with open(os.path.join(ROOT, s, t), encoding="utf-8") as fh:
                    src = fh.read()
                for other in SKILLS:
                    if other != s:
                        self.assertNotIn(other + "/", src.replace("/" + other + "/", ""),
                                         "%s/%s imports from %s" % (s, t, other))
                self.assertNotRegex(src, r"^\s*(import|from)\s+(numpy|PIL|requests|yaml|toml)\b",
                                    "%s/%s needs a third-party module" % (s, t))

    def test_every_skill_carries_the_guard_rails(self):
        for s in SKILLS:
            _, text = frontmatter(os.path.join(ROOT, s, "SKILL.md"))
            low = text.lower()
            self.assertIn("guard rails", low, s)
            self.assertRegex(low, r"\bown\b", "%s: bring your own game" % s)
            self.assertIn("publish", low, "%s: nothing from the game gets published" % s)

    def test_untracked_workspace_files_are_not_audited(self):
        if not os.path.lexists(os.path.join(ROOT, ".git")):
            self.skipTest("Git index is unavailable in a source archive")
        skill_dir = os.path.join(ROOT, "console-reverse")
        with tempfile.NamedTemporaryFile(prefix=".workspace-noise-", dir=ROOT) as root_noise:
            with tempfile.NamedTemporaryFile(prefix=".workspace-noise-", dir=skill_dir) as skill_noise:
                self.assertNotIn(root_noise.name, tracked_files_in(ROOT))
                self.assertNotIn(skill_noise.name, tracked_files_in(skill_dir))

    def test_no_em_dashes_anywhere(self):
        for p in every_text_file():
            with open(p, encoding="utf-8") as fh:
                self.assertNotIn(chr(0x2014), fh.read(), os.path.relpath(p, ROOT))

    def test_no_game_data_or_manuals_in_the_repo(self):
        for p in every_file():
            rel = os.path.relpath(p, ROOT)
            if rel.startswith(os.path.join("tests", "fixtures") + os.sep):
                # hand-made synthetic fixtures only: tiny, and never a disc or a manual
                self.assertLess(os.path.getsize(p), 64 * 1024, rel)
                self.assertFalse(rel.lower().endswith((".iso", ".pdf", ".elf", ".irx")), rel)
                continue
            self.assertFalse(rel.lower().endswith(GAME_EXT), "%s looks like game data" % rel)
            self.assertLess(os.path.getsize(p), MAX_FILE, "%s is too big for this repo" % rel)
            with open(p, "rb") as fh:
                head = fh.read(4)
            if head == b"\x7fELF":
                self.fail("%s is an ELF binary" % rel)

    def test_plugin_manifests(self):
        with open(os.path.join(ROOT, ".claude-plugin", "plugin.json")) as fh:
            plugin = json.load(fh)
        self.assertEqual(plugin["name"], "console-skill")
        self.assertEqual(plugin["skills"], "./")
        self.assertEqual(plugin["license"], "MIT")
        self.assertEqual(plugin["description"], ABOUT)
        with open(os.path.join(ROOT, ".claude-plugin", "marketplace.json")) as fh:
            market = json.load(fh)
        self.assertEqual(market["plugins"][0]["name"], "console-skill")
        self.assertEqual(market["plugins"][0]["source"], "./")

    def test_readme_lists_the_eleven_and_the_fine_print(self):
        with open(os.path.join(ROOT, "README.md"), encoding="utf-8") as fh:
            readme = fh.read()
        self.assertIn(README_ABOUT, readme)
        for s in SKILLS:
            self.assertIn("`/%s`" % s, readme)
        for must in ("hkmodd/ps2-recomp-Agent-SKILL", "ran-j/PS2Recomp", "own", "Sony"):
            self.assertIn(must, readme)

    def test_license_credits_the_base_skill(self):
        with open(os.path.join(ROOT, "LICENSE"), encoding="utf-8") as fh:
            lic = fh.read()
        # plain MIT so GitHub detects it; the base skill's notice travels in the README
        self.assertTrue(lic.startswith("MIT License\n\nCopyright (c) 2026 Jake Schincariol"))
        self.assertEqual(lic.count("Permission is hereby granted"), 1)
        self.assertNotIn("----", lic)
        with open(os.path.join(ROOT, "README.md"), encoding="utf-8") as fh:
            readme = fh.read()
        notice = readme.split("License notice for hkmodd/ps2-recomp-Agent-SKILL")[1]
        self.assertIn("Copyright (c) 2026 [Your Name / Alias]", notice)
        self.assertIn("Permission is hereby granted", notice)
        self.assertIn("THE SOFTWARE IS PROVIDED \"AS IS\"", notice)


    def test_agents_skill_copies_match_root(self):
        mirror = os.path.join(ROOT, ".agents", "skills")
        self.assertTrue(os.path.isdir(mirror), ".agents/skills is missing")

        for skill in SKILLS:
            source = os.path.join(ROOT, skill)
            target = os.path.join(mirror, skill)
            self.assertTrue(os.path.isdir(target), "%s is missing from .agents/skills" % skill)

            source_files = set()
            for source_path in tracked_files_in(source):
                relative = os.path.relpath(source_path, source)
                if relative.endswith(".pyc"):
                    continue
                source_files.add(relative)
                target_path = os.path.join(target, relative)
                self.assertTrue(os.path.isfile(source_path),
                                "%s is missing from canonical skill %s" % (relative, skill))
                self.assertTrue(os.path.isfile(target_path),
                                "%s is missing from .agents/skills/%s" % (skill, relative))
                with open(source_path, "rb") as source_fh, open(target_path, "rb") as target_fh:
                    self.assertEqual(source_fh.read(), target_fh.read(),
                                     "%s/%s differs from its Codex copy" % (skill, relative))

            target_files = set()
            for target_path in tracked_files_in(target):
                if target_path.endswith(".pyc"):
                    continue
                target_files.add(os.path.relpath(target_path, target))
            self.assertEqual(target_files, source_files,
                             "%s has extra or missing files in .agents/skills" % skill)


    def test_codex_skill_paths_use_metadata_path_not_claude_env(self):
        for skill in SKILLS:
            _, text = frontmatter(os.path.join(ROOT, skill, "SKILL.md"))
            self.assertIn("Codex does not document a corresponding skill-directory environment variable", text)
            self.assertIn("parent directory of that provided path", text)
            self.assertIn("${CLAUDE_SKILL_DIR}", text)


if __name__ == "__main__":
    unittest.main()
