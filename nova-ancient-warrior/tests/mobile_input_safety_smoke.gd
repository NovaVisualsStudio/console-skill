extends SceneTree

const MobileInputSafety = preload("res://scripts/mobile_input_safety.gd")
const TouchCamera = preload("res://scripts/touch_camera_controller.gd")


func _initialize() -> void:
	var actions: Array[String] = MobileInputSafety.ACTIONS
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
		Input.action_press(action_name)
	var camera := TouchCamera.new()
	camera.active_touch_id = 17
	camera.yaw = 1.2
	camera.pitch = 0.7
	MobileInputSafety.release_synthetic_inputs(camera)
	for action_name in actions:
		if Input.is_action_pressed(action_name):
			_fail("Focus recovery left synthetic action pressed: " + action_name)
			return
	if camera.active_touch_id != -1 or not is_zero_approx(camera.yaw) or not is_equal_approx(camera.pitch, 0.52):
		_fail("Focus recovery did not reset the camera's active touch and orbit")
		return
	print("Mobile input safety smoke test passed: all held actions and camera touch state clear on focus recovery")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
