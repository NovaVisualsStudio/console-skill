extends SceneTree

const NovaTouchJoystickScript = preload("res://scripts/virtual_joystick.gd")


func _initialize() -> void:
	for action_name in ["move_left", "move_right", "move_forward", "move_back"]:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
	var joystick := NovaTouchJoystickScript.new()
	joystick.position = Vector2(20.0, 500.0)
	joystick.size = Vector2(180.0, 180.0)
	get_root().add_child(joystick)
	call_deferred("_run_joystick_smoke", joystick)


func _run_joystick_smoke(joystick: Control) -> void:
	await process_frame
	var rect := joystick.get_global_rect()
	var center := rect.position + rect.size * 0.5
	var touch := InputEventScreenTouch.new()
	touch.index = 3
	touch.position = center
	touch.pressed = true
	joystick._input(touch)
	if joystick.active_touch_id != 3:
		_fail(joystick, "The lower-left joystick did not capture its first finger")
		return

	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = center + Vector2(60.0, 0.0)
	drag.relative = Vector2(60.0, 0.0)
	joystick._input(drag)
	if Input.get_action_strength("move_right") < 0.70 or Input.get_action_strength("move_left") > 0.01:
		_fail(joystick, "Horizontal joystick movement did not map to right movement")
		return

	var other_finger := InputEventScreenDrag.new()
	other_finger.index = 4
	other_finger.position = center + Vector2(-60.0, 0.0)
	other_finger.relative = Vector2(-120.0, 0.0)
	joystick._input(other_finger)
	if Input.get_action_strength("move_right") < 0.70:
		_fail(joystick, "A second finger was allowed to hijack the joystick")
		return

	var release := InputEventScreenTouch.new()
	release.index = 3
	release.position = center
	release.pressed = false
	joystick._input(release)
	for action_name in ["move_left", "move_right", "move_forward", "move_back"]:
		if Input.get_action_strength(action_name) > 0.01:
			_fail(joystick, "Joystick release left a movement action pressed")
			return
	if joystick.active_touch_id != -1:
		_fail(joystick, "Joystick finger ownership was not released")
		return

	# Simulate Android backgrounding while a finger is still holding the stick.
	var resume_touch := InputEventScreenTouch.new()
	resume_touch.index = 5
	resume_touch.position = center
	resume_touch.pressed = true
	joystick._input(resume_touch)
	var resume_drag := InputEventScreenDrag.new()
	resume_drag.index = 5
	resume_drag.position = center + Vector2(60.0, 0.0)
	resume_drag.relative = Vector2(60.0, 0.0)
	joystick._input(resume_drag)
	if Input.get_action_strength("move_right") < 0.70:
		_fail(joystick, "The joystick did not establish movement before simulated app suspension")
		return
	joystick._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	for action_name in ["move_left", "move_right", "move_forward", "move_back"]:
		if Input.get_action_strength(action_name) > 0.01:
			_fail(joystick, "Application focus loss left a virtual movement action pressed")
			return
	if joystick.active_touch_id != -1 or joystick._pressed or not joystick._axis.is_zero_approx():
		_fail(joystick, "Application focus loss did not clear joystick finger and visual state")
		return
	var post_resume_touch := InputEventScreenTouch.new()
	post_resume_touch.index = 6
	post_resume_touch.position = center
	post_resume_touch.pressed = true
	joystick._input(post_resume_touch)
	if joystick.active_touch_id != 6:
		_fail(joystick, "The joystick did not accept a new finger after application resume")
		return
	joystick._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)

	print("Virtual joystick smoke test passed: analogue axis, isolated finger and release cleanup")
	joystick.queue_free()
	quit(0)


func _fail(joystick: Control, message: String) -> void:
	push_error(message)
	joystick.queue_free()
	quit(1)
