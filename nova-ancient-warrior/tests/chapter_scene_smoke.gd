extends SceneTree

const CHAPTER_SCENES := [
	"res://scenes/chapters/sunken_ruins.tscn",
	"res://scenes/chapters/ember_causeway.tscn",
	"res://scenes/chapters/obsidian_throne.tscn"
]
const EXPECTED_NAMES := ["SunkenRuins", "EmberCauseway", "ObsidianThrone"]
const ExplorationSecretDirector = preload("res://scripts/exploration_secret_director.gd")
const CACHE_POSITIONS := [Vector3(-10.6, 0.17, -3.5), Vector3(8.2, 0.07, -7.0), Vector3(-13.0, 0.09, -8.0)]
const CACHE_PLATFORM_NAMES := ["SunkenSidePlatform", "EmberFlankStep", "ObsidianSideWalk"]


func _initialize() -> void:
	call_deferred("_run_chapter_scene_smoke")


func _run_chapter_scene_smoke() -> void:
	var observed_layout_sizes: Array[int] = []
	for index in range(CHAPTER_SCENES.size()):
		var packed := load(CHAPTER_SCENES[index]) as PackedScene
		assert(packed != null, "Every chapter must be a loadable PackedScene")
		var scene := packed.instantiate() as Node3D
		assert(scene != null, "Every chapter root must be Node3D")
		assert(scene.name == EXPECTED_NAMES[index], "Chapter scene identity must remain unique")
		scene.set("graphics_quality", "mid")
		get_root().add_child(scene)
		await process_frame
		var dressing := scene.get_node_or_null("GeneratedStageDressing")
		var layout := scene.get_node_or_null("GeneratedCampaignLayout")
		assert(dressing != null, "Chapter must build its own visual environment")
		assert(layout != null, "Chapter must build its own collision-backed layout")
		assert(layout.find_children("*", "StaticBody3D", true, false).size() >= 10, "Chapter needs collision-backed traversal geometry")
		assert(dressing.get_child_count() >= 10, "Chapter needs distinct visual landmarks")
		var cache := ExplorationSecretDirector.build_stage(scene, index)
		assert(cache.position.is_equal_approx(CACHE_POSITIONS[index]), "Secret cache must use its chapter flank route")
		var cache_has_platform := false
		for body in layout.find_children("*", "StaticBody3D", true, false):
			if body.name != CACHE_PLATFORM_NAMES[index]:
				continue
			var collision := body.get_node_or_null("Collision") as CollisionShape3D
			if collision == null or not collision.shape is BoxShape3D:
				continue
			var platform_size := (collision.shape as BoxShape3D).size
			var within_x := absf(cache.position.x - body.position.x) <= platform_size.x * 0.5
			var within_z := absf(cache.position.z - body.position.z) <= platform_size.z * 0.5
			var aligned_height := is_equal_approx(cache.position.y + 0.11, body.position.y + platform_size.y * 0.5)
			if within_x and within_z and aligned_height:
				cache_has_platform = true
				break
		assert(cache_has_platform, "Secret cache must sit flush on a collision-backed chapter traversal platform")
		observed_layout_sizes.append(dressing.get_child_count())
		scene.queue_free()
		await process_frame
	assert(observed_layout_sizes.size() == 3, "All three chapter scenes must be tested")
	print("Chapter scene smoke test passed: three independent PackedScenes with unique collision layouts and dressing")
	quit(0)
