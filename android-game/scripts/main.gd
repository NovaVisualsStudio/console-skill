extends Node3D
class_name NovaArenaController

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")
const CAMERA_SCRIPT = preload("res://scripts/camera_rig.gd")
const AUDIO_SCRIPT = preload("res://scripts/audio_fx.gd")
const SAVE_PATH := "user://nova_progress.cfg"
const CHAPTER_NAMES := ["THE ASHEN GATE", "THE SUNKEN SANCTUM", "THE CROWN OF ASH"]
const BOSS_NAMES := ["ASHEN WARDEN", "DROWNED SENTINEL", "CROWNED TYRANT"]
const CHAPTER_BACKGROUNDS := [Color(0.012, 0.018, 0.035), Color(0.008, 0.035, 0.052), Color(0.045, 0.012, 0.018)]
const CHAPTER_FOG := [Color(0.075, 0.095, 0.15), Color(0.035, 0.12, 0.16), Color(0.18, 0.045, 0.035)]
const CHAPTER_RINGS := [Color(0.19, 0.46, 0.63), Color(0.10, 0.54, 0.58), Color(0.78, 0.18, 0.08)]

var player: NovaPlayer
var boss: NovaEnemy
var camera_rig: NovaCameraRig
var audio_fx: NovaAudioFX
var active_enemies: Array[NovaEnemy] = []
var hud_label: Label
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var boss_bar: ProgressBar
var boss_panel: PanelContainer
var result_label: Label
var intro_label: Label
var retry_button: Button
var continue_button: Button
var chapter_index := 0
var unlocked_chapter := 0
var campaign_complete := false
var intro_timer := 3.1
var defeated_count := 0
var combat_started := false
var boss_defeated := false
var lock_index := -1

func _ready() -> void:
    _load_campaign_progress()
    _ensure_input_actions()
    audio_fx = AUDIO_SCRIPT.new() as NovaAudioFX
    add_child(audio_fx)
    audio_fx.start_ambience()
    _build_world()
    _spawn_encounter()
    _build_hud()
    if campaign_complete:
        _show_campaign_complete()
    else:
        _start_cinematic_intro()

func _process(delta: float) -> void:
    if not combat_started:
        intro_timer = maxf(0.0, intro_timer - delta)
        if intro_timer <= 0.0:
            _begin_combat()
func _input(event: InputEvent) -> void:
    if event is InputEventKey and (event as InputEventKey).echo:
        return
    if combat_started and event.is_action_pressed("lock_on"):
        _on_lock_pressed()

func _ensure_input_actions() -> void:
    var keys := {
        "move_forward": KEY_W,
        "move_back": KEY_S,
        "move_left": KEY_A,
        "move_right": KEY_D,
        "attack": KEY_J,
        "heavy_attack": KEY_K,
        "dodge": KEY_SPACE,
        "guard": KEY_L,
        "lock_on": KEY_TAB
    }
    for action in keys:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        var event := InputEventKey.new()
        event.physical_keycode = keys[action]
        InputMap.action_add_event(action, event)

