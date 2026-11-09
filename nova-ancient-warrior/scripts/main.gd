extends Node3D

const PLAYER_SPEED := 5.2
const JUMP_SPEED := 7.0
const GRAVITY := 18.0
const ENEMY_SPEED := 1.65
const ATTACK_RANGE := 2.35
const ARENA_LIMIT := 16.0
const CombatRules = preload("res://scripts/combat_rules.gd")
const EnemyTactics = preload("res://scripts/enemy_tactics.gd")
const NarrativeDirector = preload("res://scripts/narrative_director.gd")
const MissionObjectiveDirector = preload("res://scripts/mission_objective_director.gd")
const ExplorationSecretDirector = preload("res://scripts/exploration_secret_director.gd")
const ExplorationPuzzleDirector = preload("res://scripts/exploration_puzzle_director.gd")
const WarriorVisual = preload("res://scripts/warrior_visual.gd")
const MusicDirector = preload("res://scripts/music_director.gd")
const CinematicDirector = preload("res://scripts/cinematic_director.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")
const StageBuilder = preload("res://scripts/stage_builder.gd")
const CampaignLayout = preload("res://scripts/campaign_layout.gd")
const MobileRenderProfile = preload("res://scripts/mobile_render_profile.gd")
const RiggedWarriorVisual = preload("res://scripts/rigged_warrior_visual.gd")
const StageHazardRules = preload("res://scripts/stage_hazard_rules.gd")
const PBRMaterialLibrary = preload("res://scripts/pbr_material_library.gd")
const TouchCameraController = preload("res://scripts/touch_camera_controller.gd")
const ThirdPersonCameraRig = preload("res://scripts/third_person_camera_rig.gd")
const NovaTouchJoystickScript = preload("res://scripts/virtual_joystick.gd")
const PauseMenuScript = preload("res://scripts/pause_menu.gd")

var player: CharacterBody3D
var hero_visual: Node3D
var camera: Camera3D
var active_chapter_scene: Node3D
var enemies: Array[Node3D] = []
var current_wave := 1
var wave_transitioning := false
var health := 100
var score := 0
var attack_cooldown := 0.0
var attack_sequence: int = 0
var combo_step := 0
var combo_display_step := 0
var combo_timer := 0.0
var dodge_remaining := 0.0
var dodge_cooldown := 0.0
var dodge_direction := Vector3.FORWARD
var game_over := false
var player_invulnerability_time := 0.0
var hud: Label
var status_label: Label
var chapter_intro_title: Label
var chapter_intro_subtitle: Label
var chapter_intro_tween: Tween
var restart_button: Button
var sound_players: Array[AudioStreamPlayer] = []
var sound_cursor := 0
var sfx_streams: Dictionary = {}
var footstep_timer := 0.0
var souls_earned := 0
var cinematic_active := false
var music_director: Node
var arena_environment: Environment
var arena_floor_material: StandardMaterial3D
var arena_sun: DirectionalLight3D
var locked_target: Node3D
var player_blocking := false
var block_window_remaining := 0.0
var built_stage_index := -1
var hazard_elapsed := 0.0
var hazard_damage_cooldown := 0.0
var hazard_warning_cooldown := 0.0
var rune_hazard_lit := false
var blade_damage_bonus := 0
var guard_damage_scale := 1.0
var upgrade_panel: PanelContainer
var upgrade_buttons: Dictionary = {}
var graphics_quality := "mid"
var quality_button: Button
var pause_menu: Control
var dialogue_panel: PanelContainer
var dialogue_speaker_label: Label
var dialogue_text_label: Label
var dialogue_next_button: Button
var dialogue_lines: Array[Dictionary] = []
var dialogue_index := -1
var dialogue_active := false
var mission_relics: Array[Node3D] = []
var exploration_cache: Node3D
var exploration_puzzle_nodes: Array[Node3D] = []
var exploration_puzzle_sequence: Array[int] = []
var exploration_puzzle_progress := 0
var exploration_puzzle_complete := false
var mission_relic_count := 0
var mission_sequence: Array[int] = []
var boss_gate_pending := false
var mission_objective_label: Label
var interact_button: Button
var touch_camera_controller := TouchCameraController.new()
const CAMERA_DISTANCE := 10.3


func _ready() -> void:
	_setup_input()
	var profile: Dictionary = _save_profile()
	graphics_quality = MobileRenderProfile.normalize_quality(str(profile.get("graphics_quality", MobileRenderProfile.QUALITY_MID)))
	var chapter_start := (int(profile.get("unlocked_chapter", 1)) - 1) * 3 + 1
	current_wave = 7 if bool(profile.get("campaign_complete", false)) else maxi(chapter_start, int(profile.get("highest_wave", 1)))
	_save_call("begin_run")
	_build_world()
	_build_player()
	_build_hud()
	_apply_gameplay_language()
	_build_enemies()
	_build_audio()
	_update_hud()


func _input(event: InputEvent) -> void:
	touch_camera_controller.set_excluded_rects(_get_touch_ui_exclusions())
	if not cinematic_active and touch_camera_controller.handle_event(event, get_viewport().get_visible_rect().size):
		get_viewport().set_input_as_handled()


func _get_touch_ui_exclusions() -> Array[Rect2]:
	var exclusions: Array[Rect2] = []
	for control in [quality_button, upgrade_panel, restart_button]:
		if is_instance_valid(control) and control.visible:
			exclusions.append(control.get_global_rect())
	if is_instance_valid(dialogue_panel) and dialogue_panel.visible:
		exclusions.append(dialogue_panel.get_global_rect())
	if is_instance_valid(interact_button) and interact_button.visible:
		exclusions.append(interact_button.get_global_rect())
	if is_instance_valid(pause_menu):
		for control_name in ["PauseButton", "PausePanel"]:
			var pause_control := pause_menu.get_node_or_null(control_name) as Control
			if is_instance_valid(pause_control) and pause_control.visible:
				exclusions.append(pause_control.get_global_rect())
	return exclusions


func _process(delta: float) -> void:
	_animate_mission_relics(delta)
	if cinematic_active:
		return
	if is_instance_valid(player) and is_instance_valid(camera):
		var look_target := player.global_position + Vector3(0.0, 1.1, 0.0)
		var orbit_distance := CAMERA_DISTANCE
		if _is_lock_target_valid():
			var midpoint: Vector3 = (player.global_position + locked_target.global_position) * 0.5
			look_target = midpoint + Vector3(0.0, 1.1, 0.0)
			orbit_distance = 12.4
		var camera_offset := touch_camera_controller.get_camera_offset(orbit_distance)
		var camera_target := look_target + camera_offset
		var camera_exclusions: Array[RID] = []
		if is_instance_valid(player):
			camera_exclusions.append(player.get_rid())
		var safe_camera_target := ThirdPersonCameraRig.resolve_position(
			get_world_3d(), look_target, camera_target, camera_exclusions
		)
		camera.global_position = camera.global_position.lerp(safe_camera_target, minf(delta * 4.5, 1.0))
		# Re-check the smoothed position so the camera cannot interpolate through a wall.
		camera.global_position = ThirdPersonCameraRig.resolve_position(
			get_world_3d(), look_target, camera.global_position, camera_exclusions
		)
		camera.look_at(look_target, Vector3.UP)
	if game_over and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	elif not game_over and Input.is_action_just_pressed("lock_on"):
		_toggle_lock_on()
	elif not game_over and Input.is_action_just_pressed("heavy_attack"):
		_attack(true)
	elif not game_over and Input.is_action_just_pressed("attack"):
		_attack(false)


func _physics_process(delta: float) -> void:
	if game_over or not is_instance_valid(player) or cinematic_active:
		return
	footstep_timer = maxf(0.0, footstep_timer - delta)
	player_invulnerability_time = maxf(0.0, player_invulnerability_time - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	dodge_remaining = maxf(0.0, dodge_remaining - delta)
	combo_timer = maxf(0.0, combo_timer - delta)
	block_window_remaining = maxf(0.0, block_window_remaining - delta)
	if combo_timer <= 0.0:
		combo_step = 0
	if Input.is_action_just_pressed("block"):
		block_window_remaining = 0.22
	var block_now := Input.is_action_pressed("block")
	if block_now != player_blocking:
		player_blocking = block_now
		if is_instance_valid(hero_visual):
			hero_visual.call("set_blocking", player_blocking)

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var camera_basis := camera.global_transform.basis
	var camera_forward := -camera_basis.z
	camera_forward.y = 0.0
	camera_forward = camera_forward.normalized()
	var camera_right := camera_basis.x
	camera_right.y = 0.0
	camera_right = camera_right.normalized()
	var direction := (camera_right * input_vector.x + camera_forward * -input_vector.y).normalized()

	if Input.is_action_just_pressed("dodge") and dodge_cooldown <= 0.0:
		dodge_direction = direction if direction.length_squared() > 0.01 else -player.global_transform.basis.z
		dodge_direction.y = 0.0
		dodge_direction = dodge_direction.normalized()
		if dodge_direction.length_squared() <= 0.01:
			dodge_direction = -player.global_transform.basis.z
		var dodge_local_direction: Vector3 = player.global_transform.basis.inverse() * dodge_direction
		dodge_remaining = 0.28
		dodge_cooldown = 0.88
		player_invulnerability_time = maxf(player_invulnerability_time, 0.42)
		_play_sfx_or_tone("dodge", 360.0, 0.09, 0.17)
		if is_instance_valid(hero_visual):
			hero_visual.call("play_dodge", dodge_local_direction)

	if dodge_remaining > 0.0:
		player.velocity.x = dodge_direction.x * 9.4
		player.velocity.z = dodge_direction.z * 9.4
		player.rotation.y = atan2(-dodge_direction.x, -dodge_direction.z)
	elif direction.length_squared() > 0.01:
		player.velocity.x = direction.x * PLAYER_SPEED
		player.velocity.z = direction.z * PLAYER_SPEED
		if not _is_lock_target_valid():
			player.rotation.y = atan2(-direction.x, -direction.z)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, PLAYER_SPEED * 5.0 * delta)
		player.velocity.z = move_toward(player.velocity.z, 0.0, PLAYER_SPEED * 5.0 * delta)

	if _is_lock_target_valid() and dodge_remaining <= 0.0:
		var target_position := locked_target.global_position
		target_position.y = player.global_position.y
		player.look_at(target_position, Vector3.UP)

	var was_on_floor := player.is_on_floor()
	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		player.velocity.y = JUMP_SPEED
		if is_instance_valid(hero_visual):
			hero_visual.call("play_jump")
		_play_sfx_or_tone("jump", 520.0, 0.08, 0.16)

	player.move_and_slide()
	if not was_on_floor and player.is_on_floor() and is_instance_valid(hero_visual):
		hero_visual.call("play_jump_land")
	var safe_position: Vector3 = player.global_position
	var previous_position: Vector3 = safe_position
	safe_position.x = clampf(safe_position.x, -ARENA_LIMIT, ARENA_LIMIT)
	safe_position.z = clampf(safe_position.z, -ARENA_LIMIT, ARENA_LIMIT)
	if not is_equal_approx(safe_position.x, previous_position.x):
		player.velocity.x = 0.0
	if not is_equal_approx(safe_position.z, previous_position.z):
		player.velocity.z = 0.0
	player.global_position = safe_position
	var planar_speed := Vector2(player.velocity.x, player.velocity.z).length()
	if player.is_on_floor() and planar_speed > 0.9 and dodge_remaining <= 0.0 and footstep_timer <= 0.0:
		_play_sfx_or_tone("footstep", 92.0, 0.07, 0.12)
		footstep_timer = 0.44
	if is_instance_valid(hero_visual):
		hero_visual.call("set_locomotion", planar_speed / PLAYER_SPEED, delta)
	_update_stage_hazards(delta)
	_update_mission_relic_interaction()
	if Input.is_action_just_pressed("interact"):
		_try_collect_mission_relic()
	_update_enemies(delta)


