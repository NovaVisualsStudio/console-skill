extends SceneTree


func _initialize() -> void:
	call_deferred("_run_character_smoke")


func _run_character_smoke() -> void:
	var character_path := "res://assets/characters/nova_mocap_candidate.glb"
	if not ResourceLoader.exists(character_path):
		push_error("Motion-capture GLB was not imported")
		quit(1)
		return
	var packed := load(character_path) as PackedScene
	if packed == null:
		push_error("Motion-capture GLB did not import as a PackedScene")
		quit(1)
		return
	var character := packed.instantiate()
	get_root().add_child(character)
	await process_frame
	var skeleton := character.find_child("Skeleton3D", true, false) as Skeleton3D
	var animation_player := character.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if skeleton == null:
		push_error("Imported character has no Skeleton3D")
		quit(1)
		return
	if skeleton.get_bone_count() < 20:
		push_error("Imported humanoid skeleton has fewer than 20 bones")
		quit(1)
		return
	if animation_player == null or animation_player.get_animation_list().is_empty():
		push_error("Imported character has no animation clips")
		quit(1)
		return
	print("Mocap character smoke test passed: %d bones, %d clips" % [
		skeleton.get_bone_count(),
		animation_player.get_animation_list().size()
	])
	quit(0)
