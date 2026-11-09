extends SceneTree

const MobileRenderProfile = preload("res://scripts/mobile_render_profile.gd")


func _initialize() -> void:
	var android_renderer := str(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile", ""))
	var desktop_renderer := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", ""))
	var mobile_width := int(ProjectSettings.get_setting("display/window/size/viewport_width.mobile", 0))
	var mobile_height := int(ProjectSettings.get_setting("display/window/size/viewport_height.mobile", 0))
	if android_renderer != "gl_compatibility":
		_fail("Android renderer baseline must remain Compatibility until physical Vulkan comparison passes")
		return
	if desktop_renderer != "forward_plus":
		_fail("Desktop master renderer must remain Forward+")
		return
	if mobile_width != 1280 or mobile_height != 720:
		_fail("Android HD viewport must be 1280x720")
		return

	var environment := Environment.new()
	var light := DirectionalLight3D.new()
	var mid := MobileRenderProfile.apply(true, environment, light, MobileRenderProfile.QUALITY_MID)
	if Engine.max_fps != MobileRenderProfile.ANDROID_MID_FPS_CAP:
		_fail("Mid Android profile must cap at 45 FPS")
		return
	if environment.glow_enabled or light.shadow_enabled:
		_fail("Mid Android profile must keep expensive effects disabled")
		return
	if environment.ambient_light_energy < 0.72 or str(mid["quality"]) != "mid":
		_fail("Mid Android ambient floor or selected tier is invalid")
		return

	var mid_budget := MobileRenderProfile.environment_budget(true, "mid")
	var high_budget := MobileRenderProfile.environment_budget(true, "high")
	if int(mid_budget["pillar_count"]) >= int(high_budget["pillar_count"]) or int(mid_budget["rock_count"]) >= int(high_budget["rock_count"]):
		_fail("High tier must provide denser environment geometry")
		return

	var high := MobileRenderProfile.apply(true, environment, light, MobileRenderProfile.QUALITY_HIGH)
	if Engine.max_fps != MobileRenderProfile.ANDROID_HIGH_FPS_CAP or not environment.glow_enabled or not light.shadow_enabled or str(high["quality"]) != "high":
		_fail("High Android profile must enable 60 FPS cap, glow and key-light shadows")
		return

	MobileRenderProfile.apply(false, environment, light)
	if Engine.max_fps != MobileRenderProfile.DESKTOP_FPS_CAP or not environment.glow_enabled or not light.shadow_enabled:
		_fail("Desktop profile must retain full lighting and 60 FPS cap")
		return
	light.free()
	light = null
	environment = null
	print("Renderer profile test passed: mid Android 45 FPS; high Android 60 FPS opt-in; desktop Forward+ profile")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
