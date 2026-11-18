extends RefCounted
## Clears synthetic mobile/keyboard actions after Android focus loss or suspension.

const ACTIONS := [
	"move_left", "move_right", "move_forward", "move_back",
	"attack", "heavy_attack", "jump", "dodge", "block",
	"lock_on", "interact", "restart"
]


static func release_synthetic_inputs(camera_controller: Object = null) -> void:
	for action_name in ACTIONS:
		if InputMap.has_action(action_name):
			Input.action_release(action_name)
	if is_instance_valid(camera_controller) and camera_controller.has_method("reset"):
		camera_controller.call("reset")
