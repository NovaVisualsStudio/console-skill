extends RefCounted
## Three distinct campaign regions; each contains two enemy waves and a boss encounter.

const LEVELS := [
	{
		"id": "sunken_ruins",
		"title": "THE SUNKEN RUINS",
		"chapter_title": "CHAPTER I - THE SUNKEN RUINS",
		"chapter_title_ar": "الفصل الأول: الأطلال الغارقة",
		"floor": Color(0.22, 0.19, 0.17),
		"sky_top": Color(0.035, 0.055, 0.11),
		"sky_horizon": Color(0.34, 0.19, 0.13),
		"ambient": Color(0.34, 0.38, 0.52),
		"sun": Color(1.0, 0.72, 0.48),
		"sun_energy": 1.25,
		"stone": Color(0.30, 0.26, 0.22),
		"accent": Color(0.73, 0.43, 0.20),
		"emission": Color(0.0, 0.0, 0.0),
		"boss_name": "THE ASH TITAN",
		"boss_name_ar": "عملاق الرماد",
		"boss_kind": "ash_titan"
	},
	{
		"id": "ember_causeway",
		"title": "THE EMBER CAUSEWAY",
		"chapter_title": "CHAPTER II - THE EMBER CAUSEWAY",
		"chapter_title_ar": "الفصل الثاني: جسر الجمر",
		"floor": Color(0.12, 0.105, 0.105),
		"sky_top": Color(0.045, 0.018, 0.028),
		"sky_horizon": Color(0.42, 0.095, 0.045),
		"ambient": Color(0.38, 0.20, 0.18),
		"sun": Color(1.0, 0.34, 0.16),
		"sun_energy": 1.45,
		"stone": Color(0.12, 0.105, 0.11),
		"accent": Color(0.70, 0.20, 0.08),
		"emission": Color(1.0, 0.12, 0.025),
		"boss_name": "THE EMBER WARLORD",
		"boss_name_ar": "قائد الحرب النارية",
		"boss_kind": "ember_warlord"
	},
	{
		"id": "obsidian_throne",
		"title": "THE OBSIDIAN THRONE",
		"chapter_title": "CHAPTER III - THE OBSIDIAN THRONE",
		"chapter_title_ar": "الفصل الثالث: العرش الأسود",
		"floor": Color(0.105, 0.12, 0.16),
		"sky_top": Color(0.025, 0.035, 0.09),
		"sky_horizon": Color(0.18, 0.16, 0.36),
		"ambient": Color(0.28, 0.32, 0.54),
		"sun": Color(0.56, 0.68, 1.0),
		"sun_energy": 1.1,
		"stone": Color(0.11, 0.13, 0.21),
		"accent": Color(0.34, 0.48, 0.86),
		"emission": Color(0.10, 0.22, 0.82),
		"boss_name": "THE OBSIDIAN SOVEREIGN",
		"boss_name_ar": "حاكم العرش الأسود",
		"boss_kind": "obsidian_sovereign"
	}
]


static func stage_index(wave: int) -> int:
	return clampi(int((clampi(wave, 1, 9) - 1) / 3), 0, LEVELS.size() - 1)


static func get_level(wave: int) -> Dictionary:
	return LEVELS[stage_index(wave)].duplicate(true)


static func level_count() -> int:
	return LEVELS.size()


static func wave_title(wave: int) -> String:
	var safe_wave := clampi(wave, 1, 9)
	var level := get_level(safe_wave)
	if TranslationServer.get_locale().begins_with("ar"):
		var encounter_ar := "مواجهة الزعيم" if safe_wave % 3 == 0 else "مواجهة الأعداء"
		return "%s  |  الموجة %d/9  |  %s" % [str(level["chapter_title_ar"]), safe_wave, encounter_ar]
	var encounter := "BOSS ENCOUNTER" if safe_wave % 3 == 0 else "ENEMY ENCOUNTER"
	return "%s  |  WAVE %d/9  |  %s" % [str(level["chapter_title"]), safe_wave, encounter]
