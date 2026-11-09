extends Control
## Always-available pause and audio settings overlay for the Android-first campaign.

signal pause_requested
signal resume_requested
signal audio_settings_changed(music_volume: float, sfx_volume: float)

var _pause_button: Button
var _panel: PanelContainer
var _music_slider: HSlider
var _sfx_slider: HSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not (event is InputEventKey and (event as InputEventKey).echo):
		_handle_cancel()
		get_viewport().set_input_as_handled()


func _handle_cancel() -> void:
	if is_paused():
		resume_requested.emit()
	else:
		pause_requested.emit()


func is_paused() -> bool:
	return is_instance_valid(_panel) and _panel.visible


func set_paused(paused: bool) -> void:
	if is_instance_valid(_panel):
		_panel.visible = paused
	if is_instance_valid(_pause_button):
		_pause_button.visible = not paused


func set_pause_available(available: bool) -> void:
	if is_instance_valid(_pause_button):
		_pause_button.disabled = not available
		_pause_button.visible = available and not is_paused()


func _build_ui() -> void:
	_pause_button = Button.new()
	_pause_button.name = "PauseButton"
	_pause_button.text = "PAUSE"
	_pause_button.anchor_left = 1.0
	_pause_button.anchor_right = 1.0
	_pause_button.offset_left = -142.0
	_pause_button.offset_right = -18.0
	_pause_button.offset_top = 72.0
	_pause_button.offset_bottom = 116.0
	_pause_button.custom_minimum_size = Vector2(124.0, 44.0)
	_pause_button.focus_mode = Control.FOCUS_NONE
	_pause_button.pressed.connect(func(): pause_requested.emit())
	add_child(_pause_button)

	_panel = PanelContainer.new()
	_panel.name = "PausePanel"
	_panel.visible = false
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -190.0
	_panel.offset_right = 190.0
	_panel.offset_top = -205.0
	_panel.offset_bottom = 205.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var stack := VBoxContainer.new()
	stack.name = "SettingsStack"
	stack.add_theme_constant_override("separation", 12)
	_panel.add_child(stack)

	var heading := Label.new()
	heading.text = "PAUSED"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 28)
	stack.add_child(heading)

	var resume := Button.new()
	resume.name = "ResumeButton"
	resume.text = "RESUME"
	resume.custom_minimum_size = Vector2(340.0, 54.0)
	resume.pressed.connect(func(): resume_requested.emit())
	stack.add_child(resume)

	var profile := _load_audio_profile()
	var music_label := Label.new()
	music_label.text = "MUSIC VOLUME"
	stack.add_child(music_label)
	_music_slider = HSlider.new()
	_music_slider.name = "MusicVolumeSlider"
	_music_slider.min_value = 0.0
	_music_slider.max_value = 1.0
	_music_slider.step = 0.05
	_music_slider.value = float(profile.get("music_volume", 0.72))
	stack.add_child(_music_slider)

	var sfx_label := Label.new()
	sfx_label.text = "SOUND EFFECTS"
	stack.add_child(sfx_label)
	_sfx_slider = HSlider.new()
	_sfx_slider.name = "SfxVolumeSlider"
	_sfx_slider.min_value = 0.0
	_sfx_slider.max_value = 1.0
	_sfx_slider.step = 0.05
	_sfx_slider.value = float(profile.get("sfx_volume", 0.85))
	stack.add_child(_sfx_slider)

	_music_slider.value_changed.connect(_emit_audio_settings)
	_sfx_slider.value_changed.connect(_emit_audio_settings)


func _load_audio_profile() -> Dictionary:
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null:
		return {"music_volume": 0.72, "sfx_volume": 0.85}
	var value: Variant = manager.get("profile")
	return value if value is Dictionary else {"music_volume": 0.72, "sfx_volume": 0.85}


func _emit_audio_settings(_changed_value: float) -> void:
	audio_settings_changed.emit(_music_slider.value, _sfx_slider.value)
