extends Control
## Analogue touch joystick for the lower-left HUD.
## Uses one tracked finger and drives the existing InputMap actions.

const DEADZONE := 0.12
const OUTER_RADIUS := 76.0
const KNOB_RADIUS := 31.0

var active_touch_id := -1
var _axis := Vector2.ZERO
var _pressed := false


func _ready() -> void:
	custom_minimum_size = Vector2(180.0, 180.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(true)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if active_touch_id == -1 and get_global_rect().has_point(event.position):
				active_touch_id = event.index
				_pressed = true
				_update_axis(event.position)
				get_viewport().set_input_as_handled()
		elif event.index == active_touch_id:
			_release_stick()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == active_touch_id:
		_update_axis(event.position)
		get_viewport().set_input_as_handled()


func _update_axis(screen_position: Vector2) -> void:
	var rect := get_global_rect()
	var center := rect.position + rect.size * 0.5
	var radius := minf(OUTER_RADIUS, minf(rect.size.x, rect.size.y) * 0.42)
	var displacement := (screen_position - center).limit_length(radius)
	_axis = displacement / maxf(radius, 1.0)
	if _axis.length() < DEADZONE:
		_axis = Vector2.ZERO
	_apply_axis("move_left", maxf(-_axis.x, 0.0))
	_apply_axis("move_right", maxf(_axis.x, 0.0))
	_apply_axis("move_forward", maxf(-_axis.y, 0.0))
	_apply_axis("move_back", maxf(_axis.y, 0.0))
	queue_redraw()


func _apply_axis(action_name: StringName, strength: float) -> void:
	if strength > 0.001:
		Input.action_press(action_name, clampf(strength, 0.0, 1.0))
	else:
		Input.action_release(action_name)


func _release_stick() -> void:
	active_touch_id = -1
	_pressed = false
	_axis = Vector2.ZERO
	for action_name in ["move_left", "move_right", "move_forward", "move_back"]:
		Input.action_release(action_name)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(OUTER_RADIUS, minf(size.x, size.y) * 0.42)
	draw_circle(center, radius, Color(0.025, 0.035, 0.055, 0.56))
	draw_arc(center, radius, 0.0, TAU, 64, Color(0.83, 0.70, 0.48, 0.82), 3.0, true)
	draw_arc(center, radius * 0.62, 0.0, TAU, 48, Color(0.72, 0.75, 0.80, 0.24), 1.5, true)
	var knob_position := center + _axis * radius
	var knob_color := Color(0.68, 0.80, 0.93, 0.76) if _pressed else Color(0.38, 0.48, 0.61, 0.58)
	draw_circle(knob_position, KNOB_RADIUS, knob_color)
	draw_arc(knob_position, KNOB_RADIUS, 0.0, TAU, 48, Color(0.92, 0.84, 0.69, 0.90), 2.0, true)