func _update_stage_hazards(delta: float) -> void:
	if game_over or not is_instance_valid(player):
		return
	hazard_elapsed += delta
	hazard_damage_cooldown = maxf(0.0, hazard_damage_cooldown - delta)
	hazard_warning_cooldown = maxf(0.0, hazard_warning_cooldown - delta)
	var stage_index := LevelCatalog.stage_index(current_wave)
	var hazard := StageHazardRules.query(stage_index, player.global_position, hazard_elapsed)
	var rune_pulse := stage_index == 2 and (bool(hazard.get("warning", false)) or bool(hazard.get("active", false)))
	if rune_pulse != rune_hazard_lit:
		rune_hazard_lit = rune_pulse
		StageBuilder.set_rune_intensity(active_chapter_scene if is_instance_valid(active_chapter_scene) else self, 1.0 if rune_hazard_lit else 0.0)
	if bool(hazard.get("warning", false)) and hazard_warning_cooldown <= 0.0:
		status_label.text = "تحذير: خطر في الساحة، تحرك الآن!" if _is_arabic() else "%s CHARGING - MOVE!" % str(hazard.get("label", "ARENA HAZARD"))
		_play_sfx_or_tone("hazard_warning", 720.0, 0.16, 0.20)
		hazard_warning_cooldown = 1.0
	if bool(hazard.get("active", false)) and hazard_damage_cooldown <= 0.0:
		_damage_player(int(hazard.get("damage", 10)))
		_play_sfx_or_tone("hazard_burst", 58.0, 0.24, 0.24)
		if not game_over:
			status_label.text = "أصابتك منطقة الخطر، ابتعد عنها!" if _is_arabic() else "%s HIT - GET CLEAR!" % str(hazard.get("label", "ARENA HAZARD"))
		hazard_damage_cooldown = 1.12


func _is_lock_target_valid() -> bool:
	return is_instance_valid(locked_target) and enemies.has(locked_target) and not locked_target.is_queued_for_deletion()


func _toggle_lock_on() -> void:
	if _is_lock_target_valid():
		locked_target = null
		status_label.text = "تم إلغاء تثبيت الهدف" if _is_arabic() else "TARGET LOCK RELEASED"
		_update_hud()
		return
	locked_target = null
	var nearest_distance := INF
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var distance := player.global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			locked_target = enemy
	if _is_lock_target_valid():
		status_label.text = "تم تثبيت الهدف" if _is_arabic() else "TARGET LOCKED: %s" % locked_target.name.to_upper()
	else:
		status_label.text = "لا يوجد هدف في المدى" if _is_arabic() else "NO TARGET IN RANGE"
	_update_hud()


func _save_manager() -> Node:
	return get_node_or_null("/root/SaveManager")


func _save_profile() -> Dictionary:
	var manager := _save_manager()
	if manager == null:
		return {}
	var value: Variant = manager.get("profile")
	return value if value is Dictionary else {}


func _save_call(method_name: String, arguments: Array = []) -> Variant:
	var manager := _save_manager()
	if manager == null or not manager.has_method(method_name):
		return false
	return manager.callv(method_name, arguments)


func _setup_input() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_forward", KEY_UP)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_back", KEY_DOWN)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_left", KEY_LEFT)
	_add_key_action("move_right", KEY_D)
	_add_key_action("move_right", KEY_RIGHT)
	_add_key_action("jump", KEY_SPACE)
	_add_key_action("dodge", KEY_SHIFT)
	_add_key_action("dodge", KEY_K)
	_add_key_action("attack", KEY_J)
	_add_key_action("attack", KEY_ENTER)
	_add_key_action("heavy_attack", KEY_H)
	_add_key_action("block", KEY_I)
	_add_key_action("lock_on", KEY_TAB)
	_add_key_action("interact", KEY_E)
	_add_key_action("restart", KEY_R)


func _add_key_action(action_name: String, key: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	var event := InputEventKey.new()
	event.physical_keycode = key
	InputMap.action_add_event(action_name, event)


func _build_world() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	arena_environment = env
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.035, 0.055, 0.11)
	sky_material.sky_horizon_color = Color(0.34, 0.19, 0.13)
	sky_material.ground_bottom_color = Color(0.055, 0.045, 0.04)
	sky_material.ground_horizon_color = Color(0.22, 0.12, 0.08)
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.34, 0.38, 0.52)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.35
	world.environment = env
	add_child(world)

	var sun := DirectionalLight3D.new()
	arena_sun = sun
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_color = Color(1.0, 0.72, 0.48)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)
	MobileRenderProfile.apply(OS.get_name() == "Android", env, sun, graphics_quality)

	var floor_body := StaticBody3D.new()
	floor_body.name = "ArenaFloor"
	add_child(floor_body)
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(36.0, 0.6, 36.0)
	var floor_instance := MeshInstance3D.new()
	floor_instance.mesh = floor_mesh
	floor_instance.position.y = -0.3
	arena_floor_material = _material(Color(0.22, 0.19, 0.17), 0.0, 0.9)
	floor_instance.material_override = arena_floor_material
	floor_body.add_child(floor_instance)
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = floor_mesh.size
	floor_collision.shape = floor_shape
	floor_collision.position.y = -0.3
	floor_body.add_child(floor_collision)

	var is_android := OS.get_name() == "Android"
	var render_budget := MobileRenderProfile.environment_budget(is_android, graphics_quality)
	var pillar_count := int(render_budget["pillar_count"])
	for i in range(pillar_count):
		var angle := TAU * float(i) / float(pillar_count)
		var pillar := MeshInstance3D.new()
		var pillar_mesh := CylinderMesh.new()
		pillar_mesh.top_radius = 0.48
		pillar_mesh.bottom_radius = 0.62
		pillar_mesh.height = randf_range(2.2, 3.8)
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(cos(angle) * 13.0, pillar_mesh.height * 0.5, sin(angle) * 13.0)
		pillar.material_override = _material(Color(0.28, 0.25, 0.22), 0.0, 1.0)
		add_child(pillar)

	var brazier_count := int(render_budget["brazier_count"])
	for i in range(brazier_count):
		var angle := TAU * float(i) / float(brazier_count)
		var brazier := MeshInstance3D.new()
		var brazier_mesh := CylinderMesh.new()
		brazier_mesh.top_radius = 0.36
		brazier_mesh.bottom_radius = 0.55
		brazier_mesh.height = 0.9
		brazier.mesh = brazier_mesh
		brazier.position = Vector3(cos(angle) * 9.0, 0.45, sin(angle) * 9.0)
		brazier.material_override = _material(Color(0.16, 0.14, 0.13), 0.0, 0.85)
		add_child(brazier)
		if i < int(render_budget["fire_light_count"]):
			var fire_light := OmniLight3D.new()
			fire_light.position = brazier.position + Vector3(0.0, 0.8, 0.0)
			fire_light.light_color = Color(1.0, 0.29, 0.075)
			fire_light.light_energy = 1.2
			fire_light.omni_range = 5.5
			add_child(fire_light)

	var rock_count := int(render_budget["rock_count"])
	for i in range(rock_count):
		var rock := MeshInstance3D.new()
		var rock_mesh := BoxMesh.new()
		rock_mesh.size = Vector3(randf_range(0.25, 0.8), randf_range(0.18, 0.5), randf_range(0.25, 0.8))
		rock.mesh = rock_mesh
		var angle := randf() * TAU
		var radius := randf_range(5.0, 16.0)
		rock.position = Vector3(cos(angle) * radius, rock_mesh.size.y * 0.5, sin(angle) * radius)
		rock.rotation.y = randf() * TAU
		rock.material_override = _material(Color(0.24, 0.21, 0.19), 0.0, 1.0)
		add_child(rock)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 68.0
	camera.position = Vector3(0.0, 6.3, 9.0)
	add_child(camera)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "AncientWarrior"
	player.position = Vector3(0.0, 0.15, 3.5)
	add_child(player)
	blade_damage_bonus = int(_save_profile().get("upgrade_blade", 0)) * 4
	health = 100 + int(_save_profile().get("upgrade_vitality", 0)) * 15
	guard_damage_scale = clampf(1.0 - float(_save_profile().get("upgrade_guard", 0)) * 0.12, 0.64, 1.0)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)
	if ResourceLoader.exists("res://assets/characters/nova_hero.glb"):
		hero_visual = RiggedWarriorVisual.new()
	else:
		hero_visual = WarriorVisual.new()
	hero_visual.name = "WarriorVisual"
	hero_visual.set("blade_upgrade", int(_save_profile().get("upgrade_blade", 0)))
	player.add_child(hero_visual)
	if hero_visual is RiggedWarriorVisual:
		hero_visual.rotation.y = PI


