extends SceneTree

const LevelCatalog = preload("res://scripts/level_catalog.gd")


func _initialize() -> void:
	var seen_ids: Dictionary = {}
	for chapter in range(3):
		var wave := chapter * 3 + 1
		var level := LevelCatalog.get_level(wave)
		var level_id := str(level.get("id", ""))
		if level_id.is_empty() or seen_ids.has(level_id):
			push_error("Campaign stage IDs must be present and unique")
			quit(1)
			return
		seen_ids[level_id] = true
		for required_key in ["floor", "sky_top", "sky_horizon", "ambient", "sun", "boss_name", "boss_name_ar", "boss_kind", "chapter_title", "chapter_title_ar"]:
			if not level.has(required_key):
				push_error("Campaign stage is missing required metadata: " + required_key)
				quit(1)
				return
	if LevelCatalog.level_count() != 3:
		push_error("Campaign must contain three distinct chapter regions")
		quit(1)
		return
	if LevelCatalog.stage_index(1) != 0 or LevelCatalog.stage_index(4) != 1 or LevelCatalog.stage_index(7) != 2:
		push_error("Wave-to-chapter mapping is incorrect")
		quit(1)
		return
	if LevelCatalog.get_level(3).get("boss_name") != "THE ASH TITAN":
		push_error("Chapter one boss identity is wrong")
		quit(1)
		return
	if LevelCatalog.get_level(6).get("boss_name") != "THE EMBER WARLORD":
		push_error("Chapter two boss identity is wrong")
		quit(1)
		return
	if LevelCatalog.get_level(9).get("boss_name") != "THE OBSIDIAN SOVEREIGN":
		push_error("Final boss identity is wrong")
		quit(1)
		return
	if not LevelCatalog.wave_title(9).contains("WAVE 9/9"):
		push_error("Final chapter status title was not generated")
		quit(1)
		return
	var original_locale := TranslationServer.get_locale()
	TranslationServer.set_locale("ar")
	var arabic_title := LevelCatalog.wave_title(9)
	if not arabic_title.contains("الفصل الثالث") or not arabic_title.contains("مواجهة الزعيم"):
		push_error("Arabic campaign chapter and encounter title was not generated")
		quit(1)
		return
	if str(LevelCatalog.get_level(9).get("boss_name_ar", "")) != "حاكم العرش الأسود":
		push_error("Final boss Arabic identity is missing")
		quit(1)
		return
	TranslationServer.set_locale(original_locale)
	print("Level catalog smoke test passed: three campaign regions and boss identities")
	quit(0)