func _build_world() -> void:
    var world := WorldEnvironment.new()
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    var stage := clampi(chapter_index, 0, CHAPTER_NAMES.size() - 1)
    environment.background_color = CHAPTER_BACKGROUNDS[stage]
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.30, 0.37, 0.52)
    environment.ambient_light_energy = 0.62
    environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.tonemap_exposure = 1.15
    environment.fog_enabled = true
    environment.fog_light_color = CHAPTER_FOG[stage]
    environment.fog_density = 0.012
    world.environment = environment
    add_child(world)

    var moon := DirectionalLight3D.new()
    moon.rotation_degrees = Vector3(-38, -28, 0)
    moon.light_color = Color(0.62, 0.72, 1.0) if stage == 0 else (Color(0.42, 0.82, 0.92) if stage == 1 else Color(1.0, 0.42, 0.25))
    moon.light_energy = 1.05
    moon.shadow_enabled = true
    add_child(moon)

    var stage_floor_tint := Color(0.82, 0.86, 0.94) if stage == 0 else (Color(0.74, 0.92, 0.98) if stage == 1 else Color(0.96, 0.74, 0.66))
    var stage_wall_tint := Color(0.72, 0.72, 0.78) if stage == 0 else (Color(0.65, 0.82, 0.85) if stage == 1 else Color(0.88, 0.62, 0.54))
    var floor_pbr := _make_pbr_material("rock_tile_floor", stage_floor_tint, 10.0)
    var wall_pbr := _make_pbr_material("stone_wall", stage_wall_tint, 6.0)
    var portal_pbr := _make_pbr_material("stone_wall", Color(0.78, 0.72, 0.62), 3.0)

    var floor_root := _add_box("ArenaFloor", Vector3(0, -0.55, 0), Vector3(42, 1.1, 42),
        stage_floor_tint, true, 0.92, 0.18)
    _apply_pbr_material(floor_root, floor_pbr)
    var north_wall_root := _add_box("NorthWall", Vector3(0, 3.0, -21), Vector3(42, 6, 1.2),
        stage_wall_tint, true, 0.92, 0.08)
    var south_wall_root := _add_box("SouthWall", Vector3(0, 3.0, 21), Vector3(42, 6, 1.2),
        stage_wall_tint, true, 0.92, 0.08)
    var west_wall_root := _add_box("WestWall", Vector3(-21, 3.0, 0), Vector3(1.2, 6, 42),
        stage_wall_tint, true, 0.92, 0.08)
    var east_wall_root := _add_box("EastWall", Vector3(21, 3.0, 0), Vector3(1.2, 6, 42),
        stage_wall_tint, true, 0.92, 0.08)
    for wall_root in [north_wall_root, south_wall_root, west_wall_root, east_wall_root]:
        _apply_pbr_material(wall_root, wall_pbr)

    _add_ritual_ring(7.6, CHAPTER_RINGS[stage])
    _add_ritual_ring(10.2, CHAPTER_RINGS[stage].darkened(0.42))
    _add_cylinder("RitualDais", Vector3(0, 0.02, -8.5), 4.8, 0.22,
        Color(0.15, 0.16, 0.21), false, 0.72, 0.36)
    _add_box("PortalCore", Vector3(0, 5.2, -19.9), Vector3(7.2, 8.2, 0.55),
        CHAPTER_FOG[stage].darkened(0.48), false, 0.38, 0.72)
    var portal_left := _add_box("PortalLeftPillar", Vector3(-4.1, 4.0, -19.5), Vector3(1.1, 8.0, 1.25),
        Color(0.30, 0.26, 0.22), true, 0.78, 0.35)
    var portal_right := _add_box("PortalRightPillar", Vector3(4.1, 4.0, -19.5), Vector3(1.1, 8.0, 1.25),
        Color(0.30, 0.26, 0.22), true, 0.78, 0.35)
    var portal_lintel := _add_box("PortalLintel", Vector3(0, 8.1, -19.5), Vector3(9.2, 1.1, 1.5),
        Color(0.35, 0.29, 0.22), true, 0.84, 0.22)
    _apply_pbr_material(portal_left, portal_pbr)
    _apply_pbr_material(portal_right, portal_pbr)
    _apply_pbr_material(portal_lintel, portal_pbr)

    for x in [-14.0, 14.0]:
        for z in [-12.0, -3.0, 6.0, 15.0]:
            _add_column(Vector3(x, 0.0, z))
    _add_torch(Vector3(-5.4, 0.0, -17.4))
    _add_torch(Vector3(5.4, 0.0, -17.4))
    _add_torch(Vector3(-15.0, 0.0, 2.5))
    _add_torch(Vector3(15.0, 0.0, 2.5))
    _add_dust_motes()
    if stage == 1:
        _add_sunken_sanctum_decor()
    elif stage == 2:
        _add_crown_of_ash_decor()

