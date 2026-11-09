extends SceneTree

const PauseMenu = preload("res://scripts/pause_menu.gd")


func _initialize() -> void:
	call_deferred("_run_pause_menu_smoke")


func _run_pause_menu_smoke() -> void:
	var menu := PauseMenu.new()
	get_root().add_child(menu)
	await process_frame
	if menu.process_mode != Node.PROCESS_MODE_ALWAYS:
		_fail(menu, "Pause menu must remain responsive while the scene tree is paused")
		return
	if menu.get_node_or_null("PauseButton") == null or menu.get_node_or_null("PausePanel") == null:
		_fail(menu, "Pause and settings controls were not created")
		return
	if menu.get_node_or_null("PausePanel/ResumeButton") == null:
		_fail(menu, "Resume control is missing")
		return
	if menu.get_node_or_null("PausePanel/MusicVolumeSlider") == null or menu.get_node_or_null("PausePanel/SfxVolumeSlider") == null:
		_fail(menu, "Audio settings sliders are missing")
		return
	var pause_events := 0
	var resume_events := 0
	menu.pause_requested.connect(func(): pause_events += 1)
	menu.resume_requested.connect(func(): resume_events += 1)
	menu.set_paused(true)
	if not menu.is_paused():
		_fail(menu, "Pause panel did not become visible")
		return
	menu.set_paused(false)
	if menu.is_paused():
		_fail(menu, "Pause panel did not close")
		return
	menu.set_pause_available(false)
	var pause_button := menu.get_node("PauseButton") as Button
	if not pause_button.disabled or pause_button.visible:
		_fail(menu, "Pause control must be disabled when gameplay is over")
		return
	menu.set_pause_available(true)
	if pause_button.disabled or not pause_button.visible:
		_fail(menu, "Pause control did not re-enable")
		return
	print("Pause menu smoke test passed: pause/resume overlay, always-on input and persistent audio controls")
	menu.free()
	quit(0)


func _fail(menu: Node, message: String) -> void:
	push_error(message)
	menu.free()
	quit(1)
