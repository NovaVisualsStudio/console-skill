extends Node3D

const PLAYER_SPEED := 5.2
const JUMP_SPEED := 7.0
const GRAVITY := 18.0
const ENEMY_SPEED := 1.65
const ATTACK_RANGE := 2.25
const ARENA_LIMIT := 16.0
const CombatRules = preload("res://scripts/combat_rules.gd")
const WarriorVisual = preload("res://scripts/warrior_visual.gd")
const MusicDirector = preload("res://scripts/music_director.gd")
const CinematicDirector = preload("res://scripts/cinematic_director.gd")
const LevelCatalog = preload("res://scripts/level_catalog.gd")

var player: CharacterBody3D
var hero_visual: Node3D
var camera: Camera3D
var enemies: Array[Node3D] = []
var current_wave := 1
var wave_transitioning := false
var health := 100
var score := 0
var attack_cooldown := 0.0
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
var restart_button: Button
var sound_players: Array[AudioStreamPlayer] = []
var sound_cursor := 0
var souls_earned := 0
var cinematic_active := false
var music_director: Node
var arena_environment: Environment
var arena_floor_material: StandardMaterial3D
var arena_sun: DirectionalLight3D


func _ready() -> void:
	_setup_input()
	_build_world()
	_build_player()
	_build_enemies()
	_build_hud()
	_build_audio()
	_update_hud()


func _process(delta: float) -> void:
	if not cinematic_active and is_instance_valid(player) and is_instance_valid(camera):
		var target := player.global_position + Vector3(0.0, 6.3, 9.0)
		camera.global_position = camera.global_position.lerp(target, minf(delta * 4.5, 1.0))
		camera.look_at(player.global_position + Vector3(0.0, 1.1, 0.0), Vector3.UP)
	if game_over and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	elif not game_over and Input.is_action_just_pressed("attack"):
		_attack()


func _physics_process(delta: float) -> void:
	if game_over or not is_instance_valid(player):
		return
	player_invulnerability_time = maxf(0.0, player_invulnerability_time - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	dodge_remaining = maxf(0.0, dodge_remaining - delta)
	combo_timer = maxf(0.0, combo_timer - delta)
	if combo_timer <= 0.0:
		combo_step = 0

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
			dodge_direction = Vector3.FORWARD
		dodge_remaining = 0.28
		dodge_cooldown = 0.88
		player_invulnerability_time = maxf(player_invulnerability_time, 0.42)
		_play_tone(360.0, 0.09, 0.17)

	if dodge_remaining > 0.0:
		player.velocity.x = dodge_direction.x * 9.4
		player.velocity.z = dodge_direction.z * 9.4
		player.rotation.y = atan2(-dodge_direction.x, -dodge_direction.z)
	elif direction.length_squared() > 0.01:
		player.velocity.x = direction.x * PLAYER_SPEED
		player.velocity.z = direction.z * PLAYER_SPEED
		player.rotation.y = atan2(-direction.x, -direction.z)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, PLAYER_SPEED * 5.0 * delta)
		player.velocity.z = move_toward(player.velocity.z, 0.0, PLAYER_SPEED * 5.0 * delta)

	if not player.is_on_floor():
		player.velocity.y -= GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		player.velocity.y = JUMP_SPEED
		_play_tone(520.0, 0.08, 0.16)

	player.move_and_slide()
	var safe_position: Vector3 = player.global_position
	var previous_position: Vector3 = safe_position
	safe_position.x = clampf(safe_position.x, -ARENA_LIMIT, ARENA_LIMIT)
	safe_position.z = clampf(safe_position.z, -ARENA_LIMIT, ARENA_LIMIT)
	if not is_equal_approx(safe_position.x, previous_position.x):
		player.velocity.x = 0.0
	if not is_equal_approx(safe_position.z, previous_position.z):
		player.velocity.z = 0.0
	player.global_position = safe_position
	if is_instance_valid(hero_visual):
		var planar_speed := Vector2(player.velocity.x, player.velocity.z).length()
		hero_visual.call("set_locomotion", planar_speed / PLAYER_SPEED, delta)
	_update_enemies(delta)


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

	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var pillar := MeshInstance3D.new()
		var pillar_mesh := CylinderMesh.new()
		pillar_mesh.top_radius = 0.48
		pillar_mesh.bottom_radius = 0.62
		pillar_mesh.height = randf_range(2.2, 3.8)
		pillar.mesh = pillar_mesh
		pillar.position = Vector3(cos(angle) * 13.0, pillar_mesh.height * 0.5, sin(angle) * 13.0)
		pillar.material_override = _material(Color(0.28, 0.25, 0.22), 0.0, 1.0)
		add_child(pillar)

	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var brazier := MeshInstance3D.new()
		var brazier_mesh := CylinderMesh.new()
		brazier_mesh.top_radius = 0.36
		brazier_mesh.bottom_radius = 0.55
		brazier_mesh.height = 0.9
		brazier.mesh = brazier_mesh
		brazier.position = Vector3(cos(angle) * 9.0, 0.45, sin(angle) * 9.0)
		brazier.material_override = _material(Color(0.16, 0.14, 0.13), 0.0, 0.85)
		add_child(brazier)
		var fire_light := OmniLight3D.new()
		fire_light.position = brazier.position + Vector3(0.0, 0.8, 0.0)
		fire_light.light_color = Color(1.0, 0.29, 0.075)
		fire_light.light_energy = 1.2
		fire_light.omni_range = 5.5
		add_child(fire_light)

	for i in range(34):
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
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	player.add_child(collision)
	hero_visual = WarriorVisual.new()
	hero_visual.name = "WarriorVisual"
	player.add_child(hero_visual)


