extends RefCounted
## Visual-first runtime profile.
## Desktop uses the Forward+ renderer; compatible Android devices use the Mobile/Vulkan renderer.
## This profile does not silently disable shadows, glow, or other quality features on Android.

const ANDROID_FPS_CAP := 60
const DESKTOP_FPS_CAP := 60
const MIN_AMBIENT_LIGHT_ENERGY := 0.62


static func apply(_is_android: bool, world_environment: Environment, key_light: DirectionalLight3D) -> void:
	Engine.max_fps = ANDROID_FPS_CAP if _is_android else DESKTOP_FPS_CAP
	if world_environment != null:
		world_environment.glow_enabled = true
		world_environment.ambient_light_energy = maxf(world_environment.ambient_light_energy, MIN_AMBIENT_LIGHT_ENERGY)
	if key_light != null:
		key_light.shadow_enabled = true