func _build_enemies() -> void:
	_spawn_wave()


func _save_checkpoint() -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager != null:
		manager.call("record_checkpoint", current_wave, score, souls_earned)


func _save_run(defeated_boss: bool) -> void:
	var manager := get_node_or_null("/root/SaveManager")
	if manager != null:
		manager.call("record_run", current_wave, score, souls_earned, defeated_boss)


func _apply_level_theme(wave: int) -> void:
	var level := LevelCatalog.get_level(wave)
	if is_instance_valid(arena_floor_material):
		arena_floor_material.albedo_color = level["floor"]
	if is_instance_valid(arena_sun):
		arena_sun.light_color = level["sun"]
		arena_sun.light_energy = float(level["sun_energy"])
	if arena_environment != null:
		arena_environment.ambient_light_color = level["ambient"]
		var sky := arena_environment.sky
		if sky != null and sky.sky_material is ProceduralSkyMaterial:
			var sky_material := sky.sky_material as ProceduralSkyMaterial
			sky_material.sky_top_color = level["sky_top"]
			sky_material.sky_horizon_color = level["sky_horizon"]
	var next_stage_index := LevelCatalog.stage_index(wave)
	if next_stage_index != built_stage_index:
		if is_instance_valid(active_chapter_scene):
			remove_child(active_chapter_scene)
			active_chapter_scene.free()
		var chapter_paths := [
			"res://scenes/chapters/sunken_ruins.tscn",
			"res://scenes/chapters/ember_causeway.tscn",
			"res://scenes/chapters/obsidian_throne.tscn"
		]
		var chapter_packed := load(chapter_paths[next_stage_index]) as PackedScene
		if chapter_packed != null:
			active_chapter_scene = chapter_packed.instantiate() as Node3D
			active_chapter_scene.name = "ActiveChapter"
			active_chapter_scene.set("graphics_quality", graphics_quality)
			add_child(active_chapter_scene)
		else:
			active_chapter_scene = null
			StageBuilder.build_stage(self, next_stage_index, graphics_quality)
			CampaignLayout.build_stage(self, next_stage_index, graphics_quality)
		built_stage_index = next_stage_index
		hazard_elapsed = 0.0
		hazard_damage_cooldown = 0.0
		hazard_warning_cooldown = 0.0
		rune_hazard_lit = false
		StageBuilder.set_rune_intensity(active_chapter_scene if is_instance_valid(active_chapter_scene) else self, 0.0)
		exploration_cache = ExplorationSecretDirector.build_stage(self, next_stage_index)
		exploration_puzzle_nodes = ExplorationPuzzleDirector.build_stage(self, next_stage_index)
		exploration_puzzle_sequence = ExplorationPuzzleDirector.sequence_for_stage(next_stage_index)
		exploration_puzzle_progress = 0
		exploration_puzzle_complete = false
		ExplorationPuzzleDirector.set_expected_order(exploration_puzzle_nodes, exploration_puzzle_sequence[0])
		if CombatRules.is_boss_wave(wave):
			MissionObjectiveDirector.clear_stage(self)
			mission_relics.clear()
			mission_sequence.clear()
			mission_relic_count = 3
		else:
			mission_relics = MissionObjectiveDirector.build_stage(self, next_stage_index)
			mission_sequence = MissionObjectiveDirector.relic_sequence(next_stage_index)
			mission_relic_count = 0
			MissionObjectiveDirector.set_expected_order(mission_relics, mission_sequence[0])
		boss_gate_pending = false


func _spawn_wave() -> void:
	_apply_level_theme(current_wave)
	if current_wave == 1 or current_wave == 4 or current_wave == 7:
		_play_chapter_intro(CombatRules.chapter_for_wave(current_wave))
	var enemy_count := CombatRules.wave_enemy_count(current_wave)
	var boss_wave := CombatRules.is_boss_wave(current_wave)
	var boss_kind := CombatRules.boss_kind_for_wave(current_wave)
	var boss_to_intro: Node3D = null
	for i in range(enemy_count):
		var enemy := Node3D.new()
		var enemy_variant := i % 3
		enemy.name = CombatRules.boss_display_name(current_wave).replace(" ", "_") if boss_wave else "AshEnemy_W%d_%d" % [current_wave, i + 1]
		enemy.position = CombatRules.wave_enemy_spawn_position(current_wave, i)
		var enemy_health := CombatRules.wave_enemy_health(current_wave)
		var enemy_speed := 1.35 if boss_wave else ENEMY_SPEED + float(CombatRules.chapter_for_wave(current_wave) - 1) * 0.16
		var enemy_damage := CombatRules.wave_enemy_damage(current_wave)
		if not boss_wave:
			if enemy_variant == 1:
				enemy_health = int(float(enemy_health) * 0.78)
				enemy_speed *= 1.32
			elif enemy_variant == 2:
				enemy_health = int(float(enemy_health) * 1.35)
				enemy_speed *= 0.78
				enemy_damage = int(float(enemy_damage) * 1.28)
		enemy.set_meta("hp", enemy_health)
		enemy.set_meta("max_hp", enemy_health)
		enemy.set_meta("base_scale", Vector3.ONE * (1.42 if boss_wave else (1.08 if enemy_variant == 2 else 1.0)))
		enemy.set_meta("speed", enemy_speed)
		enemy.set_meta("damage", enemy_damage)
		enemy.set_meta("boss", boss_wave)
		enemy.set_meta("boss_kind", boss_kind)
		enemy.set_meta("boss_phase", 1)
		enemy.set_meta("enemy_variant", enemy_variant)
		enemy.set_meta("flank_sign", -1.0 if i % 2 == 0 else 1.0)
		enemy.set_meta("windup_duration", (0.76 if boss_wave else 0.46 - float(CombatRules.chapter_for_wave(current_wave) - 1) * 0.035))
		enemy.set_meta("recovery_duration", 1.05 if boss_wave else 0.78)
		enemy.set_meta("attack_state", "approach")
		enemy.set_meta("attack_timer", 0.0)
		enemy.set_meta("attack_cooldown", randf_range(0.25, 0.85))
		var enemy_visual := WarriorVisual.new()
		enemy_visual.name = "WarriorVisual"
		enemy_visual.set("is_enemy", true)
		enemy_visual.set("is_boss", boss_wave)
		enemy_visual.set("boss_kind", boss_kind)
		enemy_visual.set("enemy_variant", enemy_variant)
		enemy.add_child(enemy_visual)
		if boss_wave:
			enemy.scale = Vector3.ONE * 1.42
			var title := Label3D.new()
			title.text = CombatRules.boss_display_name(current_wave)
			title.position = Vector3(0.0, 3.15, 0.0)
			title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			title.font_size = 40
			title.outline_size = 8
			title.modulate = Color(1.0, 0.64, 0.36) if boss_kind != "obsidian_sovereign" else Color(0.55, 0.70, 1.0)
			enemy.add_child(title)
			boss_to_intro = enemy
		add_child(enemy)
		enemies.append(enemy)
	_update_hud()
	if boss_wave and is_instance_valid(boss_to_intro):
		call_deferred("_start_boss_intro", boss_to_intro)


func _play_chapter_intro(chapter: int) -> void:
	if not is_instance_valid(chapter_intro_title) or not is_instance_valid(chapter_intro_subtitle):
		return
	var titles := [
		"",
		"CHAPTER I  |  THE SUNKEN RUINS",
		"CHAPTER II  |  THE EMBER CAUSEWAY",
		"CHAPTER III  |  THE OBSIDIAN THRONE"
	]
	var subtitles := [
		"",
		"The first seal lies beneath the drowned temple. Break the Ash Titan's guard.",
		"Cross the burning causeway. The Ember Warlord protects the second seal.",
		"The last seal waits in the frozen throne room. End the Obsidian Sovereign."
	]
	if _is_arabic():
		titles = ["", "الفصل الأول  |  الأطلال الغارقة", "الفصل الثاني  |  ممر الجمر", "الفصل الثالث  |  عرش السبج"]
		subtitles = ["", "الختم الأول يرقد تحت المعبد الغارق. اكسر دفاع عملاق الرماد.", "اعبر ممر النار. قائد الحرب النارية يحرس الختم الثاني.", "الختم الأخير ينتظر في قاعة العرش المتجمدة. أنهِ حكم سيد السبج."]
	var safe_chapter := clampi(chapter, 1, 3)
	if chapter_intro_tween != null and chapter_intro_tween.is_running():
		chapter_intro_tween.kill()
	chapter_intro_title.text = titles[safe_chapter]
	chapter_intro_subtitle.text = subtitles[safe_chapter]
	chapter_intro_title.visible = true
	chapter_intro_subtitle.visible = true
	chapter_intro_title.modulate.a = 0.0
	chapter_intro_subtitle.modulate.a = 0.0
	chapter_intro_tween = create_tween()
	chapter_intro_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	chapter_intro_tween.tween_property(chapter_intro_title, "modulate:a", 1.0, 0.45)
	chapter_intro_tween.parallel().tween_property(chapter_intro_subtitle, "modulate:a", 1.0, 0.55)
	chapter_intro_tween.tween_interval(2.0)
	chapter_intro_tween.tween_property(chapter_intro_title, "modulate:a", 0.0, 0.65)
	chapter_intro_tween.parallel().tween_property(chapter_intro_subtitle, "modulate:a", 0.0, 0.65)
	chapter_intro_tween.finished.connect(func():
		if is_instance_valid(chapter_intro_title):
			chapter_intro_title.visible = false
		if is_instance_valid(chapter_intro_subtitle):
			chapter_intro_subtitle.visible = false
		_start_dialogue(NarrativeDirector.chapter_dialogue(safe_chapter))
	)


