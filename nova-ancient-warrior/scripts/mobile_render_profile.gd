extends RefCounted
## Mobile-first Android baseline: Godot Compatibility renderer / OpenGL ES 3.0.
## Desktop master remains Forward+. Physical-device profiling is required before raising
## the Android frame cap or re-enabling expensive lighting features.

const ANDROID_FPS_CAP := 30
const DESKTOP_FPS_CAP := 60
const ANDROID_AMBIENT_FLOOR := 0.68
const ANDROID_PILLAR_COUNT := 8
const DESKTOP_PILLAR_COUNT := 12
const ANDROID_BRAZIER_COUNT := 4
const DESKTOP_BRAZIER_COUNT := 8
const ANDROID_ROCK_COUNT := 18
const DESKTOP_ROCK_COUNT := 34
const ANDROID_FIRE_LIGHT_COUNT := 1


static func apply(is_android: bool, world_environment: Environment, key_light: DirectionalLight3D) -> void:
	Engine.max_fps = ANDROID_FPS_CAP if is_android else DESKTOP_FPS_CAP
	if world_environment != null:
		world_environment.glow_enabled = not is_android
		world_environment.ambient_light_energy = maxf(world_environment.ambient_light_energy, ANDROID_AMBIENT_FLOOR if is_android else 0.0)
	if key_light != null:
		key_light.shadow_enabled = not is_android
