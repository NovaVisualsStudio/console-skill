extends Node3D
## Runtime adapter for the generated skinned hero. Keeps the combat API used by main.gd.

const ProceduralFallback = preload("res://scripts/warrior_visual.gd")
const HERO_SCENE := "res://assets/characters/nova_hero.glb"

var blade_upgrade := 0
var _model: Node3D
var _animation_player: AnimationPlayer
var _one_shot := false
var _blocking := false
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
	if _one_shot or _blocking:
		return
	if speed_ratio > 0.78:
		_play_loop("run", lerpf(0.95, 1.18, clampf(speed_ratio, 0.0, 1.0)))
	elif speed_ratio > 0.08:
		_play_loop("walk", lerpf(0.68, 1.0, clampf(speed_ratio, 0.0, 1.0)))
	else:
		_play_loop("idle")


func play_attack(combo_step: int) -> void:
	if _model is WarriorVisual:
		_model.call("play_attack", combo_step)
		return
	var fragment := "lightattack"
	match clampi(combo_step, 0, 2):
		1:
			fragment = "lightattack2"
		2:
			fragment = "lightattack3"
	_play_action(fragment)


func play_heavy_attack() -> void:
	if _model is WarriorVisual:
		_model.call("play_heavy_attack")
		return
	_play_action("heavyattack")


func play_dodge() -> void:
	if _model is WarriorVisual:
		_model.call("play_dodge")
		return
	_play_action("dodge")


func set_blocking(enabled: bool) -> void:
	_blocking = enabled
	# Guard intentionally interrupts an active one-shot. Clear the one-shot
	# latch so releasing guard cannot leave locomotion permanently disabled.
	_one_shot = false
	if _model is WarriorVisual:
		_model.call("set_blocking", enabled)
	elif enabled:
		_play_loop("block")
	else:
		_play_loop("idle")


func telegraph(enabled: bool) -> void:
	if _model is WarriorVisual:
		_model.call("telegraph", enabled)


func play_parry() -> void:
	if _model is WarriorVisual:
		_model.call("play_parry")
	else:
		_play_action("parry")


func phase_change(phase: int) -> void:
	if _model is WarriorVisual:
		_model.call("phase_change", phase)
	else:
		_play_action("hitreact")


func hit_react() -> void:
	if _model is WarriorVisual:
		_model.call("hit_react")
	else:
		_play_action("hitreact")


func _find_animation(fragment: String) -> String:
	if _animation_player == null:
		return ""
	for animation_name in _animation_player.get_animation_list():
		if fragment.to_lower() in animation_name.to_lower():
			return animation_name
	return ""


func _play_loop(fragment: String, speed_scale: float = 1.0) -> void:
	var animation_name := _find_animation(fragment)
	if animation_name.is_empty() or _animation_player == null:
		return
	var animation := _animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_LINEAR
	if _active_animation == animation_name and _animation_player.is_playing():
		return
	_active_animation = animation_name
	_animation_player.play(animation_name, 0.12, speed_scale)


func _play_action(fragment: String) -> void:
	var animation_name := _find_animation(fragment)
	if animation_name.is_empty() or _animation_player == null:
		return
	var animation := _animation_player.get_animation(animation_name)
	if animation != null:
		animation.loop_mode = Animation.LOOP_NONE
	_one_shot = true
	_active_animation = animation_name
	_animation_player.play(animation_name, 0.06)


func _on_animation_finished(animation_name: StringName) -> void:
	if str(animation_name) != _active_animation:
		return
	_one_shot = false
	if _blocking:
		_play_loop("block")
	else:
		_play_loop("idle")
