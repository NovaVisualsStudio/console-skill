extends Node3D
## Runtime adapter for the generated skinned hero. Keeps the combat API used by main.gd.

const ProceduralFallback = preload("res://scripts/warrior_visual.gd")
const HERO_SCENE := "res://assets/characters/nova_hero.glb"

var blade_upgrade := 0
var _model: Node3D
var _animation_player: AnimationPlayer
var _skeleton: Skeleton3D
var _death_tween: Tween
var _one_shot := false
var _blocking := false
var _jumping := false
var _dead := false
var _active_animation := ""


func _ready() -> void:
	var packed := load(HERO_SCENE) as PackedScene
	if packed == null:
		var fallback := ProceduralFallback.new()
		fallback.set("blade_upgrade", blade_upgrade)
		add_child(fallback)
		_model = fallback
		return
	_model = packed.instantiate() as Node3D
	if _model == null:
		return
	add_child(_model)
	var skeleton_nodes := _model.find_children("*", "Skeleton3D", true, false)
	_skeleton = skeleton_nodes[0] as Skeleton3D if not skeleton_nodes.is_empty() else null
	var animation_nodes := _model.find_children("*", "AnimationPlayer", true, false)
	_animation_player = animation_nodes[0] as AnimationPlayer if not animation_nodes.is_empty() else null
	if _animation_player != null:
		_animation_player.animation_finished.connect(_on_animation_finished)
		_play_loop("idle")


func set_locomotion(speed_ratio: float, _delta: float) -> void:
	if _dead:
		return
	if _model is WarriorVisual:
		_model.call("set_locomotion", speed_ratio, _delta)
		return
	if _one_shot or _blocking or _jumping:
		return
	if speed_ratio > 0.78:
		_play_loop("run")
	elif speed_ratio > 0.08:
		_play_loop("walk")
	else:
		_play_loop("idle")


func play_attack(combo_step: int) -> void:
	if _dead:
		return
	if _model is WarriorVisual:
		_model.call("play_attack", combo_step)
		return
	# The third light strike uses the authored three-cut combo; the first opens with a fast slash.
	_play_action("sword_slash" if posmod(combo_step, 3) == 0 else "sword_combo")


func play_heavy_attack() -> void:
	if _dead:
		return
	if _model is WarriorVisual:
		_model.call("play_heavy_attack")
		return
	_play_action("sword_thrust")


func set_blocking(enabled: bool) -> void:
	if _dead:
		return
	_blocking = enabled
	if _model is WarriorVisual:
		_model.call("set_blocking", enabled)
		return
	# Airborne motion has priority over guard stance until landing completes.
	if _jumping:
		return
	if enabled:
		_play_loop("sword_block")
	else:
		_play_loop("idle")


func telegraph(enabled: bool) -> void:
	if _model is WarriorVisual:
		_model.call("telegraph", enabled)


func play_parry() -> void:
	if _dead:
		return
	if _model is WarriorVisual:
		_model.call("play_parry")
	else:
		_play_action("sword_block")


func play_jump() -> void:
	if _dead:
		return
	if _model is WarriorVisual:
		return
	_jumping = true
	_play_action("jump_start", 1.5)


func play_jump_land() -> void:
	if _dead:
		return
	if _model is WarriorVisual:
		return
	_jumping = false
	_play_action("jump_land", 1.35)


func play_dodge(direction: Vector3) -> void:
	if _dead:
		return
	if _model is WarriorVisual:
		return
	var local_direction := direction
	if absf(local_direction.x) > absf(local_direction.z):
		_play_action("dodge_left" if local_direction.x < 0.0 else "dodge_right", 2.2)
	else:
		_play_action("forward_roll", 3.0)


func phase_change(phase: int) -> void:
	if _dead:
		return
	if _model is WarriorVisual:
		_model.call("phase_change", phase)
	else:
		_play_action("sword_block")


func play_death() -> void:
	if _dead:
		return
	_dead = true
	_one_shot = true
	_blocking = false
	_jumping = false
	if _model is WarriorVisual:
		_model.call("play_death")
		return

	# The imported death clip contains bone tracks but does not produce a
	# reliable fall pose in the Godot runtime. Stop its static pose and drive a
	# deterministic, one-shot skeletal collapse on the named humanoid joints.
	_active_animation = "death"
	if is_instance_valid(_animation_player):
		_animation_player.stop()
	_start_procedural_death_fallback()


