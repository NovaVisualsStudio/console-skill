extends RefCounted
## Deterministic combat and campaign rules shared by gameplay and tests.

const CAMPAIGN_CHAPTERS := 3
const WAVES_PER_CHAPTER := 3
const CAMPAIGN_WAVES := CAMPAIGN_CHAPTERS * WAVES_PER_CHAPTER
const DEFAULT_ATTACK_DOT_THRESHOLD := 0.2


static func is_target_in_attack_arc(
	facing: Vector3,
	target_offset: Vector3,
	max_distance: float,
	dot_threshold: float = DEFAULT_ATTACK_DOT_THRESHOLD
) -> bool:
	if max_distance <= 0.0 or target_offset.length_squared() <= 0.000001:
		return false
	var flat_facing := Vector3(facing.x, 0.0, facing.z)
	var flat_target := Vector3(target_offset.x, 0.0, target_offset.z)
	if flat_facing.length_squared() <= 0.000001 or flat_target.length_squared() <= 0.000001:
		return false
	if flat_target.length_squared() > max_distance * max_distance:
		return false
	return flat_facing.normalized().dot(flat_target.normalized()) >= dot_threshold


static func can_receive_hit(invulnerability_remaining: float) -> bool:
	return invulnerability_remaining <= 0.0


static func combo_damage(step: int) -> int:
	match clampi(step, 0, 2):
		0:
			return 24
		1:
			return 30
		_:
			return 48


static func combo_range(step: int) -> float:
	return 2.8 if clampi(step, 0, 2) == 2 else 2.35


static func combo_cooldown(step: int) -> float:
	match clampi(step, 0, 2):
		0:
			return 0.30
		1:
			return 0.34
		_:
			return 0.55


static func heavy_attack_damage() -> int:
	return 68


static func heavy_attack_range() -> float:
	return 3.15


static func heavy_attack_cooldown() -> float:
	return 0.82



static func attack_startup(heavy: bool, combo_step: int = 0) -> float:
	if heavy:
		return 0.22
	var startup_times := [0.12, 0.14, 0.16]
	return float(startup_times[clampi(combo_step, 0, 2)])


static func attack_active_duration(heavy: bool) -> float:
	return 0.18 if heavy else 0.12


static func should_start_enemy_windup(distance: float, cooldown: float, windup_range: float = 1.85) -> bool:
	return distance <= maxf(0.0, windup_range) and cooldown <= 0.0


static func is_boss_wave(wave: int) -> bool:
	var safe_wave := clampi(wave, 1, CAMPAIGN_WAVES)
	return safe_wave % WAVES_PER_CHAPTER == 0


static func chapter_for_wave(wave: int) -> int:
	return clampi(int((clampi(wave, 1, CAMPAIGN_WAVES) - 1) / WAVES_PER_CHAPTER) + 1, 1, CAMPAIGN_CHAPTERS)


static func boss_kind_for_wave(wave: int) -> String:
	match chapter_for_wave(wave):
		1:
			return "ash_titan"
		2:
			return "ember_warlord"
		_:
			return "obsidian_sovereign"


static func boss_display_name(wave: int) -> String:
	match boss_kind_for_wave(wave):
		"ash_titan":
			return "THE ASH TITAN"
		"ember_warlord":
			return "THE EMBER WARLORD"
		_:
			return "THE OBSIDIAN SOVEREIGN"


static func boss_phase(current_hp: int, maximum_hp: int) -> int:
	if maximum_hp <= 0:
		return 3
	var ratio := float(maxi(0, current_hp)) / float(maximum_hp)
	if ratio > 0.66:
		return 1
	if ratio > 0.33:
		return 2
	return 3


static func wave_enemy_count(wave: int) -> int:
	var safe_wave := clampi(wave, 1, CAMPAIGN_WAVES)
	if is_boss_wave(safe_wave):
		return 1
	var chapter_offset := chapter_for_wave(safe_wave) - 1
	var position_in_chapter := (safe_wave - 1) % WAVES_PER_CHAPTER
	return 4 + chapter_offset + (1 if position_in_chapter == 1 else 0)


static func wave_enemy_spawn_position(wave: int, enemy_index: int) -> Vector3:
	var count := wave_enemy_count(wave)
	var safe_index := clampi(enemy_index, 0, count - 1)
	var angle := TAU * float(safe_index) / float(count) + 0.4
	var chapter_offset := chapter_for_wave(wave) - 1
	var radius := 7.8 if is_boss_wave(wave) else 6.2 + float(chapter_offset) * 0.7
	return Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)


static func wave_enemy_health(wave: int) -> int:
	var safe_wave := clampi(wave, 1, CAMPAIGN_WAVES)
	var chapter_offset := chapter_for_wave(safe_wave) - 1
	if is_boss_wave(safe_wave):
		return 300 + chapter_offset * 130
	return 58 + chapter_offset * 18 + ((safe_wave - 1) % WAVES_PER_CHAPTER) * 8


static func wave_enemy_damage(wave: int) -> int:
	var safe_wave := clampi(wave, 1, CAMPAIGN_WAVES)
	var chapter_offset := chapter_for_wave(safe_wave) - 1
	if is_boss_wave(safe_wave):
		return 20 + chapter_offset * 7
	return 8 + chapter_offset * 3 + ((safe_wave - 1) % WAVES_PER_CHAPTER)


static func is_final_boss_wave(wave: int) -> bool:
	return clampi(wave, 1, CAMPAIGN_WAVES) == CAMPAIGN_WAVES
