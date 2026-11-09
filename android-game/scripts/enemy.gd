extends CharacterBody3D
class_name NovaEnemy

signal defeated(is_boss: bool)
signal health_changed(current: int, maximum: int)
signal phase_changed(phase: int)
signal attack_telegraph(is_boss: bool)
signal attack_landed(damage: int)

const HUMANOID_SCRIPT = preload("res://scripts/humanoid_rig.gd")

enum BrainState { CHASE, TELEGRAPH, STRIKE, RECOVERY, STAGGER, DEAD }
enum AttackPattern { MELEE, SWEEP, SLAM, THRUST, RING_BURST }

var player: Node3D
var is_boss := false
var difficulty_scale := 1.0
var chapter_variant := 0
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
var humanoid: NovaHumanoidRig
var telegraph_mesh: MeshInstance3D
var telegraph_material: StandardMaterial3D
var body_material: StandardMaterial3D
var _strike_done := false
var current_attack_pattern: AttackPattern = AttackPattern.MELEE
var attack_pattern_index := 0
var flank_side := 0.0
var last_attack_hit := false

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
    health = maxi(1, roundi(float(health) * difficulty_scale))
    max_health = health
    move_speed *= 1.0 + (difficulty_scale - 1.0) * 0.22
    attack_damage = maxi(1, roundi(float(attack_damage) * difficulty_scale))
    telegraph_duration = maxf(0.48, telegraph_duration - (difficulty_scale - 1.0) * 0.16)
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

    humanoid = HUMANOID_SCRIPT.new() as NovaHumanoidRig
    humanoid.name = "EnemyHumanoid"
    var enemy_tints := [Color(0.29, 0.12, 0.11), Color(0.08, 0.25, 0.28), Color(0.31, 0.08, 0.06)]
    var boss_tints := [Color(0.17, 0.10, 0.25), Color(0.07, 0.19, 0.26), Color(0.25, 0.065, 0.035)]
    var accent_tints := [Color(0.58, 0.22, 0.10), Color(0.16, 0.62, 0.70), Color(0.92, 0.28, 0.055)]
    var palette_index := clampi(chapter_variant, 0, 2)
    humanoid.tint_color = enemy_tints[palette_index] if not is_boss else boss_tints[palette_index]
    humanoid.armor_style = "enemy" if not is_boss else "boss"
    humanoid.accent_color = accent_tints[palette_index]
    humanoid.character_scale = 1.0 if not is_boss else 1.55
    add_child(humanoid)
    body_mesh = humanoid.primary_mesh
    body_material = humanoid.primary_material
    humanoid.play_action("idle")
    _build_enemy_weapon()
    telegraph_mesh = MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = 1.0 if not is_boss else 2.0
    ring.outer_radius = 1.12 if not is_boss else 2.18
    telegraph_mesh.mesh = ring
    telegraph_mesh.position.y = 0.06
    telegraph_material = StandardMaterial3D.new()
    telegraph_material.albedo_color = Color(1.0, 0.12, 0.025, 0.75)
    telegraph_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    telegraph_material.emission_enabled = true
    telegraph_material.emission = Color(0.95, 0.045, 0.008)
    telegraph_mesh.material_override = telegraph_material
    telegraph_mesh.visible = false
    add_child(telegraph_mesh)

