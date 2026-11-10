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
	var skeleton := skeleton_nodes[0] as Skeleton3D if not skeleton_nodes.is_empty() else null
	var animation_player := animation_nodes[0] as AnimationPlayer if not animation_nodes.is_empty() else null
	if skeleton == null or skeleton.get_bone_count() < 16:
		_fail(visual, "Generated Nova hero has no valid humanoid skeleton")
		return
	if animation_player == null:
		_fail(visual, "Generated Nova hero has no AnimationPlayer")
		return
	var required := ["Idle", "Walk", "Run", "LightAttack", "LightAttack2", "LightAttack3", "HeavyAttack", "Dodge", "Block", "Parry", "HitReact", "Death"]
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
	visual.call("set_locomotion", 0.5, 0.016)
	var locomotion_name := str(animation_player.current_animation).to_lower()
	if "walk" not in locomotion_name:
		_fail(visual, "Rigged hero did not select its walk clip")
		return
	if animation_player.get_animation(animation_player.current_animation).loop_mode != Animation.LOOP_LINEAR:
		_fail(visual, "Locomotion clips must loop continuously")
		return
	visual.call("play_dodge")
	if "dodge" not in str(animation_player.current_animation).to_lower():
		_fail(visual, "Rigged hero did not play its dodge clip")
		return
	for combo_index in range(3):
		visual.call("play_attack", combo_index)
		var expected_combo_clip := "lightattack" if combo_index == 0 else ("lightattack2" if combo_index == 1 else "lightattack3")
		if expected_combo_clip not in str(animation_player.current_animation).to_lower():
			_fail(visual, "Rigged hero did not select combo clip %d" % (combo_index + 1))
			return
	visual.call("play_heavy_attack")
	if "heavyattack" not in str(animation_player.current_animation).to_lower():
		_fail(visual, "Rigged hero did not select its heavy attack clip")
		return
	visual.call("set_blocking", true)
	if "block" not in str(animation_player.current_animation).to_lower():
		_fail(visual, "Rigged hero did not enter its guard loop")
		return
	visual.call("set_blocking", false)
	if "idle" not in str(animation_player.current_animation).to_lower():
		_fail(visual, "Rigged hero did not leave guard cleanly")
		return
	visual.call("set_locomotion", 0.5, 0.016)
	if "walk" not in str(animation_player.current_animation).to_lower():
		_fail(visual, "Guard release left the one-shot latch blocking locomotion")
		return
	visual.call("play_parry")
	if "parry" not in str(animation_player.current_animation).to_lower():
		_fail(visual, "Rigged hero did not select its parry clip")
		return
	visual.call("hit_react")
	if "hitreact" not in str(animation_player.current_animation).to_lower():
		_fail(visual, "Rigged hero did not select its hit reaction clip")
		return
	print("Rigged Nova hero smoke test passed: %d bones, %d animation clips" % [skeleton.get_bone_count(), names.size()])
	visual.free()
	quit(0)


func _fail(visual: Node, message: String) -> void:
	push_error(message)
	visual.free()
	quit(1)