func _start_boss_intro(boss: Node3D) -> void:
	if cinematic_active or not is_instance_valid(boss) or not is_instance_valid(player) or not is_instance_valid(camera):
		return
	cinematic_active = true
	if is_instance_valid(music_director):
		music_director.call("set_intensity", 0.9)
	_play_sfx_or_tone("boss_roar", 82.0, 0.34, 0.22)
	var return_position := player.global_position + Vector3(0.0, 6.3, 9.0)
	var return_target := player.global_position + Vector3(0.0, 1.1, 0.0)
	var reveal := CinematicDirector.play_camera_reveal(camera, boss, return_position, return_target, 3.0)
	if reveal == null:
		cinematic_active = false
		return
	reveal.finished.connect(func():
		cinematic_active = false
		if is_instance_valid(music_director):
			music_director.call("set_intensity", 0.35)
		_start_dialogue(NarrativeDirector.boss_dialogue(str(boss.get_meta("boss_kind", "ash_titan"))))
	)


func _start_dialogue(lines: Array[Dictionary]) -> void:
	if not is_instance_valid(dialogue_panel) or lines.is_empty():
		cinematic_active = false
		return
	dialogue_lines = lines.duplicate(true)
	dialogue_index = -1
	dialogue_active = true
	cinematic_active = true
	dialogue_panel.visible = true
	_advance_dialogue()


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		dialogue_panel.visible = false
		dialogue_active = false
		cinematic_active = false
		dialogue_lines.clear()
		dialogue_index = -1
		return
	_render_current_dialogue_line()


func _render_current_dialogue_line() -> void:
	if dialogue_index < 0 or dialogue_index >= dialogue_lines.size():
		return
	var line: Dictionary = dialogue_lines[dialogue_index]
	var use_arabic := _is_arabic()
	var speaker := str(line.get("speaker", ""))
	if use_arabic:
		var speakers := {
			"THE WAYFINDER": "دليل الطريق",
			"NOVA": "نوفا",
			"THE ASH TITAN": "عملاق الرماد",
			"THE EMBER WARLORD": "قائد الحرب النارية",
			"THE OBSIDIAN SOVEREIGN": "حاكم العرش الأسود"
		}
		dialogue_speaker_label.text = str(speakers.get(speaker, speaker))
		dialogue_speaker_label.text_direction = Control.TEXT_DIRECTION_RTL
		dialogue_text_label.text_direction = Control.TEXT_DIRECTION_RTL
	else:
		dialogue_speaker_label.text = speaker
		dialogue_speaker_label.text_direction = Control.TEXT_DIRECTION_LTR
		dialogue_text_label.text_direction = Control.TEXT_DIRECTION_LTR
	dialogue_text_label.text = str(line.get("text_ar", line.get("text", ""))) if use_arabic else str(line.get("text", ""))
	dialogue_next_button.text = "التالي" if use_arabic else "CONTINUE"
	dialogue_next_button.text_direction = Control.TEXT_DIRECTION_RTL if use_arabic else Control.TEXT_DIRECTION_LTR


func _animate_mission_relics(delta: float) -> void:
	var clock := float(Time.get_ticks_msec()) / 1000.0
	for relic in mission_relics:
		if not is_instance_valid(relic) or bool(relic.get_meta("collected", false)):
			continue
		var phase := float(relic.get_meta("phase", 0.0))
		relic.rotation.y += delta * 0.85
		relic.position.y = float(relic.get_meta("base_y", 0.0)) + sin(clock * 1.7 + phase) * 0.13


func _update_mission_relic_interaction() -> void:
	if not is_instance_valid(interact_button):
		return
	var nearest_distance := 3.0
	var nearby := false
	var cache_is_nearest := false
	var puzzle_is_nearest := false
	if is_instance_valid(player):
		if is_instance_valid(exploration_cache) and not bool(exploration_cache.get_meta("collected", false)):
			var cache_distance := player.global_position.distance_to(exploration_cache.global_position)
			if cache_distance <= nearest_distance:
				nearby = true
				cache_is_nearest = true
				puzzle_is_nearest = false
				nearest_distance = cache_distance
		for relic in mission_relics:
			if not is_instance_valid(relic) or bool(relic.get_meta("collected", false)):
				continue
			var distance := player.global_position.distance_to(relic.global_position)
			if distance <= nearest_distance:
				nearby = true
				cache_is_nearest = false
				puzzle_is_nearest = false
				nearest_distance = distance
		for rune in exploration_puzzle_nodes:
			if not is_instance_valid(rune) or bool(rune.get_meta("activated", false)):
				continue
			var distance := player.global_position.distance_to(rune.global_position)
			if distance <= nearest_distance:
				nearby = true
				cache_is_nearest = false
				puzzle_is_nearest = true
				nearest_distance = distance
	interact_button.visible = nearby and not cinematic_active and not game_over
	_update_mission_objective_ui()
	if nearby and cache_is_nearest:
		interact_button.text = "افتح الصندوق السري" if _is_arabic() else "OPEN SECRET CACHE"
	elif nearby and puzzle_is_nearest and exploration_puzzle_progress < exploration_puzzle_sequence.size():
		var expected_rune := exploration_puzzle_sequence[exploration_puzzle_progress]
		interact_button.text = ("فعّل الرمز %s" % _rune_roman(expected_rune)) if _is_arabic() else ("ATTUNE RUNE %s" % _rune_roman(expected_rune))


func _try_collect_mission_relic() -> void:
	if not is_instance_valid(player) or cinematic_active or game_over:
		return
	var nearest: Node3D = null
	var nearest_distance := 3.0
	var nearest_is_puzzle := false
	if is_instance_valid(exploration_cache) and not bool(exploration_cache.get_meta("collected", false)):
		var cache_distance := player.global_position.distance_to(exploration_cache.global_position)
		if cache_distance <= nearest_distance:
			nearest = exploration_cache
			nearest_is_puzzle = false
			nearest_distance = cache_distance
	for relic in mission_relics:
		if not is_instance_valid(relic) or bool(relic.get_meta("collected", false)):
			continue
		var distance := player.global_position.distance_to(relic.global_position)
		if distance <= nearest_distance:
			nearest = relic
			nearest_is_puzzle = false
			nearest_distance = distance
	for rune in exploration_puzzle_nodes:
		if not is_instance_valid(rune) or bool(rune.get_meta("activated", false)):
			continue
		var distance := player.global_position.distance_to(rune.global_position)
		if distance <= nearest_distance:
			nearest = rune
			nearest_is_puzzle = true
			nearest_distance = distance
	if nearest == null:
		return
	if nearest == exploration_cache:
		if ExplorationSecretDirector.collect(exploration_cache):
			score += 450
			souls_earned += 18
			_save_checkpoint()
			status_label.text = "عثرت على كنز مخفي! +450 نقطة و18 روحاً" if _is_arabic() else "SECRET CACHE FOUND! +450 SCORE AND 18 SOULS"
			_play_sfx_or_tone("upgrade", 880.0, 0.22, 0.22)
			_update_hud()
			_update_mission_relic_interaction()
		return
	if nearest_is_puzzle:
		if exploration_puzzle_complete or exploration_puzzle_progress >= exploration_puzzle_sequence.size():
			return
		var found_rune := int(nearest.get_meta("rune_index", 0))
		var evaluation: Dictionary = ExplorationPuzzleDirector.evaluate_rune(found_rune, exploration_puzzle_progress, exploration_puzzle_sequence)
		if not bool(evaluation.get("accepted", false)):
			status_label.text = "الرمز مرفوض | اتبع ترتيب النقش" if _is_arabic() else "RUNE REJECTED | FOLLOW THE INSCRIBED ORDER"
			_play_tone(145.0, 0.10, 0.14)
			return
		if not ExplorationPuzzleDirector.activate(nearest):
			return
		exploration_puzzle_progress = int(evaluation.get("progress", exploration_puzzle_progress))
		if not bool(evaluation.get("solved", false)):
			ExplorationPuzzleDirector.set_expected_order(exploration_puzzle_nodes, int(evaluation.get("expected", 0)))
			status_label.text = ("تمت مزامنة الرمز %d/3" % exploration_puzzle_progress) if _is_arabic() else ("RUNE SYNCHRONIZED %d/3" % exploration_puzzle_progress)
		else:
			exploration_puzzle_complete = true
			var puzzle_root := get_node_or_null(ExplorationPuzzleDirector.ROOT_NAME)
			if puzzle_root != null:
				puzzle_root.set_meta("solved", true)
			score += 700
			souls_earned += 24
			_save_checkpoint()
			status_label.text = "حُلّ لغز الرنين القديم! +700 نقطة و24 روحاً" if _is_arabic() else "ANCIENT RESONANCE SOLVED! +700 SCORE AND 24 SOULS"
			_play_sfx_or_tone("upgrade", 1040.0, 0.28, 0.24)
			_update_hud()
		_update_mission_relic_interaction()
		return
	var expected_order := mission_sequence[mission_relic_count] if mission_relic_count < mission_sequence.size() else 0
	var found_order := int(nearest.get_meta("sequence_order", 0))
	if found_order != expected_order:
		status_label.text = "تم رفض الختم | اتبع الترتيب المحفور" if TranslationServer.get_locale().begins_with("ar") else "SEAL REJECTED  |  FOLLOW THE CARVED ORDER"
		_play_tone(145.0, 0.10, 0.14)
		return
	if not MissionObjectiveDirector.collect(nearest):
		return
	mission_relic_count = mini(3, mission_relic_count + 1)
	if mission_relic_count < mission_sequence.size():
		MissionObjectiveDirector.set_expected_order(mission_relics, mission_sequence[mission_relic_count])
	_play_sfx_or_tone("upgrade", 640.0 + float(mission_relic_count) * 100.0, 0.12, 0.18)
	status_label.text = ("تم استرجاع جزء الختم  |  %d/3" % mission_relic_count) if TranslationServer.get_locale().begins_with("ar") else ("SEAL FRAGMENT RECOVERED  |  %d/3" % mission_relic_count)
	_update_mission_objective_ui()
	if mission_relic_count >= 3 and boss_gate_pending:
		_release_boss_gate()


