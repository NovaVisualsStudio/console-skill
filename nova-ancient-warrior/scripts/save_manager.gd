extends Node
## Versioned offline save profile with checkpoint-safe currency accounting and permanent upgrades.

const SAVE_PATH := "user://nova_profile.cfg"
const SCHEMA_VERSION := 3
const MAX_WAVE := 9

var file_path := SAVE_PATH
var profile: Dictionary = {}


func _ready() -> void:
	load_profile()


func begin_run() -> bool:
	profile["pending_souls"] = 0
	return save_profile()


func _default_profile() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"best_score": 0,
		"total_souls": 0,
		"pending_souls": 0,
		"highest_wave": 1,
		"unlocked_chapter": 1,
		"boss_defeated": false,
		"campaign_complete": false,
		"upgrade_blade": 0,
		"upgrade_vitality": 0,
		"upgrade_guard": 0,
		"music_volume": 0.72,
		"sfx_volume": 0.85,
		"graphics_quality": "mid"
	}


func load_profile() -> bool:
	var config := ConfigFile.new()
	var error := config.load(file_path)
	if error != OK:
		profile = _default_profile()
		return false
	var stored_version := int(config.get_value("meta", "schema_version", 0))
	if stored_version < 1 or stored_version > SCHEMA_VERSION:
		profile = _default_profile()
		return false
	var defaults := _default_profile()
	for key in defaults:
		profile[key] = config.get_value("profile", key, defaults[key])
	profile["best_score"] = maxi(0, int(profile["best_score"]))
	profile["total_souls"] = maxi(0, int(profile["total_souls"]))
	profile["pending_souls"] = clampi(int(profile["pending_souls"]), 0, int(profile["total_souls"]))
	profile["highest_wave"] = clampi(int(profile["highest_wave"]), 1, MAX_WAVE)
	profile["unlocked_chapter"] = clampi(int(profile["unlocked_chapter"]), 1, 3)
	profile["boss_defeated"] = bool(profile["boss_defeated"])
	profile["campaign_complete"] = bool(profile["campaign_complete"])
	profile["upgrade_blade"] = clampi(int(profile["upgrade_blade"]), 0, 3)
	profile["upgrade_vitality"] = clampi(int(profile["upgrade_vitality"]), 0, 3)
	profile["upgrade_guard"] = clampi(int(profile["upgrade_guard"]), 0, 3)
	profile["music_volume"] = clampf(float(profile["music_volume"]), 0.0, 1.0)
	profile["sfx_volume"] = clampf(float(profile["sfx_volume"]), 0.0, 1.0)
	var graphics_quality := str(profile.get("graphics_quality", "mid")).to_lower()
	profile["graphics_quality"] = "high" if graphics_quality == "high" else "mid"
	profile["schema_version"] = SCHEMA_VERSION
	return true


func save_profile() -> bool:
	var config := ConfigFile.new()
	config.set_value("meta", "schema_version", SCHEMA_VERSION)
	for key in profile:
		config.set_value("profile", key, profile[key])
	return config.save(file_path) == OK


func _commit_pending_souls(run_souls: int) -> void:
	var total_run_souls := maxi(0, run_souls)
	var already_committed := clampi(int(profile.get("pending_souls", 0)), 0, total_run_souls)
	var new_souls := total_run_souls - already_committed
	profile["total_souls"] = maxi(0, int(profile.get("total_souls", 0)) + new_souls)
	profile["pending_souls"] = total_run_souls


func record_checkpoint(wave: int, run_score: int, run_souls: int = 0) -> bool:
	profile["best_score"] = maxi(int(profile.get("best_score", 0)), maxi(0, run_score))
	profile["highest_wave"] = maxi(int(profile.get("highest_wave", 1)), clampi(wave, 1, MAX_WAVE))
	_commit_pending_souls(run_souls)
	return save_profile()


func record_boss_victory(wave: int) -> bool:
	var safe_wave := clampi(wave, 1, MAX_WAVE)
	if safe_wave % 3 != 0:
		return false
	var chapter_cleared := int(safe_wave / 3)
	profile["boss_defeated"] = true
	profile["unlocked_chapter"] = maxi(int(profile.get("unlocked_chapter", 1)), mini(3, chapter_cleared + 1))
	if safe_wave == MAX_WAVE:
		profile["campaign_complete"] = true
	return save_profile()


func record_run(wave: int, run_score: int, souls_earned: int, defeated_boss: bool = false) -> bool:
	profile["best_score"] = maxi(int(profile.get("best_score", 0)), maxi(0, run_score))
	profile["highest_wave"] = maxi(int(profile.get("highest_wave", 1)), clampi(wave, 1, MAX_WAVE))
	_commit_pending_souls(souls_earned)
	profile["pending_souls"] = 0
	if defeated_boss:
		record_boss_victory(wave)
	return save_profile()


func upgrade_cost(upgrade_name: String) -> int:
	var key := _upgrade_key(upgrade_name)
	if key.is_empty():
		return -1
	var current_level := int(profile.get(key, 0))
	if current_level >= 3:
		return -1
	return 3 + current_level * 3


func purchase_upgrade(upgrade_name: String) -> bool:
	var key := _upgrade_key(upgrade_name)
	if key.is_empty():
		return false
	var cost := upgrade_cost(upgrade_name)
	if cost < 0 or int(profile.get("total_souls", 0)) < cost:
		return false
	profile["total_souls"] = int(profile["total_souls"]) - cost
	profile[key] = int(profile.get(key, 0)) + 1
	return save_profile()


func _upgrade_key(upgrade_name: String) -> String:
	match upgrade_name.to_lower():
		"blade":
			return "upgrade_blade"
		"vitality":
			return "upgrade_vitality"
		"guard":
			return "upgrade_guard"
		_:
			return ""


func set_audio_options(music: float, sfx: float) -> bool:
	profile["music_volume"] = clampf(music, 0.0, 1.0)
	profile["sfx_volume"] = clampf(sfx, 0.0, 1.0)
	return save_profile()


func set_graphics_quality(quality: String) -> bool:
	var normalized := quality.strip_edges().to_lower()
	if normalized not in ["mid", "high"]:
		return false
	profile["graphics_quality"] = normalized
	return save_profile()


func reset_profile() -> bool:
	profile = _default_profile()
	return save_profile()
