extends SceneTree

func _initialize() -> void:
	call_deferred("_run_gameplay_localization_smoke")


func _run_gameplay_localization_smoke() -> void:
	var save_manager := get_root().get_node_or_null("SaveManager")
	if save_manager == null or not save_manager.call("set_language", "ar"):
		_fail("Could not set Arabic locale for gameplay localization test")
		return
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("Main gameplay scene could not be loaded")
		return
	var game := packed.instantiate()
	get_root().add_child(game)
	await process_frame
	await process_frame

	for node_name in ["Touch_attack", "Touch_heavy_attack", "Touch_jump", "Touch_lock_on", "Touch_dodge", "Touch_block", "CombatHint"]:
		if game.find_child(node_name, true, false) == null:
			_fail("Gameplay localization node is missing: %s" % node_name)
			return

	if (game.find_child("Touch_attack", true, false) as Button).text != "هجوم":
		_fail("Attack touch control did not localize to Arabic")
		return
	if (game.find_child("Touch_dodge", true, false) as Button).text != "مراوغة":
		_fail("Dodge touch control did not localize to Arabic")
		return
	if "تحرك" not in (game.find_child("CombatHint", true, false) as Label).text:
		_fail("Combat hint did not localize to Arabic")
		return

	save_manager.call("set_language", "en")
	game.call("_apply_gameplay_language")
	if (game.find_child("Touch_attack", true, false) as Button).text != "ATTACK":
		_fail("Attack touch control did not restore English")
		return
	if "MOVE" not in (game.find_child("CombatHint", true, false) as Label).text:
		_fail("Combat hint did not restore English")
		return

	game.queue_free()
	await process_frame
	print("Gameplay localization smoke test passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