func _add_sunken_sanctum_decor() -> void:
    var water_material := StandardMaterial3D.new()
    water_material.albedo_color = Color(0.025, 0.28, 0.36, 0.72)
    water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    water_material.roughness = 0.18
    water_material.metallic = 0.42
    water_material.emission_enabled = true
    water_material.emission = Color(0.015, 0.12, 0.18)
    for puddle in [Vector3(-8.0, -0.015, 1.0), Vector3(8.0, -0.015, 2.5), Vector3(0.0, -0.015, 14.0)]:
        var water := MeshInstance3D.new()
        var water_mesh := CylinderMesh.new()
        water_mesh.top_radius = 2.3
        water_mesh.bottom_radius = 2.3
        water_mesh.height = 0.035
        water.mesh = water_mesh
        water.position = puddle
        water.material_override = water_material
        add_child(water)
    var crystal_material := StandardMaterial3D.new()
    crystal_material.albedo_color = Color(0.08, 0.48, 0.62)
    crystal_material.metallic = 0.56
    crystal_material.roughness = 0.22
    crystal_material.emission_enabled = true
    crystal_material.emission = Color(0.02, 0.16, 0.24)
    for crystal_position in [Vector3(-12.0, 0.55, -5.0), Vector3(12.0, 0.55, -7.0), Vector3(-10.5, 0.55, 10.0), Vector3(10.5, 0.55, 11.0)]:
        var crystal := MeshInstance3D.new()
        var crystal_mesh := CylinderMesh.new()
        crystal_mesh.top_radius = 0.025
        crystal_mesh.bottom_radius = 0.34
        crystal_mesh.height = 1.1
        crystal_mesh.radial_segments = 6
        crystal.mesh = crystal_mesh
        crystal.position = crystal_position
        crystal.rotation_degrees.z = 12.0
        crystal.material_override = crystal_material
        add_child(crystal)

func _add_crown_of_ash_decor() -> void:
    var lava_material := StandardMaterial3D.new()
    lava_material.albedo_color = Color(0.78, 0.13, 0.025)
    lava_material.emission_enabled = true
    lava_material.emission = Color(1.0, 0.11, 0.012)
    lava_material.emission_energy_multiplier = 2.2
    lava_material.roughness = 0.38
    for index in range(6):
        var fissure := MeshInstance3D.new()
        var fissure_mesh := BoxMesh.new()
        fissure_mesh.size = Vector3(2.7, 0.035, 0.13)
        fissure.mesh = fissure_mesh
        fissure.position = Vector3(-12.5 + float(index) * 5.0, 0.025, -1.5 if index % 2 == 0 else 8.5)
        fissure.rotation_degrees.y = -12.0 if index % 2 == 0 else 18.0
        fissure.material_override = lava_material
        add_child(fissure)
    var ash_material := StandardMaterial3D.new()
    ash_material.albedo_color = Color(0.20, 0.075, 0.065)
    ash_material.roughness = 0.94
    for spike_position in [Vector3(-13.0, 0.72, -8.0), Vector3(13.0, 0.72, -8.0), Vector3(-14.0, 0.72, 9.0), Vector3(14.0, 0.72, 9.0)]:
        var spike := MeshInstance3D.new()
        var spike_mesh := CylinderMesh.new()
        spike_mesh.top_radius = 0.015
        spike_mesh.bottom_radius = 0.42
        spike_mesh.height = 1.45
        spike_mesh.radial_segments = 7
        spike.mesh = spike_mesh
        spike.position = spike_position
        spike.rotation_degrees.z = -7.0
        spike.material_override = ash_material
        add_child(spike)

func _add_box(node_name: String, position: Vector3, size: Vector3, color: Color,
        solid: bool, roughness: float = 0.82, metallic: float = 0.18) -> Node3D:
    var root: Node3D
    if solid:
        var body := StaticBody3D.new()
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
        root = body
    else:
        root = Node3D.new()
    root.name = node_name
    root.position = position
    var instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    instance.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    instance.material_override = material
    root.add_child(instance)
    add_child(root)
    return root

func _make_pbr_material(asset_id: String, tint: Color, tiling: float) -> StandardMaterial3D:
    var texture_root := "res://assets/textures/"
    var diffuse := load(texture_root + asset_id + "_diff_1k.jpg") as Texture2D
    var normal_map := load(texture_root + asset_id + "_nor_gl_1k.jpg") as Texture2D
    var roughness_map := load(texture_root + asset_id + "_rough_1k.jpg") as Texture2D
    if diffuse == null or normal_map == null or roughness_map == null:
        push_error("NOVA missing CC0 PBR maps for: " + asset_id)
        return null
    var material := StandardMaterial3D.new()
    material.albedo_color = tint
    material.albedo_texture = diffuse
    material.normal_enabled = true
    material.normal_texture = normal_map
    material.normal_scale = 0.78
    material.roughness = 0.90
    material.roughness_texture = roughness_map
    material.metallic = 0.0
    material.uv1_scale = Vector3.ONE * maxf(1.0, tiling)
    return material

