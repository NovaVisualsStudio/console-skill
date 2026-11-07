extends Node
## Versioned local profile storage. No account or network dependency.
const SAVE_PATH := "user://nova_profile.cfg"
const SCHEMA_VERSION := 1

var file_path := SAVE_PATH
var profile: Dictionary = {}


func _ready() -> void:
	load_profile()


func _default_profile() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"best_score": 0,
		"total_souls": 0,
		"highest_wave": 1,
		"unlocked_chapter": 1,
		"boss_defeated": false,
		"music_volume": 0.72,
		"sfx_volume": 0.85
	}


func load_profile() -> bool:
	var config := ConfigFile.new()
	var error := config.load(file_path)
	if error != OK:
		profile = _default_profile()
		return false
	if int(config.get_value("meta", "schema_version", 0)) != SCHEMA_VERSION:
		profile = _default_profile()
		return false
	var defaults := _default_profile()
	for key in defaults:
		profile[key] = config.get_value("profile", key, defaults[key])
	profile["best_score"] = maxi(0, int(profile["best_score"]))
	profile["total_souls"] = maxi(0, int(profile["total_souls"]))
	profile["highest_wave"] = clampi(int(profile["highest_wave"]), 1, 3)
	profile["unlocked_chapter"] = clampi(int(profile["unlocked_chapter"]), 1, 3)
	profile["boss_defeated"] = bool(profile["boss_defeated"])
	profile["music_volume"] = clampf(float(profile["music_volume"]), 0.0, 1.0)
	profile["sfx_volume"] = clampf(float(profile["sfx_volume"]), 0.0, 1.0)
	return true


func save_profile() -> bool:
	var config := ConfigFile.new()
	config.set_value("meta", "schema_version", SCHEMA_VERSION)
	for key in profile:
		config.set_value("profile", key, profile[key])
	return config.save(file_path) == OK


func record_checkpoint(wave: int, run_score: int) -> bool:
	profile["best_score"] = maxi(int(profile["best_score"]), run_score)
	profile["highest_wave"] = maxi(int(profile["highest_wave"]), clampi(wave, 1, 3))
	return save_profile()


func record_run(wave: int, run_score: int, souls_earned: int, defeated_boss: bool = false) -> bool:
	profile["best_score"] = maxi(int(profile["best_score"]), run_score)
	profile["total_souls"] = maxi(0, int(profile["total_souls"]) + maxi(0, souls_earned))
	profile["highest_wave"] = maxi(int(profile["highest_wave"]), clampi(wave, 1, 3))
	if defeated_boss:
		profile["boss_defeated"] = true
		profile["unlocked_chapter"] = maxi(int(profile["unlocked_chapter"]), 2)
	return save_profile()


func set_audio_options(music: float, sfx: float) -> bool:
	profile["music_volume"] = clampf(music, 0.0, 1.0)
	profile["sfx_volume"] = clampf(sfx, 0.0, 1.0)
	return save_profile()


func reset_profile() -> bool:
	profile = _default_profile()
	return save_profile()
