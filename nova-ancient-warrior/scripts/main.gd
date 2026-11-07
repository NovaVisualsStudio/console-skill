extends Node3D

const PLAYER_SPEED := 5.2
const JUMP_SPEED := 7.0
const GRAVITY := 18.0
const ENEMY_SPEED := 1.65
const ATTACK_RANGE := 2.25

var player: CharacterBody3D
var sword: MeshInstance3D
var camera: Camera3D
var enemies: Array[Node3D] = []
var health := 100
var score := 0
var attack_ready := true
var game_over := false
var hud: Label
var status_label: Label
var restart_button: Button
var sound_players: Array[AudioStreamPlayer] = []
var sound_cursor := 0


func _ready() -> void:
	_setup_input()
	_build_world()
	_build_player()
	_build_enemies()
	_build_hud()
	_build_audio()
	_update_hud()


func _process(delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(camera):
		var target := player.global_position + Vector3(0.0, 6.3, 9.0)
		camera.global_position = camera.global_position.lerp(target, minf(delta * 4.5, 1.0))
		camera.look_at(player.global_position + Vector3(0.0, 1.1, 0.0), Vector3.UP)
	_update_enemies(delta)
	if game_over and Input.is_action_just_pressed("restart"):
		get_tree().reload_current_scene()
	elif not game_over and Input.is_action_just_pressed("attack"):
		_attack()


func _physics_process(delta: float) -> void:
	if game_over or not is_instance_valid(player):
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_vector.x, 0.0, input_vector.y).normalized()
	if direction.length_squared() > 0.01:
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
	floor_instance.material_override = _material(Color(0.22, 0.19, 0.17), 0.0, 0.9)
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
	var body := MeshInstance3D.new()
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.42
	body_mesh.height = 1.8
	body.mesh = body_mesh
	body.position.y = 0.9
	body.material_override = _material(Color(0.48, 0.19, 0.12), 0.0, 0.65)
	player.add_child(body)
	var helmet := MeshInstance3D.new()
	var helmet_mesh := SphereMesh.new()
	helmet_mesh.radius = 0.34
	helmet_mesh.height = 0.48
	helmet.mesh = helmet_mesh
	helmet.position = Vector3(0.0, 1.83, -0.02)
	helmet.material_override = _material(Color(0.72, 0.48, 0.17), 0.25, 0.35)
	player.add_child(helmet)
	sword = MeshInstance3D.new()
	var blade := BoxMesh.new()
	blade.size = Vector3(0.12, 1.25, 0.18)
	sword.mesh = blade
	sword.position = Vector3(0.58, 1.05, -0.28)
	sword.rotation.z = -0.55
	sword.material_override = _material(Color(0.72, 0.78, 0.83), 0.35, 0.22)
	player.add_child(sword)


func _build_enemies() -> void:
	for i in range(4):
		var angle := TAU * float(i) / 4.0 + 0.4
		var enemy := Node3D.new()
		enemy.name = "AshSentinel_%d" % i
		enemy.position = Vector3(cos(angle) * 6.0, 0.0, sin(angle) * 6.0)
		enemy.set_meta("hp", 60)
		enemy.set_meta("cooldown", randf_range(0.2, 1.0))
		add_child(enemy)
		var mesh_instance := MeshInstance3D.new()
		var enemy_mesh := CapsuleMesh.new()
		enemy_mesh.radius = 0.46
		enemy_mesh.height = 1.75
		mesh_instance.mesh = enemy_mesh
		mesh_instance.position.y = 0.88
		mesh_instance.material_override = _material(Color(0.24, 0.34, 0.37), 0.0, 0.75)
		enemy.add_child(mesh_instance)
		var mask := MeshInstance3D.new()
		var mask_mesh := SphereMesh.new()
		mask_mesh.radius = 0.31
		mask_mesh.height = 0.42
		mask.mesh = mask_mesh
		mask.position = Vector3(0.0, 1.78, -0.02)
		mask.material_override = _material(Color(0.72, 0.19, 0.09), 0.15, 0.3)
		enemy.add_child(mask)
		enemies.append(enemy)


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
	layer.add_child(status_label)
	_add_touch_button(layer, "↑", "move_forward", Vector2(112.0, -190.0))
	_add_touch_button(layer, "↓", "move_back", Vector2(112.0, -88.0))
	_add_touch_button(layer, "←", "move_left", Vector2(10.0, -139.0))
	_add_touch_button(layer, "→", "move_right", Vector2(214.0, -139.0))
	_add_touch_button(layer, "ATTACK", "attack", Vector2(-168.0, -126.0), Vector2(150.0, 72.0), true)
	_add_touch_button(layer, "JUMP", "jump", Vector2(-168.0, -210.0), Vector2(112.0, 64.0), true)
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
	hint.text = "WASD / Arrows  |  J Attack  |  Space Jump"
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
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			enemies.erase(enemy)
			continue
		var offset: Vector3 = player.global_position - enemy.global_position
		offset.y = 0.0
		var distance: float = offset.length()
		if distance > 1.55:
			enemy.global_position += offset.normalized() * ENEMY_SPEED * delta
		enemy.look_at(Vector3(player.global_position.x, enemy.global_position.y, player.global_position.z), Vector3.UP)
		var cooldown := float(enemy.get_meta("cooldown", 0.0)) - delta
		if distance <= 1.65 and cooldown <= 0.0:
			enemy.set_meta("cooldown", 1.25)
			_damage_player(9)
			_play_tone(125.0, 0.12, 0.2)
		else:
			enemy.set_meta("cooldown", cooldown)


func _attack() -> void:
	if not attack_ready or game_over:
		return
	attack_ready = false
	_play_tone(740.0, 0.11, 0.22)
	var tween := create_tween()
	tween.tween_property(sword, "rotation:z", 1.25, 0.09)
	tween.tween_property(sword, "rotation:z", -0.55, 0.16)
	for enemy in enemies.duplicate():
		if not is_instance_valid(enemy):
			continue
		if player.global_position.distance_to(enemy.global_position) <= ATTACK_RANGE:
			var hp := int(enemy.get_meta("hp", 60)) - 40
			enemy.set_meta("hp", hp)
			_play_tone(260.0, 0.07, 0.2)
			if hp <= 0:
				enemy.queue_free()
				enemies.erase(enemy)
				score += 100
				_update_hud()
				if enemies.is_empty():
					status_label.text = "ARENA CLEARED | TAP RESTART OR PRESS R"
					game_over = true
					restart_button.visible = true
					_play_tone(880.0, 0.3, 0.22)
			else:
				enemy.scale = Vector3(0.88, 0.88, 0.88)
				var hit_tween := create_tween()
				hit_tween.tween_property(enemy, "scale", Vector3.ONE, 0.12)
	var timer := get_tree().create_timer(0.42)
	timer.timeout.connect(func(): attack_ready = true)


func _damage_player(amount: int) -> void:
	health = maxi(0, health - amount)
	_update_hud()
	if health <= 0:
		game_over = true
		status_label.text = "YOU FELL | TAP RESTART OR PRESS R"
		restart_button.visible = true


func _update_hud() -> void:
	if is_instance_valid(hud):
		hud.text = "NOVA  |  VITALITY %d%%  |  SOULS %d" % [health, score]


func _build_audio() -> void:
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