func _rune_roman(value: int) -> String:
	match value:
		1:
			return "I"
		2:
			return "II"
		_:
			return "III"


func _update_mission_objective_ui() -> void:
	if not is_instance_valid(mission_objective_label):
		return
	if mission_relics.is_empty():
		mission_objective_label.visible = false
		return
	mission_objective_label.visible = mission_relic_count < 3 or boss_gate_pending
	var order_text := "%d → %d → %d" % [mission_sequence[0], mission_sequence[1], mission_sequence[2]] if mission_sequence.size() >= 3 else "-"
	var use_arabic := TranslationServer.get_locale().begins_with("ar")
	mission_objective_label.text_direction = Control.TEXT_DIRECTION_RTL if use_arabic else Control.TEXT_DIRECTION_LTR
	if is_instance_valid(interact_button):
		interact_button.text = "تفاعل" if use_arabic else "INTERACT"
	if use_arabic and boss_gate_pending:
		mission_objective_label.text = "بوابة الزعيم مغلقة  |  ترتيب الأختام %s  |  %d/3" % [order_text, mission_relic_count]
	elif use_arabic and mission_relic_count < 3:
		mission_objective_label.text = "لغز الأختام  |  الترتيب %s  |  %d/3  |  اقترب واضغط تفاعل" % [order_text, mission_relic_count]
	elif boss_gate_pending:
		mission_objective_label.text = "BOSS GATE SEALED  |  SEAL ORDER %s  |  %d/3" % [order_text, mission_relic_count]
	elif mission_relic_count < 3:
		mission_objective_label.text = "SEAL PUZZLE  |  ORDER %s  |  %d/3  |  APPROACH AND INTERACT" % [order_text, mission_relic_count]
	else:
		mission_objective_label.visible = false


func _release_boss_gate() -> void:
	if not boss_gate_pending or mission_relic_count < 3 or wave_transitioning or game_over:
		return
	boss_gate_pending = false
	wave_transitioning = true
	status_label.text = "اكتملت الأختام الثلاثة | فُتحت بوابة الزعيم" if TranslationServer.get_locale().begins_with("ar") else "THREE SEALS RESTORED  |  THE BOSS GATE OPENS"
	_update_mission_objective_ui()
	get_tree().create_timer(0.9).timeout.connect(func():
		if game_over or not is_inside_tree():
			return
		current_wave += 1
		_save_checkpoint()
		_spawn_wave()
		wave_transitioning = false
		status_label.text = LevelCatalog.wave_title(current_wave)
		_update_hud()
		_play_tone(620.0, 0.18, 0.2)
	)


func _handle_wave_cleared() -> void:
	if wave_transitioning or game_over:
		return
	var cleared_wave := current_wave
	_save_checkpoint()
	if CombatRules.is_boss_wave(cleared_wave):
		_save_call("record_boss_victory", [cleared_wave])
		if is_instance_valid(music_director):
			music_director.call("set_intensity", 0.24)
	if cleared_wave % 3 == 2 and mission_relic_count < 3:
		boss_gate_pending = true
		wave_transitioning = false
		status_label.text = "بوابة الزعيم مغلقة | استرجع أجزاء الأختام الثلاثة" if TranslationServer.get_locale().begins_with("ar") else "BOSS GATE SEALED  |  RECOVER THE THREE SEAL FRAGMENTS"
		_update_mission_objective_ui()
		return
	if cleared_wave >= CombatRules.CAMPAIGN_WAVES:
		game_over = true
		_save_run(true)
		status_label.text = "سقط حاكم العرش الأسود | اكتملت الحملة" if _is_arabic() else "THE OBSIDIAN SOVEREIGN HAS FALLEN | CAMPAIGN COMPLETE"
		restart_button.text = "إعادة الفصل الأخير" if _is_arabic() else "REPLAY FINAL CHAPTER"
		restart_button.visible = true
		upgrade_panel.visible = true
		_refresh_upgrade_panel()
		if is_instance_valid(pause_menu):
			pause_menu.call("set_pause_available", false)
		_play_sfx_or_tone("victory", 880.0, 0.3, 0.22)
		return
	wave_transitioning = true
	if CombatRules.is_boss_wave(cleared_wave):
		status_label.text = ("%s هُزم | فُتح الفصل %d" % [_localized_boss_name(cleared_wave), CombatRules.chapter_for_wave(cleared_wave) + 1]) if _is_arabic() else "%s DEFEATED | CHAPTER %d UNLOCKED" % [CombatRules.boss_display_name(cleared_wave), CombatRules.chapter_for_wave(cleared_wave) + 1]
	else:
		status_label.text = ("تم اجتياز الموجة %d | استعد للهجوم التالي" % cleared_wave) if _is_arabic() else "WAVE %d CLEARED | PREPARE FOR THE NEXT ATTACK" % cleared_wave
	_play_tone(660.0, 0.18, 0.18)
	var transition := get_tree().create_timer(1.65)
	transition.timeout.connect(func():
		if game_over or not is_inside_tree():
			return
		current_wave += 1
		_save_checkpoint()
		_spawn_wave()
		wave_transitioning = false
		status_label.text = LevelCatalog.wave_title(current_wave)
		_update_hud()
		_play_tone(520.0 + float(CombatRules.chapter_for_wave(current_wave)) * 100.0, 0.14, 0.18)
	)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.anchor_left = 0.02
	hud.anchor_right = 0.98
	hud.offset_left = 0.0
	hud.offset_right = 0.0
	hud.offset_top = 14.0
	hud.offset_bottom = 48.0
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_theme_font_size_override("font_size", 18)
	hud.add_theme_color_override("font_color", Color(1.0, 0.84, 0.58))
	layer.add_child(hud)
	status_label = Label.new()
	status_label.anchor_left = 0.04
	status_label.anchor_right = 0.96
	status_label.offset_left = 0.0
	status_label.offset_right = 0.0
	status_label.offset_top = 50.0
	status_label.offset_bottom = 78.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(0.92, 0.84, 0.72))
	status_label.text = LevelCatalog.wave_title(current_wave)
	layer.add_child(status_label)
	mission_objective_label = Label.new()
	mission_objective_label.anchor_left = 0.08
	mission_objective_label.anchor_right = 0.92
	mission_objective_label.offset_left = 0.0
	mission_objective_label.offset_right = 0.0
	mission_objective_label.offset_top = 82.0
	mission_objective_label.offset_bottom = 112.0
	mission_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_objective_label.add_theme_font_size_override("font_size", 16)
	mission_objective_label.add_theme_color_override("font_color", Color(0.48, 0.88, 1.0))
	mission_objective_label.visible = false
	layer.add_child(mission_objective_label)
	chapter_intro_title = Label.new()
	chapter_intro_title.name = "ChapterIntroTitle"
	chapter_intro_title.anchor_left = 0.5
	chapter_intro_title.anchor_right = 0.5
	chapter_intro_title.anchor_top = 0.29
	chapter_intro_title.anchor_bottom = 0.29
	chapter_intro_title.offset_left = -360.0
	chapter_intro_title.offset_right = 360.0
	chapter_intro_title.offset_top = 0.0
	chapter_intro_title.offset_bottom = 54.0
	chapter_intro_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_intro_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chapter_intro_title.add_theme_font_size_override("font_size", 31)
	chapter_intro_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.55))
	chapter_intro_title.add_theme_color_override("font_shadow_color", Color(0.01, 0.01, 0.015, 0.95))
	chapter_intro_title.add_theme_constant_override("shadow_offset_x", 2)
	chapter_intro_title.add_theme_constant_override("shadow_offset_y", 2)
	chapter_intro_title.visible = false
	layer.add_child(chapter_intro_title)
	chapter_intro_subtitle = Label.new()
	chapter_intro_subtitle.name = "ChapterIntroSubtitle"
	chapter_intro_subtitle.anchor_left = 0.5
	chapter_intro_subtitle.anchor_right = 0.5
	chapter_intro_subtitle.anchor_top = 0.29
	chapter_intro_subtitle.anchor_bottom = 0.29
	chapter_intro_subtitle.offset_left = -390.0
	chapter_intro_subtitle.offset_right = 390.0
	chapter_intro_subtitle.offset_top = 58.0
	chapter_intro_subtitle.offset_bottom = 105.0
	chapter_intro_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_intro_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chapter_intro_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chapter_intro_subtitle.add_theme_font_size_override("font_size", 17)
	chapter_intro_subtitle.add_theme_color_override("font_color", Color(0.91, 0.85, 0.76))
	chapter_intro_subtitle.visible = false
	layer.add_child(chapter_intro_subtitle)

	dialogue_panel = PanelContainer.new()
	dialogue_panel.name = "DialoguePanel"
	dialogue_panel.anchor_left = 0.5
	dialogue_panel.anchor_right = 0.5
	dialogue_panel.anchor_top = 0.53
	dialogue_panel.anchor_bottom = 0.53
	dialogue_panel.offset_left = -350.0
	dialogue_panel.offset_right = 350.0
	dialogue_panel.offset_top = 0.0
	dialogue_panel.offset_bottom = 150.0
	dialogue_panel.visible = false
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dialogue_panel)
	var dialogue_box := VBoxContainer.new()
	dialogue_box.add_theme_constant_override("separation", 7)
	dialogue_panel.add_child(dialogue_box)
	dialogue_speaker_label = Label.new()
	dialogue_speaker_label.name = "DialogueSpeaker"
	dialogue_speaker_label.add_theme_font_size_override("font_size", 15)
	dialogue_speaker_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.42))
	dialogue_box.add_child(dialogue_speaker_label)
	dialogue_text_label = Label.new()
	dialogue_text_label.name = "DialogueText"
	dialogue_text_label.add_theme_font_size_override("font_size", 18)
	dialogue_text_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.87))
	dialogue_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text_label.custom_minimum_size = Vector2(0.0, 66.0)
	dialogue_box.add_child(dialogue_text_label)
	dialogue_next_button = Button.new()
	dialogue_next_button.name = "DialogueNextButton"
	dialogue_next_button.text = "CONTINUE"
	dialogue_next_button.custom_minimum_size = Vector2(150.0, 38.0)
	dialogue_next_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	dialogue_next_button.pressed.connect(_advance_dialogue)
	dialogue_box.add_child(dialogue_next_button)

	var virtual_stick := NovaTouchJoystickScript.new()
	virtual_stick.name = "MovementJoystick"
	virtual_stick.anchor_left = 0.0
	virtual_stick.anchor_right = 0.0
	virtual_stick.anchor_top = 1.0
	virtual_stick.anchor_bottom = 1.0
	virtual_stick.offset_left = 20.0
	virtual_stick.offset_right = 200.0
	virtual_stick.offset_top = -200.0
	virtual_stick.offset_bottom = -20.0
	layer.add_child(virtual_stick)
	_add_touch_button(layer, "ATTACK", "attack", Vector2(-168.0, -126.0), Vector2(150.0, 72.0), true)
	_add_touch_button(layer, "HEAVY", "heavy_attack", Vector2(-312.0, -126.0), Vector2(132.0, 62.0), true)
	_add_touch_button(layer, "JUMP", "jump", Vector2(-168.0, -210.0), Vector2(112.0, 64.0), true)
	_add_touch_button(layer, "LOCK", "lock_on", Vector2(-312.0, -210.0), Vector2(112.0, 56.0), true)
	_add_touch_button(layer, "DODGE", "dodge", Vector2(-168.0, -48.0), Vector2(132.0, 56.0), true)
	_add_touch_button(layer, "BLOCK", "block", Vector2(-312.0, -48.0), Vector2(132.0, 56.0), true)
	interact_button = Button.new()
	interact_button.name = "InteractButton"
	interact_button.text = "INTERACT"
	interact_button.focus_mode = Control.FOCUS_NONE
	interact_button.custom_minimum_size = Vector2(132.0, 48.0)
	interact_button.anchor_left = 1.0
	interact_button.anchor_right = 1.0
	interact_button.anchor_top = 1.0
	interact_button.anchor_bottom = 1.0
	interact_button.offset_left = -312.0
	interact_button.offset_right = -180.0
	interact_button.offset_top = -278.0
	interact_button.offset_bottom = -230.0
	interact_button.visible = false
	interact_button.button_down.connect(func(): Input.action_press("interact"))
	interact_button.button_up.connect(func(): Input.action_release("interact"))
	layer.add_child(interact_button)
	restart_button = Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "RESTART"
	restart_button.visible = false
	restart_button.focus_mode = Control.FOCUS_NONE
	restart_button.custom_minimum_size = Vector2(220.0, 64.0)
	restart_button.anchor_left = 0.5
	restart_button.anchor_right = 0.5
	restart_button.anchor_top = 0.84
	restart_button.anchor_bottom = 0.84
	restart_button.offset_left = -110.0
	restart_button.offset_right = 110.0
	restart_button.offset_top = 0.0
	restart_button.offset_bottom = 64.0
	restart_button.add_theme_font_size_override("font_size", 22)
	restart_button.add_theme_color_override("font_color", Color(1.0, 0.88, 0.7))
	restart_button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.13, 0.16, 0.92)))
	restart_button.add_theme_stylebox_override("pressed", _button_style(Color(0.55, 0.23, 0.1, 0.98)))
	restart_button.button_down.connect(func(): Input.action_press("restart"))
	restart_button.button_up.connect(func(): Input.action_release("restart"))
	layer.add_child(restart_button)
	upgrade_panel = PanelContainer.new()
	upgrade_panel.name = "PermanentUpgradePanel"
	upgrade_panel.visible = false
	upgrade_panel.anchor_left = 0.5
	upgrade_panel.anchor_right = 0.5
	upgrade_panel.anchor_top = 0.42
	upgrade_panel.anchor_bottom = 0.42
	upgrade_panel.offset_left = -190.0
	upgrade_panel.offset_right = 190.0
	upgrade_panel.offset_top = -112.0
	upgrade_panel.offset_bottom = 126.0
	upgrade_panel.add_theme_stylebox_override("panel", _button_style(Color(0.045, 0.055, 0.075, 0.96)))
	var upgrade_list := VBoxContainer.new()
	upgrade_list.add_theme_constant_override("separation", 8)
	upgrade_panel.add_child(upgrade_list)
	var upgrade_heading := Label.new()
	upgrade_heading.text = "SOUL FORGE  |  PERMANENT UPGRADES"
	upgrade_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_heading.add_theme_font_size_override("font_size", 16)
	upgrade_heading.add_theme_color_override("font_color", Color(1.0, 0.82, 0.52))
	upgrade_list.add_child(upgrade_heading)
	for upgrade_name in ["blade", "vitality", "guard"]:
		var upgrade_button := Button.new()
		upgrade_button.custom_minimum_size = Vector2(340.0, 48.0)
		upgrade_button.focus_mode = Control.FOCUS_NONE
		upgrade_button.add_theme_font_size_override("font_size", 16)
		upgrade_button.add_theme_stylebox_override("normal", _button_style(Color(0.13, 0.14, 0.18, 0.98)))
		upgrade_button.pressed.connect(_purchase_upgrade.bind(upgrade_name))
		upgrade_buttons[upgrade_name] = upgrade_button
		upgrade_list.add_child(upgrade_button)
	layer.add_child(upgrade_panel)
	_refresh_upgrade_panel()
	var hint := Label.new()
	hint.name = "CombatHint"
	hint.anchor_left = 0.5
	hint.anchor_right = 0.5
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = -180.0
	hint.offset_right = 180.0
	hint.offset_top = -34.0
	hint.offset_bottom = -8.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "تحرك  |  J هجوم  |  H ثقيل  |  I صد  |  TAB تثبيت  |  SHIFT مراوغة" if _is_arabic() else "MOVE  |  J ATTACK  |  H HEAVY  |  I BLOCK  |  TAB LOCK  |  SHIFT DODGE"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.72, 0.68, 0.61))
	layer.add_child(hint)

	quality_button = Button.new()
	quality_button.name = "GraphicsQualityButton"
	quality_button.anchor_left = 1.0
	quality_button.anchor_right = 1.0
	quality_button.offset_left = -220.0
	quality_button.offset_right = -18.0
	quality_button.offset_top = 18.0
	quality_button.offset_bottom = 62.0
	quality_button.focus_mode = Control.FOCUS_NONE
	quality_button.custom_minimum_size = Vector2(202.0, 44.0)
	quality_button.add_theme_font_size_override("font_size", 17)
	quality_button.add_theme_color_override("font_color", Color(0.94, 0.84, 0.66))
	quality_button.add_theme_stylebox_override("normal", _button_style(Color(0.08, 0.10, 0.15, 0.90)))
	quality_button.add_theme_stylebox_override("pressed", _button_style(Color(0.34, 0.20, 0.10, 0.96)))
	quality_button.pressed.connect(_cycle_graphics_quality)
	layer.add_child(quality_button)
	_refresh_quality_button()

	pause_menu = PauseMenuScript.new()
	pause_menu.name = "PauseMenu"
	pause_menu.pause_requested.connect(_on_pause_requested)
	pause_menu.resume_requested.connect(_on_resume_requested)
	pause_menu.audio_settings_changed.connect(_on_audio_settings_changed)
	pause_menu.language_changed.connect(_on_language_changed)
	layer.add_child(pause_menu)


