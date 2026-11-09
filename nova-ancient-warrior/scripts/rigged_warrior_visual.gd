extends Node3D
## Runtime adapter for the generated skinned hero. Keeps the combat API used by main.gd.

const ProceduralFallback = preload("res://scripts/warrior_visual.gd")
const HERO_SCENE := "res://assets/characters/nova_hero.glb"

var blade_upgrade := 0
var _model: Node3D
var _animation_player: AnimationPlayer
var _one_shot := false
var _blocking := false
var _jumping := false
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
	var animation_nodes := _model.find_children("*", "AnimationPlayer", true, false)
	_animation_player = animation_nodes[0] as AnimationPlayer if not animation_nodes.is_empty() else null
	if _animation_player != null:
		_animation_player.animation_finished.connect(_on_animation_finished)
		_play_loop("idle")


func set_locomotion(speed_ratio: float, _delta: float) -> void:
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
	if _model is WarriorVisual:
		_model.call("play_attack", combo_step)
		return
	# The third light strike uses the authored three-cut combo; the first opens with a fast slash.
	_play_action("sword_slash" if posmod(combo_step, 3) == 0 else "sword_combo")


func play_heavy_attack() -> void:
	if _model is WarriorVisual:
		_model.call("play_heavy_attack")
		return
	_play_action("sword_thrust")


func set_blocking(enabled: bool) -> void:
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
	if _model is WarriorVisual:
		_model.call("play_parry")
	else:
		_play_action("sword_block")


func play_jump() -> void:
	if _model is WarriorVisual:
		return
	_jumping = true
	_play_action("jump_start", 1.5)


func play_jump_land() -> void:
	if _model is WarriorVisual:
		return
	_jumping = false
	_play_action("jump_land", 1.35)


func play_dodge(direction: Vector3) -> void:
	if _model is WarriorVisual:
		return
	var local_direction := direction
	if absf(local_direction.x) > absf(local_direction.z):
		_play_action("dodge_left" if local_direction.x < 0.0 else "dodge_right", 2.2)
	else:
		_play_action("forward_roll", 3.0)


func phase_change(phase: int) -> void:
	if _model is WarriorVisual:
		_model.call("phase_change", phase)
	else:
		_play_action("sword_block")


func hit_react() -> void:
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
	if str(animation_name) != _active_animation:
		return
	_one_shot = false
	if _jumping:
		_play_loop("jump_air")
	elif _blocking:
		_play_loop("sword_block")
	else:
		_play_loop("idle")