func _build_enemies() -> void:
	_spawn_wave()


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


func _spawn_wave() -> void:
	_apply_level_theme(current_wave)
	var enemy_count := CombatRules.wave_enemy_count(current_wave)
	var boss_wave := CombatRules.is_boss_wave(current_wave)
	for i in range(enemy_count):
		var angle := TAU * float(i) / float(enemy_count) + 0.4
		var enemy := Node3D.new()
		enemy.name = "AshTitan" if boss_wave else "AshSentinel_W%d_%d" % [current_wave, i + 1]
		var spawn_radius := 7.8 if boss_wave else 6.2 + float(current_wave - 1) * 0.7
		enemy.position = Vector3(cos(angle) * spawn_radius, 0.0, sin(angle) * spawn_radius)
		enemy.set_meta("hp", CombatRules.wave_enemy_health(current_wave))
		enemy.set_meta("base_scale", Vector3.ONE * (1.42 if boss_wave else 1.0))
		enemy.set_meta("speed", 1.35 if boss_wave else ENEMY_SPEED + float(current_wave - 1) * 0.12)
		enemy.set_meta("damage", CombatRules.wave_enemy_damage(current_wave))
		enemy.set_meta("boss", boss_wave)
		enemy.set_meta("windup_duration", 0.64 if boss_wave else 0.42 - float(current_wave - 1) * 0.04)
		enemy.set_meta("recovery_duration", 1.0 if boss_wave else 0.78)
		enemy.set_meta("attack_state", "approach")
		enemy.set_meta("attack_timer", 0.0)
		enemy.set_meta("attack_cooldown", randf_range(0.25, 0.85))
		var enemy_visual := WarriorVisual.new()
		enemy_visual.name = "WarriorVisual"
		enemy_visual.set("is_enemy", true)
		enemy_visual.set("is_boss", boss_wave)
		enemy.add_child(enemy_visual)
		if boss_wave:
			enemy.scale = Vector3.ONE * 1.42
			var title := Label3D.new()
			title.text = str(LevelCatalog.get_level(current_wave).get("boss_name", "ASH TITAN"))
			title.position = Vector3(0.0, 3.15, 0.0)
			title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			title.font_size = 40
			title.outline_size = 8
			title.modulate = Color(1.0, 0.64, 0.36)
			enemy.add_child(title)
		add_child(enemy)
		enemies.append(enemy)
	_update_hud()
	if boss_wave:
		call_deferred("_start_boss_intro", get_node_or_null("AshTitan"))


func _start_boss_intro(boss: Node3D) -> void:
	if cinematic_active or not is_instance_valid(boss) or not is_instance_valid(player) or not is_instance_valid(camera):
		return
	cinematic_active = true
	if is_instance_valid(music_director):
		music_director.call("set_intensity", 0.9)
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
	)


