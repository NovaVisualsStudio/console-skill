extends SceneTree

const RiggedWarriorVisual = preload("res://scripts/rigged_warrior_visual.gd")


func _initialize() -> void:
	call_deferred("_run_rigged_hero_smoke")


func _run_rigged_hero_smoke() -> void:
	var visual := RiggedWarriorVisual.new()
	get_root().add_child(visual)
	await process_frame
	var skeleton_nodes := visual.find_children("*", "Skeleton3D", true, false)
	var animation_nodes := visual.find_children("*", "AnimationPlayer", true, false)
	var mesh_nodes := visual.find_children("*", "MeshInstance3D", true, false)
	var skeleton := skeleton_nodes[0] as Skeleton3D if not skeleton_nodes.is_empty() else null
	var animation_player := animation_nodes[0] as AnimationPlayer if not animation_nodes.is_empty() else null
	if skeleton == null or skeleton.get_bone_count() < 16:
		_fail(visual, "Generated Nova hero has no valid humanoid skeleton")
		return
	if animation_player == null:
		_fail(visual, "Generated Nova hero has no AnimationPlayer")
		return
	var required := ["Idle", "Walk", "Run", "LightAttack", "HeavyAttack", "Dodge", "Block", "Parry", "HitReact", "Death"]
	var names := animation_player.get_animation_list()
	for required_name in required:
		var found := false
		for actual_name in names:
			if required_name.to_lower() in actual_name.to_lower():
				found = true
				break
		if not found:
			_fail(visual, "Missing required hero animation: %s" % required_name)
			return
	if mesh_nodes.size() < 40:
		_fail(visual, "Detailed armoured hero should contain at least 40 skinned mesh parts")
		return
	var textured_materials := 0
	for mesh_node in mesh_nodes:
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for surface_index in range(mesh_instance.mesh.get_surface_count()):
			var surface_material := mesh_instance.get_active_material(surface_index) as StandardMaterial3D
			if surface_material != null and surface_material.albedo_texture != null and surface_material.normal_texture != null:
				textured_materials += 1
				break
	if textured_materials < 4:
		_fail(visual, "Hero must import with textured PBR albedo and normal maps")
		return
	visual.call("set_locomotion", 0.5, 0.016)
	var locomotion_name := str(animation_player.current_animation).to_lower()
	if "walk" not in locomotion_name:
		_fail(visual, "Rigged hero did not select its walk clip")
		return
	if animation_player.get_animation(animation_player.current_animation).loop_mode != Animation.LOOP_LINEAR:
		_fail(visual, "Locomotion clips must loop continuously")
		return
	visual.call("play_attack", 0)
	visual.call("play_heavy_attack")
	visual.call("set_blocking", true)
	visual.call("play_parry")
	visual.call("hit_react")
	print("Rigged Nova hero smoke test passed: %d bones, %d animation clips, %d mesh parts, %d textured PBR materials" % [skeleton.get_bone_count(), names.size(), mesh_nodes.size(), textured_materials])
	visual.free()
	quit(0)


func _fail(visual: Node, message: String) -> void:
	push_error(message)
	visual.free()
	quit(1)
