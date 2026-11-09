extends Control
## Touch-first title screen with a live 3D hero preview, campaign entry and local settings.

const RiggedWarriorVisual = preload("res://scripts/rigged_warrior_visual.gd")

var _continue_button: Button
var _progress_label: Label
var _settings_panel: PanelContainer
var _credits_panel: PanelContainer
var _controls_panel: PanelContainer
var _music_slider: HSlider
var _sfx_slider: HSlider
var _quality_button: Button
var _language_button: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_hero_preview()
	_build_ui()
	_apply_language()
	_refresh_campaign_state()


func _build_hero_preview() -> void:
	var container := SubViewportContainer.new()
	container.name = "HeroPreview"
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.stretch = true
	add_child(container)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)

	var world := Node3D.new()
	world.name = "PreviewWorld"
	viewport.add_child(world)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.018, 0.027, 0.052)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.42, 0.46, 0.56)
	environment.ambient_light_energy = 0.72
	environment_node.environment = environment
	world.add_child(environment_node)

	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(18.0, 18.0)
	floor.mesh = floor_mesh
	floor.position.y = -0.035
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.045, 0.052, 0.075)
	floor_material.metallic = 0.32
	floor_material.roughness = 0.42
	floor.material_override = floor_material
	world.add_child(floor)

	var halo := MeshInstance3D.new()
	var halo_mesh := TorusMesh.new()
	halo_mesh.inner_radius = 1.55
	halo_mesh.outer_radius = 1.62
	halo.mesh = halo_mesh
	halo.position = Vector3(0.0, 1.55, -0.65)
	halo.rotation.x = deg_to_rad(90.0)
	var halo_material := StandardMaterial3D.new()
	halo_material.albedo_color = Color(0.22, 0.56, 0.86)
	halo_material.emission_enabled = true
	halo_material.emission = Color(0.08, 0.22, 0.5)
	halo_material.emission_energy_multiplier = 1.1
	halo_material.metallic = 0.5
	halo.material_override = halo_material
	world.add_child(halo)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-34.0, -28.0, 0.0)
	key_light.light_energy = 2.1
	key_light.shadow_enabled = false
	world.add_child(key_light)
	var fill_light := OmniLight3D.new()
	fill_light.position = Vector3(2.4, 2.7, 2.0)
	fill_light.light_color = Color(0.35, 0.58, 1.0)
	fill_light.light_energy = 1.1
	fill_light.omni_range = 7.0
	fill_light.shadow_enabled = false
	world.add_child(fill_light)

	var camera := Camera3D.new()
	camera.position = Vector3(0.25, 1.45, 5.2)
	camera.fov = 34.0
	camera.current = true
	camera.look_at(Vector3(0.0, 0.98, 0.0), Vector3.UP)
	world.add_child(camera)

	var hero := RiggedWarriorVisual.new()
	hero.name = "TitleHero"
	hero.rotation.y = PI
	world.add_child(hero)


