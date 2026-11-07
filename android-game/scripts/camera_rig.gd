extends Node3D
class_name NovaCameraRig

@export var follow_distance := 6.8
@export var follow_height := 3.0
@export var shoulder_offset := 1.05
@export var follow_smoothing := 7.5
@export var look_height := 1.25

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