func _start_procedural_death_fallback() -> void:
	if not is_instance_valid(_skeleton):
		if is_instance_valid(_model):
			var root_fall := create_tween()
			root_fall.tween_property(_model, "rotation:x", 0.72, 0.82)
			root_fall.parallel().tween_property(_model, "position:y", -0.38, 0.82)
		return
	if _death_tween != null and _death_tween.is_running():
		_death_tween.kill()

	var joint_angles := {
		"Hips": Vector3(0.18, 0.0, 0.0),
		"Spine": Vector3(0.28, 0.0, 0.0),
		"Spine1": Vector3(0.22, 0.0, 0.0),
		"Spine2": Vector3(0.14, 0.0, 0.0),
		"Neck": Vector3(-0.12, 0.0, 0.0),
		"Head": Vector3(-0.22, 0.0, 0.0),
		"LeftArm": Vector3(0.0, 0.0, 0.55),
		"LeftForeArm": Vector3(0.42, 0.0, 0.24),
		"RightArm": Vector3(0.0, 0.0, -0.55),
		"RightForeArm": Vector3(-0.42, 0.0, -0.24),
		"LeftUpLeg": Vector3(0.24, 0.0, 0.0),
		"LeftLeg": Vector3(-0.34, 0.0, 0.0),
		"RightUpLeg": Vector3(0.24, 0.0, 0.0),
		"RightLeg": Vector3(-0.34, 0.0, 0.0)
	}
	_death_tween = create_tween()
	_death_tween.set_parallel(true)
	for joint_name in joint_angles:
		var bone_index := _skeleton.find_bone(str(joint_name))
		if bone_index < 0:
			continue
		var start_rotation := _skeleton.get_bone_pose_rotation(bone_index)
		var target_rotation: Quaternion = start_rotation * Quaternion.from_euler(joint_angles[joint_name])
		var rotation_track := _death_tween.tween_method(
			Callable(self, "_apply_death_bone_rotation").bind(_skeleton, bone_index),
			start_rotation,
			target_rotation,
			0.82
		)
		rotation_track.set_trans(Tween.TRANS_SINE)
		rotation_track.set_ease(Tween.EASE_OUT)

	var hips_index := _skeleton.find_bone("Hips")
	if hips_index >= 0:
		var start_position := _skeleton.get_bone_pose_position(hips_index)
		var target_position := start_position + Vector3(0.0, -0.12, 0.0)
		var hips_track := _death_tween.tween_method(
			Callable(self, "_apply_death_bone_position").bind(_skeleton, hips_index),
			start_position,
			target_position,
			0.82
		)
		hips_track.set_trans(Tween.TRANS_SINE)
		hips_track.set_ease(Tween.EASE_OUT)


func _apply_death_bone_rotation(value: Quaternion, skeleton: Skeleton3D, bone_index: int) -> void:
	if is_instance_valid(skeleton):
		skeleton.set_bone_pose_rotation(bone_index, value)


func _apply_death_bone_position(value: Vector3, skeleton: Skeleton3D, bone_index: int) -> void:
	if is_instance_valid(skeleton):
		skeleton.set_bone_pose_position(bone_index, value)


func hit_react() -> void:
	if _dead:
		return
	if _model is WarriorVisual:
		_model.call("hit_react")
	else:
		_play_action("hit_from_front", 1.4)


func _find_animation(fragment: String) -> String:
	if _animation_player == null:
		return ""
	var wanted := fragment.to_lower().replace("_", "").replace("-", "").replace(" ", "")
	for animation_name in _animation_player.get_animation_list():
		var candidate := str(animation_name).to_lower().replace("_", "").replace("-", "").replace(" ", "").replace("(", "").replace(")", "")
		if wanted in candidate or (wanted == "jumpair" and candidate == "jumpinair"):
			return animation_name
	return ""


func _play_loop(fragment: String) -> void:
	var animation_name := _find_animation("sword_idle") if fragment == "idle" else ""
	if animation_name.is_empty():
		animation_name = _find_animation(fragment)
	if animation_name.is_empty() or _animation_player == null:
		return
	var animation := _animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR
	# A looping stance may interrupt a one-shot action (attack/parry). Clear the
	# one-shot latch before the same-clip early return as well as before a new play.
	_one_shot = false
	if _active_animation == animation_name and _animation_player.is_playing():
		return
	_active_animation = animation_name
	_animation_player.play(animation_name, 0.12)


func _play_action(fragment: String, speed_scale: float = 1.0) -> void:
	var animation_name := _find_animation(fragment)
	if animation_name.is_empty() or _animation_player == null:
		return
	var animation := _animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_NONE
	_one_shot = true
	_active_animation = animation_name
	_animation_player.play(animation_name, 0.06, speed_scale)


func _on_animation_finished(animation_name: StringName) -> void:
	if _dead or str(animation_name) != _active_animation:
		return
	_one_shot = false
	if _jumping:
		_play_loop("jump_air")
	elif _blocking:
		_play_loop("sword_block")
	else:
		_play_loop("idle")
