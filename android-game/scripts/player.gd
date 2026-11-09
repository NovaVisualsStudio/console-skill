extends CharacterBody3D
class_name NovaPlayer

signal health_changed(current: int, maximum: int)
signal stamina_changed(current: float, maximum: float)
signal defeated
signal parry_success
signal hit_confirmed(target_position: Vector3, heavy: bool, combo_step: int)
signal attack_started(heavy: bool, combo_step: int)
signal attack_impact(heavy: bool, combo_step: int)
signal dodge_started

enum CombatState { IDLE, MOVE, ATTACK, DODGE, GUARD, STAGGER, DEAD }

const HUMANOID_SCRIPT = preload("res://scripts/humanoid_rig.gd")
const WALK_SPEED := 5.2
const DODGE_SPEED := 12.0
const DODGE_DURATION := 0.42
const LIGHT_RANGE := 2.95
const MAX_HEALTH := 160
const MAX_STAMINA := 100.0

var health := MAX_HEALTH
var stamina := MAX_STAMINA
var stamina_regen_delay := 0.0
var current_state: CombatState = CombatState.IDLE
var dodge_timer := 0.0
var attack_cooldown := 0.0
var attack_recovery_timer := 0.0
var attack_startup_timer := 0.0
var attack_active_timer := 0.0
var pending_attack_active_duration := 0.14
var pending_attack_damage := 0
var pending_attack_range := LIGHT_RANGE
var pending_attack_min_dot := 0.08
var pending_attack_heavy := false
var attack_start_position := Vector3.ZERO
var attack_hit_targets: Array[int] = []
var parry_timer := 0.0
var stagger_timer := 0.0
var combo_chain_timer := 0.0
var combo_step := 0
var invulnerable := false
var guard_active := false
var input_enabled := true
var dodge_direction := Vector3.ZERO
var lock_target: Node3D
var movement_camera: Camera3D
var weapon_pivot: Node3D
var body_pivot: Node3D
var humanoid: NovaHumanoidRig
var weapon_tween: Tween
var _locomotion_phase := 0.0
var _impact_recoil := Vector3.ZERO
var _stamina_ui_timer := 0.0

func _ready() -> void:
    add_to_group("player")
    _build_character()
    health_changed.emit(health, MAX_HEALTH)
    stamina_changed.emit(stamina, MAX_STAMINA)

func _build_character() -> void:
    var collider := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.43
    capsule.height = 1.82
    collider.shape = capsule
    collider.position.y = 0.91
    add_child(collider)

    body_pivot = Node3D.new()
    body_pivot.name = "WarriorRig"
    add_child(body_pivot)

    humanoid = HUMANOID_SCRIPT.new() as NovaHumanoidRig
    humanoid.name = "HeroHumanoid"
    humanoid.tint_color = Color(0.16, 0.25, 0.34)
    humanoid.armor_style = "hero"
    humanoid.accent_color = Color(0.62, 0.43, 0.20)
    body_pivot.add_child(humanoid)

    var bronze := _material(Color(0.48, 0.30, 0.13), 0.34, 0.82)
    var hand_attachment := humanoid.attach_to_bone("hand_r")
    weapon_pivot = Node3D.new()
    weapon_pivot.name = "WarAxe"
    weapon_pivot.position = Vector3(0.0, -0.28, 0.02) if hand_attachment != humanoid else Vector3(0.58, 1.18, -0.12)
    hand_attachment.add_child(weapon_pivot)
    var handle := MeshInstance3D.new()
    var handle_mesh := CylinderMesh.new()
    handle_mesh.top_radius = 0.045
    handle_mesh.bottom_radius = 0.065
    handle_mesh.height = 1.15
    handle.mesh = handle_mesh
    handle.rotation.z = -0.42
    handle.position.y = 0.37
    handle.material_override = _material(Color(0.22, 0.10, 0.045), 0.88, 0.08)
    weapon_pivot.add_child(handle)

    var axe_head := MeshInstance3D.new()
    var axe_mesh := BoxMesh.new()
    axe_mesh.size = Vector3(0.62, 0.48, 0.12)
    axe_head.mesh = axe_mesh
    axe_head.position = Vector3(0.06, 0.87, 0.0)
    axe_head.rotation.z = -0.16
    axe_head.material_override = _material(Color(0.57, 0.69, 0.77), 0.24, 0.92)
    weapon_pivot.add_child(axe_head)
    _add_sphere(weapon_pivot, Vector3(-0.18, 0.87, 0.0), 0.13, bronze)
    humanoid.play_action("idle")