func _apply_pbr_material(target: Node, material: StandardMaterial3D) -> void:
    if material == null:
        push_error("NOVA cannot apply a missing PBR material.")
        return
    var mesh_instance := _find_mesh_instance(target)
    if mesh_instance == null:
        push_error("NOVA PBR target has no MeshInstance3D: " + target.name)
        return
    mesh_instance.material_override = material

func _find_mesh_instance(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D:
        return node as MeshInstance3D
    for child in node.get_children():
        var found := _find_mesh_instance(child)
        if found != null:
            return found
    return null

func _add_cylinder(node_name: String, position: Vector3, radius: float, height: float,
        color: Color, solid: bool, roughness: float, metallic: float) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    instance.name = node_name
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 24
    instance.mesh = mesh
    instance.position = position
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    instance.material_override = material
    if solid:
        var body := StaticBody3D.new()
        body.position = position
        var collision := CollisionShape3D.new()
        var shape := CylinderShape3D.new()
        shape.radius = radius
        shape.height = height
        collision.shape = shape
        body.add_child(collision)
        add_child(body)
    add_child(instance)
    return instance

func _add_ritual_ring(radius: float, color: Color) -> void:
    var ring := MeshInstance3D.new()
    var mesh := TorusMesh.new()
    mesh.inner_radius = radius - 0.07
    mesh.outer_radius = radius + 0.07
    mesh.rings = 48
    mesh.ring_segments = 8
    ring.mesh = mesh
    ring.position.y = 0.035
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = 0.32
    material.metallic = 0.72
    material.emission_enabled = true
    material.emission = color * 0.18
    ring.material_override = material
    add_child(ring)

func _add_column(position: Vector3) -> void:
    _add_cylinder("PillarBase", position + Vector3(0, 0.48, 0), 1.0, 0.7,
        Color(0.25, 0.23, 0.22), true, 0.88, 0.16)
    _add_cylinder("AncientPillar", position + Vector3(0, 3.15, 0), 0.70, 5.0,
        Color(0.31, 0.28, 0.25), true, 0.90, 0.12)
    _add_cylinder("PillarCapital", position + Vector3(0, 5.85, 0), 0.95, 0.48,
        Color(0.39, 0.31, 0.23), true, 0.78, 0.20)

func _add_torch(position: Vector3) -> void:
    _add_cylinder("TorchStand", position + Vector3(0, 1.15, 0), 0.12, 2.3,
        Color(0.18, 0.10, 0.055), false, 0.78, 0.22)
    var flame := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.24
    sphere.height = 0.52
    flame.mesh = sphere
    flame.position = position + Vector3(0, 2.45, 0)
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 0.25, 0.055)
    material.emission_enabled = true
    material.emission = Color(1.0, 0.12, 0.018)
    material.emission_energy_multiplier = 2.4
    flame.material_override = material
    add_child(flame)

func _add_dust_motes() -> void:
    var particles := GPUParticles3D.new()
    particles.name = "AtmosphericAsh"
    particles.amount = 44
    particles.lifetime = 7.0
    particles.position = Vector3(0, 3.2, 0)
    particles.visibility_aabb = AABB(Vector3(-20, -4, -20), Vector3(40, 15, 40))
    var process := ParticleProcessMaterial.new()
    process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
    process.emission_box_extents = Vector3(17, 4, 17)
    process.direction = Vector3(0.08, 1.0, 0.02)
    process.spread = 22.0
    process.initial_velocity_min = 0.08
    process.initial_velocity_max = 0.26
    process.gravity = Vector3(0.0, 0.035, 0.0)
    process.scale_min = 0.012
    process.scale_max = 0.028
    particles.process_material = process
    var particle_mesh := SphereMesh.new()
    particle_mesh.radius = 0.045
    particle_mesh.height = 0.09
    var particle_material := StandardMaterial3D.new()
    particle_material.albedo_color = Color(0.72, 0.79, 0.88, 0.52)
    particle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    particles.draw_pass_1 = particle_mesh
    particles.material_override = particle_material
    particles.emitting = true
    add_child(particles)

