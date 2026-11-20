extends RefCounted
## Broad Android compatibility baseline: Godot Compatibility renderer / OpenGL ES 3.0.
## Desktop master: Forward+. Android exports include ARMv7 and ARM64.
## Start at 60 FPS; real-device profiling will determine quality tier and frame pacing.

const ANDROID_FPS_CAP := 60
const DESKTOP_FPS_CAP := 60
const ANDROID_AMBIENT_FLOOR := 0.62


static func apply(is_android: bool, world_environment: Environment, key_light: DirectionalLight3D) -> void:
	Engine.max_fps = ANDROID_FPS_CAP if is_android else DESKTOP_FPS_CAP
	if world_environment != null:
		world_environment.glow_enabled = true
		world_environment.ambient_light_energy = maxf(world_environment.ambient_light_energy, ANDROID_AMBIENT_FLOOR)
	if key_light != null:
		key_light.shadow_enabled = true