func _build_ui() -> void:
	var left_shade := ColorRect.new()
	left_shade.name = "MenuShade"
	left_shade.anchor_right = 0.53
	left_shade.anchor_bottom = 1.0
	left_shade.color = Color(0.012, 0.018, 0.032, 0.91)
	left_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(left_shade)

	var title := Label.new()
	title.text = "NOVA"
	title.position = Vector2(72.0, 76.0)
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", Color(0.93, 0.84, 0.64))
	add_child(title)

	var subtitle := Label.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "ANCIENT WARRIOR"
	subtitle.position = Vector2(78.0, 158.0)
	subtitle.add_theme_font_size_override("font_size", 25)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.84, 0.94))
	add_child(subtitle)

	var tagline := Label.new()
	tagline.name = "TaglineLabel"
	tagline.text = "THREE SEALS. THREE KINGDOMS. ONE FINAL OATH."
	tagline.position = Vector2(80.0, 202.0)
	tagline.add_theme_font_size_override("font_size", 13)
	tagline.add_theme_color_override("font_color", Color(0.58, 0.69, 0.83))
	add_child(tagline)

	_progress_label = Label.new()
	_progress_label.name = "CampaignProgress"
	_progress_label.position = Vector2(80.0, 244.0)
	_progress_label.add_theme_font_size_override("font_size", 12)
	_progress_label.add_theme_color_override("font_color", Color(0.76, 0.72, 0.61))
	add_child(_progress_label)

	var menu := VBoxContainer.new()
	menu.name = "MainMenuButtons"
	menu.position = Vector2(76.0, 290.0)
	menu.custom_minimum_size = Vector2(360.0, 0.0)
	menu.add_theme_constant_override("separation", 12)
	add_child(menu)

	var new_game := _make_button("NEW CAMPAIGN", Vector2(350.0, 56.0))
	new_game.name = "NewCampaignButton"
	new_game.pressed.connect(_start_new_campaign)
	menu.add_child(new_game)

	_continue_button = _make_button("CONTINUE", Vector2(350.0, 56.0))
	_continue_button.name = "ContinueButton"
	_continue_button.pressed.connect(_continue_campaign)
	menu.add_child(_continue_button)

	var settings := _make_button("SETTINGS", Vector2(350.0, 50.0))
	settings.name = "SettingsButton"
	settings.pressed.connect(_open_settings)
	menu.add_child(settings)

	var how_to_play := _make_button("HOW TO PLAY", Vector2(350.0, 50.0))
	how_to_play.name = "HowToPlayButton"
	how_to_play.pressed.connect(_open_controls)
	menu.add_child(how_to_play)

	var credits := _make_button("CREDITS", Vector2(350.0, 50.0))
	credits.name = "CreditsButton"
	credits.pressed.connect(_open_credits)
	menu.add_child(credits)

	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		var quit_button := _make_button("QUIT", Vector2(350.0, 46.0))
		quit_button.name = "QuitButton"
		quit_button.pressed.connect(func(): get_tree().quit())
		menu.add_child(quit_button)

	var footer := Label.new()
	footer.name = "FooterLabel"
	footer.text = "OFFLINE CAMPAIGN  •  MID / HIGH ANDROID PROFILES"
	footer.position = Vector2(78.0, 690.0)
	footer.add_theme_font_size_override("font_size", 11)
	footer.add_theme_color_override("font_color", Color(0.48, 0.57, 0.7))
	add_child(footer)

	_build_settings_panel()
	_build_credits_panel()
	_build_controls_panel()


func _open_settings() -> void:
	_credits_panel.visible = false
	_controls_panel.visible = false
	_settings_panel.visible = true


func _open_controls() -> void:
	_settings_panel.visible = false
	_credits_panel.visible = false
	_controls_panel.visible = true


func _open_credits() -> void:
	_settings_panel.visible = false
	_controls_panel.visible = false
	_credits_panel.visible = true


func _make_button(label: String, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = minimum_size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 17)
	return button


func _build_settings_panel() -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.name = "SettingsPanel"
	_settings_panel.anchor_left = 0.5
	_settings_panel.anchor_right = 0.5
	_settings_panel.anchor_top = 0.5
	_settings_panel.anchor_bottom = 0.5
	_settings_panel.offset_left = -230.0
	_settings_panel.offset_right = 230.0
	_settings_panel.offset_top = -220.0
	_settings_panel.offset_bottom = 220.0
	_settings_panel.visible = false
	_settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_settings_panel)

	var stack := VBoxContainer.new()
	stack.name = "SettingsStack"
	stack.add_theme_constant_override("separation", 13)
	_settings_panel.add_child(stack)
	var heading := Label.new()
	heading.name = "SettingsHeading"
	heading.text = "SETTINGS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 27)
	stack.add_child(heading)

	var profile := _save_profile()
	var music_label := Label.new()
	music_label.name = "MusicVolumeLabel"
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
	sfx_label.name = "SfxVolumeLabel"
	sfx_label.text = "SOUND EFFECTS"
	stack.add_child(sfx_label)
	_sfx_slider = HSlider.new()
	_sfx_slider.name = "SfxVolumeSlider"
	_sfx_slider.min_value = 0.0
	_sfx_slider.max_value = 1.0
	_sfx_slider.step = 0.05
	_sfx_slider.value = float(profile.get("sfx_volume", 0.85))
	stack.add_child(_sfx_slider)

	_music_slider.value_changed.connect(_save_audio_options)
	_sfx_slider.value_changed.connect(_save_audio_options)

	_language_button = _make_button("", Vector2(400.0, 48.0))
	_language_button.name = "LanguageButton"
	_language_button.pressed.connect(_toggle_language)
	stack.add_child(_language_button)

	_quality_button = _make_button("", Vector2(400.0, 48.0))
	_quality_button.name = "QualityButton"
	_quality_button.pressed.connect(_toggle_graphics_quality)
	stack.add_child(_quality_button)
	_refresh_quality_button()

	var close := _make_button("CLOSE", Vector2(400.0, 46.0))
	close.name = "SettingsCloseButton"
	close.pressed.connect(func(): _settings_panel.visible = false)
	stack.add_child(close)


