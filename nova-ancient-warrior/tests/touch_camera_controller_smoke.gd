extends SceneTree

const TouchCamera = preload("res://scripts/touch_camera_controller.gd")


func _initialize() -> void:
	var controller := TouchCamera.new()
	var viewport := Vector2(1280.0, 720.0)

	var action_zone_touch := InputEventScreenTouch.new()
	action_zone_touch.index = 1
	action_zone_touch.position = Vector2(1100.0, 660.0)
	action_zone_touch.pressed = true
	if controller.handle_event(action_zone_touch, viewport):
		_fail("Bottom-right action region must not capture camera look")
		return

	var look_touch := InputEventScreenTouch.new()
	look_touch.index = 7
	look_touch.position = Vector2(900.0, 240.0)
	look_touch.pressed = true
	if not controller.handle_event(look_touch, viewport) or controller.active_touch_id != 7:
		_fail("A touch in the upper-right look region was not captured")
		return

	var unrelated_drag := InputEventScreenDrag.new()
	unrelated_drag.index = 8
	unrelated_drag.relative = Vector2(100.0, 60.0)
	if controller.handle_event(unrelated_drag, viewport) or not is_zero_approx(controller.yaw):
		_fail("A second finger changed the active camera orbit")
		return

	var look_drag := InputEventScreenDrag.new()
	look_drag.index = 7
	look_drag.relative = Vector2(100.0, 40.0)
	if not controller.handle_event(look_drag, viewport):
		_fail("The active look finger drag was not handled")
		return
	if absf(controller.yaw + 0.6) > 0.0001 or absf(controller.pitch - 0.64) > 0.0001:
		_fail("Touch drag did not produce the expected yaw/pitch update")
		return
	var offset := controller.get_camera_offset(10.0)
	if not is_finite(offset.x) or not is_finite(offset.y) or not is_finite(offset.z) or absf(offset.length() - 10.0) > 0.001:
		_fail("Camera orbit offset is invalid or does not preserve distance")
		return

	var release := InputEventScreenTouch.new()
	release.index = 7
	release.pressed = false
	if not controller.handle_event(release, viewport) or controller.active_touch_id != -1:
		_fail("Releasing the active finger did not clear camera capture")
		return

	var extreme_drag := InputEventScreenDrag.new()
	extreme_drag.index = 7
	extreme_drag.relative = Vector2(0.0, 100000.0)
	controller.handle_event(extreme_drag, viewport)
	if controller.pitch > TouchCamera.MAX_PITCH or controller.pitch < TouchCamera.MIN_PITCH:
		_fail("Camera pitch escaped its safety limits")
		return

	print("Touch camera smoke test passed: action-zone isolation, one-finger orbit, multi-touch and pitch bounds")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
