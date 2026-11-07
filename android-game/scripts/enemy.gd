extends CharacterBody3D
class_name NovaEnemy

signal defeated(is_boss: bool)

var player: Node3D
var is_boss := false
var health := 80
var move_speed := 2.6
var attack_range := 1.75
var attack_damage := 12
var attack_cooldown := 0.0
var body_mesh: MeshInstance3D

func _ready() -> void:
    add_to_group("enemies")
    if is_boss:
        health = 520
        move_speed = 1.55
        attack_range = 2.8
        attack_damage = 28
    _build_enemy()

func _build_enemy() -> void:
    var radius := 0.48 if not is_boss else 0.92
    var height := 1.8 if not is_boss else 3.2
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = radius
    capsule.height = height
    collider.shape = capsule
    collider.position.y = height * 0.5
    add_child(collider)

    body_mesh = MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    body_mesh.mesh = mesh
    body_mesh.position.y = height * 0.5
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.45, 0.12, 0.10) if not is_boss else Color(0.19, 0.08, 0.25)
    mat.roughness = 0.72
    mat.metallic = 0.18
    body_mesh.material_override = mat
    add_child(body_mesh)

    var eye := MeshInstance3D.new()
    var eye_mesh := SphereMesh.new()
    eye_mesh.radius = 0.12 if not is_boss else 0.2
    eye_mesh.height = eye_mesh.radius * 2.0
    eye.mesh = eye_mesh
    eye.position = Vector3(0, height * 0.72, -radius * 0.82)
    var eye_mat := StandardMaterial3D.new()
    eye_mat.albedo_color = Color(1.0, 0.28, 0.08)
    eye_mat.emission_enabled = true
    eye_mat.emission = Color(0.8, 0.08, 0.015)
    eye.material_override = eye_mat
    add_child(eye)

func _physics_process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    if not is_instance_valid(player):
        velocity = Vector3.ZERO
        return

    var offset: Vector3 = player.global_position - global_position
    offset.y = 0.0
    var distance := offset.length()
    if distance > attack_range:
        var direction := offset.normalized()
        velocity.x = direction.x * move_speed
        velocity.z = direction.z * move_speed
        if direction.length_squared() > 0.01:
            rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), delta * 5.0)
    else:
        velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)
        if attack_cooldown <= 0.0 and player.has_method("take_damage"):
            attack_cooldown = 1.35 if not is_boss else 2.4
            player.take_damage(attack_damage)
    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()

func take_damage(amount: int) -> void:
    if health <= 0:
        return
    health = maxi(0, health - amount)
    if is_instance_valid(body_mesh):
        var material := body_mesh.material_override as StandardMaterial3D
        if material != null:
            var original: Color = material.albedo_color
            material.albedo_color = Color(1.0, 0.72, 0.35)
            var tween := create_tween()
            tween.tween_property(material, "albedo_color", original, 0.16)
    if health == 0:
        defeated.emit(is_boss)
        queue_free()
