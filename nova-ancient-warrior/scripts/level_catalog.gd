extends RefCounted
## Data-driven arena themes. Each wave is a distinct visual region even in the compact vertical slice.
const LEVELS := [
	{
		"id": "sunken_ruins",
		"title": "THE SUNKEN RUINS",
		"floor": Color(0.22, 0.19, 0.17),
		"sky_top": Color(0.035, 0.055, 0.11),
		"sky_horizon": Color(0.34, 0.19, 0.13),
		"ambient": Color(0.34, 0.38, 0.52),
		"sun": Color(1.0, 0.72, 0.48),
		"sun_energy": 1.25,
		"boss_name": "ASH SENTINELS"
	},
	{
		"id": "ember_causeway",
		"title": "THE EMBER CAUSEWAY",
		"floor": Color(0.12, 0.105, 0.105),
		"sky_top": Color(0.045, 0.018, 0.028),
		"sky_horizon": Color(0.42, 0.095, 0.045),
		"ambient": Color(0.38, 0.20, 0.18),
		"sun": Color(1.0, 0.34, 0.16),
		"sun_energy": 1.45,
		"boss_name": "EMBER SENTINELS"
	},
	{
		"id": "obsidian_throne",
		"title": "THE OBSIDIAN THRONE",
		"floor": Color(0.105, 0.12, 0.16),
		"sky_top": Color(0.025, 0.035, 0.09),
		"sky_horizon": Color(0.18, 0.16, 0.36),
		"ambient": Color(0.28, 0.32, 0.54),
		"sun": Color(0.56, 0.68, 1.0),
		"sun_energy": 1.1,
		"boss_name": "ASH TITAN"
	}
]


static func get_level(wave: int) -> Dictionary:
	return LEVELS[clampi(wave - 1, 0, LEVELS.size() - 1)].duplicate(true)


static func level_count() -> int:
	return LEVELS.size()