func _spawn_encounter() -> void:
    player = PLAYER_SCRIPT.new() as NovaPlayer
    player.position = Vector3(0, 0.05, 7.0)
    player.input_enabled = false
    player.health_changed.connect(_on_player_health_changed)
    player.stamina_changed.connect(_on_player_stamina_changed)
    player.defeated.connect(_on_player_defeated)
    player.hit_confirmed.connect(_on_player_hit_confirmed)
    player.attack_started.connect(_on_player_attack_started)
    player.dodge_started.connect(_on_player_dodge_started)
    player.parry_success.connect(_on_parry_success)
    add_child(player)

    _make_enemy(Vector3(-5.2, 0.05, -3.0), false)
    _make_enemy(Vector3(5.2, 0.05, -4.2), false)
    _make_enemy(Vector3(0.0, 0.05, -10.5), true)

    camera_rig = CAMERA_SCRIPT.new() as NovaCameraRig
    camera_rig.follow_target = player
    add_child(camera_rig)

func _make_enemy(spawn: Vector3, boss_enemy: bool) -> void:
    var enemy := ENEMY_SCRIPT.new() as NovaEnemy
    enemy.position = spawn
    enemy.player = player
    enemy.is_boss = boss_enemy
    enemy.difficulty_scale = 1.0 + float(chapter_index) * 0.24
    enemy.chapter_variant = chapter_index
    enemy.defeated.connect(_on_enemy_defeated)
    enemy.attack_telegraph.connect(_on_enemy_telegraph)
    if boss_enemy:
        boss = enemy
        boss.health_changed.connect(_on_boss_health_changed)
        boss.phase_changed.connect(_on_boss_phase_changed)
    active_enemies.append(enemy)
    add_child(enemy)

func _start_cinematic_intro() -> void:
    camera_rig.start_intro(intro_timer, boss)
    intro_label.text = CHAPTER_NAMES[chapter_index]
    var tween := create_tween()
    tween.tween_interval(1.25)
    tween.tween_property(intro_label, "modulate:a", 0.0, 1.35)
    tween.tween_callback(func() -> void: intro_label.visible = false)

