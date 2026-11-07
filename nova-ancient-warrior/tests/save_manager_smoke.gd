extends SceneTree

const SaveManagerScript = preload("res://scripts/save_manager.gd")


func _initialize() -> void:
	call_deferred("_run_save_smoke")


func _run_save_smoke() -> void:
	var test_path := "user://nova_profile_smoke.cfg"
	var writer := SaveManagerScript.new()
	writer.file_path = test_path
	writer.name = "SaveSmokeWriter"
	get_root().add_child(writer)
	await process_frame
	if not writer.record_checkpoint(2, 1200):
		push_error("SaveManager failed to write a wave checkpoint")
		quit(1)
		return
	if not writer.set_audio_options(0.4, 0.6):
		push_error("SaveManager failed to write audio settings")
		quit(1)
		return
	var reader := SaveManagerScript.new()
	reader.file_path = test_path
	reader.name = "SaveSmokeReader"
	get_root().add_child(reader)
	await process_frame
	if int(reader.profile.get("best_score", 0)) != 1200:
		push_error("Best score was not restored from the local profile")
		quit(1)
		return
	if int(reader.profile.get("highest_wave", 0)) != 2:
		push_error("Highest wave checkpoint was not restored")
		quit(1)
		return
	if int(reader.profile.get("unlocked_chapter", 0)) != 1:
		push_error("A non-boss run incorrectly unlocked the next chapter")
		quit(1)
		return
	if not reader.record_run(3, 1800, 1, true):
		push_error("SaveManager failed to persist boss victory")
		quit(1)
		return
	reader.load_profile()
	if int(reader.profile.get("unlocked_chapter", 0)) != 2 or not bool(reader.profile.get("boss_defeated", false)) or int(reader.profile.get("total_souls", 0)) != 1:
		push_error("Boss victory did not unlock the next chapter")
		quit(1)
		return
	var absolute_path := ProjectSettings.globalize_path(test_path)
	DirAccess.remove_absolute(absolute_path)
	print("Save manager smoke test passed: checkpoint, settings, best score and boss unlock")
	quit(0)