func _localized_touch_caption(action: String, fallback: String) -> String:
	if not _is_arabic():
		return fallback
	var captions := {"attack": "هجوم", "heavy_attack": "ثقيل", "jump": "قفز", "lock_on": "تثبيت", "dodge": "مراوغة", "block": "صد"}
	return str(captions.get(action, fallback))


func _apply_gameplay_language() -> void:
	var arabic := _is_arabic()
	var hint := find_child("CombatHint", true, false) as Label
	if hint != null:
		hint.text = "تحرك  |  J هجوم  |  H ثقيل  |  I صد  |  TAB تثبيت  |  SHIFT مراوغة" if arabic else "MOVE  |  J ATTACK  |  H HEAVY  |  I BLOCK  |  TAB LOCK  |  SHIFT DODGE"
		hint.text_direction = Control.TEXT_DIRECTION_RTL if arabic else Control.TEXT_DIRECTION_LTR
	for action in ["attack", "heavy_attack", "jump", "lock_on", "dodge", "block"]:
		var button := find_child("Touch_" + action, true, false) as Button
		if button != null:
			var captions := {"attack": "ATTACK", "heavy_attack": "HEAVY", "jump": "JUMP", "lock_on": "LOCK", "dodge": "DODGE", "block": "BLOCK"}
			button.text = _localized_touch_caption(action, str(captions[action]))
			button.text_direction = Control.TEXT_DIRECTION_RTL if arabic else Control.TEXT_DIRECTION_LTR
	if is_instance_valid(interact_button):
		interact_button.text = "تفاعل" if arabic else "INTERACT"
		interact_button.text_direction = Control.TEXT_DIRECTION_RTL if arabic else Control.TEXT_DIRECTION_LTR
	if is_instance_valid(restart_button):
		restart_button.text = "إعادة المحاولة" if arabic else "RESTART"
	if is_instance_valid(dialogue_panel):
		dialogue_panel.layout_direction = Control.LAYOUT_DIRECTION_RTL if arabic else Control.LAYOUT_DIRECTION_LTR
	if is_instance_valid(upgrade_panel):
		_refresh_upgrade_panel()
	_refresh_quality_button()
	_update_hud()


func _add_touch_button(layer: CanvasLayer, caption: String, action: String, offset: Vector2, size: Vector2 = Vector2(92.0, 82.0), right_side: bool = false) -> void:
	var button := Button.new()
	button.name = "Touch_" + action
	button.text = _localized_touch_caption(action, caption)
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = size
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	if right_side:
		button.anchor_left = 1.0
		button.anchor_right = 1.0
		button.offset_left = offset.x
		button.offset_right = offset.x + size.x
	else:
		button.anchor_left = 0.0
		button.anchor_right = 0.0
		button.offset_left = offset.x
		button.offset_right = offset.x + size.x
	button.offset_top = offset.y
	button.offset_bottom = offset.y + size.y
	button.add_theme_font_size_override("font_size", 19 if right_side else 27)
	button.add_theme_color_override("font_color", Color(1.0, 0.88, 0.7))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.12, 0.13, 0.16, 0.82)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.55, 0.23, 0.1, 0.95)))
	button.button_down.connect(func(): Input.action_press(action))
	button.button_up.connect(func(): Input.action_release(action))
	layer.add_child(button)


