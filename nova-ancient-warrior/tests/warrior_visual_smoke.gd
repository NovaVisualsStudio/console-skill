extends SceneTree

const WarriorVisual = preload("res://scripts/warrior_visual.gd")


func _initialize() -> void:
	call_deferred("_run_visual_smoke")


func _run_visual_smoke() -> void:
	var hero := WarriorVisual.new()
	hero.name = "WarriorVisualSmoke"
	get_root().add_child(hero)
	await process_frame
	if hero.get_child_count() < 10:
		push_error("Hero visual did not build enough articulated parts")
		quit(1)
		return
	hero.call("set_locomotion", 0.75, 1.0 / 60.0)
	hero.call("play_attack", 2)
	hero.call("play_heavy_attack")
	hero.call("set_blocking", true)
	hero.call("play_parry")
	hero.call("telegraph", true)
	hero.call("hit_react")
	await create_timer(0.35).timeout
	if not is_instance_valid(hero):
		push_error("Hero visual was unexpectedly freed during animation smoke test")
		quit(1)
		return
	hero.queue_free()

	var boss := WarriorVisual.new()
	boss.name = "EmberWarlordVisualSmoke"
	boss.set("is_enemy", true)
	boss.set("is_boss", true)
	boss.set("boss_kind", "ember_warlord")
	get_root().add_child(boss)
	await process_frame
	if boss.get_child_count() < 10:
		push_error("Boss visual did not build its articulated model and armour")
		quit(1)
		return
	boss.call("phase_change", 2)
	boss.call("phase_change", 3)
	boss.call("telegraph", true)
	boss.call("hit_react")
	boss.queue_free()
	print("Warrior visual smoke test passed: hero combos, heavy strike, guard, parry and boss phases")
	quit(0)
