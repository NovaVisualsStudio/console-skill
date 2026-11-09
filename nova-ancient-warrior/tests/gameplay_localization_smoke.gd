extends SceneTree

var _active_game: Node


func _initialize() -> void:
	call_deferred("_run_gameplay_localization_smoke")


func _run_gameplay_localization_smoke() -> void:
	var save_manager := get_root().get_node_or_null("SaveManager")
	if save_manager == null or not save_manager.call("set_language", "ar"):
		_fail("Could not set Arabic locale for gameplay localization test")
		return
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("Main gameplay scene could not be loaded")
		return
	var game := packed.instantiate()
	_active_game = game
	get_root().add_child(game)
	await process_frame
	await process_frame

	for node_name in ["Touch_attack", "Touch_heavy_attack", "Touch_jump", "Touch_lock_on", "Touch_dodge", "Touch_block", "CombatHint"]:
		if game.find_child(node_name, true, false) == null:
			_fail("Gameplay localization node is missing: %s" % node_name)
			return

	if (game.find_child("Touch_attack", true, false) as Button).text != "هجوم":
		_fail("Attack touch control did not localize to Arabic")
		return
	if (game.find_child("Touch_dodge", true, false) as Button).text != "مراوغة":
		_fail("Dodge touch control did not localize to Arabic")
		return
	if "تحرك" not in (game.find_child("CombatHint", true, false) as Label).text:
		_fail("Combat hint did not localize to Arabic")
		return
	var quality_button := game.find_child("GraphicsQualityButton", true, false) as Button
	if quality_button == null or not quality_button.text.contains("جودة الرسوم"):
		_fail("Graphics quality control did not localize to Arabic")
		return

	var dialogue_lines: Array[Dictionary] = [
		{"speaker": "NOVA", "text": "The language changed while the story was open.", "text_ar": "تغيرت اللغة أثناء عرض القصة."}
	]
	game.call("_start_dialogue", dialogue_lines)
	var dialogue_text := game.find_child("DialogueText", true, false) as Label
	var dialogue_speaker := game.find_child("DialogueSpeaker", true, false) as Label
	if dialogue_text == null or dialogue_text.text != "تغيرت اللغة أثناء عرض القصة.":
		_fail("Dialogue did not start in Arabic")
		return
	var pause_menu := game.find_child("PauseMenu", true, false)
	if pause_menu == null:
		_fail("Pause menu is missing from gameplay")
		return
	pause_menu.call("_toggle_language")
	if TranslationServer.get_locale().begins_with("ar"):
		_fail("Pause menu language toggle did not switch to English")
		return
	if (game.find_child("Touch_attack", true, false) as Button).text != "ATTACK":
		_fail("Pause menu language change did not refresh touch controls")
		return
	if not quality_button.text.contains("QUALITY"):
		_fail("Graphics quality control did not refresh after live language switch")
		return
	if "MOVE" not in (game.find_child("CombatHint", true, false) as Label).text:
		_fail("Pause menu language change did not refresh combat hint")
		return
	if dialogue_text.text != "The language changed while the story was open." or dialogue_speaker.text != "NOVA":
		_fail("Open dialogue did not refresh into English when language changed")
		return
	pause_menu.call("_toggle_language")
	if not TranslationServer.get_locale().begins_with("ar") or dialogue_text.text != "تغيرت اللغة أثناء عرض القصة.":
		_fail("Pause menu language change did not restore Arabic dialogue")
		return

	# Explicitly shut down ambient playback while the gameplay scene is still
	# alive, then allow the audio server and scene tree to retire its playback.
	var music_director := game.get_node_or_null("MusicDirector")
	var ambient_player := game.get_node_or_null("MusicDirector/AmbientMusicPlayer") as AudioStreamPlayer
	if music_director == null or ambient_player == null or not ambient_player.playing:
		_fail("Ambient music player did not start for the gameplay session")
		return
	music_director.call("shutdown")
	await process_frame
	await process_frame
	if is_instance_valid(ambient_player):
		_fail("Ambient music player was not released by MusicDirector.shutdown()")
		return
	print("Gameplay localization smoke test passed: Arabic/English live switch and ambient audio shutdown")
	# Return from the test coroutine first so PackedScene and UI references are
	# released before the main scene is destroyed and Godot checks resource leaks.
	call_deferred("_cleanup_and_quit", 0)


func _fail(message: String) -> void:
	push_error(message)
	# Each failure path returns immediately after this call; defer cleanup until
	# the test coroutine has unwound and dropped its temporary resource references.
	call_deferred("_cleanup_and_quit", 1)


func _cleanup_and_quit(exit_code: int) -> void:
	if is_instance_valid(_active_game):
		_active_game.free()
	_active_game = null
	await process_frame
	await process_frame
	call_deferred("_quit_after_cleanup", exit_code)


func _quit_after_cleanup(exit_code: int) -> void:
	await process_frame
	quit(exit_code)