func _build_credits_panel() -> void:
	_credits_panel = PanelContainer.new()
	_credits_panel.name = "CreditsPanel"
	_credits_panel.anchor_left = 0.5
	_credits_panel.anchor_right = 0.5
	_credits_panel.anchor_top = 0.5
	_credits_panel.anchor_bottom = 0.5
	_credits_panel.offset_left = -270.0
	_credits_panel.offset_right = 270.0
	_credits_panel.offset_top = -230.0
	_credits_panel.offset_bottom = 230.0
	_credits_panel.visible = false
	_credits_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_credits_panel)
	var stack := VBoxContainer.new()
	stack.name = "CreditsStack"
	stack.add_theme_constant_override("separation", 12)
	_credits_panel.add_child(stack)
	var heading := Label.new()
	heading.name = "CreditsHeading"
	heading.text = "CREDITS & ASSET NOTICES"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 23)
	stack.add_child(heading)
	var notice := Label.new()
	notice.name = "CreditsNotice"
	notice.text = "NOVA Ancient Warrior is an original project. Hero generation: Ara 3D Gen (MIT). Character data: MakeHuman (CC0 1.0). Motion data: CMU Graphics Lab Motion Capture Database.\n\nThe data used in this project was obtained from mocap.cs.cmu.edu. The database was created with funding from NSF EIA-0196217."
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.custom_minimum_size = Vector2(490.0, 250.0)
	notice.add_theme_font_size_override("font_size", 14)
	stack.add_child(notice)
	var close := _make_button("CLOSE", Vector2(490.0, 48.0))
	close.name = "CreditsCloseButton"
	close.pressed.connect(func(): _credits_panel.visible = false)
	stack.add_child(close)


func _build_controls_panel() -> void:
	_controls_panel = PanelContainer.new()
	_controls_panel.name = "ControlsPanel"
	_controls_panel.anchor_left = 0.5
	_controls_panel.anchor_right = 0.5
	_controls_panel.anchor_top = 0.5
	_controls_panel.anchor_bottom = 0.5
	_controls_panel.offset_left = -280.0
	_controls_panel.offset_right = 280.0
	_controls_panel.offset_top = -235.0
	_controls_panel.offset_bottom = 235.0
	_controls_panel.visible = false
	_controls_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_controls_panel)
	var stack := VBoxContainer.new()
	stack.name = "ControlsStack"
	stack.add_theme_constant_override("separation", 12)
	_controls_panel.add_child(stack)
	var heading := Label.new()
	heading.name = "ControlsHeading"
	heading.text = "HOW TO PLAY"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	stack.add_child(heading)
	var notice := Label.new()
	notice.name = "ControlsNotice"
	notice.text = "ANDROID: Left joystick moves; drag the right side to orbit the camera. Tap ATTACK, HEAVY, GUARD, DODGE, LOCK, JUMP and INTERACT on the touch controls. Hold GUARD; tap just before impact for a perfect parry. PC: WASD / arrows move; mouse drag orbits; Space jumps; Shift or K dodges; J / Enter attacks; H heavy attack; I guard; Tab locks on; E interacts; R restarts; Esc pauses. Collect numbered seal fragments in the displayed order; each chapter has a different sequence. Defeat the boss after the gate opens."
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notice.custom_minimum_size = Vector2(510.0, 300.0)
	notice.add_theme_font_size_override("font_size", 15)
	stack.add_child(notice)
	var close := _make_button("CLOSE", Vector2(510.0, 48.0))
	close.name = "ControlsCloseButton"
	close.pressed.connect(func(): _controls_panel.visible = false)
	stack.add_child(close)


