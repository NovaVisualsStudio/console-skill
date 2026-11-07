extends CharacterBody3D
class_name NovaPlayer

signal health_changed(current: int, maximum: int)
signal defeated

const WALK_SPEED := 5.2
const DODGE_SPEED := 12.0
const DODGE_DURATION := 0.24
const ATTACK_RANGE := 2.8
const MAX_HEALTH := 160

var health := MAX_HEALTH
var dodge_timer := 0.0
var attack_cooldown := 0.0
var invulnerable := false
var weapon_pivot: Node3D
var body_mesh: MeshInstance3D

func _ready() -> void:
    add_to_group("player")
    _build_character()
    health_changed.emit(health, MAX_HEALTH)

func _build_character() -> void:
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.42
    capsule.height = 1.75
    collider.shape = capsule
    collider.position.y = 0.88
    add_child(collider)

    body_mesh = MeshInstance3D.new()
    var body := CapsuleMesh.new()
    body.radius = 0.42
    body.height = 1.75
    body_mesh.mesh = body
    body_mesh.position.y = 0.9
    body_mesh.material_override = _material(Color(0.16, 0.24, 0.34), 0.55, 0.35)
    add_child(body_mesh)

    var head := MeshInstance3D.new()
    var head_mesh := SphereMesh.new()
    head_mesh.radius = 0.25
    head_mesh.height = 0.5
    head.mesh = head_mesh
    head.position = Vector3(0, 1.95, 0)
    head.material_override = _material(Color(0.68, 0.48, 0.31), 0.8, 0.0)
    add_child(head)

    weapon_pivot = Node3D.new()
    weapon_pivot.position = Vector3(0.55, 1.15, -0.2)
    add_child(weapon_pivot)

    var handle := MeshInstance3D.new()
    var handle_mesh := CylinderMesh.new()
    handle_mesh.top_radius = 0.055
    handle_mesh.bottom_radius = 0.07
    handle_mesh.height = 0.85
    handle.mesh = handle_mesh
    handle.rotation.z = -0.35
    handle.material_override = _material(Color(0.25, 0.13, 0.07), 0.9, 0.1)
    weapon_pivot.add_child(handle)

    var blade := MeshInstance3D.new()
    var blade_mesh := BoxMesh.new()
    blade_mesh.size = Vector3(0.22, 0.62, 0.12)
    blade.mesh = blade_mesh
    blade.position = Vector3(0.0, 0.48, 0.0)
    blade.rotation.z = -0.25
    blade.material_override = _material(Color(0.58, 0.66, 0.72), 0.3, 0.8)
    weapon_pivot.add_child(blade)

func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = roughness
    mat.metallic = metallic
    return mat

func _physics_process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    dodge_timer = maxf(0.0, dodge_timer - delta)
    invulnerable = dodge_timer > 0.0

    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = 0.0

    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var move_direction := Vector3(input_vector.x, 0.0, input_vector.y)
    if move_direction.length_squared() > 0.01:
        move_direction = move_direction.normalized()
        rotation.y = lerp_angle(rotation.y, atan2(-move_direction.x, -move_direction.z), delta * 12.0)

    if dodge_timer > 0.0:
        velocity.x = -global_transform.basis.z.x * DODGE_SPEED
        velocity.z = -global_transform.basis.z.z * DODGE_SPEED
    elif Input.is_action_pressed("guard"):
        velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 8.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 8.0 * delta)
    else:
        velocity.x = move_direction.x * WALK_SPEED
        velocity.z = move_direction.z * WALK_SPEED

    move_and_slide()

func perform_attack() -> void:
    if attack_cooldown > 0.0 or health <= 0:
        return
    attack_cooldown = 0.48
    var tween := create_tween()
    tween.tween_property(weapon_pivot, "rotation:z", -1.25, 0.10)
    tween.tween_property(weapon_pivot, "rotation:z", 0.0, 0.18)
    var forward := -global_transform.basis.z
    for target in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(target) or not target.has_method("take_damage"):
            continue
        var offset: Vector3 = target.global_position - global_position
        var distance := offset.length()
        if distance <= ATTACK_RANGE and distance > 0.01 and forward.dot(offset.normalized()) > 0.18:
            target.take_damage(34)

func perform_dodge() -> void:
    if health <= 0 or dodge_timer > 0.0:
        return
    dodge_timer = DODGE_DURATION
    invulnerable = true

func take_damage(amount: int) -> void:
    if health <= 0 or invulnerable:
        return
    if Input.is_action_pressed("guard"):
        amount = maxi(1, int(round(float(amount) * 0.3)))
    health = maxi(0, health - amount)
    health_changed.emit(health, MAX_HEALTH)
    if health == 0:
        defeated.emit()
