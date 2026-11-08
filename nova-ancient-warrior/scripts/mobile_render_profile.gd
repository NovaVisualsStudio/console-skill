extends RefCounted
## Runtime targets: desktop uses Forward+ at 60 FPS; Android uses GL Compatibility.
## Compatibility avoids requiring Vulkan support on Android GPU drivers.
## Keep a 720p mobile viewport; retain visually useful glow and one key directional shadow.

const ANDROID_FPS_CAP := 30
const DESKTOP_FPS_CAP := 60
const ANDROID_AMBIENT_FLOOR := 0.62


static func apply(is_android: bool, world_environment: Environment, key_light: DirectionalLight3D) -> void:
	Engine.max_fps = ANDROID_FPS_CAP if is_android else DESKTOP_FPS_CAP
	if world_environment != null:
		world_environment.glow_enabled = true
		world_environment.ambient_light_energy = maxf(world_environment.ambient_light_energy, ANDROID_AMBIENT_FLOOR)
	if key_light != null:
		key_light.shadow_enabled = true
