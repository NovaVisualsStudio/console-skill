extends CharacterBody3D
class_name NovaEnemy

signal defeated(is_boss: bool)
signal health_changed(current: int, maximum: int)
signal phase_changed(phase: int)
signal attack_telegraph(is_boss: bool)
signal attack_landed(damage: int)

enum BrainState { CHASE, TELEGRAPH, STRIKE, RECOVERY, STAGGER, DEAD }

var player: Node3D
var is_boss := false
var active := false
var health := 80
var max_health := 80
var phase := 1
var move_speed := 2.6
var attack_range := 1.9
var attack_damage := 12
var telegraph_duration := 0.64
var current_state: BrainState = BrainState.CHASE
var state_timer := 0.0
var attack_cooldown := 0.35
var body_mesh: MeshInstance3D
var telegraph_mesh: MeshInstance3D
var body_material: StandardMaterial3D
var _strike_done := false

func _ready() -> void:
    add_to_group("enemies")
    if is_boss:
        add_to_group("boss")
        health = 620
        max_health = 620
        move_speed = 1.55
        attack_range = 3.65
        attack_damage = 28
        telegraph_duration = 0.95
    _build_enemy()
    health_changed.emit(health, max_health)

func _build_enemy() -> void:
    var radius := 0.48 if not is_boss else 0.98
    var height := 1.85 if not is_boss else 3.35
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = radius
    capsule.height = height
    collider.shape = capsule
    collider.position.y = height * 0.5
    add_child(collider)

    body_mesh = MeshInstance3D.new()
    var body := CapsuleMesh.new()
    body.radius = radius
    body.height = height
    body_mesh.mesh = body
    body_mesh.position.y = height * 0.5
    body_material = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.34, 0.095, 0.075) if not is_boss else Color(0.15, 0.075, 0.19)
    body_material.roughness = 0.68
    body_material.metallic = 0.30
    body_mesh.material_override = body_material
    add_child(body_mesh)

    var armor := MeshInstance3D.new()
    var armor_mesh := BoxMesh.new()
    armor_mesh.size = Vector3(1.0, 0.34, 0.68) if not is_boss else Vector3(2.05, 0.62, 1.26)
    armor.mesh = armor_mesh
    armor.position = Vector3(0.0, height * 0.66, 0.0)
    armor.material_override = _material(Color(0.36, 0.24, 0.16), 0.42, 0.76)
    body_mesh.add_child(armor)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = radius * 0.52
    head_mesh.height = radius * 1.05
    head.mesh = head_mesh
    head.position = Vector3(0.0, height * 0.88, -radius * 0.20)
    head.material_override = _material(Color(0.26, 0.12, 0.10), 0.76, 0.08)
    add_child(head)

    var eye_mat := StandardMaterial3D.new()
    eye_mat.albedo_color = Color(1.0, 0.20, 0.045)
    eye_mat.emission_enabled = true
    eye_mat.emission = Color(0.95, 0.075, 0.012)
    var eye_size := 0.11 if not is_boss else 0.19
    for side in [-1.0, 1.0]:
        var eye := MeshInstance3D.new()
        var eye_mesh := SphereMesh.new()
        eye_mesh.radius = eye_size
        eye_mesh.height = eye_size * 2.0
        eye.mesh = eye_mesh
        eye.position = Vector3(side * radius * 0.24, height * 0.88, -radius * 0.68)
        eye.material_override = eye_mat
        add_child(eye)
        if is_boss:
            var horn := MeshInstance3D.new()
            var horn_mesh := CylinderMesh.new()
            horn_mesh.top_radius = 0.015
            horn_mesh.bottom_radius = 0.15
            horn_mesh.height = 0.78
            horn.mesh = horn_mesh
            horn.position = Vector3(side * radius * 0.68, height * 0.98, 0.0)
            horn.rotation.z = side * -0.48
            horn.material_override = _material(Color(0.12, 0.09, 0.085), 0.94, 0.0)
            add_child(horn)

    telegraph_mesh = MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = 1.0 if not is_boss else 2.0
    ring.outer_radius = 1.12 if not is_boss else 2.18
    telegraph_mesh.mesh = ring
    telegraph_mesh.position.y = 0.06
    var ring_material := StandardMaterial3D.new()
    ring_material.albedo_color = Color(1.0, 0.12, 0.025, 0.75)
    ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    ring_material.emission_enabled = true
    ring_material.emission = Color(0.95, 0.045, 0.008)
    telegraph_mesh.material_override = ring_material
    telegraph_mesh.visible = false
    add_child(telegraph_mesh)