func _handle_wave_cleared() -> void:
	if wave_transitioning or game_over:
		return
	if current_wave >= 3:
		game_over = true
		SaveManager.record_run(current_wave, score, souls_earned, true)
		status_label.text = "ASH TITAN DEFEATED | CHAPTER 2 UNLOCKED"
		restart_button.visible = true
		_play_tone(880.0, 0.3, 0.22)
		return
	wave_transitioning = true
	SaveManager.record_checkpoint(current_wave, score)
	status_label.text = "WAVE %d CLEARED | PREPARE FOR THE NEXT ATTACK" % current_wave
	_play_tone(660.0, 0.18, 0.18)
	var transition := get_tree().create_timer(1.35)
	transition.timeout.connect(func():
		if game_over or not is_inside_tree():
			return
		current_wave += 1
		_spawn_wave()
		wave_transitioning = false
		status_label.text = "%s | DEFEAT THE ENEMIES" % str(LevelCatalog.get_level(current_wave).get("title", "ARENA"))
		_update_hud()
		_play_tone(520.0 + float(current_wave) * 80.0, 0.14, 0.18)
	)


func _build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(24.0, 18.0)
	hud.add_theme_font_size_override("font_size", 26)
	hud.add_theme_color_override("font_color", Color(1.0, 0.84, 0.58))
	layer.add_child(hud)
	status_label = Label.new()
	status_label.anchor_left = 0.5
	status_label.anchor_right = 0.5
	status_label.offset_left = -190.0
	status_label.offset_right = 190.0
	status_label.offset_top = 20.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color(0.92, 0.84, 0.72))
	status_label.text = "WAVE 1 / 3 | DEFEAT THE ASH SENTINELS"
	layer.add_child(status_label)
	_add_touch_button(layer, "↑", "move_forward", Vector2(112.0, -190.0))
	_add_touch_button(layer, "↓", "move_back", Vector2(112.0, -88.0))
	_add_touch_button(layer, "←", "move_left", Vector2(10.0, -139.0))
	_add_touch_button(layer, "→", "move_right", Vector2(214.0, -139.0))
	_add_touch_button(layer, "ATTACK", "attack", Vector2(-168.0, -126.0), Vector2(150.0, 72.0), true)
	_add_touch_button(layer, "JUMP", "jump", Vector2(-168.0, -210.0), Vector2(112.0, 64.0), true)
	_add_touch_button(layer, "DODGE", "dodge", Vector2(-156.0, -48.0), Vector2(132.0, 56.0), true)
	restart_button = Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "RESTART"
	restart_button.visible = false
	restart_button.focus_mode = Control.FOCUS_NONE
	restart_button.custom_minimum_size = Vector2(220.0, 64.0)
	restart_button.anchor_left = 0.5
	restart_button.anchor_right = 0.5
	restart_button.anchor_top = 0.62
	restart_button.anchor_bottom = 0.62
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
	var hint := Label.new()
	hint.anchor_left = 0.5
	hint.anchor_right = 0.5
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = -180.0
	hint.offset_right = 180.0
	hint.offset_top = -34.0
	hint.offset_bottom = -8.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "MOVE  |  J ATTACK  |  SHIFT DODGE  |  SPACE JUMP"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.72, 0.68, 0.61))
	layer.add_child(hint)


func _add_touch_button(layer: CanvasLayer, caption: String, action: String, offset: Vector2, size: Vector2 = Vector2(92.0, 82.0), right_side: bool = false) -> void:
	var button := Button.new()
	button.text = caption
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
			continue
		var offset: Vector3 = player.global_position - enemy.global_position
		offset.y = 0.0
		var distance: float = offset.length()
		var enemy_speed := float(enemy.get_meta("speed", ENEMY_SPEED))
		if distance > 0.001:
			enemy.look_at(Vector3(player.global_position.x, enemy.global_position.y, player.global_position.z), Vector3.UP)
		var visual := enemy.get_node_or_null("WarriorVisual")
		var attack_state := str(enemy.get_meta("attack_state", "approach"))
		var attack_timer := maxf(0.0, float(enemy.get_meta("attack_timer", 0.0)))
		var attack_cooldown_value := maxf(0.0, float(enemy.get_meta("attack_cooldown", 0.0)) - delta)

		if attack_state == "approach":
			if distance > 1.85:
				enemy.global_position += offset.normalized() * enemy_speed * delta
				if visual != null:
					visual.call("set_locomotion", 0.46, delta)
			elif CombatRules.should_start_enemy_windup(distance, attack_cooldown_value):
				attack_state = "windup"
				attack_timer = float(enemy.get_meta("windup_duration", 0.42))
				if visual != null:
					visual.call("telegraph", true)
			else:
				if visual != null:
					visual.call("set_locomotion", 0.0, delta)
		elif attack_state == "windup":
			attack_timer = maxf(0.0, attack_timer - delta)
			if attack_timer <= 0.0:
				if distance <= 2.0:
					_damage_player(int(enemy.get_meta("damage", 9)))
					_play_tone(125.0 if not bool(enemy.get_meta("boss", false)) else 85.0, 0.12, 0.2)
				attack_state = "recovery"
				attack_timer = float(enemy.get_meta("recovery_duration", 0.78))
				if visual != null:
					visual.call("telegraph", false)
				if game_over:
					break
		elif attack_state == "recovery":
			attack_timer = maxf(0.0, attack_timer - delta)
			if attack_timer <= 0.0:
				attack_state = "approach"
				attack_cooldown_value = 0.22

		enemy.set_meta("attack_state", attack_state)
		enemy.set_meta("attack_timer", attack_timer)
		enemy.set_meta("attack_cooldown", attack_cooldown_value)


