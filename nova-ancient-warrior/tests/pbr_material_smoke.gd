extends SceneTree

const PBRMaterials = preload("res://scripts/pbr_material_library.gd")


func _initialize() -> void:
	call_deferred("_run_pbr_smoke")


func _run_pbr_smoke() -> void:
	var stone := PBRMaterials.create_surface_material(Color(0.42, 0.36, 0.28), 0.08, 0.92, 1701, 2.8)
	var basalt := PBRMaterials.create_surface_material(Color(0.10, 0.075, 0.07), 0.22, 0.76, 1702, 3.2)
	var stone_repeat := PBRMaterials.create_surface_material(Color(0.42, 0.36, 0.28), 0.08, 0.92, 1701, 2.8)
	if stone.albedo_texture == null or stone.roughness_texture == null or stone.normal_texture == null:
		_fail("PBR material is missing generated texture maps")
		return
	if not stone.normal_enabled or not (stone.normal_texture is NoiseTexture2D):
		_fail("PBR material normal map is not enabled")
		return
	if not (stone.albedo_texture is NoiseTexture2D) or not (stone.roughness_texture is NoiseTexture2D):
		_fail("PBR albedo and roughness maps must be procedural NoiseTexture2D resources")
		return
	if stone.albedo_texture.width != 128 or stone.albedo_texture.height != 128:
		_fail("Procedural PBR maps must use the mobile 128x128 source budget")
		return
	if not stone.normal_texture.as_normal_map:
		_fail("Generated surface normal texture is not flagged as a normal map")
		return
	if stone.albedo_texture != stone_repeat.albedo_texture or stone.roughness_texture != stone_repeat.roughness_texture or stone.normal_texture != stone_repeat.normal_texture:
		_fail("Repeated material requests did not reuse cached texture maps")
		return
	if stone.uv1_scale.x <= 0.0 or basalt.roughness <= 0.0:
		_fail("PBR material UV scale or roughness is invalid")
		return
	if PBRMaterials.cached_texture_count() < 6:
		_fail("Procedural material cache did not retain shared maps")
		return
	print("PBR material smoke test passed: albedo, roughness and normal maps generated and cached")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