func _begin_combat() -> void:
    combat_started = true
    player.input_enabled = true
    camera_rig.clear_lock_target()
    for enemy in active_enemies:
        if is_instance_valid(enemy):
            enemy.activate()
    intro_label.visible = true
    intro_label.modulate.a = 1.0
    intro_label.text = "CHAPTER %d - THE WARDEN AWAKENS" % (chapter_index + 1)
    var tween := create_tween()
    tween.tween_interval(0.75)
    tween.tween_property(intro_label, "modulate:a", 0.0, 0.7)
    tween.tween_callback(func() -> void: intro_label.visible = false)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    layer.name = "CombatHUD"
    add_child(layer)

    var top_bar := PanelContainer.new()
    top_bar.position = Vector2(22, 42)
    top_bar.custom_minimum_size = Vector2(310, 94)
    layer.add_child(top_bar)
    var stats := VBoxContainer.new()
    stats.add_theme_constant_override("separation", 4)
    top_bar.add_child(stats)
    hud_label = Label.new()
    hud_label.text = "NOVA  |  VITALITY 160 / 160"
    hud_label.add_theme_font_size_override("font_size", 17)
    stats.add_child(hud_label)
    health_bar = ProgressBar.new()
    health_bar.max_value = NovaPlayer.MAX_HEALTH
    health_bar.value = NovaPlayer.MAX_HEALTH
    health_bar.custom_minimum_size = Vector2(270, 16)
    stats.add_child(health_bar)
    stamina_bar = ProgressBar.new()
    stamina_bar.max_value = NovaPlayer.MAX_STAMINA
    stamina_bar.value = NovaPlayer.MAX_STAMINA
    stamina_bar.custom_minimum_size = Vector2(270, 11)
    stats.add_child(stamina_bar)

    boss_panel = PanelContainer.new()
    boss_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
    boss_panel.position = Vector2(-190, 42)
    boss_panel.custom_minimum_size = Vector2(380, 58)
    layer.add_child(boss_panel)
    var boss_stats := VBoxContainer.new()
    boss_panel.add_child(boss_stats)
    var boss_name := Label.new()
    boss_name.text = BOSS_NAMES[chapter_index]
    boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    boss_name.add_theme_font_size_override("font_size", 15)
    boss_stats.add_child(boss_name)
    boss_bar = ProgressBar.new()
    boss_bar.max_value = 620
    boss_bar.value = 620
    boss_bar.custom_minimum_size = Vector2(340, 14)
    boss_stats.add_child(boss_bar)
    if is_instance_valid(boss):
        boss_bar.max_value = boss.max_health
        boss_bar.value = boss.health

    result_label = Label.new()
    result_label.set_anchors_preset(Control.PRESET_CENTER)
    result_label.position = Vector2(-260, -30)
    result_label.size = Vector2(520, 60)
    result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_label.add_theme_font_size_override("font_size", 30)
    result_label.visible = false
    layer.add_child(result_label)

    intro_label = Label.new()
    intro_label.set_anchors_preset(Control.PRESET_CENTER)
    intro_label.position = Vector2(-300, -95)
    intro_label.size = Vector2(600, 80)
    intro_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    intro_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    intro_label.add_theme_font_size_override("font_size", 38)
    intro_label.add_theme_color_override("font_color", Color(0.92, 0.79, 0.58))
    intro_label.text = "THE ASHEN GATE"
    layer.add_child(intro_label)

    var letterbox_top := ColorRect.new()
    letterbox_top.color = Color(0.005, 0.007, 0.012, 0.88)
    letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
    letterbox_top.custom_minimum_size = Vector2(0, 34)
    letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(letterbox_top)
    var letterbox_bottom := ColorRect.new()
    letterbox_bottom.color = Color(0.005, 0.007, 0.012, 0.88)
    letterbox_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    letterbox_bottom.custom_minimum_size = Vector2(0, 34)
    letterbox_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(letterbox_bottom)

    var poly_haven_credit := Label.new()
    poly_haven_credit.name = "PolyHavenCredits"
    poly_haven_credit.text = "ENVIRONMENT MATERIALS  ·  POWERED BY POLY HAVEN  ·  CC0"
    poly_haven_credit.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    poly_haven_credit.offset_left = 0.0
    poly_haven_credit.offset_right = 0.0
    poly_haven_credit.offset_top = -29.0
    poly_haven_credit.offset_bottom = -8.0
    poly_haven_credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    poly_haven_credit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    poly_haven_credit.add_theme_font_size_override("font_size", 9)
    poly_haven_credit.add_theme_color_override("font_color", Color(0.76, 0.80, 0.88, 0.78))
    poly_haven_credit.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(poly_haven_credit)

    _add_control_button(layer, "↑", Vector2(94, -208), "move_forward")
    _add_control_button(layer, "↓", Vector2(94, -78), "move_back")
    _add_control_button(layer, "←", Vector2(27, -143), "move_left")
    _add_control_button(layer, "→", Vector2(160, -143), "move_right")
    _add_action_button(layer, "LIGHT", Vector2(-210, -155), "light_attack")
    _add_action_button(layer, "HEAVY", Vector2(-110, -240), "heavy_attack")
    _add_action_button(layer, "DODGE", Vector2(-110, -75), "dodge")
    _add_action_button(layer, "GUARD", Vector2(-210, -75), "guard")
    _add_action_button(layer, "LOCK", Vector2(-210, -240), "lock_on")

    retry_button = Button.new()
    retry_button.text = "RETRY"
    retry_button.set_anchors_preset(Control.PRESET_CENTER)
    retry_button.position = Vector2(-70, 42)
    retry_button.custom_minimum_size = Vector2(140, 52)
    retry_button.visible = false
    retry_button.pressed.connect(_on_retry_pressed)
    layer.add_child(retry_button)

    continue_button = Button.new()
    continue_button.text = "NEXT CHAPTER"
    continue_button.set_anchors_preset(Control.PRESET_CENTER)
    continue_button.position = Vector2(-95, 42)
    continue_button.custom_minimum_size = Vector2(190, 52)
    continue_button.visible = false
    continue_button.pressed.connect(_on_continue_pressed)
    layer.add_child(continue_button)

func _add_control_button(layer: CanvasLayer, button_text: String, offset: Vector2, action: String) -> void:
    var button := Button.new()
    button.name = action
    button.text = button_text
    button.custom_minimum_size = Vector2(58, 58)
    button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    button.position = offset
    button.add_theme_font_size_override("font_size", 24)
    button.button_down.connect(_press_action.bind(action))
    button.button_up.connect(_release_action.bind(action))
    layer.add_child(button)