func _save_profile() -> Dictionary:
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null:
		return {}
	var value: Variant = manager.get("profile")
	return value if value is Dictionary else {}


func _refresh_campaign_state() -> void:
	var profile := _save_profile()
	var complete := bool(profile.get("campaign_complete", false))
	var highest_wave := clampi(int(profile.get("highest_wave", 1)), 1, 9)
	var chapter := int((highest_wave - 1) / 3) + 1
	var can_continue := highest_wave > 1 or complete
	_continue_button.disabled = not can_continue
	if _is_arabic():
		_continue_button.text = "إعادة الفصل الأخير" if complete else "متابعة"
		_progress_label.text = "اكتملت الحملة  |  أفضل نتيجة %d" % int(profile.get("best_score", 0)) if complete else "أفضل تقدم  |  الفصل %d  |  الموجة %d/9" % [chapter, highest_wave]
	else:
		_continue_button.text = "REPLAY FINAL CHAPTER" if complete else "CONTINUE"
		_progress_label.text = "CAMPAIGN COMPLETE  |  BEST SCORE %d" % int(profile.get("best_score", 0)) if complete else "BEST PROGRESS  |  CHAPTER %d  |  WAVE %d/9" % [chapter, highest_wave]


func _start_new_campaign() -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager != null:
		manager.call("start_new_campaign")
		manager.call("begin_run")
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _continue_campaign() -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager != null:
		manager.call("begin_run")
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _save_audio_options(_value: float) -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager != null:
		manager.call("set_audio_options", _music_slider.value, _sfx_slider.value)


func _toggle_graphics_quality() -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager == null:
		return
	var profile := _save_profile()
	var next_quality := "high" if str(profile.get("graphics_quality", "mid")) == "mid" else "mid"
	manager.call("set_graphics_quality", next_quality)
	_refresh_quality_button()


func _refresh_quality_button() -> void:
	var profile := _save_profile()
	var quality := str(profile.get("graphics_quality", "mid")).to_lower()
	if _is_arabic():
		_quality_button.text = "جودة الرسوم: مرتفعة" if quality == "high" else "جودة الرسوم: متوسطة"
	else:
		_quality_button.text = "GRAPHICS PROFILE: %s" % quality.to_upper()


func _is_arabic() -> bool:
	return TranslationServer.get_locale().begins_with("ar")


func _toggle_language() -> void:
	var manager := get_node_or_null("/root/SaveManager")
	var next_language := "en" if _is_arabic() else "ar"
	if manager != null:
		manager.call("set_language", next_language)
	else:
		TranslationServer.set_locale(next_language)
	_apply_language()
	_refresh_campaign_state()


