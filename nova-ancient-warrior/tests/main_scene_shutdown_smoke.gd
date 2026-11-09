extends SceneTree

const MAIN_SCENE := preload("res://scenes/main.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var main_scene := MAIN_SCENE.instantiate()
	root.add_child(main_scene)
	await process_frame
	# Let the procedural generator create and push a live playback before shutdown.
	await create_timer(0.8).timeout
	if not main_scene.has_method("stop_audio_and_wait"):
		push_error("Main scene has no graceful audio shutdown method")
		quit(1)
		return
	main_scene.call("stop_audio_and_wait")
	await create_timer(0.25).timeout
	if not bool(main_scene.get("_shutdown_in_progress")):
		push_error("Graceful audio shutdown did not start")
		quit(1)
		return
	print("MAIN_SCENE_GRACEFUL_SHUTDOWN_OK")
	quit(0)