func _attack() -> void:
	if attack_cooldown > 0.0 or game_over:
		return
	var current_step := combo_step
	var damage := CombatRules.combo_damage(current_step)
	var attack_range_value := CombatRules.combo_range(current_step)
	attack_cooldown = CombatRules.combo_cooldown(current_step)
	combo_display_step = current_step
	combo_step = (combo_step + 1) % 3
	combo_timer = 1.05
	if is_instance_valid(hero_visual):
		hero_visual.call("play_attack", current_step)
	_play_tone(740.0 + float(current_step) * 90.0, 0.11, 0.22)
	for index in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[index]
		if not is_instance_valid(enemy):
			enemies.remove_at(index)
			continue
		var to_enemy: Vector3 = enemy.global_position - player.global_position
		to_enemy.y = 0.0
		var facing := -player.global_transform.basis.z
		facing.y = 0.0
		var in_attack_arc := CombatRules.is_target_in_attack_arc(facing, to_enemy, ATTACK_RANGE)
		if current_step > 0:
			in_attack_arc = CombatRules.is_target_in_attack_arc(facing, to_enemy, attack_range_value)
		if in_attack_arc:
			var hp := int(enemy.get_meta("hp", 60)) - damage
			enemy.set_meta("hp", hp)
			var enemy_visual := enemy.get_node_or_null("WarriorVisual")
			if enemy_visual != null:
				enemy_visual.call("hit_react")
				var base_scale: Vector3 = enemy.get_meta("base_scale", Vector3.ONE)
				enemy.scale = base_scale * 0.92
				var hit_tween := create_tween()
				hit_tween.tween_property(enemy, "scale", base_scale, 0.14)
			_play_tone(260.0, 0.07, 0.2)
			if hp <= 0:
				enemy.queue_free()
				enemies.remove_at(index)
				score += 500 if bool(enemy.get_meta("boss", false)) else 100
				souls_earned += 1
				_update_hud()
				if enemies.is_empty():
					_handle_wave_cleared()
	if is_instance_valid(hud):
		_update_hud()


func _damage_player(amount: int) -> void:
	if not CombatRules.can_receive_hit(player_invulnerability_time):
		return
	player_invulnerability_time = 0.72
	if is_instance_valid(hero_visual):
		hero_visual.call("hit_react")
	_play_tone(105.0, 0.13, 0.24)
	health = maxi(0, health - amount)
	_update_hud()
	if health <= 0:
		game_over = true
		SaveManager.record_run(current_wave, score, souls_earned, false)
		status_label.text = "YOU FELL | TAP RESTART OR PRESS R"
		restart_button.visible = true


func _update_hud() -> void:
	if is_instance_valid(hud):
		var combo_display := combo_display_step + 1 if combo_timer > 0.0 else 1
		hud.text = "NOVA  |  WAVE %d/3  |  VITALITY %d%%  |  SOULS %d  |  COMBO x%d" % [current_wave, health, score, combo_display]


func _build_audio() -> void:
	music_director = MusicDirector.new()
	music_director.name = "MusicDirector"
	add_child(music_director)
	for i in range(4):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -7.0
		add_child(voice)
		sound_players.append(voice)


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
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material
