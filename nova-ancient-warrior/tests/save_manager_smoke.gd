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
	if not writer.record_checkpoint(2, 1200, 2):
		_fail("Could not persist first checkpoint")
		return
	if not writer.set_audio_options(0.4, 0.6):
		_fail("Could not persist audio settings")
		return
	var reader := SaveManagerScript.new()
	reader.file_path = test_path
	reader.name = "SaveSmokeReader"
	get_root().add_child(reader)
	await process_frame
	if int(reader.profile.get("best_score", 0)) != 1200 or int(reader.profile.get("highest_wave", 0)) != 2:
		_fail("Checkpoint score or wave was not restored")
		return
	if int(reader.profile.get("total_souls", 0)) != 2 or int(reader.profile.get("pending_souls", 0)) != 2:
		_fail("Checkpoint souls were not safely banked")
		return
	if int(reader.profile.get("unlocked_chapter", 0)) != 1:
		_fail("A regular wave incorrectly unlocked a chapter")
		return
	if not reader.record_checkpoint(3, 1800, 4):
		_fail("Could not persist boss checkpoint")
		return
	reader.load_profile()
	if int(reader.profile.get("total_souls", 0)) != 4:
		_fail("Checkpoint retry double-counted or lost souls")
		return
	if not reader.record_run(3, 2000, 4, true):
		_fail("Could not persist boss victory")
		return
	reader.load_profile()
	if int(reader.profile.get("unlocked_chapter", 0)) != 2 or not bool(reader.profile.get("boss_defeated", false)):
		_fail("Boss victory did not unlock chapter two")
		return
	if int(reader.profile.get("total_souls", 0)) != 4:
		_fail("End-of-run reward double-counted checkpointed souls")
		return
	if int(reader.upgrade_cost("blade")) != 3 or not reader.purchase_upgrade("blade"):
		_fail("Blade upgrade purchase failed despite enough souls")
		return
	reader.load_profile()
	if int(reader.profile.get("upgrade_blade", 0)) != 1 or int(reader.profile.get("total_souls", 0)) != 1:
		_fail("Purchased upgrade or remaining soul balance was not saved")
		return
	if not reader.begin_run():
		_fail("Could not begin a fresh run")
		return
	reader.load_profile()
	if int(reader.profile.get("pending_souls", -1)) != 0:
		_fail("Run-local pending souls were not reset")
		return
	var absolute_path := ProjectSettings.globalize_path(test_path)
	DirAccess.remove_absolute(absolute_path)
	writer.queue_free()
	reader.queue_free()
	print("Save manager smoke test passed: checkpoint delta, resume, chapter unlock, upgrade, audio and run reset")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	var absolute_path := ProjectSettings.globalize_path("user://nova_profile_smoke.cfg")
	DirAccess.remove_absolute(absolute_path)
	quit(1)
