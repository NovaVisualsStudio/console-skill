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

    def test_icon_and_runtime_smoke_are_configured(self):
        project = self.read("project.godot")
        self.assertIn('config/icon="res://icon.svg"', project)
        self.assertTrue(os.path.isfile(os.path.join(ROOT, "icon.svg")))
        self.assertTrue(os.path.isfile(os.path.join(ROOT, "tests", "runtime_smoke.gd")))
        self.assertIn('PackedStringArray("4.7"', project)
        with open(os.path.join(ROOT, "..", ".github", "workflows", "godot-android-prototype.yml"), encoding="utf-8") as handle:
            workflow = handle.read()
        self.assertIn("version: 4.7.2", workflow)
        self.assertIn("sdk install platform-tools", workflow)
        self.assertIn("platforms/android-35", workflow)
        self.assertIn("build-tools/35.0.1", workflow)
        self.assertIn("ndk/28.1.13356709", workflow)
        self.assertNotIn("sdkmanager ", workflow)
        self.assertIn("pass in 1 2 3 4 5 6", workflow)

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
        for token in ("_make_ambience", "_make_one_shot", "play_hit", "play_parry", "play_telegraph", "func shutdown()", "one_shot_players.clear()"):
            self.assertIn(token, audio)

    def test_combat_and_cinematic_runtime_tests_exist(self):
        self.assertTrue(os.path.isfile(os.path.join(ROOT, "tests", "combat_smoke.gd")))
        self.assertTrue(os.path.isfile(os.path.join(ROOT, "tests", "cinematic_smoke.gd")))
        combat = self.read("tests/combat_smoke.gd")
        cinematic = self.read("tests/cinematic_smoke.gd")
        self.assertIn("Perfect parry", combat)
        self.assertIn("Boss phase transition", combat)
        self.assertIn("arena.camera_rig.set_lock_target", cinematic)
        self.assertIn("Player lock-on did not rotate", cinematic)
        self.assertIn("combat_started", cinematic)
        self.assertIn("audio_fx", self.read("scripts/main.gd"))

    def test_no_proprietary_game_assets_are_bundled(self):
        for current, directories, filenames in os.walk(ROOT):
            directories[:] = [name for name in directories if name not in {".godot", "build"}]
            for filename in filenames:
                self.assertFalse(filename.lower().endswith((".iso", ".elf", ".irx", ".exe", ".apk")))
        self.assertTrue(os.path.isfile(os.path.join(ROOT, "README.md")))

    def test_three_chapter_campaign_persists_progress(self):
        main_script = self.read("scripts/main.gd")
        campaign_test = self.read("tests/campaign_smoke.gd")
        self.assertIn("THE SUNKEN SANCTUM", main_script)
        self.assertIn("THE CROWN OF ASH", main_script)
        self.assertIn("user://nova_progress.cfg", main_script)
        self.assertIn("_save_campaign_progress", main_script)
        self.assertIn("campaign_complete", campaign_test)

    def test_cc0_pbr_environment_assets_are_imported_and_tested(self):
        fetcher = self.read("tools/fetch_cc0_textures.py")
        self.assertIn("api.polyhaven.com/files/", fetcher)
        self.assertIn("md5", fetcher)
        self.assertIn("1k", fetcher)
        self.assertIn("nor_gl", fetcher)
        self.assertIn("dl.polyhaven.org", fetcher)
        main_script = self.read("scripts/main.gd")
        for token in ("rock_tile_floor", "stone_wall", "_diff_1k.jpg", "_nor_gl_1k.jpg",
                      "_rough_1k.jpg", "_make_pbr_material", "_apply_pbr_material",
                      "PolyHavenCredits", "POWERED BY POLY HAVEN"):
            self.assertIn(token, main_script)
        visual_test = self.read("tests/visual_material_smoke.gd")
        self.assertIn("normal_texture", visual_test)
        self.assertIn("roughness_texture", visual_test)
        self.assertIn("ConfigFile.new()", visual_test)
        self.assertIn("compress/mode", visual_test)
        self.assertIn("mipmaps/generate", visual_test)
        self.assertIn("compress/normal_map", visual_test)
        self.assertIn("six mobile-compressed 1K maps are verified", visual_test)
        self.assertIn("write_import_settings", fetcher)
        self.assertIn('compress/mode": "2"', fetcher)
        self.assertIn('mipmaps/generate": "true"', fetcher)
        self.assertIn('compress/normal_map"] = "1"', fetcher)
        self.assertIn("PBR VISUAL TEST PASS", visual_test)
        self.assertIn("str(node.name)", visual_test)
        self.assertNotIn("node.name.to_string()", visual_test)
        self.assertIn("func _count_torch_lights", visual_test)
        self.assertIn("func _validate_torch_lights", visual_test)
        self.assertIn("expected four low-cost torch lights", visual_test)
        self.assertIn("TorchGlow", main_script)
        self.assertIn("OmniLight3D.new()", main_script)
        self.assertIn("torch_glow.shadow_enabled = false", main_script)
        self.assertIn("torch_glow.omni_range = 6.5", main_script)
        self.assertIn('func _add_column(position: Vector3, stone_material: StandardMaterial3D)', main_script)
        self.assertIn("NorthWallLowerTrim", main_script)
        self.assertIn("ritual_dais.material_override = floor_pbr", main_script)
        self.assertIn("await create_timer(0.5).timeout", visual_test)
        self.assertIn("AudioServer time", visual_test)
        license_file = self.read("assets/textures/ASSET_LICENSES.md")
        self.assertIn("CC0 1.0", license_file)
        self.assertIn("stone_wall", license_file)
        self.assertIn("rock_tile_floor", license_file)
        workflow = self.read("../.github/workflows/godot-android-prototype.yml")
        self.assertIn("fetch_cc0_textures.py", workflow)
        self.assertIn("visual_material_smoke.gd", workflow)
        self.assertIn("thirteen gates", workflow)

    def test_cc0_humanoid_assets_are_documented(self):
        manifest = self.read("assets/ASSET_MANIFEST.md")
        humanoid = self.read("scripts/humanoid_rig.gd")
        fetcher = os.path.join(ROOT, "tools", "fetch_cc0_animations.py")
        self.assertTrue(os.path.isfile(fetcher))
        fetcher = self.read("tools/fetch_cc0_animations.py")
        self.assertIn("quaternius-standard-male.glb", fetcher)
        self.assertIn("charactercreator-base-body.glb", fetcher)
        self.assertIn("charactercreator-trenchcoat.glb", fetcher)
        self.assertIn("gltf-transform", fetcher)
        self.assertIn("normalize.mjs", fetcher)
        self.assertIn("sparse-free", fetcher)
        normalizer = self.read("tools/gltf-normalizer/normalize.mjs")
        self.assertIn("accessor.setSparse(false)", normalizer)
        self.assertIn("dequantize()", normalizer)
        self.assertIn("registerExtensions(KHRONOS_EXTENSIONS)", normalizer)
        self.assertIn("sparseAccessors", normalizer)
        self.assertIn("KHR_mesh_quantization", normalizer)
        workflow = self.read("../.github/workflows/godot-android-prototype.yml")
        self.assertIn("@gltf-transform/cli@4.5.1", workflow)
        self.assertIn("@gltf-transform/core@4.5.1", workflow)
        self.assertIn("@gltf-transform/extensions@4.5.1", workflow)
        self.assertIn("@gltf-transform/functions@4.5.1", workflow)
        self.assertIn("CC0", manifest)
        self.assertIn("CC0 1.0", manifest)
        self.assertIn("UAL2_Standard.glb", humanoid)
        self.assertIn("Skeleton3D", humanoid)
        self.assertIn("_retarget_animation", humanoid)

if __name__ == "__main__":
    unittest.main()