func _material(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
    var material := StandardMaterial3D.new()
    material.albedo_color = color
    material.roughness = roughness
    material.metallic = metallic
    return material

func _add_sphere(parent: Node3D, position: Vector3, radius: float, material: Material) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    instance.mesh = mesh
    instance.position = position
    instance.material_override = material
    parent.add_child(instance)
    return instance

func _add_capsule(parent: Node3D, position: Vector3, radius: float, height: float,
        material: Material, mesh_scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    instance.mesh = mesh
    instance.position = position
    instance.scale = mesh_scale
    instance.material_override = material
    parent.add_child(instance)
    return instance

func _add_box(parent: Node3D, position: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
    var instance := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    instance.mesh = mesh
    instance.position = position
    instance.material_override = material
    parent.add_child(instance)
    return instance

func _physics_process(delta: float) -> void:
    _update_timers(delta)
    if current_state == CombatState.DEAD:
        return

    if Input.is_action_just_pressed("guard"):
        set_guard(true)
    elif Input.is_action_just_released("guard"):
        set_guard(false)

    if not input_enabled:
        velocity = Vector3.ZERO
        move_and_slide()
        return

    # Lock-on must orient the warrior even while standing still.
    if is_instance_valid(lock_target):
        var lock_offset := lock_target.global_position - global_position
        lock_offset.y = 0.0
        if lock_offset.length_squared() > 0.01:
            rotation.y = lerp_angle(rotation.y, atan2(-lock_offset.x, -lock_offset.z), delta * 10.0)

    if Input.is_action_just_pressed("attack"):
        perform_light_attack()
    if Input.is_action_just_pressed("heavy_attack"):
        perform_heavy_attack()
    if Input.is_action_just_pressed("dodge"):
        perform_dodge()

    if current_state == CombatState.DODGE:
        velocity.x = dodge_direction.x * DODGE_SPEED
        velocity.z = dodge_direction.z * DODGE_SPEED
    elif current_state == CombatState.STAGGER:
        velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
    elif guard_active:
        current_state = CombatState.GUARD
        velocity.x = move_toward(velocity.x, 0.0, WALK_SPEED * 10.0 * delta)
        velocity.z = move_toward(velocity.z, 0.0, WALK_SPEED * 10.0 * delta)
    else:
        var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
        var move_direction := _get_camera_relative_direction(input_vector)
        if move_direction.length_squared() > 0.01:
            move_direction = move_direction.normalized()
            if not is_instance_valid(lock_target):
                rotation.y = lerp_angle(rotation.y, atan2(-move_direction.x, -move_direction.z), delta * 10.0)
        var input_strength := clampf(input_vector.length(), 0.0, 1.0)
        var movement_speed := WALK_SPEED * lerpf(0.48, 1.0, input_strength)
        if current_state == CombatState.ATTACK:
            movement_speed *= 0.48
        var target_velocity := move_direction * movement_speed
        var acceleration := 30.0 if move_direction.length_squared() > 0.01 else 38.0
        velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
        velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
        if current_state != CombatState.ATTACK:
            current_state = CombatState.MOVE if move_direction.length_squared() > 0.01 else CombatState.IDLE

    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()
    _sync_humanoid_animation()
    _update_body_secondary_motion(delta)

func _update_body_secondary_motion(delta: float) -> void:
    if not is_instance_valid(body_pivot):
        return
    var planar_velocity := Vector3(velocity.x, 0.0, velocity.z)
    var local_velocity := global_transform.basis.inverse() * planar_velocity
    var speed_ratio := clampf(planar_velocity.length() / WALK_SPEED, 0.0, 1.0)
    _locomotion_phase = fposmod(_locomotion_phase + delta * lerpf(4.2, 8.0, speed_ratio), TAU)
    var gait_bob := absf(sin(_locomotion_phase)) * 0.032 * speed_ratio
    var forward_lean := clampf(-local_velocity.z / WALK_SPEED, -1.0, 1.0) * 0.055
    var lateral_lean := clampf(-local_velocity.x / WALK_SPEED, -1.0, 1.0) * 0.075
    var target_rotation := Vector3(forward_lean + _impact_recoil.x, 0.0, lateral_lean + _impact_recoil.z)
    body_pivot.rotation.x = lerp_angle(body_pivot.rotation.x, target_rotation.x, clampf(delta * 10.0, 0.0, 1.0))
    body_pivot.rotation.z = lerp_angle(body_pivot.rotation.z, target_rotation.z, clampf(delta * 10.0, 0.0, 1.0))
    body_pivot.position.y = lerpf(body_pivot.position.y, 0.012 + gait_bob, clampf(delta * 12.0, 0.0, 1.0))
    _impact_recoil = _impact_recoil.lerp(Vector3.ZERO, clampf(delta * 7.5, 0.0, 1.0))

func _get_camera_relative_direction(input_vector: Vector2) -> Vector3:
    var camera_forward := Vector3.FORWARD
    var camera_right := Vector3.RIGHT
    if is_instance_valid(movement_camera):
        var camera_basis := movement_camera.global_transform.basis
        camera_forward = -camera_basis.z
        camera_forward.y = 0.0
        camera_right = camera_basis.x
        camera_right.y = 0.0
        if camera_forward.length_squared() > 0.001:
            camera_forward = camera_forward.normalized()
        else:
            camera_forward = Vector3.FORWARD
        if camera_right.length_squared() > 0.001:
            camera_right = camera_right.normalized()
        else:
            camera_right = Vector3.RIGHT
    var direction := camera_right * input_vector.x + camera_forward * -input_vector.y
    return direction.normalized() if direction.length_squared() > 1.0 else direction

func _sync_humanoid_animation() -> void:
    if not is_instance_valid(humanoid):
        return
    match current_state:
        CombatState.ATTACK:
            humanoid.play_attack_variant(combo_step, pending_attack_heavy, 0.06)
        CombatState.DODGE:
            humanoid.play_action("dodge")
        CombatState.GUARD:
            humanoid.play_action("guard")
        CombatState.STAGGER:
            humanoid.play_action("hit", 0.045)
        CombatState.DEAD:
            humanoid.play_action("death")
        CombatState.MOVE:
            var speed_ratio := Vector2(velocity.x, velocity.z).length() / WALK_SPEED
            humanoid.play_locomotion("run" if speed_ratio > 0.82 else "walk", speed_ratio)
        _:
            humanoid.play_action("idle")

func _update_timers(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    attack_recovery_timer = maxf(0.0, attack_recovery_timer - delta)
    dodge_timer = maxf(0.0, dodge_timer - delta)
    parry_timer = maxf(0.0, parry_timer - delta)
    stagger_timer = maxf(0.0, stagger_timer - delta)
    combo_chain_timer = maxf(0.0, combo_chain_timer - delta)
    stamina_regen_delay = maxf(0.0, stamina_regen_delay - delta)
    var previous_stamina := stamina
    if stamina_regen_delay <= 0.0 and stamina < MAX_STAMINA:
        var regen_rate := 7.0 if guard_active else 14.0
        stamina = minf(MAX_STAMINA, stamina + regen_rate * delta)
    invulnerable = dodge_timer > 0.0
    if not is_equal_approx(stamina, previous_stamina):
        _stamina_ui_timer += delta
        if stamina >= MAX_STAMINA or _stamina_ui_timer >= 0.10:
            _stamina_ui_timer = 0.0
            stamina_changed.emit(stamina, MAX_STAMINA)
    else:
        _stamina_ui_timer = 0.0

    if current_state == CombatState.ATTACK:
        if attack_startup_timer > 0.0:
            attack_startup_timer = maxf(0.0, attack_startup_timer - delta)
            if attack_startup_timer <= 0.0:
                attack_active_timer = pending_attack_active_duration
                attack_impact.emit(pending_attack_heavy, combo_step)
        if attack_active_timer > 0.0:
            _hit_enemies(pending_attack_damage, pending_attack_range, pending_attack_min_dot, pending_attack_heavy)
            attack_active_timer = maxf(0.0, attack_active_timer - delta)

    if current_state == CombatState.DODGE and dodge_timer <= 0.0:
        current_state = CombatState.IDLE
    elif current_state == CombatState.STAGGER and stagger_timer <= 0.0:
        current_state = CombatState.IDLE
    elif current_state == CombatState.ATTACK and attack_recovery_timer <= 0.0:
        current_state = CombatState.IDLE
    if combo_chain_timer <= 0.0:
        combo_step = 0

func set_guard(active: bool) -> void:
    if current_state == CombatState.DEAD:
        return
    if active and not guard_active:
        _cancel_pending_attack()
        guard_active = true
        parry_timer = 0.22
        current_state = CombatState.GUARD
    elif not active and guard_active:
        guard_active = false
        parry_timer = 0.0
        if current_state == CombatState.GUARD:
            current_state = CombatState.IDLE

func perform_light_attack() -> bool:
    if current_state in [CombatState.DEAD, CombatState.STAGGER, CombatState.DODGE] or guard_active or attack_cooldown > 0.0 or not input_enabled:
        return false
    if combo_chain_timer > 0.0:
        combo_step = (combo_step % 3) + 1
    else:
        combo_step = 1
    combo_chain_timer = 0.92
    var damage_values: Array[int] = [32, 39, 56]
    var damage := damage_values[combo_step - 1]
    attack_cooldown = 0.38
    attack_recovery_timer = 0.32
    current_state = CombatState.ATTACK
    _animate_weapon(false, combo_step)
    humanoid.play_attack_variant(combo_step, false, 0.06)
    attack_started.emit(false, combo_step)
    _queue_attack(damage, LIGHT_RANGE + float(combo_step - 1) * 0.15, 0.08, false, 0.10, 0.14)
    return true

func perform_attack() -> void:
    perform_light_attack()

func perform_heavy_attack() -> bool:
    if current_state in [CombatState.DEAD, CombatState.STAGGER, CombatState.DODGE] or guard_active or attack_cooldown > 0.0 or not input_enabled:
        return false
    if stamina < 30.0:
        return false
    stamina -= 30.0
    stamina_regen_delay = 1.05
    _stamina_ui_timer = 0.0
    stamina_changed.emit(stamina, MAX_STAMINA)
    combo_step = 0
    combo_chain_timer = 0.0
    attack_cooldown = 0.76
    attack_recovery_timer = 0.64
    current_state = CombatState.ATTACK
    _animate_weapon(true, 0)
    humanoid.play_attack_variant(0, true, 0.06)
    attack_started.emit(true, 0)
    _queue_attack(82, 3.75, -0.02, true, 0.16, 0.20)
    return true

func _queue_attack(damage: int, attack_range: float, min_dot: float, heavy: bool,
        startup: float, active_duration: float) -> void:
    pending_attack_damage = damage
    pending_attack_range = attack_range
    pending_attack_min_dot = min_dot
    pending_attack_heavy = heavy
    pending_attack_active_duration = active_duration
    attack_startup_timer = startup
    attack_active_timer = 0.0
    attack_hit_targets.clear()

func _cancel_pending_attack() -> void:
    attack_startup_timer = 0.0
    attack_active_timer = 0.0
    pending_attack_damage = 0
    attack_hit_targets.clear()

func _hit_enemies(damage: int, attack_range: float, min_dot: float, heavy: bool) -> void:
    var forward := -global_transform.basis.z
    forward.y = 0.0
    forward = forward.normalized()
    for target in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(target) or not target.has_method("take_damage"):
            continue
        var target_id := target.get_instance_id()
        if attack_hit_targets.has(target_id):
            continue
        var target_point := target.global_position + Vector3.UP * 0.95
        var attack_origin := global_position + Vector3.UP * 1.0
        var offset: Vector3 = target_point - attack_origin
        var distance: float = offset.length()
        if distance > attack_range or distance <= 0.01:
            continue
        var horizontal_offset := Vector3(offset.x, 0.0, offset.z)
        if horizontal_offset.length_squared() <= 0.001 or forward.dot(horizontal_offset.normalized()) <= min_dot:
            continue
        if not _has_clear_attack_line(target, attack_origin, target_point):
            continue
        attack_hit_targets.append(target_id)
        target.take_damage(damage, global_position, heavy)
        hit_confirmed.emit(target_point, heavy, combo_step)

func _has_clear_attack_line(target: Node, origin: Vector3, target_point: Vector3) -> bool:
    if not target is CollisionObject3D:
        return true
    var world := get_world_3d()
    if world == null:
        return true
    var exclusions: Array[RID] = [get_rid()]
    var query := PhysicsRayQueryParameters3D.create(origin, target_point, 1, exclusions)
    query.collide_with_areas = false
    query.collide_with_bodies = true
    var hit := world.direct_space_state.intersect_ray(query)
    return not hit.is_empty() and hit.collider == target

func _animate_weapon(heavy: bool, step: int) -> void:
    if not is_instance_valid(weapon_pivot):
        return
    if is_instance_valid(weapon_tween):
        weapon_tween.kill()
    weapon_pivot.rotation = Vector3.ZERO
    weapon_tween = create_tween()
    weapon_tween.set_trans(Tween.TRANS_CUBIC)
    weapon_tween.set_parallel(true)
    if heavy:
        weapon_tween.tween_property(weapon_pivot, "rotation:z", -1.75, 0.16)
        weapon_tween.tween_property(weapon_pivot, "rotation:x", 0.72, 0.16)
        weapon_tween.set_parallel(false)
        weapon_tween.tween_property(weapon_pivot, "rotation:z", 0.04, 0.20)
        weapon_tween.parallel().tween_property(weapon_pivot, "rotation:x", 0.0, 0.20)
    else:
        var end_angles := [-1.04, 1.02, -0.16]
        var lift_angles := [-0.18, 0.22, 0.92]
        var variant_index := clampi(step - 1, 0, 2)
        weapon_tween.tween_property(weapon_pivot, "rotation:z", end_angles[variant_index], 0.10)
        weapon_tween.tween_property(weapon_pivot, "rotation:x", lift_angles[variant_index], 0.10)
        weapon_tween.set_parallel(false)
        weapon_tween.tween_property(weapon_pivot, "rotation:z", 0.0, 0.14)
        weapon_tween.parallel().tween_property(weapon_pivot, "rotation:x", 0.0, 0.14)

func perform_dodge() -> bool:
    if current_state == CombatState.DEAD or dodge_timer > 0.0 or stamina < 18.0 or not input_enabled:
        return false
    _cancel_pending_attack()
    stamina -= 18.0
    stamina_regen_delay = 0.65
    stamina_changed.emit(stamina, MAX_STAMINA)
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    dodge_direction = _get_camera_relative_direction(input_vector)
    if dodge_direction.length_squared() <= 0.01:
        dodge_direction = -global_transform.basis.z
        dodge_direction.y = 0.0
        dodge_direction = dodge_direction.normalized()
    if not is_instance_valid(lock_target):
        rotation.y = atan2(-dodge_direction.x, -dodge_direction.z)
    dodge_timer = DODGE_DURATION
    invulnerable = true
    current_state = CombatState.DODGE
    humanoid.play_action("dodge", 0.05)
    dodge_started.emit()
    return true

func take_damage(amount: int, source_position: Vector3 = Vector3.ZERO, heavy: bool = false) -> bool:
    if current_state == CombatState.DEAD or invulnerable or amount <= 0:
        return false
    if guard_active:
        if parry_timer > 0.0:
            parry_timer = 0.0
            stamina = minf(MAX_STAMINA, stamina + 12.0)
            stamina_changed.emit(stamina, MAX_STAMINA)
            parry_success.emit()
            return false
        amount = maxi(1, int(round(float(amount) * 0.30)))
    _cancel_pending_attack()
    health = maxi(0, health - amount)
    _impact_recoil = Vector3(deg_to_rad(-11.0 if heavy else -6.0), 0.0, deg_to_rad(7.0 if heavy else 4.0))
    health_changed.emit(health, MAX_HEALTH)
    if source_position != Vector3.ZERO:
        var knockback := global_position - source_position
        knockback.y = 0.0
        if knockback.length_squared() > 0.01:
            knockback = knockback.normalized()
            velocity.x = knockback.x * (7.0 if heavy else 3.5)
            velocity.z = knockback.z * (7.0 if heavy else 3.5)
    if health <= 0:
        current_state = CombatState.DEAD
        humanoid.play_action("death", 0.08)
        guard_active = false
        defeated.emit()
    else:
        current_state = CombatState.STAGGER
        stagger_timer = 0.25 if not heavy else 0.42
    return true