func _add_action_button(layer: CanvasLayer, button_text: String, offset: Vector2, action: String) -> void:
    var button := Button.new()
    button.name = action
    button.text = button_text
    button.custom_minimum_size = Vector2(84, 60)
    button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    button.position = offset
    button.add_theme_font_size_override("font_size", 15)
    if action == "light_attack":
        button.pressed.connect(_on_light_attack_pressed)
    elif action == "heavy_attack":
        button.pressed.connect(_on_heavy_attack_pressed)
    elif action == "dodge":
        button.pressed.connect(_on_dodge_pressed)
    elif action == "guard":
        button.button_down.connect(_on_guard_pressed)
        button.button_up.connect(_on_guard_released)
    else:
        button.pressed.connect(_on_lock_pressed)
    layer.add_child(button)

func _press_action(action: String) -> void:
    Input.action_press(action)

func _release_action(action: String) -> void:
    Input.action_release(action)

func _on_light_attack_pressed() -> void:
    if is_instance_valid(player):
        player.perform_light_attack()

func _on_heavy_attack_pressed() -> void:
    if is_instance_valid(player):
        player.perform_heavy_attack()

func _on_dodge_pressed() -> void:
    if is_instance_valid(player):
        player.perform_dodge()

func _on_guard_pressed() -> void:
    if is_instance_valid(player):
        player.set_guard(true)

func _on_guard_released() -> void:
    if is_instance_valid(player):
        player.set_guard(false)

func _on_lock_pressed() -> void:
    var live: Array[NovaEnemy] = []
    for enemy in active_enemies:
        if is_instance_valid(enemy) and enemy.health > 0:
            live.append(enemy)
    if live.is_empty():
        return
    lock_index = (lock_index + 1) % live.size()
    var target := live[lock_index]
    camera_rig.set_lock_target(target)
    player.lock_target = target

func _on_player_health_changed(current: int, maximum: int) -> void:
    if is_instance_valid(hud_label):
        hud_label.text = "NOVA  |  VITALITY %d / %d" % [current, maximum]
    if is_instance_valid(health_bar):
        health_bar.value = current

func _on_player_stamina_changed(current: float, maximum: float) -> void:
    if is_instance_valid(stamina_bar):
        stamina_bar.value = current

func _on_boss_health_changed(current: int, maximum: int) -> void:
    if is_instance_valid(boss_bar):
        boss_bar.max_value = maximum
        boss_bar.value = current

func _on_boss_phase_changed(phase: int) -> void:
    audio_fx.play_boss_phase()
    result_label.visible = true
    result_label.text = "PHASE %d — THE WARDEN ENRAGES" % phase
    camera_rig.shake(0.48, 0.42)
    var tween := create_tween()
    tween.tween_interval(1.15)
    tween.tween_property(result_label, "modulate:a", 0.0, 0.45)
    tween.tween_callback(func() -> void:
        result_label.visible = false
        result_label.modulate.a = 1.0
    )

func _on_enemy_telegraph(is_boss_enemy: bool) -> void:
    camera_rig.shake(0.10 if not is_boss_enemy else 0.20, 0.12 if not is_boss_enemy else 0.22)
    audio_fx.play_telegraph(is_boss_enemy)

func _on_player_attack_started(heavy: bool, combo: int) -> void:
    audio_fx.play_swing(heavy)

func _on_player_dodge_started() -> void:
    audio_fx.play_dodge()

func _on_player_hit_confirmed(target_position: Vector3, heavy: bool, combo: int) -> void:
    camera_rig.shake(0.16 if not heavy else 0.32, 0.12 if not heavy else 0.22)
    audio_fx.play_hit(heavy)
    _spawn_hit_sparks(target_position, heavy)

func _spawn_hit_sparks(position: Vector3, heavy: bool) -> void:
    var particles := GPUParticles3D.new()
    particles.amount = 12 if not heavy else 24
    particles.lifetime = 0.42 if not heavy else 0.62
    particles.one_shot = true
    var process := ParticleProcessMaterial.new()
    process.direction = Vector3(0.0, 0.7, 0.0)
    process.spread = 180.0
    process.initial_velocity_min = 1.5 if not heavy else 2.8
    process.initial_velocity_max = 3.8 if not heavy else 5.8
    process.gravity = Vector3(0.0, -4.5, 0.0)
    process.scale_min = 0.025
    process.scale_max = 0.075
    particles.process_material = process
    var spark := SphereMesh.new()
    spark.radius = 0.045
    spark.height = 0.09
    particles.draw_pass_1 = spark
    var material := StandardMaterial3D.new()
    material.albedo_color = Color(1.0, 0.66, 0.24)
    material.emission_enabled = true
    material.emission = Color(1.0, 0.23, 0.035)
    particles.material_override = material
    particles.global_position = position
    add_child(particles)
    particles.emitting = true
    get_tree().create_timer(1.2).timeout.connect(particles.queue_free)

