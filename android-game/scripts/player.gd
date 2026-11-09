extends CharacterBody3D
class_name NovaPlayer

signal health_changed(current: int, maximum: int)
signal stamina_changed(current: float, maximum: float)
signal defeated
signal parry_success
signal hit_confirmed(target_position: Vector3, heavy: bool, combo_step: int)
signal attack_started(heavy: bool, combo_step: int)
signal dodge_started

enum CombatState { IDLE, MOVE, ATTACK, DODGE, GUARD, STAGGER, DEAD }

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
var weapon_pivot: Node3D
var body_pivot: Node3D
var body_material: StandardMaterial3D

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

    body_material = _material(Color(0.13, 0.20, 0.29), 0.46, 0.55)
    _add_capsule(body_pivot, Vector3(0.0, 1.12, 0.0), 0.39, 0.88, body_material, Vector3(1.0, 1.0, 0.82))
    _add_sphere(body_pivot, Vector3(0.0, 1.72, 0.0), 0.27, _material(Color(0.66, 0.45, 0.30), 0.78, 0.0))
    _add_box(body_pivot, Vector3(0.0, 1.43, 0.0), Vector3(0.78, 0.16, 0.64), _material(Color(0.30, 0.19, 0.11), 0.82, 0.15))

    var bronze := _material(Color(0.48, 0.30, 0.13), 0.34, 0.82)
    var dark_steel := _material(Color(0.10, 0.14, 0.19), 0.32, 0.88)
    _add_sphere(body_pivot, Vector3(-0.43, 1.45, 0.0), 0.23, bronze)
    _add_sphere(body_pivot, Vector3(0.43, 1.45, 0.0), 0.23, bronze)
    _add_capsule(body_pivot, Vector3(-0.51, 1.08, 0.0), 0.12, 0.58, dark_steel)
    _add_capsule(body_pivot, Vector3(0.51, 1.08, 0.0), 0.12, 0.58, dark_steel)
    _add_capsule(body_pivot, Vector3(-0.22, 0.48, 0.0), 0.15, 0.68, dark_steel)
    _add_capsule(body_pivot, Vector3(0.22, 0.48, 0.0), 0.15, 0.68, dark_steel)
    _add_box(body_pivot, Vector3(-0.22, 0.12, -0.06), Vector3(0.31, 0.20, 0.48), bronze)
    _add_box(body_pivot, Vector3(0.22, 0.12, -0.06), Vector3(0.31, 0.20, 0.48), bronze)

    var helmet := _add_sphere(body_pivot, Vector3(0.0, 1.91, 0.0), 0.29, bronze)
    helmet.scale = Vector3(1.0, 0.74, 0.92)
    _add_box(body_pivot, Vector3(0.0, 1.78, -0.22), Vector3(0.36, 0.10, 0.08), dark_steel)

    weapon_pivot = Node3D.new()
    weapon_pivot.name = "WarAxe"
    weapon_pivot.position = Vector3(0.58, 1.18, -0.12)
    body_pivot.add_child(weapon_pivot)
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
        var move_direction := Vector3(input_vector.x, 0.0, input_vector.y)
        if move_direction.length_squared() > 0.01:
            move_direction = move_direction.normalized()
            if not is_instance_valid(lock_target):
                rotation.y = lerp_angle(rotation.y, atan2(-move_direction.x, -move_direction.z), delta * 10.0)
        var movement_speed := WALK_SPEED * (0.48 if current_state == CombatState.ATTACK else 1.0)
        velocity.x = move_direction.x * movement_speed
        velocity.z = move_direction.z * movement_speed
        if current_state != CombatState.ATTACK:
            current_state = CombatState.MOVE if move_direction.length_squared() > 0.01 else CombatState.IDLE

    if not is_on_floor():
        velocity.y -= 24.0 * delta
    else:
        velocity.y = 0.0
    move_and_slide()

    if is_instance_valid(body_pivot) and current_state == CombatState.MOVE:
        body_pivot.position.y = 0.025 * sin(Time.get_ticks_msec() * 0.012)

func _update_timers(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    attack_recovery_timer = maxf(0.0, attack_recovery_timer - delta)
    dodge_timer = maxf(0.0, dodge_timer - delta)
    parry_timer = maxf(0.0, parry_timer - delta)
    stagger_timer = maxf(0.0, stagger_timer - delta)
    combo_chain_timer = maxf(0.0, combo_chain_timer - delta)
    stamina_regen_delay = maxf(0.0, stamina_regen_delay - delta)
    if stamina_regen_delay <= 0.0:
        var regen_rate := 7.0 if guard_active else 14.0
        stamina = minf(MAX_STAMINA, stamina + regen_rate * delta)
    invulnerable = dodge_timer > 0.0
    stamina_changed.emit(stamina, MAX_STAMINA)

    if current_state == CombatState.ATTACK:
        if attack_startup_timer > 0.0:
            attack_startup_timer = maxf(0.0, attack_startup_timer - delta)
            if attack_startup_timer <= 0.0:
                attack_active_timer = pending_attack_active_duration
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
    stamina_changed.emit(stamina, MAX_STAMINA)
    combo_step = 0
    combo_chain_timer = 0.0
    attack_cooldown = 0.76
    attack_recovery_timer = 0.64
    current_state = CombatState.ATTACK
    _animate_weapon(true, 0)
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
    for target in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(target) or not target.has_method("take_damage"):
            continue
        var target_id := target.get_instance_id()
        if attack_hit_targets.has(target_id):
            continue
        var offset: Vector3 = target.global_position - global_position
        var distance := offset.length()
        if distance <= attack_range and distance > 0.01 and forward.dot(offset.normalized()) > min_dot:
            attack_hit_targets.append(target_id)
            target.take_damage(damage, global_position, heavy)
            hit_confirmed.emit(target.global_position + Vector3.UP, heavy, combo_step)

func _animate_weapon(heavy: bool, step: int) -> void:
    if not is_instance_valid(weapon_pivot):
        return
    weapon_pivot.rotation = Vector3.ZERO
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_CUBIC)
    if heavy:
        tween.tween_property(weapon_pivot, "rotation:z", -1.75, 0.16)
        tween.tween_property(weapon_pivot, "rotation:z", 0.05, 0.28)
    else:
        var end_angle := -1.0 - float(step) * 0.12
        tween.tween_property(weapon_pivot, "rotation:z", end_angle, 0.10)
        tween.tween_property(weapon_pivot, "rotation:z", 0.0, 0.22)

func perform_dodge() -> bool:
    if current_state == CombatState.DEAD or dodge_timer > 0.0 or stamina < 18.0 or not input_enabled:
        return false
    _cancel_pending_attack()
    stamina -= 18.0
    stamina_regen_delay = 0.65
    stamina_changed.emit(stamina, MAX_STAMINA)
    var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    dodge_direction = Vector3(input_vector.x, 0.0, input_vector.y)
    if dodge_direction.length_squared() <= 0.01:
        dodge_direction = -global_transform.basis.z
    dodge_direction = dodge_direction.normalized()
    if is_instance_valid(lock_target):
        rotation.y = atan2(-dodge_direction.x, -dodge_direction.z)
    dodge_timer = DODGE_DURATION
    invulnerable = true
    current_state = CombatState.DODGE
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
        guard_active = false
        defeated.emit()
    else:
        current_state = CombatState.STAGGER
        stagger_timer = 0.25 if not heavy else 0.42
    return true
