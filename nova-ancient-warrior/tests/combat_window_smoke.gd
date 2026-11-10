extends SceneTree

const CombatRules = preload("res://scripts/combat_rules.gd")

var _finished := false
var _watchdog_timer: Timer
var _active_game: Node


func _initialize() -> void:
	_watchdog_timer = Timer.new()
	_watchdog_timer.name = "CombatWindowWatchdog"
	_watchdog_timer.one_shot = true
	_watchdog_timer.wait_time = 12.0
	_watchdog_timer.timeout.connect(_on_watchdog_timeout)
	call_deferred("_install_watchdog_timer")
	call_deferred("_run_combat_window_smoke")


func _install_watchdog_timer() -> void:
	if not is_instance_valid(_watchdog_timer):
		return
	root.add_child(_watchdog_timer)
	_watchdog_timer.start()


func _on_watchdog_timeout() -> void:
	if not _finished:
		push_error("Combat window smoke test timed out before completing")
		_finish(1, _active_game)


func _run_combat_window_smoke() -> void:
	var main_scene := load("res://scenes/main.tscn") as PackedScene
	if main_scene == null:
		await _finish(1, null, "Could not load the actual main scene")
		return
	var game := main_scene.instantiate()
	game.name = "CombatWindowSmoke"
	_active_game = game
	root.add_child(game)
	await process_frame
	await physics_frame
	var has_save_manager := root.get_node_or_null("SaveManager") != null
	if not has_save_manager:
		await _finish(1, game, "SaveManager autoload was not initialized for the main scene")
		return
	print("Combat window test: main scene and SaveManager autoload booted")
	var hud := game.get("hud") as Label
	var status_label := game.get("status_label") as Label
	if hud == null or hud.anchor_left > 0.05 or hud.anchor_right < 0.95:
		await _finish(1, game, "HUD must use responsive safe-width anchors")
		return
	if status_label == null or status_label.anchor_left > 0.1 or status_label.anchor_right < 0.9:
		await _finish(1, game, "Encounter status must fit a responsive mobile width")
		return
	var original_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("ar")
	game.call("_update_hud")
	if hud == null or not hud.text.contains("الفصل") or hud.text_direction != Control.TEXT_DIRECTION_RTL:
		await _finish(1, game, "In-game HUD did not switch to Arabic and right-to-left layout")
		return
	TranslationServer.set_locale(original_locale)
	game.call("_update_hud")
	if hud.text_direction != Control.TEXT_DIRECTION_LTR:
		await _finish(1, game, "In-game HUD did not restore its original layout direction")
		return
	print("Combat window test: in-game HUD supports Arabic and English layout")
	var music_director := game.get_node_or_null("MusicDirector")
	if music_director == null:
		await _finish(1, game, "Main scene did not create MusicDirector")
		return
	var music_player := music_director.get_node_or_null("AmbientMusicPlayer") as AudioStreamPlayer
	if music_player == null:
		await _finish(1, game, "MusicDirector did not create an AudioStreamPlayer")
		return
	var music_stream := music_player.stream as AudioStreamWAV
	if music_stream == null or music_stream.loop_mode != AudioStreamWAV.LOOP_FORWARD or music_stream.loop_end <= 0:
		await _finish(1, game, "Main scene did not configure a looping ambient music stream")
		return
	print("Combat window test: ambient music stream configured in main scene")
	music_player.stop()
	music_player.stream = null
	await process_frame
	await process_frame
	music_stream = null
	music_player = null
	music_director = null

	var player := game.get("player") as CharacterBody3D
	var enemies: Array = game.get("enemies")
	if player == null or enemies.is_empty():
		await _finish(1, game, "Main scene did not create a player and enemy wave")
		return

	var target := enemies[0] as Node3D
	for index in range(enemies.size()):
		var enemy := enemies[index] as Node3D
		enemy.global_position = Vector3(12.0 + float(index), 0.0, 12.0)
	target.global_position = player.global_position + Vector3(0.0, 0.0, -1.4)
	target.set_meta("hp", 200)
	target.set_meta("max_hp", 200)
	await physics_frame

	var before := int(target.get_meta("hp"))
	game.call("_attack", false)
	print("Combat window test: attack started")
	if int(target.get_meta("hp")) != before:
		await _finish(1, game, "Light attack applied damage before its startup window")
		return

	await create_timer(CombatRules.attack_startup(false, 0) * 0.5).timeout
	if int(target.get_meta("hp")) != before:
		await _finish(1, game, "Light attack hit before the configured startup elapsed")
		return

	await create_timer(CombatRules.attack_startup(false, 0) * 0.7).timeout
	var expected := before - CombatRules.combo_damage(0)
	print("Combat window test: startup elapsed")
	if int(target.get_meta("hp")) != expected:
		await _finish(1, game, "Light attack did not apply its configured damage during the active window")
		return

	await create_timer(CombatRules.attack_active_duration(false) + 0.06).timeout
	if int(target.get_meta("hp")) != expected:
		await _finish(1, game, "One swing damaged the same target more than once")
		return

	var intro_player_position := player.global_position
	var intro_attack_sequence := int(game.get("attack_sequence"))
	game.set("cinematic_active", true)
	Input.action_press("move_forward")
	Input.action_press("attack")
	game.call("_physics_process", 1.0 / 60.0)
	game.call("_process", 1.0 / 60.0)
	Input.action_release("move_forward")
	Input.action_release("attack")
	if player.global_position.distance_to(intro_player_position) > 0.0001:
		await _finish(1, game, "Player movement continued during the boss introduction cinematic")
		return
	if int(game.get("attack_sequence")) != intro_attack_sequence:
		await _finish(1, game, "Player attacks were accepted during the boss introduction cinematic")
		return
	print("Combat window test: boss introduction locks player movement and attacks")

	print("Combat window smoke test passed: startup delay, active hit, one hit per target and cinematic input lock")
	# Drop test-only references before the main scene is destroyed so Godot can release
	# its transient packed scene and actor resources at process exit.
	target = null
	player = null
	enemies.clear()
	hud = null
	status_label = null
	main_scene = null
	await _finish(0, game)


func _finish(exit_code: int, game: Node, message: String = "") -> void:
	if _finished:
		return
	_finished = true
	if not message.is_empty():
		push_error(message)
	if is_instance_valid(game):
		# Stop every short-lived SFX voice and detach its stream before freeing
		# the scene; the audio server can otherwise retain an active WAV playback
		# after this headless test exits.
		var voices: Array = game.get("sound_players")
		for voice_variant in voices:
			var voice := voice_variant as AudioStreamPlayer
			if is_instance_valid(voice):
				voice.stop()
				voice.stream = null
		voices.clear()
		var streams: Dictionary = game.get("sfx_streams")
		streams.clear()
		game.free()
	_active_game = null
	if is_instance_valid(_watchdog_timer):
		_watchdog_timer.stop()
		_watchdog_timer.queue_free()
	await process_frame
	await process_frame
	# Defer quitting until the caller coroutine has returned and released its
	# PackedScene, streams and temporary test references.
	call_deferred("_quit_after_cleanup", exit_code)


func _quit_after_cleanup(exit_code: int) -> void:
	await process_frame
	quit(exit_code)
