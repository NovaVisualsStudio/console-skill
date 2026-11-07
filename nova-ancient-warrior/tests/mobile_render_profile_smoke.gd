extends SceneTree

const MobileRenderProfile = preload("res://scripts/mobile_render_profile.gd")


func _initialize() -> void:
	var environment := Environment.new()
	environment.glow_enabled = true
	environment.ambient_light_energy = 0.4
	var light := DirectionalLight3D.new()
	light.shadow_enabled = true
	MobileRenderProfile.apply(true, environment, light)
	if Engine.max_fps != MobileRenderProfile.ANDROID_FPS_CAP:
		_fail("Android frame cap was not applied")
		return
	if environment.glow_enabled or environment.ambient_light_energy < 0.62:
		_fail("Android environment did not receive the low-cost lighting profile")
		return
	if light.shadow_enabled:
		_fail("Android key-light shadows should be disabled in the conservative profile")
		return
	MobileRenderProfile.apply(false, environment, light)
	if Engine.max_fps != MobileRenderProfile.DESKTOP_FPS_CAP:
		_fail("Desktop frame cap was not restored")
		return
	if not light.shadow_enabled:
		_fail("Desktop preview should retain key-light shadows")
		return
	print("Mobile render profile smoke test passed: Android and desktop profiles")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
