extends Node3D

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")

var player: NovaPlayer
var hud_label: Label
var result_label: Label
var defeated_count := 0
var boss_defeated := false

func _ready() -> void:
    _ensure_input_actions()
    _build_world()
    _spawn_encounter()
    _build_hud()

func _ensure_input_actions() -> void:
    var keys := {
        "move_forward": KEY_W,
        "move_back": KEY_S,
        "move_left": KEY_A,
        "move_right": KEY_D
    }
    for action in keys:
        if not InputMap.has_action(action):
            InputMap.add_action(action)
        var event := InputEventKey.new()
        event.physical_keycode = keys[action]
        InputMap.action_add_event(action, event)
    for action in ["attack", "dodge", "guard"]:
        if not InputMap.has_action(action):
            InputMap.add_action(action)

func _build_world() -> void:
    var environment := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.025, 0.035, 0.055)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.42, 0.48, 0.62)
    env.ambient_light_energy = 0.7
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    environment.environment = env
    add_child(environment)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48, -32, 0)
    sun.light_energy = 1.25
    sun.shadow_enabled = true
    add_child(sun)

    _add_box("ArenaFloor", Vector3(0, -0.5, 0), Vector3(34, 1, 34),
        Color(0.19, 0.20, 0.22), true)
    _add_box("NorthWall", Vector3(0, 2.0, -17), Vector3(34, 4, 1),
        Color(0.24, 0.22, 0.20), true)
    _add_box("SouthWall", Vector3(0, 2.0, 17), Vector3(34, 4, 1),
        Color(0.24, 0.22, 0.20), true)
    _add_box("WestWall", Vector3(-17, 2.0, 0), Vector3(1, 4, 34),
        Color(0.24, 0.22, 0.20), true)
    _add_box("EastWall", Vector3(17, 2.0, 0), Vector3(1, 4, 34),
        Color(0.24, 0.22, 0.20), true)

    for x in [-12.0, -4.0, 4.0, 12.0]:
        _add_box("AncientPillar", Vector3(x, 2.0, -12.5), Vector3(1.5, 4.0, 1.5),
            Color(0.34, 0.30, 0.25), true)
        _add_box("AncientPillar", Vector3(x, 2.0, 12.5), Vector3(1.5, 4.0, 1.5),
            Color(0.34, 0.30, 0.25), true)

func _add_box(node_name: String, position: Vector3, size: Vector3, color: Color, solid: bool) -> void:
    var root: Node3D
    if solid:
        root = StaticBody3D.new()
        var collision := CollisionShape3D.new()
        var shape := BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        root.add_child(collision)
    else:
        root = Node3D.new()
    root.name = node_name
    root.position = position
    var mesh_instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.92
    mesh_instance.material_override = mat
    root.add_child(mesh_instance)
    add_child(root)

func _spawn_encounter() -> void:
    player = PLAYER_SCRIPT.new() as NovaPlayer
    player.position = Vector3(0, 0.05, 5.0)
    player.health_changed.connect(_on_health_changed)
    player.defeated.connect(_on_player_defeated)
    add_child(player)

    _make_enemy(Vector3(-3.5, 0.05, -3.0), false)
    _make_enemy(Vector3(3.5, 0.05, -4.0), false)
    _make_enemy(Vector3(0, 0.05, -10.0), true)

    var camera := Camera3D.new()
    camera.position = Vector3(0, 3.8, 8.2)
    camera.current = true
    player.add_child(camera)
    camera.look_at(Vector3(0, 1.2, 0), Vector3.UP)
    camera.fov = 72.0

func _make_enemy(spawn: Vector3, boss: bool) -> void:
    var enemy := ENEMY_SCRIPT.new() as NovaEnemy
    enemy.position = spawn
    enemy.player = player
    enemy.is_boss = boss
    enemy.defeated.connect(_on_enemy_defeated)
    add_child(enemy)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := PanelContainer.new()
    panel.position = Vector2(22, 18)
    panel.custom_minimum_size = Vector2(330, 74)
    layer.add_child(panel)

    hud_label = Label.new()
    hud_label.text = "NOVA  |  VITALITY 160 / 160\nDEFEATED 0  |  BOSS: ACTIVE"
    hud_label.add_theme_font_size_override("font_size", 20)
    panel.add_child(hud_label)

    result_label = Label.new()
    result_label.position = Vector2(430, 28)
    result_label.size = Vector2(420, 50)
    result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    result_label.add_theme_font_size_override("font_size", 28)
    layer.add_child(result_label)

    _add_control_button(layer, "↑", Vector2(104, -196), "move_forward", "left")
    _add_control_button(layer, "↓", Vector2(104, -72), "move_back", "left")
    _add_control_button(layer, "←", Vector2(40, -134), "move_left", "left")
    _add_control_button(layer, "→", Vector2(168, -134), "move_right", "left")
    _add_action_button(layer, "HIT", Vector2(-190, -120), "attack")
    _add_action_button(layer, "DODGE", Vector2(-112, -192), "dodge")
    _add_action_button(layer, "GUARD", Vector2(-112, -48), "guard")

func _add_control_button(layer: CanvasLayer, label_text: String, offset: Vector2,
        action: String, side: String) -> void:
    var button := Button.new()
    button.text = label_text
    button.custom_minimum_size = Vector2(58, 58)
    button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
    button.position = offset
    button.add_theme_font_size_override("font_size", 24)
    button.button_down.connect(_press_action.bind(action))
    button.button_up.connect(_release_action.bind(action))
    layer.add_child(button)

func _add_action_button(layer: CanvasLayer, label_text: String, offset: Vector2,
        action: String) -> void:
    var button := Button.new()
    button.text = label_text
    button.custom_minimum_size = Vector2(82, 62)
    button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
    button.position = offset
    button.add_theme_font_size_override("font_size", 17)
    if action == "attack":
        button.pressed.connect(_on_attack_pressed)
    elif action == "dodge":
        button.pressed.connect(_on_dodge_pressed)
    else:
        button.button_down.connect(_press_action.bind(action))
        button.button_up.connect(_release_action.bind(action))
    layer.add_child(button)

func _press_action(action: String) -> void:
    Input.action_press(action)

func _release_action(action: String) -> void:
    Input.action_release(action)

func _on_attack_pressed() -> void:
    if is_instance_valid(player):
        player.perform_attack()

func _on_dodge_pressed() -> void:
    if is_instance_valid(player):
        player.perform_dodge()

func _on_health_changed(current: int, maximum: int) -> void:
    if is_instance_valid(hud_label):
        hud_label.text = "NOVA  |  VITALITY %d / %d\nDEFEATED %d  |  BOSS: %s" % [
            current, maximum, defeated_count, "DOWN" if boss_defeated else "ACTIVE"
        ]

func _on_enemy_defeated(is_boss: bool) -> void:
    defeated_count += 1
    if is_boss:
        boss_defeated = true
        result_label.text = "ARENA CLEARED"
    _on_health_changed(player.health, player.MAX_HEALTH)

func _on_player_defeated() -> void:
    result_label.text = "YOU HAVE FALLEN  |  RESTART TO RETRY"