func _build_enemy_weapon() -> void:
    var attachment := humanoid.attach_to_bone("hand_r")
    if attachment == humanoid:
        return
    var weapon := Node3D.new()
    weapon.name = "WardenBlade" if is_boss else "GuardianSword"
    weapon.position = Vector3(0.0, -0.10, 0.02)
    attachment.add_child(weapon)
    var grip := MeshInstance3D.new()
    var grip_mesh := CylinderMesh.new()
    grip_mesh.top_radius = 0.035
    grip_mesh.bottom_radius = 0.045
    grip_mesh.height = 0.42 if not is_boss else 0.62
    grip.mesh = grip_mesh
    grip.position.y = -0.08
    grip.material_override = _material(Color(0.16, 0.075, 0.035), 0.88, 0.08)
    weapon.add_child(grip)
    var blade := MeshInstance3D.new()
    var blade_mesh := BoxMesh.new()
    blade_mesh.size = Vector3(0.13, 0.78, 0.055) if not is_boss else Vector3(0.20, 1.22, 0.075)
    blade.mesh = blade_mesh
    blade.position.y = 0.48 if not is_boss else 0.73
    blade.material_override = _material(Color(0.48, 0.57, 0.66), 0.24, 0.94)
    weapon.add_child(blade)
    var guard := MeshInstance3D.new()
    var guard_mesh := BoxMesh.new()
    guard_mesh.size = Vector3(0.34, 0.075, 0.10) if not is_boss else Vector3(0.48, 0.10, 0.14)
    guard.mesh = guard_mesh
    guard.position.y = 0.14
    guard.material_override = _material(Color(0.56, 0.34, 0.12), 0.32, 0.86)
    weapon.add_child(guard)

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
        attack_cooldown = 0.42 + (0.58 if flank_side > 0.0 else 0.0) if not is_boss else 0.72

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
                humanoid.play_action("walk")
                _move_toward_player(offset, delta)
            elif attack_cooldown <= 0.0:
                _begin_telegraph()
            elif not is_boss and distance < attack_range * 1.65:
                humanoid.play_action("walk")
                _orbit_player(offset, delta)
            else:
                humanoid.play_action("idle")
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
    if not is_boss and absf(flank_side) > 0.1 and offset.length() < attack_range * 2.6:
        var tangent := Vector3(-direction.z, 0.0, direction.x) * flank_side
        direction = (direction + tangent * 0.22).normalized()
    direction = (direction + _get_separation_vector() * 0.38).normalized()
    velocity.x = direction.x * move_speed
    velocity.z = direction.z * move_speed
    rotation.y = lerp_angle(rotation.y, atan2(-offset.normalized().x, -offset.normalized().z), delta * 5.5)

func _orbit_player(offset: Vector3, delta: float) -> void:
    if offset.length_squared() <= 0.001:
        _stop_horizontal(delta)
        return
    var radial := offset.normalized()
    var tangent := Vector3(-radial.z, 0.0, radial.x) * (1.0 if flank_side >= 0.0 else -1.0)
    var orbit_velocity := tangent * move_speed * 0.58 + radial * move_speed * 0.10
    velocity.x = orbit_velocity.x
    velocity.z = orbit_velocity.z
    rotation.y = lerp_angle(rotation.y, atan2(-radial.x, -radial.z), delta * 6.0)

func _get_separation_vector() -> Vector3:
    var separation := Vector3.ZERO
    for other in get_tree().get_nodes_in_group("enemies"):
        if other == self or not is_instance_valid(other):
            continue
        var away: Vector3 = global_position - other.global_position
        away.y = 0.0
        var distance := away.length()
        if distance > 0.01 and distance < 1.65:
            separation += away.normalized() * ((1.65 - distance) / 1.65)
    return separation

func _stop_horizontal(delta: float) -> void:
    velocity.x = move_toward(velocity.x, 0.0, move_speed * 7.0 * delta)
    velocity.z = move_toward(velocity.z, 0.0, move_speed * 7.0 * delta)

