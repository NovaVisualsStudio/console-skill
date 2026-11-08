extends SceneTree

const MobileRenderProfile = preload("res://scripts/mobile_render_profile.gd")


func _initialize() -> void:
	var environment := Environment.new()
	environment.glow_enabled = false
	environment.ambient_light_energy = 0.4
	var light := DirectionalLight3D.new()
	light.shadow_enabled = false

	MobileRenderProfile.apply(true, environment, light)
	if Engine.max_fps != MobileRenderProfile.ANDROID_FPS_CAP:
		_fail("Android visual target frame cap was not applied")
		return
	if not environment.glow_enabled:
		_fail("Android profile must preserve glow for the visual-first target")
		return
	if environment.ambient_light_energy < MobileRenderProfile.MIN_AMBIENT_LIGHT_ENERGY:
		_fail("Android environment ambient contribution is below the visual target")
		return
	if not light.shadow_enabled:
		_fail("Android profile must preserve key-light shadows")
		return

	MobileRenderProfile.apply(false, environment, light)
	if Engine.max_fps != MobileRenderProfile.DESKTOP_FPS_CAP:
		_fail("Desktop visual target frame cap was not applied")
		return
	if not environment.glow_enabled or not light.shadow_enabled:
		_fail("Desktop profile must preserve visual quality features")
		return

	print("Visual-first render profile smoke test passed: Android Mobile and desktop Forward+ quality flags")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