func _on_pause_requested() -> void:
	if game_over or not is_instance_valid(pause_menu):
		return
	get_tree().paused = true
	pause_menu.call("set_paused", true)
	if is_instance_valid(status_label):
		status_label.text = "متوقف مؤقتاً" if _is_arabic() else "PAUSED"


func _on_resume_requested() -> void:
	get_tree().paused = false
	if is_instance_valid(pause_menu):
		pause_menu.call("set_paused", false)
	if is_instance_valid(status_label):
		status_label.text = LevelCatalog.wave_title(current_wave)


func _on_language_changed(_language: String) -> void:
	_apply_gameplay_language()
	if dialogue_active and dialogue_index >= 0 and dialogue_index < dialogue_lines.size():
		_render_current_dialogue_line()
	elif is_instance_valid(status_label):
		var paused := is_instance_valid(pause_menu) and bool(pause_menu.call("is_paused"))
		status_label.text = ("متوقف مؤقتاً" if _is_arabic() else "PAUSED") if paused else LevelCatalog.wave_title(current_wave)


func _on_audio_settings_changed(music_volume: float, sfx_volume: float) -> void:
	_save_call("set_audio_options", [music_volume, sfx_volume])
	if is_instance_valid(music_director) and music_director.has_method("set_music_volume"):
		music_director.call("set_music_volume", music_volume)
	var gain_db := linear_to_db(maxf(sfx_volume, 0.0001)) - 5.0
	for voice in sound_players:
		if is_instance_valid(voice):
			voice.volume_db = gain_db


func _cycle_graphics_quality() -> void:
	graphics_quality = MobileRenderProfile.QUALITY_HIGH if graphics_quality == MobileRenderProfile.QUALITY_MID else MobileRenderProfile.QUALITY_MID
	_save_call("set_graphics_quality", [graphics_quality])
	if arena_environment != null and is_instance_valid(arena_sun):
		MobileRenderProfile.apply(OS.get_name() == "Android", arena_environment, arena_sun, graphics_quality)
	_refresh_quality_button()
	if is_instance_valid(status_label):
		status_label.text = ("جودة الرسوم: %s | يتغير مستوى التفاصيل بعد إعادة التشغيل" % ("مرتفعة" if graphics_quality == "high" else "متوسطة")) if _is_arabic() else "GRAPHICS: %s | DETAIL COUNT UPDATES AFTER RESTART" % graphics_quality.to_upper()


func _refresh_quality_button() -> void:
	if is_instance_valid(quality_button):
		quality_button.text = ("جودة الرسوم: مرتفعة" if graphics_quality == MobileRenderProfile.QUALITY_HIGH else "جودة الرسوم: متوسطة") if _is_arabic() else "QUALITY: %s" % graphics_quality.to_upper()
		quality_button.text_direction = Control.TEXT_DIRECTION_RTL if _is_arabic() else Control.TEXT_DIRECTION_LTR


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.74, 0.48, 0.24, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style


func _update_enemies(delta: float) -> void:
	if game_over or not is_instance_valid(player):
		return
	for index in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[index]
		if not is_instance_valid(enemy):
			enemies.remove_at(index)
			if locked_target == enemy:
				locked_target = null
			continue
		var offset: Vector3 = player.global_position - enemy.global_position
		offset.y = 0.0
		var distance: float = offset.length()
		var enemy_speed := float(enemy.get_meta("speed", ENEMY_SPEED))
		if distance > 0.001:
			enemy.look_at(Vector3(player.global_position.x, enemy.global_position.y, player.global_position.z), Vector3.UP)
		var visual := enemy.get_node_or_null("WarriorVisual")
		var is_boss := bool(enemy.get_meta("boss", false))
		var boss_kind := str(enemy.get_meta("boss_kind", "ash_titan"))
		var hp := int(enemy.get_meta("hp", 60))
		var max_hp := int(enemy.get_meta("max_hp", maxi(1, hp)))
		var phase := CombatRules.boss_phase(hp, max_hp) if is_boss else 1
		var previous_phase := int(enemy.get_meta("boss_phase", 1))
		if is_boss and phase != previous_phase:
			enemy.set_meta("boss_phase", phase)
			enemy.set_meta("speed", enemy_speed * 1.12)
			if visual != null:
				visual.call("phase_change", phase)
			if is_instance_valid(music_director):
				music_director.call("set_intensity", 0.68 if phase == 2 else 1.0)
			status_label.text = ("%s | المرحلة %d" % [_localized_boss_name(current_wave), phase]) if _is_arabic() else "%s | PHASE %d" % [CombatRules.boss_display_name(current_wave), phase]

		var attack_state := str(enemy.get_meta("attack_state", "approach"))
		var attack_timer := maxf(0.0, float(enemy.get_meta("attack_timer", 0.0)))
		var attack_cooldown_value := maxf(0.0, float(enemy.get_meta("attack_cooldown", 0.0)) - delta)
		if attack_state == "approach":
			var desired_range := 1.85
			if is_boss:
				match boss_kind:
					"ember_warlord":
						desired_range = 5.0
					"obsidian_sovereign":
						desired_range = 4.8
					_:
						desired_range = 2.1
			var tactical_plan: Dictionary = EnemyTactics.plan_movement(
				distance,
				desired_range,
				attack_cooldown_value,
				int(enemy.get_meta("enemy_variant", 0)),
				is_boss,
				phase,
				float(enemy.get_meta("flank_sign", 1.0))
			)
			var tactical_action := str(tactical_plan.get("action", EnemyTactics.ACTION_APPROACH))
			if tactical_action == EnemyTactics.ACTION_APPROACH or tactical_action == EnemyTactics.ACTION_FLANK:
				var movement_direction: Vector3 = EnemyTactics.movement_direction(
					offset,
					float(tactical_plan.get("lateral_weight", 0.0))
				)
				var chase_speed := enemy_speed * float(tactical_plan.get("speed_scale", 1.0))
				if is_boss and boss_kind == "ember_warlord":
					chase_speed *= 1.18
				enemy.global_position += movement_direction * chase_speed * delta
				if visual != null:
					visual.call("set_locomotion", 0.52 if tactical_action == EnemyTactics.ACTION_APPROACH else 0.38, delta)
			elif tactical_action == EnemyTactics.ACTION_WINDUP:
				attack_state = "windup"
				var windup := float(enemy.get_meta("windup_duration", 0.42))
				if is_boss and phase >= 2:
					windup *= 0.82
				attack_timer = windup
				if visual != null:
					visual.call("telegraph", true)
			elif visual != null:
				visual.call("set_locomotion", 0.0, delta)
		elif attack_state == "windup":
			attack_timer = maxf(0.0, attack_timer - delta)
			if attack_timer <= 0.0:
				if visual != null:
					if is_boss:
						visual.call("play_heavy_attack")
					else:
						visual.call("play_attack", 0)
				var damage := int(enemy.get_meta("damage", 9))
				var hit_range := 2.0
				if is_boss:
					hit_range = CombatRules.boss_attack_range(boss_kind, phase)
					match boss_kind:
						"ember_warlord":
							if distance <= hit_range:
								enemy.global_position += offset.normalized() * minf(3.0, maxf(0.0, distance - 1.15))
						"obsidian_sovereign":
							damage += 8 if phase >= 2 else 0
						_:
							damage += 5 if phase >= 2 else 0
					if phase == 3:
						damage = int(float(damage) * 1.25)
				if distance <= hit_range:
					_damage_player(damage, enemy)
					_play_sfx_or_tone("heavy_swing" if is_boss else "sword_swing", 125.0 if not is_boss else (78.0 if boss_kind == "obsidian_sovereign" else 92.0), 0.16, 0.22)
				attack_state = "recovery"
				attack_timer = float(enemy.get_meta("recovery_duration", 0.78))
				if is_boss and phase >= 2:
					attack_timer *= 0.82
				if visual != null:
					visual.call("telegraph", false)
				if game_over:
					break
		elif attack_state == "recovery":
			attack_timer = maxf(0.0, attack_timer - delta)
			if attack_timer <= 0.0:
				attack_state = "approach"
				attack_cooldown_value = 0.28 if not is_boss else (0.75 if phase == 1 else 0.55)
		enemy.set_meta("attack_state", attack_state)
		enemy.set_meta("attack_timer", attack_timer)
		enemy.set_meta("attack_cooldown", attack_cooldown_value)


func _attack(heavy: bool = false) -> void:
	if attack_cooldown > 0.0 or game_over or wave_transitioning:
		return
	var current_step := combo_step
	var damage := CombatRules.heavy_attack_damage() if heavy else CombatRules.combo_damage(current_step)
	damage += blade_damage_bonus
	var attack_range_value := CombatRules.heavy_attack_range() if heavy else CombatRules.combo_range(current_step)
	attack_cooldown = CombatRules.heavy_attack_cooldown() if heavy else CombatRules.combo_cooldown(current_step)
	attack_sequence += 1
	var sequence: int = attack_sequence
	if not heavy:
		combo_display_step = current_step
		combo_step = (combo_step + 1) % 3
		combo_timer = 1.05
	if is_instance_valid(hero_visual):
		if heavy:
			hero_visual.call("play_heavy_attack")
		else:
			hero_visual.call("play_attack", current_step)
	_play_sfx_or_tone("heavy_swing" if heavy else "sword_swing", 560.0 if heavy else 740.0 + float(current_step) * 90.0, 0.14 if heavy else 0.11, 0.22)
	_resolve_attack_window(sequence, heavy, current_step, damage, attack_range_value)