func _apply_language() -> void:
	var arabic := _is_arabic()
	var texts := {
		"SubtitleLabel": "المحارب القديم" if arabic else "ANCIENT WARRIOR",
		"TaglineLabel": "ثلاثة أختام. ثلاث ممالك. عهد أخير." if arabic else "THREE SEALS. THREE KINGDOMS. ONE FINAL OATH.",
		"FooterLabel": "حملة بلا اتصال  •  إعدادات Android متوسطة / عالية" if arabic else "OFFLINE CAMPAIGN  •  MID / HIGH ANDROID PROFILES",
		"SettingsHeading": "الإعدادات" if arabic else "SETTINGS",
		"MusicVolumeLabel": "صوت الموسيقى" if arabic else "MUSIC VOLUME",
		"SfxVolumeLabel": "المؤثرات الصوتية" if arabic else "SOUND EFFECTS",
		"SettingsCloseButton": "إغلاق" if arabic else "CLOSE",
		"CreditsHeading": "الاعتمادات وإشعارات الأصول" if arabic else "CREDITS & ASSET NOTICES",
		"CreditsCloseButton": "إغلاق" if arabic else "CLOSE",
		"ControlsHeading": "طريقة اللعب والتحكم" if arabic else "HOW TO PLAY",
		"ControlsCloseButton": "إغلاق" if arabic else "CLOSE",
		"NewCampaignButton": "حملة جديدة" if arabic else "NEW CAMPAIGN",
		"SettingsButton": "الإعدادات" if arabic else "SETTINGS",
		"CreditsButton": "الاعتمادات" if arabic else "CREDITS",
		"HowToPlayButton": "طريقة اللعب" if arabic else "HOW TO PLAY",
		"QuitButton": "خروج" if arabic else "QUIT"
	}
	for node_name in texts:
		var node := find_child(node_name, true, false)
		if node is Label:
			var label := node as Label
			label.text = texts[node_name]
			label.text_direction = Control.TEXT_DIRECTION_RTL if arabic else Control.TEXT_DIRECTION_LTR
		elif node is Button:
			var button := node as Button
			button.text = texts[node_name]
			button.text_direction = Control.TEXT_DIRECTION_RTL if arabic else Control.TEXT_DIRECTION_LTR

	var controls_notice := find_child("ControlsNotice", true, false) as Label
	if controls_notice != null:
		if arabic:
			controls_notice.text = "أندرويد: حرّك عصا التحكم اليسرى للمشي، واسحب الجهة اليمنى لتحريك الكاميرا. استخدم أزرار الهجوم الثقيل والدفاع والمراوغة والقفل والقفز والتفاعل. استمر في الضغط على الدرع، واضغط قبل وصول الضربة مباشرة لتنفيذ صد مثالي. الكمبيوتر: WASD أو الأسهم للحركة، وسحب الفأرة للكاميرا، وSpace للقفز، وShift أو K للمراوغة، وJ أو Enter للهجوم، وH للهجوم الثقيل، وI للدفاع، وTab لقفل الهدف، وE للتفاعل، وR لإعادة المحاولة، وEsc للإيقاف المؤقت والاستئناف. اجمع شظايا الأختام المرقمة بالترتيب الظاهر؛ لكل فصل ترتيب مختلف. اهزم الزعيم بعد فتح البوابة."
		else:
			controls_notice.text = "ANDROID: Left joystick moves. Drag the right side to orbit the camera. ATTACK: tap sword. HEAVY: use the heavy-strike button. GUARD: hold shield; tap just before impact for a perfect parry. DODGE: evade to avoid damage. LOCK: lock onto a target. JUMP: clear hazards. INTERACT: collect the numbered seal fragments in the displayed order. Each chapter has a different sequence. Defeat the boss after the gate opens."
		controls_notice.text_direction = Control.TEXT_DIRECTION_RTL if arabic else Control.TEXT_DIRECTION_LTR

	var notice := find_child("CreditsNotice", true, false) as Label
	if notice != null:
		if arabic:
			notice.text = "مشروع NOVA Ancient Warrior أصلي. توليد البطل: Ara 3D Gen (MIT). بيانات الشخصية: MakeHuman (CC0 1.0). بيانات الحركة: CMU Graphics Lab Motion Capture Database.\n\nThe data used in this project was obtained from mocap.cs.cmu.edu. The database was created with funding from NSF EIA-0196217."
			notice.text_direction = Control.TEXT_DIRECTION_RTL
		else:
			notice.text = "NOVA Ancient Warrior is an original project. Hero generation: Ara 3D Gen (MIT). Character data: MakeHuman (CC0 1.0). Motion data: CMU Graphics Lab Motion Capture Database.\n\nThe data used in this project was obtained from mocap.cs.cmu.edu. The database was created with funding from NSF EIA-0196217."
			notice.text_direction = Control.TEXT_DIRECTION_LTR

	if is_instance_valid(_settings_panel):
		_settings_panel.layout_direction = Control.LAYOUT_DIRECTION_RTL if arabic else Control.LAYOUT_DIRECTION_LTR
	if is_instance_valid(_credits_panel):
		_credits_panel.layout_direction = Control.LAYOUT_DIRECTION_RTL if arabic else Control.LAYOUT_DIRECTION_LTR
	if is_instance_valid(_controls_panel):
		_controls_panel.layout_direction = Control.LAYOUT_DIRECTION_RTL if arabic else Control.LAYOUT_DIRECTION_LTR
	if is_instance_valid(_language_button):
		_language_button.text = "اللغة: العربية" if arabic else "LANGUAGE: ENGLISH"
		_language_button.text_direction = Control.TEXT_DIRECTION_RTL if arabic else Control.TEXT_DIRECTION_LTR
	_refresh_quality_button()
