extends SceneTree

const NarrativeDirector = preload("res://scripts/narrative_director.gd")
const CinematicDirector = preload("res://scripts/cinematic_director.gd")


func _initialize() -> void:
	call_deferred("_run_narrative_smoke")


func _run_narrative_smoke() -> void:
	for chapter in range(1, 4):
		var lines: Array[Dictionary] = NarrativeDirector.chapter_dialogue(chapter)
		assert(lines.size() >= 3, "Every chapter needs a complete story setup")
		for line in lines:
			assert(not str(line.get("speaker", "")).is_empty(), "Dialogue speaker cannot be empty")
			assert(not str(line.get("text", "")).is_empty(), "English subtitle cannot be empty")
			assert(not str(line.get("text_ar", "")).is_empty(), "Arabic subtitle cannot be empty")

	for boss_kind in ["ash_titan", "ember_warlord", "obsidian_sovereign"]:
		var lines: Array[Dictionary] = NarrativeDirector.boss_dialogue(boss_kind)
		assert(lines.size() >= 2, "Every boss needs an introduction exchange")

	var root := Node3D.new()
	get_root().add_child(root)
	var camera := Camera3D.new()
	root.add_child(camera)
	var subject := Node3D.new()
	root.add_child(subject)
	var return_position := Vector3(0.0, 6.0, 9.0)
	var return_target := Vector3(0.0, 1.1, 0.0)
	var reveal := CinematicDirector.play_camera_reveal(camera, subject, return_position, return_target, 0.12)
	assert(reveal != null, "Chapter and boss intros need a valid camera reveal tween")
	await reveal.finished
	assert(camera.global_position.distance_to(return_position) < 0.05, "Camera reveal must return to the gameplay camera position")
	root.free()
	print("Narrative director smoke test passed: localized chapter arcs, boss exchanges and camera reveal return")
	quit(0)