func _resolve_attack_window(sequence: int, heavy: bool, current_step: int, damage: int, attack_range_value: float) -> void:
	await get_tree().create_timer(CombatRules.attack_startup(heavy, current_step)).timeout
	if not is_inside_tree() or sequence != attack_sequence or game_over or wave_transitioning:
		return
	var already_hit: Dictionary = {}
	var active_end_usec := Time.get_ticks_usec() + int(CombatRules.attack_active_duration(heavy) * 1000000.0)
	while Time.get_ticks_usec() < active_end_usec:
		if not is_inside_tree() or sequence != attack_sequence or game_over or wave_transitioning or not is_instance_valid(player):
			return
		_apply_attack_hits(heavy, damage, attack_range_value, already_hit)
		await get_tree().physics_frame


func _apply_attack_hits(heavy: bool, damage: int, attack_range_value: float, already_hit: Dictionary) -> void:
	var facing := -player.global_transform.basis.z
	if _is_lock_target_valid():
		facing = locked_target.global_position - player.global_position
	facing.y = 0.0
	for index in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[index]
		if not is_instance_valid(enemy):
			enemies.remove_at(index)
			continue
		var enemy_id := enemy.get_instance_id()
		if already_hit.has(enemy_id):
			continue
		var to_enemy: Vector3 = enemy.global_position - player.global_position
		to_enemy.y = 0.0
		var effective_range := attack_range_value
		if heavy and bool(enemy.get_meta("boss", false)):
			effective_range += 0.25
		var target_is_in_arc := CombatRules.is_target_in_attack_arc(facing, to_enemy, ATTACK_RANGE)
		if heavy or not is_equal_approx(effective_range, ATTACK_RANGE):
			target_is_in_arc = CombatRules.is_target_in_attack_arc(facing, to_enemy, effective_range)
		if not target_is_in_arc:
			continue
		already_hit[enemy_id] = true
		var hp := int(enemy.get_meta("hp", 60)) - damage
		enemy.set_meta("hp", hp)
		var enemy_visual := enemy.get_node_or_null("WarriorVisual")
		if enemy_visual != null:
			enemy_visual.call("hit_react")
		var base_scale: Vector3 = enemy.get_meta("base_scale", Vector3.ONE)
		enemy.scale = base_scale * (0.90 if heavy else 0.94)
		var hit_tween := create_tween()
		hit_tween.tween_property(enemy, "scale", base_scale, 0.18 if heavy else 0.14)
		_play_sfx_or_tone("impact", 190.0 if heavy else 260.0, 0.09, 0.22)
		if hp <= 0:
			var was_boss := bool(enemy.get_meta("boss", false))
			enemy.queue_free()
			enemies.remove_at(index)
			if locked_target == enemy:
				locked_target = null
			score += 900 if was_boss else 100
			souls_earned += 3 if was_boss else 1
			_update_hud()
			if enemies.is_empty():
				_handle_wave_cleared()
	if is_instance_valid(hud):
		_update_hud()


func _damage_player(amount: int, source: Node3D = null) -> void:
	if not CombatRules.can_receive_hit(player_invulnerability_time):
		return
	if player_blocking:
		if block_window_remaining > 0.0:
			block_window_remaining = 0.0
			player_invulnerability_time = 0.36
			score += 75
			if is_instance_valid(hero_visual):
				hero_visual.call("play_parry")
			if is_instance_valid(source):
				source.set_meta("attack_state", "recovery")
				source.set_meta("attack_timer", 1.0)
				source.set_meta("attack_cooldown", 1.25)
				var source_visual := source.get_node_or_null("WarriorVisual")
				if source_visual != null:
					source_visual.call("hit_react")
			status_label.text = "صد مثالي  |  +75 نقطة" if _is_arabic() else "PERFECT PARRY  |  +75 SCORE"
			_play_sfx_or_tone("parry", 980.0, 0.12, 0.24)
			_update_hud()
			return
		amount = maxi(1, int(ceil(float(amount) * guard_damage_scale * 0.35)))
	else:
		amount = maxi(1, int(ceil(float(amount) * guard_damage_scale)))
	player_invulnerability_time = 0.72
	if is_instance_valid(hero_visual):
		hero_visual.call("hit_react")
	_play_sfx_or_tone("hurt", 105.0, 0.13, 0.24)
	health = maxi(0, health - amount)
	_update_hud()
	if health <= 0:
		game_over = true
		_save_run(false)
		status_label.text = "سقطت في المعركة | الأرواح محفوظة | طوّر محاربك" if _is_arabic() else "YOU FELL | SOULS SAVED | FORGE YOUR WARRIOR"
		restart_button.text = "متابعة الحملة" if _is_arabic() else "CONTINUE CAMPAIGN"
		restart_button.visible = true
		upgrade_panel.visible = true
		_refresh_upgrade_panel()
		if is_instance_valid(pause_menu):
			pause_menu.call("set_pause_available", false)


func _update_hud() -> void:
	if is_instance_valid(hud):
		var combo_display := combo_display_step + 1 if combo_timer > 0.0 else 1
		var profile: Dictionary = _save_profile()
		var banked_souls := int(profile.get("total_souls", 0))
		if _is_arabic():
			hud.text = "نوفا  |  الفصل %d  |  الموجة %d/9  |  الصحة %d  |  النقاط %d  |  أرواح الجولة %d  |  الضربات ×%d  |  الرصيد %d" % [
				CombatRules.chapter_for_wave(current_wave), current_wave, health, score, souls_earned, combo_display, banked_souls
			]
			hud.text_direction = Control.TEXT_DIRECTION_RTL
		else:
			hud.text = "NOVA  |  CHAPTER %d  |  WAVE %d/9  |  HP %d  |  SCORE %d  |  RUN SOULS %d  |  COMBO x%d  |  BANK %d" % [
				CombatRules.chapter_for_wave(current_wave), current_wave, health, score, souls_earned, combo_display, banked_souls
			]
			hud.text_direction = Control.TEXT_DIRECTION_LTR
	_update_mission_objective_ui()


func _is_arabic() -> bool:
	return TranslationServer.get_locale().begins_with("ar")


func _localized_boss_name(wave: int) -> String:
	var level := LevelCatalog.get_level(wave)
	return str(level.get("boss_name_ar", level.get("boss_name", ""))) if _is_arabic() else str(level.get("boss_name", ""))


func _refresh_upgrade_panel() -> void:
	if not is_instance_valid(upgrade_panel):
		return
	var labels := {
		"blade": "النصل  +4 ضرر" if _is_arabic() else "BLADE  +4 DAMAGE",
		"vitality": "الحيوية  +15 صحة قصوى" if _is_arabic() else "VITALITY  +15 MAX HP",
		"guard": "الدرع  -12% ضرر" if _is_arabic() else "GUARD  -12% DAMAGE"
	}
	for key in upgrade_buttons:
		var button := upgrade_buttons[key] as Button
		var cost := int(_save_call("upgrade_cost", [key]))
		var level_key := "upgrade_" + str(key)
		var level := int(_save_profile().get(level_key, 0))
		if cost < 0:
			button.text = "%s  |  %s" % [labels[key], "أقصى مستوى" if _is_arabic() else "MAX LEVEL"]
			button.disabled = true
		else:
			button.text = ("%s  |  مستوى %d/3  |  %d روح" % [labels[key], level, cost]) if _is_arabic() else ("%s  |  LV %d/3  |  %d SOULS" % [labels[key], level, cost])
			button.disabled = int(_save_profile().get("total_souls", 0)) < cost


func _purchase_upgrade(upgrade_name: String) -> void:
	if not game_over:
		return
	if _save_call("purchase_upgrade", [upgrade_name]):
		status_label.text = ("تم تطوير %s | يظهر التأثير في الجولة القادمة" % upgrade_name) if _is_arabic() else "%s UPGRADED | EFFECTIVE NEXT RUN" % upgrade_name.to_upper()
		_play_sfx_or_tone("upgrade", 820.0, 0.16, 0.2)
	else:
		status_label.text = "الأرواح غير كافية أو وصلت إلى المستوى الأقصى" if _is_arabic() else "NOT ENOUGH SOULS OR MAX LEVEL REACHED"
	_refresh_upgrade_panel()
	_update_hud()


func _build_audio() -> void:
	music_director = MusicDirector.new()
	music_director.name = "MusicDirector"
	add_child(music_director)
	var sfx_level := float(_save_profile().get("sfx_volume", 0.85))
	var sfx_gain_db := linear_to_db(maxf(sfx_level, 0.0001)) - 5.0
	for i in range(4):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = sfx_gain_db
		add_child(voice)
		sound_players.append(voice)
	var sound_names := [
		"sword_swing", "heavy_swing", "impact", "parry", "footstep",
		"dodge", "jump", "hurt", "boss_roar", "hazard_warning",
		"hazard_burst", "victory", "upgrade"
	]
	for sound_name in sound_names:
		var audio_path := "res://audio/generated/%s.wav" % sound_name
		if ResourceLoader.exists(audio_path):
			var stream := load(audio_path) as AudioStreamWAV
			if stream != null:
				sfx_streams[sound_name] = stream


func _play_sfx(sound_name: String) -> bool:
	if sound_players.is_empty() or not sfx_streams.has(sound_name):
		return false
	var voice := sound_players[sound_cursor]
	sound_cursor = (sound_cursor + 1) % sound_players.size()
	voice.stream = sfx_streams[sound_name]
	voice.play()
	return true


func _play_sfx_or_tone(sound_name: String, frequency: float, duration: float, amplitude: float) -> void:
	if not _play_sfx(sound_name):
		_play_tone(frequency, duration, amplitude)


func _play_tone(frequency: float, duration: float, amplitude: float) -> void:
	if sound_players.is_empty():
		return
	var voice := sound_players[sound_cursor]
	sound_cursor = (sound_cursor + 1) % sound_players.size()
	var sample_rate := 22050
	var count := maxi(1, int(sample_rate * duration))
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(sample_rate)
		var envelope := 1.0 - float(i) / float(count)
		var sample := int(sin(TAU * frequency * t) * amplitude * envelope * 32767.0)
		data.encode_s16(i * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	voice.stream = stream
	voice.play()


func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var seed_value := int(absf(color.r * 997.0 + color.g * 467.0 + color.b * 193.0 + metallic * 61.0)) + 701
	return PBRMaterialLibrary.create_surface_material(color, metallic, roughness, seed_value, 2.6)
