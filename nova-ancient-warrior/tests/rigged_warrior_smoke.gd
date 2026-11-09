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
	if skeleton == null or skeleton.get_bone_count() < 50:
		_fail(visual, "Generated Nova hero has no valid humanoid skeleton")
		return
	if animation_player == null:
		_fail(visual, "Generated Nova hero has no AnimationPlayer")
		return
	var required := ["Idle", "Walk", "Run", "Sword idle", "Sword slash", "Sword thrust", "Sword block", "Sword combo", "Side dodge left", "Side dodge right", "Hit from front", "Death (fall backward)", "Forward roll", "Jump start", "Jump air", "Jump land"]
	var names := animation_player.get_animation_list()
	if names.size() > 25:
		_fail(visual, "Mobile hero export must not ship the entire unused animation catalog")
		return
	for required_name in required:
		var found := false
		for actual_name in names:
			if required_name.to_lower().replace(" ", "") in str(actual_name).to_lower().replace(" ", "").replace("_", ""):
				found = true
				break
		if not found:
			_fail(visual, "Missing required hero animation: %s" % required_name)
			return
	if mesh_nodes.is_empty():
		_fail(visual, "Realistic rigged hero must import at least one skinned mesh instance")
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
	if "swordslash" not in str(animation_player.current_animation).to_lower().replace(" ", "").replace("_", ""):
		_fail(visual, "Light attack must select the sword slash clip")
		return
	visual.call("play_heavy_attack")
	if "swordthrust" not in str(animation_player.current_animation).to_lower().replace(" ", "").replace("_", ""):
		_fail(visual, "Heavy attack must select the sword thrust clip")
		return
	visual.call("set_blocking", true)
	if "swordblock" not in str(animation_player.current_animation).to_lower().replace(" ", "").replace("_", ""):
		_fail(visual, "Guard must select the sword block clip")
		return
	visual.call("play_parry")
	visual.call("play_dodge", Vector3.LEFT)
	if "sidedodgeleft" not in str(animation_player.current_animation).to_lower().replace(" ", ""):
		_fail(visual, "Left dodge must select the left motion-captured evade")
		return
	visual.call("play_dodge", Vector3.RIGHT)
	if "sidedodgeright" not in str(animation_player.current_animation).to_lower().replace(" ", ""):
		_fail(visual, "Right dodge must select the right motion-captured evade")
		return
	visual.call("play_dodge", Vector3.FORWARD)
	if "forwardroll" not in str(animation_player.current_animation).to_lower().replace(" ", ""):
		_fail(visual, "Forward dodge must select the forward roll clip")
		return
	visual.call("play_jump")
	if "jumpstart" not in str(animation_player.current_animation).to_lower().replace(" ", "").replace("_", ""):
		_fail(visual, "Jump takeoff must select the jump-start clip")
		return
	visual.call("_on_animation_finished", animation_player.current_animation)
	if "jumpair" not in str(animation_player.current_animation).to_lower().replace(" ", "").replace("_", ""):
		_fail(visual, "Jump takeoff must transition to the airborne loop")
		return
	visual.call("set_locomotion", 0.5, 0.016)
	if "jumpair" not in str(animation_player.current_animation).to_lower().replace(" ", "").replace("_", ""):
		_fail(visual, "Locomotion updates must not override airborne animation")
		return
	visual.call("play_jump_land")
	if "jumpland" not in str(animation_player.current_animation).to_lower().replace(" ", "").replace("_", ""):
		_fail(visual, "Landing must select the jump-land clip")
		return
	visual.call("hit_react")
	if "hitfromfront" not in str(animation_player.current_animation).to_lower().replace(" ", ""):
		_fail(visual, "Hit reaction must select a directional reaction clip")
		return
	print("Rigged Nova hero smoke test passed: %d bones, %d animation clips, %d mesh nodes, %d textured PBR materials" % [skeleton.get_bone_count(), names.size(), mesh_nodes.size(), textured_materials])
	visual.free()
	quit(0)


func _fail(visual: Node, message: String) -> void:
	push_error(message)
	visual.free()
	quit(1)
