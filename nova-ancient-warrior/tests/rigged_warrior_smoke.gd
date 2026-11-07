extends SceneTree

const RiggedWarriorVisual = preload("res://scripts/rigged_warrior_visual.gd")


func _initialize() -> void:
	call_deferred("_run_rigged_hero_smoke")


func _run_rigged_hero_smoke() -> void:
	var visual := RiggedWarriorVisual.new()
	get_root().add_child(visual)
	await process_frame
	var skeleton := visual.find_child("Skeleton3D", true, false) as Skeleton3D
	var animation_player := visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
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
	visual.call("set_locomotion", 0.5, 0.016)
	visual.call("play_attack", 0)
	visual.call("play_heavy_attack")
	visual.call("set_blocking", true)
	visual.call("play_parry")
	visual.call("hit_react")
	print("Rigged Nova hero smoke test passed: %d bones, %d animation clips" % [skeleton.get_bone_count(), names.size()])
	visual.free()
	quit(0)


func _fail(visual: Node, message: String) -> void:
	push_error(message)
	visual.free()
	quit(1)
