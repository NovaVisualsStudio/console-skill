extends SceneTree

const TitleScreen = preload("res://scripts/title_screen.gd")


func _initialize() -> void:
	call_deferred("_run_title_screen_smoke")


func _run_title_screen_smoke() -> void:
	var menu := TitleScreen.new()
	get_root().add_child(menu)
	await process_frame

	for node_path in [
		"HeroPreview/SubViewport",
		"MainMenuButtons/NewCampaignButton",
		"MainMenuButtons/ContinueButton",
		"CampaignProgress",
		"MainMenuButtons/SettingsButton",
		"MainMenuButtons/CreditsButton",
		"SettingsPanel/SettingsStack/MusicVolumeSlider",
		"SettingsPanel/SettingsStack/SfxVolumeSlider",
		"SettingsPanel/SettingsStack/QualityButton",
		"SettingsPanel/SettingsStack/LanguageButton",
		"CreditsPanel/CreditsStack/CreditsNotice"
	]:
		if menu.get_node_or_null(node_path) == null:
			_fail(menu, "Title screen is missing required control: %s" % node_path)
			return

	var settings_button := menu.get_node("MainMenuButtons/SettingsButton") as Button
	settings_button.pressed.emit()
	if not (menu.get_node("SettingsPanel") as PanelContainer).visible:
		_fail(menu, "Settings panel did not open")
		return

	var quality_button := menu.get_node("SettingsPanel/SettingsStack/QualityButton") as Button
	if quality_button.text.is_empty():
		_fail(menu, "Graphics profile control is not initialized")
		return

	var language_button := menu.get_node("SettingsPanel/SettingsStack/LanguageButton") as Button
	var was_arabic := TranslationServer.get_locale().begins_with("ar")
	language_button.pressed.emit()
	if TranslationServer.get_locale().begins_with("ar") == was_arabic:
		_fail(menu, "Language selector did not switch language")
		return
	var switched_subtitle := (menu.get_node("SubtitleLabel") as Label).text
	if (not was_arabic and switched_subtitle != "المحارب القديم") or (was_arabic and switched_subtitle != "ANCIENT WARRIOR"):
		_fail(menu, "Language selector did not localize the title screen")
		return
	language_button.pressed.emit()
	if TranslationServer.get_locale().begins_with("ar") != was_arabic:
		_fail(menu, "Language selector did not restore the original language")
		return

	var credits_button := menu.get_node("MainMenuButtons/CreditsButton") as Button
	credits_button.pressed.emit()
	var credits_panel := menu.get_node("CreditsPanel") as PanelContainer
	var credits_notice := menu.get_node("CreditsPanel/CreditsNotice") as Label
	if not credits_panel.visible or "mocap.cs.cmu.edu" not in credits_notice.text:
		_fail(menu, "Credits panel or required CMU acknowledgement is missing")
		return

	var manager := get_root().get_node_or_null("SaveManager")
	if manager == null:
		_fail(menu, "Offline SaveManager autoload is missing")
		return
	var profile: Dictionary = manager.get("profile")
	var complete := bool(profile.get("campaign_complete", false))
	var expected_continue_disabled := int(profile.get("highest_wave", 1)) <= 1 and not complete
	var continue_button := menu.get_node("MainMenuButtons/ContinueButton") as Button
	if continue_button.disabled != expected_continue_disabled:
		_fail(menu, "Continue availability does not match saved campaign progress")
		return

	print("Title screen smoke test passed: 3D preview, campaign entry, save-aware continue, settings and credits")
	menu.free()
	quit(0)


func _fail(menu: Node, message: String) -> void:
	push_error(message)
	menu.free()
	quit(1)
