extends RefCounted
## Conservative runtime profile for Android compatibility-renderer devices.
## Desktop preview keeps the full presentation; Android favours stable frame pacing.

const ANDROID_FPS_CAP := 45
const DESKTOP_FPS_CAP := 60


static func apply(is_android: bool, world_environment: Environment, key_light: DirectionalLight3D) -> void:
	Engine.max_fps = ANDROID_FPS_CAP if is_android else DESKTOP_FPS_CAP
	if not is_android:
		if world_environment != null:
			world_environment.glow_enabled = true
		if key_light != null:
			key_light.shadow_enabled = true
		return
	if world_environment != null:
		world_environment.glow_enabled = false
		world_environment.ambient_light_energy = maxf(world_environment.ambient_light_energy, 0.62)
	if key_light != null:
		key_light.shadow_enabled = false
