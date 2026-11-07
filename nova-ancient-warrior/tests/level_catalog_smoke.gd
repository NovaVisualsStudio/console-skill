extends SceneTree

const LevelCatalog = preload("res://scripts/level_catalog.gd")


func _initialize() -> void:
	var seen_ids: Dictionary = {}
	for wave in range(1, LevelCatalog.level_count() + 1):
		var level := LevelCatalog.get_level(wave)
		if str(level.get("id", "")).is_empty() or seen_ids.has(level.get("id")):
			push_error("Arena level IDs must be present and unique")
			quit(1)
			return
		seen_ids[level["id"]] = true
		if not level.has("floor") or not level.has("sky_top") or not level.has("boss_name"):
			push_error("Arena theme is missing required environment data")
			quit(1)
			return
	if LevelCatalog.get_level(3).get("boss_name") != "ASH TITAN":
		push_error("Final arena boss label does not match the final encounter")
		quit(1)
		return
	print("Level catalog smoke test passed: three unique arena themes and final boss metadata")
	quit(0)