func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    return material

func activate() -> void:
    if current_state != BrainState.DEAD:
        active = true
        current_state = BrainState.CHASE

func deactivate() -> void:
    active = false
    velocity = Vector3.ZERO
    if is_instance_valid(telegraph_mesh):
        telegraph_mesh.visible = false

func _physics_process(delta: float) -> void:
    if not active or current_state == BrainState.DEAD or not is_instance_valid(player):
        return
    attack_cooldown = maxf(0.0, attack_cooldown - delta)

    var offset: Vector3 = player.global_position - global_position
    offset.y = 0.0
    var distance := offset.length()

    match current_state:
        BrainState.CHASE:
            if distance > attack_range:
                _move_toward_player(offset, delta)
            elif attack_cooldown <= 0.0:
                _begin_telegraph()
            else:
                _stop_horizontal(delta)
        BrainState.TELEGRAPH:
            _stop_horizontal(delta)
            state_timer -= delta
            if is_instance_valid(telegraph_mesh):
                telegraph_mesh.rotation.y += delta * 1.8
            if state_timer <= 0.0:
                current_state = BrainState.STRIKE
                state_timer = 0.22 if is_boss else 0.16
                _strike_done = false
                _execute_strike()
        BrainState.STRIKE:
            _stop_horizontal(delta)
            state_timer -= delta
            if state_timer <= 0.0:
                current_state = BrainState.RECOVERY
                state_timer = 0.82 if is_boss else 0.58
                if is_instance_valid(telegraph_mesh):
                    telegraph_mesh.visible = false
        BrainState.RECOVERY:
            _stop_horizontal(delta)
            state_timer -= delta
            if state_timer <= 0.0:
                current_state = BrainState.CHASE
                attack_cooldown = 0.32 if not is_boss else 0.50
        BrainState.STAGGER:
            _stop_horizontal(delta)
            state_timer -= delta
            if state_timer <= 0.0:
                current_state = BrainState.CHASE

    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()

func _move_toward_player(offset: Vector3, delta: float) -> void:
    if offset.length_squared() <= 0.001:
        return
    var direction := offset.normalized()
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed
    rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 5.5)

func _stop_horizontal(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, move_speed * 7.0 * delta)
    velocity.z = move_toward(velocity.z, 0.0, move_speed * 7.0 * delta)

func _begin_telegraph() -> void:
    current_state = BrainState.TELEGRAPH
    state_timer = telegraph_duration
    _strike_done = false
    if is_instance_valid(telegraph_mesh):
        telegraph_mesh.visible = true
    attack_telegraph.emit(is_boss)

func _execute_strike() -> void:
    if _strike_done:
        return
    _strike_done = true
    if not is_instance_valid(player) or not player.has_method("take_damage"):
        return
    var offset: Vector3 = player.global_position - global_position
    offset.y = 0.0
    var strike_range := attack_range * (1.42 if is_boss else 1.12)
    if offset.length() <= strike_range:
        player.take_damage(attack_damage, global_position, is_boss)
        attack_landed.emit(attack_damage)

func take_damage(amount: int, source_position: Vector3 = Vector3.ZERO, heavy: bool = false) -> void:
    if current_state == BrainState.DEAD or amount <= 0:
        return
    health = maxi(0, health - amount)
    health_changed.emit(health, max_health)
    if is_boss and phase == 1 and health <= int(float(max_health) * 0.5):
        phase = 2
        move_speed = 2.05
        attack_damage = 38
        telegraph_duration = 0.72
        phase_changed.emit(phase)
        if body_material != null:
            body_material.albedo_color = Color(0.34, 0.065, 0.12)
            body_material.emission_enabled = true
            body_material.emission = Color(0.22, 0.012, 0.035)
    if is_instance_valid(body_material):
        var original := body_material.albedo_color
        body_material.albedo_color = Color(1.0, 0.58, 0.28)
        var tween := create_tween()
        tween.tween_property(body_material, "albedo_color", original, 0.20)
    if health <= 0:
        current_state = BrainState.DEAD
        active = false
        defeated.emit(is_boss)
        queue_free()
    else:
        current_state = BrainState.STAGGER
        state_timer = 0.24 if not heavy else 0.38
