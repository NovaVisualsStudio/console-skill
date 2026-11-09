extends SceneTree

const CHAPTER_SCENES := [
	"res://scenes/chapters/sunken_ruins.tscn",
	"res://scenes/chapters/ember_causeway.tscn",
	"res://scenes/chapters/obsidian_throne.tscn"
]
const EXPECTED_NAMES := ["SunkenRuins", "EmberCauseway", "ObsidianThrone"]
const ExplorationSecretDirector = preload("res://scripts/exploration_secret_director.gd")
const ExplorationPuzzleDirector = preload("res://scripts/exploration_puzzle_director.gd")
const CACHE_POSITIONS := [Vector3(-10.6, 0.17, -3.5), Vector3(8.2, 0.07, -7.0), Vector3(-13.0, 0.09, -8.0)]
const CACHE_PLATFORM_NAMES := ["SunkenSidePlatform", "EmberFlankStep", "ObsidianSideWalk"]
const PUZZLE_RAISED_PLATFORM_NAME := "EmberCauseway"


func _initialize() -> void:
	call_deferred("_run_chapter_scene_smoke")


func _run_chapter_scene_smoke() -> void:
	var observed_layout_sizes: Array[int] = []
	for index in range(CHAPTER_SCENES.size()):
		print("Chapter smoke: entering chapter %d (%s)" % [index + 1, EXPECTED_NAMES[index]])
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
		var puzzle_runes := ExplorationPuzzleDirector.build_stage(scene, index)
		var puzzle_positions := ExplorationPuzzleDirector.rune_positions(index)
		assert(puzzle_runes.size() == 3, "Every chapter must provide three environmental puzzle runes")
		for rune_index in range(puzzle_runes.size()):
			assert(puzzle_runes[rune_index].position.is_equal_approx(puzzle_positions[rune_index]), "Puzzle rune must be placed on its authored route")
		if index == 1:
			var causeway := layout.get_node_or_null(PUZZLE_RAISED_PLATFORM_NAME) as StaticBody3D
			assert(causeway != null, "Ember chapter must provide its safe raised causeway")
			var causeway_collision := causeway.get_node_or_null("Collision") as CollisionShape3D
			assert(causeway_collision != null and causeway_collision.shape is BoxShape3D, "Ember causeway must be collision-backed")
			var causeway_top := causeway.position.y + (causeway_collision.shape as BoxShape3D).size.y * 0.5
			assert(is_equal_approx(puzzle_runes[2].position.y, causeway_top), "Middle Ember rune must sit exactly on the causeway top")
		var cache_has_platform := false
		var platform_diagnostics: Array[String] = []
		var cache_world := cache.global_position
		var expected_cache_bottom := cache_world.y + 0.11
		for body in layout.find_children("*", "StaticBody3D", true, false):
			if not body.name.begins_with(CACHE_PLATFORM_NAMES[index] + "_"):
				continue
			var collision := body.get_node_or_null("Collision") as CollisionShape3D
			if collision == null or not collision.shape is BoxShape3D:
				continue
			var platform_size := (collision.shape as BoxShape3D).size
			var platform_world := collision.global_position
			var within_x := absf(cache_world.x - platform_world.x) <= platform_size.x * 0.5 + 0.02
			var within_z := absf(cache_world.z - platform_world.z) <= platform_size.z * 0.5 + 0.02
			var platform_top := platform_world.y + platform_size.y * 0.5
			var height_delta := absf(expected_cache_bottom - platform_top)
			platform_diagnostics.append("%s center=%s size=%s top=%.4f cache_bottom=%.4f delta=%.4f" % [
				body.name, str(platform_world), str(platform_size), platform_top, expected_cache_bottom, height_delta
			])
			if within_x and within_z and height_delta <= 0.02:
				cache_has_platform = true
				break
		if not cache_has_platform:
			_fail(scene, "Chapter %d secret cache does not sit on %s. Cache world=%s; candidates=%s" % [
				index + 1, CACHE_PLATFORM_NAMES[index], str(cache_world), "; ".join(platform_diagnostics)
			])
			return
		observed_layout_sizes.append(dressing.get_child_count())
		scene.queue_free()
		await process_frame
	assert(observed_layout_sizes.size() == 3, "All three chapter scenes must be tested")
	print("Chapter scene smoke test passed: three independent PackedScenes with unique collision layouts and dressing")
	quit(0)


func _fail(scene: Node3D, message: String) -> void:
	push_error(message)
	if is_instance_valid(scene):
		scene.free()
	quit(1)
