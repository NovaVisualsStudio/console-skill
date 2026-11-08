extends SceneTree

const MobileRenderProfile = preload("res://scripts/mobile_render_profile.gd")


func _initialize() -> void:
	var android_renderer := str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", ""))
	var desktop_renderer := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	var mobile_width := int(ProjectSettings.get_setting("display/window/size/viewport_width.mobile", 0))
	var mobile_height := int(ProjectSettings.get_setting("display/window/size/viewport_height.mobile", 0))
	if android_renderer != "gl_compatibility":
		_fail("Android must use GL Compatibility, not Vulkan Mobile")
		return
	if desktop_renderer != "forward_plus":
		_fail("Desktop master renderer must remain Forward+")
		return
	if mobile_width != 1280 or mobile_height != 720:
		_fail("Android viewport must use the tested 1280x720 HD profile")
		return

	var environment := Environment.new()
	environment.glow_enabled = false
	environment.ambient_light_energy = 0.4
	var light := DirectionalLight3D.new()
	light.shadow_enabled = false

	MobileRenderProfile.apply(true, environment, light)
	if Engine.max_fps != MobileRenderProfile.ANDROID_FPS_CAP:
		_fail("Android 30 FPS frame pacing target was not applied")
		return
	if not environment.glow_enabled or not light.shadow_enabled:
		_fail("Android quality profile must preserve glow and key-light shadows")
		return
	if environment.ambient_light_energy < MobileRenderProfile.ANDROID_AMBIENT_FLOOR:
		_fail("Android ambient lighting is below the visual baseline")
		return

	MobileRenderProfile.apply(false, environment, light)
	if Engine.max_fps != MobileRenderProfile.DESKTOP_FPS_CAP:
		_fail("Desktop 60 FPS target was not applied")
		return
	if not environment.glow_enabled or not light.shadow_enabled:
		_fail("Desktop Forward+ profile must retain visual effects")
		return

	print("Renderer target smoke test passed: desktop Forward+, Android GL Compatibility 1280x720")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
