extends SceneTree

const AudioManager = preload("res://scripts/audio_manager.gd")


func _initialize() -> void:
	call_deferred("_run_audio_manager_smoke")


func _run_audio_manager_smoke() -> void:
	var manager := AudioManager.new()
	get_root().add_child(manager)
	manager.configure({"music_volume": 0.72, "sfx_volume": 0.85})
	if not manager.play_sfx_or_tone("missing_test_clip", 440.0, 0.08, 0.12):
		_fail(manager, "Synthesized fallback tone could not be scheduled")
		return
	if not manager.play_tone(660.0, 0.06, 0.10):
		_fail(manager, "Direct fallback tone could not be scheduled")
		return
	manager.stop_and_release()
	await create_timer(0.2).timeout
	manager.queue_free()
	print("Audio manager smoke test passed: configuration, fallback tone and shutdown")
	quit(0)


func _fail(manager: Node, message: String) -> void:
	push_error(message)
	manager.queue_free()
	quit(1)
