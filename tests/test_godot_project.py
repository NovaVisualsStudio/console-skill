import os
import unittest

ROOT = os.path.join(os.path.dirname(__file__), "..", "android-game")

class GodotProjectIntegrity(unittest.TestCase):
    def read(self, relative):
        with open(os.path.join(ROOT, relative), encoding="utf-8") as handle:
            return handle.read()

    def test_project_has_a_main_scene(self):
        project = self.read("project.godot")
        scene = self.read("scenes/main.tscn")
        self.assertIn('run/main_scene="res://scenes/main.tscn"', project)
        self.assertIn('res://scripts/main.gd', scene)

    def test_mobile_renderer_is_compatibility(self):
        project = self.read("project.godot")
        self.assertIn('renderer/rendering_method="gl_compatibility"', project)
        self.assertIn('renderer/rendering_method.mobile="gl_compatibility"', project)

    def test_android_export_preset_and_landscape(self):
        project = self.read("project.godot")
        preset = self.read("export_presets.cfg")
        self.assertIn("window/handheld/orientation=0", project)
        self.assertIn('name="Android"', preset)
        self.assertIn('package/unique_name="com.novavisuals.ancientwarrior"', preset)
        self.assertIn("architectures/arm64-v8a=true", preset)

    def test_combat_actions_exist(self):
        player = self.read("scripts/player.gd")
        main = self.read("scripts/main.gd")
        for action in ("perform_attack", "perform_dodge", "take_damage"):
            self.assertIn(action, player)
        for action in ("move_forward", "move_back", "move_left", "move_right", "guard"):
            self.assertIn(action, main)

    def test_boss_and_enemy_ai_exist(self):
        enemy = self.read("scripts/enemy.gd")
        main = self.read("scripts/main.gd")
        self.assertIn("is_boss", enemy)
        self.assertIn("attack_damage", enemy)
        self.assertIn("_make_enemy(Vector3(0, 0.05, -10.0), true)", main)

    def test_no_external_or_proprietary_game_assets_are_bundled(self):
        for current, _, filenames in os.walk(ROOT):
            for filename in filenames:
                self.assertFalse(filename.lower().endswith((".iso", ".elf", ".irx", ".exe", ".apk")))
        self.assertTrue(os.path.isfile(os.path.join(ROOT, "README.md")))

if __name__ == "__main__":
    unittest.main()
