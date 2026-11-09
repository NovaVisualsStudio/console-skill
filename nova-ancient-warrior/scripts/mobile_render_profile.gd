extends RefCounted
## Two explicit Android profiles for supported mid-range and high-end devices.
## The high profile is opt-in until physical-device frame pacing and thermal tests pass.

const QUALITY_MID := "mid"
const QUALITY_HIGH := "high"
const ANDROID_MID_FPS_CAP := 45
const ANDROID_HIGH_FPS_CAP := 60
const ANDROID_FPS_CAP := ANDROID_MID_FPS_CAP
const DESKTOP_FPS_CAP := 60
const ANDROID_AMBIENT_FLOOR := 0.72
const ANDROID_PILLAR_COUNT := 8
const DESKTOP_PILLAR_COUNT := 12
const ANDROID_BRAZIER_COUNT := 4
const DESKTOP_BRAZIER_COUNT := 8
const ANDROID_ROCK_COUNT := 18
const DESKTOP_ROCK_COUNT := 34
const ANDROID_FIRE_LIGHT_COUNT := 1


static func normalize_quality(quality: String) -> String:
	return QUALITY_HIGH if quality.strip_edges().to_lower() == QUALITY_HIGH else QUALITY_MID


static func environment_budget(is_android: bool, quality: String = QUALITY_MID) -> Dictionary:
	if not is_android:
		return {
			"pillar_count": DESKTOP_PILLAR_COUNT,
			"brazier_count": DESKTOP_BRAZIER_COUNT,
			"rock_count": DESKTOP_ROCK_COUNT,
			"fire_light_count": DESKTOP_BRAZIER_COUNT
		}
	if normalize_quality(quality) == QUALITY_HIGH:
		return {
			"pillar_count": DESKTOP_PILLAR_COUNT,
			"brazier_count": DESKTOP_BRAZIER_COUNT,
			"rock_count": DESKTOP_ROCK_COUNT,
			"fire_light_count": 3
		}
	return {
		"pillar_count": ANDROID_PILLAR_COUNT,
		"brazier_count": ANDROID_BRAZIER_COUNT,
		"rock_count": ANDROID_ROCK_COUNT,
		"fire_light_count": ANDROID_FIRE_LIGHT_COUNT
	}


static func apply(
	is_android: bool,
	world_environment: Environment,
	key_light: DirectionalLight3D,
	quality: String = QUALITY_MID
) -> Dictionary:
	var tier := normalize_quality(quality)
	var fps_cap := DESKTOP_FPS_CAP
	var glow_enabled := true
	var shadows_enabled := true
	var ambient_floor := 0.0
	if is_android:
		if tier == QUALITY_HIGH:
			fps_cap = ANDROID_HIGH_FPS_CAP
			glow_enabled = true
			shadows_enabled = true
			ambient_floor = 0.74
		else:
			fps_cap = ANDROID_MID_FPS_CAP
			glow_enabled = false
			shadows_enabled = false
			ambient_floor = ANDROID_AMBIENT_FLOOR
	Engine.max_fps = fps_cap
	if world_environment != null:
		world_environment.glow_enabled = glow_enabled
		world_environment.ambient_light_energy = maxf(world_environment.ambient_light_energy, ambient_floor)
	if key_light != null:
		key_light.shadow_enabled = shadows_enabled
	return {
		"quality": tier if is_android else "desktop",
		"fps_cap": fps_cap,
		"glow_enabled": glow_enabled,
		"shadows_enabled": shadows_enabled
	}
