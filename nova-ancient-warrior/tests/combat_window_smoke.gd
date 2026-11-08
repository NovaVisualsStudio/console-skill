extends SceneTree

const MainScript = preload("res://scripts/main.gd")
const CombatRules = preload("res://scripts/combat_rules.gd")

var _finished := false


func _initialize() -> void:
	call_deferred("_run_combat_window_smoke")
	call_deferred("_watchdog")


func _watchdog() -> void:
	await create_timer(12.0).timeout
	if not _finished:
		push_error("Combat window smoke test timed out before completing")
		quit(1)


func _run_combat_window_smoke() -> void:
	var game := MainScript.new()
	game.name = "CombatWindowSmoke"
	root.add_child(game)
	await process_frame
	await physics_frame
	print("Combat window test: main scene booted")

	var player := game.get("player") as CharacterBody3D
	var enemies: Array = game.get("enemies")
	if player == null or enemies.is_empty():
		await _finish(1, game, "Main scene did not create a player and enemy wave")
		return

	var target := enemies[0] as Node3D
	for index in range(enemies.size()):
		var enemy := enemies[index] as Node3D
		enemy.global_position = Vector3(12.0 + float(index), 0.0, 12.0)
	target.global_position = player.global_position + Vector3(0.0, 0.0, -1.4)
	target.set_meta("hp", 200)
	target.set_meta("max_hp", 200)
	await physics_frame

	var before := int(target.get_meta("hp"))
	game.call("_attack", false)
	print("Combat window test: attack started")
	if int(target.get_meta("hp")) != before:
		await _finish(1, game, "Light attack applied damage before its startup window")
		return

	await create_timer(CombatRules.attack_startup(false, 0) * 0.5).timeout
	if int(target.get_meta("hp")) != before:
		await _finish(1, game, "Light attack hit before the configured startup elapsed")
		return

	await create_timer(CombatRules.attack_startup(false, 0) * 0.7).timeout
	var expected := before - CombatRules.combo_damage(0)
	print("Combat window test: startup elapsed")
	if int(target.get_meta("hp")) != expected:
		await _finish(1, game, "Light attack did not apply its configured damage during the active window")
		return

	await create_timer(CombatRules.attack_active_duration(false) + 0.06).timeout
	if int(target.get_meta("hp")) != expected:
		await _finish(1, game, "One swing damaged the same target more than once")
		return

	print("Combat window smoke test passed: startup delay, active hit and one hit per target per swing")
	await _finish(0, game)


func _finish(exit_code: int, game: Node, message: String = "") -> void:
	_finished = true
	if not message.is_empty():
		push_error(message)
	if is_instance_valid(game):
		game.free()
	await process_frame
	await process_frame
	quit(exit_code)
