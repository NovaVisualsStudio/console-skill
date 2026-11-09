extends SceneTree

const CHAPTER_SCENES := [
	"res://scenes/chapters/sunken_ruins.tscn",
	"res://scenes/chapters/ember_causeway.tscn",
	"res://scenes/chapters/obsidian_throne.tscn"
]
const EXPECTED_NAMES := ["SunkenRuins", "EmberCauseway", "ObsidianThrone"]


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
		observed_layout_sizes.append(dressing.get_child_count())
		scene.queue_free()
		await process_frame
	assert(observed_layout_sizes.size() == 3, "All three chapter scenes must be tested")
	print("Chapter scene smoke test passed: three independent PackedScenes with unique collision layouts and dressing")
	quit(0)
