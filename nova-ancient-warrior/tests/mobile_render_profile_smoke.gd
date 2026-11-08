extends SceneTree

const MobileRenderProfile = preload("res://scripts/mobile_render_profile.gd")


func _initialize() -> void:
	var android_renderer := str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", ""))
	var desktop_renderer := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	var mobile_width := int(ProjectSettings.get_setting("display/window/size/viewport_width.mobile", 0))
	var mobile_height := int(ProjectSettings.get_setting("display/window/size/viewport_height.mobile", 0))
	if android_renderer != "gl_compatibility":
		_fail("Android baseline must use GL Compatibility / OpenGL ES 3.0")
		return
	if desktop_renderer != "forward_plus":
		_fail("Desktop master renderer must remain Forward+")
		return
	if mobile_width != 1280 or mobile_height != 720:
		_fail("Android HD viewport must be 1280x720")
		return

	var environment := Environment.new()
	environment.glow_enabled = true
	environment.ambient_light_energy = 0.4
	var light := DirectionalLight3D.new()
	light.shadow_enabled = true

	MobileRenderProfile.apply(true, environment, light)
	if Engine.max_fps != MobileRenderProfile.ANDROID_FPS_CAP:
		_fail("Android mobile-first frame cap was not applied", light)
		return
	if environment.glow_enabled or light.shadow_enabled:
		_fail("Android baseline must disable glow and real-time key shadows", light)
		return
	if environment.ambient_light_energy < MobileRenderProfile.ANDROID_AMBIENT_FLOOR:
		_fail("Android ambient lighting is below the readability baseline", light)
		return

	MobileRenderProfile.apply(false, environment, light)
	if Engine.max_fps != 60:
		_fail("Desktop 60 FPS cap was not applied", light)
		return
	if not environment.glow_enabled or not light.shadow_enabled:
		_fail("Desktop visual profile must retain glow and key-light shadows", light)
		return

	light.free()
	light = null
	environment = null
	print("Renderer profile test passed: Android 30 FPS mobile baseline; desktop 60 FPS with full lighting")
	call_deferred("quit", 0)


func _fail(message: String, light: DirectionalLight3D = null) -> void:
	if is_instance_valid(light):
		light.free()
	push_error(message)
	call_deferred("quit", 1)
