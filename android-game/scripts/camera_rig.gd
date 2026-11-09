extends Node3D
class_name NovaCameraRig

@export var follow_distance := 6.8
@export var follow_height := 3.0
@export var shoulder_offset := 1.05
@export var follow_smoothing := 7.5
@export var look_height := 1.25
@export_flags_3d_physics var collision_mask := 1
@export var collision_margin := 0.24
@export var collision_recovery_speed := 14.0

var follow_target: Node3D
var lock_target: Node3D
var camera: Camera3D
var intro_timer := 0.0
var intro_duration := 0.0
var shake_timer := 0.0
var shake_strength := 0.0
var random := RandomNumberGenerator.new()

func _ready() -> void:
    random.randomize()
    camera = Camera3D.new()
    camera.name = "ShoulderCamera"
    camera.current = true
    camera.fov = 68.0
    camera.near = 0.08
    camera.far = 180.0
    add_child(camera)

func start_intro(duration: float = 3.0, focus: Node3D = null) -> void:
    intro_duration = maxf(0.1, duration)
    intro_timer = intro_duration
    if is_instance_valid(focus):
        lock_target = focus

func set_lock_target(target: Node3D) -> void:
    lock_target = target

func clear_lock_target() -> void:
    lock_target = null

func shake(strength: float = 0.2, duration: float = 0.16) -> void:
    shake_strength = maxf(shake_strength, strength)
    shake_timer = maxf(shake_timer, duration)

func _process(delta: float) -> void:
    if not is_instance_valid(follow_target) or not is_instance_valid(camera):
        return

    var target_position := follow_target.global_position
    var basis := follow_target.global_transform.basis
    var right := basis.x.normalized()
    var back := basis.z.normalized()
    var desired_position := target_position + back * follow_distance
    desired_position += Vector3.UP * follow_height + right * shoulder_offset
    var look_position := target_position + Vector3.UP * look_height

    if intro_timer > 0.0:
        var progress := 1.0 - intro_timer / intro_duration
        var orbit := sin(progress * PI) * 2.4
        desired_position += right * orbit
        desired_position += Vector3.UP * lerpf(1.6, 0.0, progress)
        desired_position += back * lerpf(3.4, 0.0, progress)
        if is_instance_valid(lock_target):
            look_position = look_position.lerp(lock_target.global_position + Vector3.UP * 1.8, 0.32)
        intro_timer = maxf(0.0, intro_timer - delta)
    elif is_instance_valid(lock_target):
        var lock_look := lock_target.global_position + Vector3.UP * (1.2 if not lock_target.is_in_group("boss") else 2.0)
        look_position = look_position.lerp(lock_look, 0.42)

    var collision_safe_position := _constrain_camera_position(look_position, desired_position)
    var camera_blocked := collision_safe_position.distance_squared_to(desired_position) > 0.0004
    if camera_blocked:
        # Retract immediately to avoid a one-frame wall clip; recover smoothly once clear.
        global_position = collision_safe_position
    else:
        var blend := 1.0 - exp(-follow_smoothing * delta)
        global_position = global_position.lerp(desired_position, blend)

    if shake_timer > 0.0:
        shake_timer = maxf(0.0, shake_timer - delta)
        var strength := shake_strength * (shake_timer / maxf(0.001, shake_timer + delta))
        global_position += Vector3(
            random.randf_range(-strength, strength),
            random.randf_range(-strength, strength),
            random.randf_range(-strength, strength)
        )
        if shake_timer <= 0.0:
            shake_strength = 0.0

    camera.look_at(look_position, Vector3.UP)

func _constrain_camera_position(focus_position: Vector3, desired_position: Vector3) -> Vector3:
    var world := get_world_3d()
    if world == null or focus_position.distance_squared_to(desired_position) <= 0.0001:
        return desired_position
    var exclusions: Array[RID] = []
    if is_instance_valid(follow_target) and follow_target is CollisionObject3D:
        exclusions.append((follow_target as CollisionObject3D).get_rid())
    var query := PhysicsRayQueryParameters3D.create(focus_position, desired_position, collision_mask, exclusions)
    query.collide_with_areas = false
    query.collide_with_bodies = true
    var hit := world.direct_space_state.intersect_ray(query)
    if hit.is_empty():
        return desired_position
    var hit_position: Vector3 = hit.position
    var hit_normal: Vector3 = hit.normal
    return hit_position + hit_normal * collision_margin
