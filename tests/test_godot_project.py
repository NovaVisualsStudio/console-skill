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
        self.assertIn("textures/vram_compression/import_etc2_astc=true", project)
        self.assertIn('name="Android"', preset)
        self.assertIn('package/unique_name="com.novavisuals.ancientwarrior"', preset)
        self.assertIn("architectures/arm64-v8a=true", preset)

    def test_cinematic_camera_and_arena_modules_exist(self):
        camera = self.read("scripts/camera_rig.gd")
        arena = self.read("scripts/main.gd")
        for token in ("start_intro", "set_lock_target", "shake", "camera.look_at"):
            self.assertIn(token, camera)
        for token in ("THE ASHEN GATE", "THE WARDEN AWAKENS", "_add_dust_motes", "_add_ritual_ring"):
            self.assertIn(token, arena)

    def test_combat_actions_and_states_exist(self):
        player = self.read("scripts/player.gd")
        main = self.read("scripts/main.gd")
        for token in ("perform_light_attack", "perform_heavy_attack", "perform_dodge", "set_guard", "parry_success"):
            self.assertIn(token, player)
        for token in ("move_forward", "move_back", "move_left", "move_right", "heavy_attack", "lock_on"):
            self.assertIn(token, main)

    def test_enemy_telegraph_and_two_phase_boss_exist(self):
        enemy = self.read("scripts/enemy.gd")
        for token in ("BrainState.TELEGRAPH", "attack_telegraph", "phase_changed", "telegraph_mesh.visible = true", "phase = 2"):
            self.assertIn(token, enemy)
        self.assertIn("_make_enemy(Vector3(0.0, 0.05, -10.5), true)", self.read("scripts/main.gd"))

    def test_audio_fx_module_and_audio_test_exist(self):
        audio = self.read("scripts/audio_fx.gd")
        self.assertTrue(os.path.isfile(os.path.join(ROOT, "tests", "audio_smoke.gd")))
        for token in ("_make_ambience", "_make_one_shot", "play_hit", "play_parry", "play_telegraph"):
            self.assertIn(token, audio)

    def test_combat_and_cinematic_runtime_tests_exist(self):
        self.assertTrue(os.path.isfile(os.path.join(ROOT, "tests", "combat_smoke.gd")))
        self.assertTrue(os.path.isfile(os.path.join(ROOT, "tests", "cinematic_smoke.gd")))
        combat = self.read("tests/combat_smoke.gd")
        cinematic = self.read("tests/cinematic_smoke.gd")
        self.assertIn("Perfect parry", combat)
        self.assertIn("Boss phase transition", combat)
        self.assertIn("arena.camera_rig.set_lock_target", cinematic)
        self.assertIn("combat_started", cinematic)
        self.assertIn("audio_fx", self.read("scripts/main.gd"))

    def test_no_external_or_proprietary_game_assets_are_bundled(self):
        for current, _, filenames in os.walk(ROOT):
            for filename in filenames:
                self.assertFalse(filename.lower().endswith((".iso", ".elf", ".irx", ".exe", ".apk")))
        self.assertTrue(os.path.isfile(os.path.join(ROOT, "README.md")))

if __name__ == "__main__":
    unittest.main()