func _begin_telegraph() -> void:
    current_state = BrainState.TELEGRAPH
    _strike_done = false
    last_attack_hit = false
    if is_boss:
        var pattern_count := 5 if phase >= 2 else 2
        var pattern_index := attack_pattern_index % pattern_count
        if pattern_index == 0:
            current_attack_pattern = AttackPattern.MELEE
        elif pattern_index == 1:
            current_attack_pattern = AttackPattern.SWEEP
        else:
            current_attack_pattern = AttackPattern.SLAM
        attack_pattern_index += 1
        match current_attack_pattern:
            AttackPattern.MELEE:
                state_timer = telegraph_duration
                if is_instance_valid(telegraph_mesh):
                    var radius_scale := attack_range * 1.42 / 2.18
                    telegraph_mesh.scale = Vector3(radius_scale, 1.0, radius_scale)
                    telegraph_mesh.rotation = Vector3.ZERO
                if is_instance_valid(telegraph_material):
                    telegraph_material.albedo_color = Color(1.0, 0.18, 0.06, 0.82)
                    telegraph_material.emission = Color(1.0, 0.07, 0.015)
            AttackPattern.SWEEP:
                state_timer = telegraph_duration * 1.12
                if is_instance_valid(telegraph_mesh):
                    var radius_scale := attack_range * 1.72 / 2.18
                    telegraph_mesh.scale = Vector3(radius_scale, 1.0, radius_scale)
                    telegraph_mesh.rotation = Vector3.ZERO
                if is_instance_valid(telegraph_material):
                    telegraph_material.albedo_color = Color(1.0, 0.52, 0.08, 0.82)
                    telegraph_material.emission = Color(1.0, 0.32, 0.025)
            AttackPattern.SLAM:
                state_timer = telegraph_duration * 1.38
                if is_instance_valid(telegraph_mesh):
                    var radius_scale := attack_range * 2.05 / 2.18
                    telegraph_mesh.scale = Vector3(radius_scale, 1.0, radius_scale)
                    telegraph_mesh.rotation = Vector3.ZERO
                if is_instance_valid(telegraph_material):
                    telegraph_material.albedo_color = Color(0.78, 0.24, 1.0, 0.82)
                    telegraph_material.emission = Color(0.46, 0.06, 1.0)
            AttackPattern.THRUST:
                state_timer = telegraph_duration * 1.08
                if is_instance_valid(telegraph_mesh):
                    telegraph_mesh.scale = Vector3(0.52, 1.0, attack_range * 2.28 / 2.18)
                    telegraph_mesh.rotation.y = rotation.y
                if is_instance_valid(telegraph_material):
                    telegraph_material.albedo_color = Color(0.08, 0.78, 1.0, 0.86)
                    telegraph_material.emission = Color(0.015, 0.38, 1.0)
            AttackPattern.RING_BURST:
                state_timer = telegraph_duration * 1.52
                if is_instance_valid(telegraph_mesh):
                    var radius_scale := attack_range * 2.52 / 2.18
                    telegraph_mesh.scale = Vector3(radius_scale, 1.0, radius_scale)
                    telegraph_mesh.rotation = Vector3.ZERO
                if is_instance_valid(telegraph_material):
                    telegraph_material.albedo_color = Color(0.30, 1.0, 0.42, 0.86)
                    telegraph_material.emission = Color(0.04, 0.82, 0.16)
        if phase >= 2:
            state_timer *= 0.82
    else:
        current_attack_pattern = AttackPattern.MELEE
        state_timer = telegraph_duration
    if is_instance_valid(telegraph_mesh):
        telegraph_mesh.visible = true
    humanoid.play_action("heavy" if is_boss else "attack", 0.08)
    attack_telegraph.emit(is_boss)

func _is_player_in_attack_area(offset: Vector3) -> bool:
    offset.y = 0.0
    var distance := offset.length()
    if not is_boss:
        return distance <= attack_range * 1.12
    var forward := -global_transform.basis.z
    match current_attack_pattern:
        AttackPattern.MELEE:
            return distance <= attack_range * 1.42 and forward.dot(offset.normalized()) > 0.18
        AttackPattern.SWEEP:
            return distance <= attack_range * 1.72 and forward.dot(offset.normalized()) > -0.32
        AttackPattern.SLAM:
            return distance <= attack_range * 2.05
        AttackPattern.THRUST:
            return distance <= attack_range * 2.28 and forward.dot(offset.normalized()) > 0.76
        AttackPattern.RING_BURST:
            return distance >= attack_range * 0.62 and distance <= attack_range * 2.52
    return false

func _execute_strike() -> void:
    if _strike_done:
        return
    _strike_done = true
    if not is_instance_valid(player) or not player.has_method("take_damage"):
        return
    var offset: Vector3 = player.global_position - global_position
    last_attack_hit = _is_player_in_attack_area(offset)
    if last_attack_hit:
        player.take_damage(attack_damage, global_position, is_boss)
        attack_landed.emit(attack_damage)

func take_damage(amount: int, source_position: Vector3 = Vector3.ZERO, heavy: bool = false) -> void:
    if current_state == BrainState.DEAD or amount <= 0:
        return
    health = maxi(0, health - amount)
    humanoid.play_action("hit", 0.06)
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
        humanoid.play_action("death", 0.05)
        active = false
        defeated.emit(is_boss)
        queue_free()
    else:
        current_state = BrainState.STAGGER
        state_timer = 0.24 if not heavy else 0.38
