extends RefCounted
## Isolates one-finger camera orbit from the movement/action touch controls.

const LOOK_REGION_LEFT_RATIO := 0.46
const LOOK_REGION_BOTTOM_RATIO := 0.70
const YAW_SENSITIVITY := 0.006
const PITCH_SENSITIVITY := 0.003
const MIN_PITCH := 0.383972435
const MAX_PITCH := 0.837758041

var active_touch_id := -1
var yaw := 0.0
var pitch := 0.52


func handle_event(event: InputEvent, viewport_size: Vector2) -> bool:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return false
	if event is InputEventScreenTouch:
		if event.pressed:
			var in_look_region: bool = (
				event.position.x >= viewport_size.x * LOOK_REGION_LEFT_RATIO
				and event.position.y <= viewport_size.y * LOOK_REGION_BOTTOM_RATIO
			)
			if active_touch_id == -1 and in_look_region:
				active_touch_id = event.index
				return true
		elif event.index == active_touch_id:
			active_touch_id = -1
			return true
	elif event is InputEventScreenDrag and event.index == active_touch_id:
		yaw = wrapf(yaw - event.relative.x * YAW_SENSITIVITY, -PI, PI)
		pitch = clampf(
			pitch + event.relative.y * PITCH_SENSITIVITY,
			MIN_PITCH,
			MAX_PITCH
		)
		return true
	return false


func get_camera_offset(distance: float) -> Vector3:
	var safe_distance := maxf(0.1, distance)
	return Vector3(0.0, sin(pitch) * safe_distance, cos(pitch) * safe_distance).rotated(Vector3.UP, yaw)


func reset() -> void:
	active_touch_id = -1
	yaw = 0.0
	pitch = 0.52
