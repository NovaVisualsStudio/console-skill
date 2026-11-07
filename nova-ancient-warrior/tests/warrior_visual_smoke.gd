extends SceneTree

const WarriorVisual = preload("res://scripts/warrior_visual.gd")


func _initialize() -> void:
	call_deferred("_run_visual_smoke")


func _run_visual_smoke() -> void:
	var visual := WarriorVisual.new()
	visual.name = "WarriorVisualSmoke"
	get_root().add_child(visual)
	await process_frame
	if visual.get_child_count() < 10:
		push_error("Warrior visual did not build enough articulated parts")
		quit(1)
		return
	visual.call("set_locomotion", 0.75, 1.0 / 60.0)
	visual.call("play_attack", 2)
	visual.call("telegraph", true)
	visual.call("hit_react")
	await create_timer(0.35).timeout
	if not is_instance_valid(visual):
		push_error("Warrior visual was unexpectedly freed during animation smoke test")
		quit(1)
		return
	visual.queue_free()
	print("Warrior visual smoke test passed: articulated rig, locomotion, combo swing and hit feedback")
	quit(0)