func _on_parry_success() -> void:
    camera_rig.shake(0.34, 0.22)
    audio_fx.play_parry()
    result_label.visible = true
    result_label.text = "PERFECT PARRY"
    var tween := create_tween()
    tween.tween_interval(0.48)
    tween.tween_property(result_label, "modulate:a", 0.0, 0.3)
    tween.tween_callback(func() -> void:
        result_label.visible = false
        result_label.modulate.a = 1.0
    )

func _on_enemy_defeated(is_boss_enemy: bool) -> void:
    defeated_count += 1
    if is_boss_enemy:
        boss_defeated = true
        result_label.visible = true
        var final_chapter := chapter_index >= CHAPTER_NAMES.size() - 1
        result_label.text = "THE ANCIENT WARRIOR RISES" if final_chapter else "CHAPTER %d COMPLETE" % (chapter_index + 1)
        continue_button.text = "REPLAY CAMPAIGN" if final_chapter else "NEXT CHAPTER"
        continue_button.visible = true
        retry_button.visible = false
        _save_campaign_progress(chapter_index if final_chapter else chapter_index + 1, final_chapter)
        camera_rig.shake(0.72, 0.65)
    elif defeated_count >= 2 and not boss_defeated:
        result_label.visible = true
        result_label.text = "THE GATE GUARDIANS FALL"
    if boss_defeated:
        for enemy in active_enemies:
            if is_instance_valid(enemy):
                enemy.deactivate()

func _show_campaign_complete() -> void:
    combat_started = true
    player.input_enabled = false
    for enemy in active_enemies:
        if is_instance_valid(enemy):
            enemy.deactivate()
    intro_label.visible = false
    boss_panel.visible = false
    retry_button.visible = false
    result_label.visible = true
    result_label.text = "THE THREE REALMS ARE RESTORED"
    continue_button.text = "REPLAY CAMPAIGN"
    continue_button.visible = true

func _on_player_defeated() -> void:
    result_label.visible = true
    result_label.text = "THE WARRIOR HAS FALLEN"
    retry_button.visible = true
    continue_button.visible = false
    for enemy in active_enemies:
        if is_instance_valid(enemy):
            enemy.deactivate()

func _on_retry_pressed() -> void:
    get_tree().reload_current_scene()

func _on_continue_pressed() -> void:
    if chapter_index >= CHAPTER_NAMES.size() - 1:
        _save_campaign_progress(0, false)
    get_tree().reload_current_scene()

func _load_campaign_progress(path: String = SAVE_PATH) -> void:
    var config := ConfigFile.new()
    if config.load(path) != OK:
        chapter_index = 0
        unlocked_chapter = 0
        campaign_complete = false
        return
    chapter_index = clampi(int(config.get_value("progress", "current_chapter", 0)), 0, CHAPTER_NAMES.size() - 1)
    unlocked_chapter = clampi(int(config.get_value("progress", "unlocked_chapter", 0)), 0, CHAPTER_NAMES.size() - 1)
    campaign_complete = bool(config.get_value("progress", "campaign_complete", false))

func _save_campaign_progress(next_chapter: int, is_complete: bool, path: String = SAVE_PATH) -> void:
    var config := ConfigFile.new()
    config.load(path)
    unlocked_chapter = maxi(unlocked_chapter, next_chapter)
    var current_to_save := clampi(next_chapter, 0, CHAPTER_NAMES.size() - 1)
    campaign_complete = is_complete
    config.set_value("progress", "current_chapter", current_to_save)
    config.set_value("progress", "unlocked_chapter", unlocked_chapter)
    config.set_value("progress", "campaign_complete", campaign_complete)
    var save_error := config.save(path)
    if save_error != OK:
        push_warning("Could not save NOVA campaign progress: %s" % error_string(save_error))
