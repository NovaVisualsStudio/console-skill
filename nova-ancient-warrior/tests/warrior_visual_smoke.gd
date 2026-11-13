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
	if boss.get_node_or_null("EmberHornLeft") == null or boss.get_node_or_null("EmberFlameCore") == null:
		push_error("Ember Warlord signature horns and flame core are missing")
		quit(1)
		return
	boss.queue_free()

	var ash_boss := WarriorVisual.new()
	ash_boss.set("is_enemy", true)
	ash_boss.set("is_boss", true)
	ash_boss.set("boss_kind", "ash_titan")
	get_root().add_child(ash_boss)
	await process_frame
	if ash_boss.get_node_or_null("AshTitanMaulHead") == null:
		push_error("Ash Titan signature maul is missing")
		quit(1)
		return
	ash_boss.queue_free()

	var final_boss := WarriorVisual.new()
	final_boss.set("is_enemy", true)
	final_boss.set("is_boss", true)
	final_boss.set("boss_kind", "obsidian_sovereign")
	get_root().add_child(final_boss)
	await process_frame
	if final_boss.get_node_or_null("ObsidianCrownSpire") == null or final_boss.get_node_or_null("ObsidianRuneOrb") == null:
		push_error("Obsidian Sovereign signature crown and rune orb are missing")
		quit(1)
		return
	final_boss.queue_free()
	print("Warrior visual smoke test passed: hero combos, heavy strike, guard, parry and boss phases")
	quit(0)
