extends SceneTree


func _initialize() -> void:
	call_deferred("_run_character_smoke")


func _run_character_smoke() -> void:
	var mobile_ok := await _check_candidate(
		"res://assets/characters/nova_mocap_candidate.glb",
		false
	)
	if not mobile_ok:
		quit(1)
		return

	var face_ok := await _check_candidate(
		"res://assets/characters/nova_mocap_candidate_face_preserved.glb",
		true
	)
	if not face_ok:
		quit(1)
		return

	print("Mocap character smoke test passed: mobile GLB and 52 facial blendshapes imported")
	quit(0)


func _check_candidate(character_path: String, expect_face: bool) -> bool:
	if not ResourceLoader.exists(character_path):
		push_error("Motion-capture GLB was not imported: %s" % character_path)
		return false

	var packed := load(character_path) as PackedScene
	if packed == null:
		push_error("Motion-capture GLB did not import as a PackedScene: %s" % character_path)
		return false

	var character := packed.instantiate()
	get_root().add_child(character)
	await process_frame

	var skeleton := character.find_child("Skeleton3D", true, false) as Skeleton3D
	var animation_player := character.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if skeleton == null:
		push_error("Imported character has no Skeleton3D: %s" % character_path)
		character.queue_free()
		await process_frame
		return false
	if skeleton.get_bone_count() < 20:
		push_error("Imported humanoid skeleton has fewer than 20 bones: %s" % character_path)
		character.queue_free()
		await process_frame
		return false
	if animation_player == null or animation_player.get_animation_list().is_empty():
		push_error("Imported character has no animation clips: %s" % character_path)
		character.queue_free()
		await process_frame
		return false

	var blend_shape_count := 0
	for node in character.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		if mesh_instance != null and mesh_instance.mesh != null:
			blend_shape_count += mesh_instance.mesh.get_blend_shape_count()

	var blend_shape_tracks := 0
	for animation_name in animation_player.get_animation_list():
		var animation := animation_player.get_animation(animation_name)
		if animation == null:
			continue
		for track_index in range(animation.get_track_count()):
			var track_path := str(animation.track_get_path(track_index))
			if track_path.contains("blend_shapes"):
				blend_shape_tracks += 1

	if expect_face:
		if blend_shape_count < 52:
			push_error("Face-preserved GLB imported fewer than 52 blendshapes: %d" % blend_shape_count)
			character.queue_free()
			await process_frame
			return false
		if blend_shape_tracks < 1:
			push_error("Face-preserved GLB has no imported facial blendshape animation tracks")
			character.queue_free()
			await process_frame
			return false
		print("Face-preserved mocap GLB passed: %d bones, %d blendshapes, %d clips, %d facial tracks" % [
			skeleton.get_bone_count(),
			blend_shape_count,
			animation_player.get_animation_list().size(),
			blend_shape_tracks
		])
	else:
		if blend_shape_count != 0 or blend_shape_tracks != 0:
			push_error("Android GLB unexpectedly retains facial blendshape data")
			character.queue_free()
			await process_frame
			return false
		print("Android mocap GLB passed: %d bones, %d clips, no facial morph data" % [
			skeleton.get_bone_count(),
			animation_player.get_animation_list().size()
		])

	character.queue_free()
	await process_frame
	return true
