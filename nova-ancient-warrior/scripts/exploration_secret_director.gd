extends RefCounted
## Optional chapter secret: one discoverable cache per chapter, rewarding exploration.

const ROOT_NAME := "GeneratedExplorationSecret"
const CACHE_POSITIONS := [
	Vector3(-10.6, 0.17, -3.5),
	Vector3(8.2, 0.07, -7.0),
	Vector3(-13.0, 0.09, -8.0)
]
const GLOWS := [
	Color(0.18, 0.82, 0.96),
	Color(1.0, 0.25, 0.06),
	Color(0.42, 0.52, 1.0)
]


static func build_stage(parent: Node3D, stage_index: int) -> Node3D:
	clear_stage(parent)
	var safe_index := clampi(stage_index, 0, 2)
	var root := Node3D.new()
	root.name = ROOT_NAME
	root.position = CACHE_POSITIONS[safe_index]
	root.set_meta("collected", false)
	root.set_meta("chapter_index", safe_index)
	var glow: Color = GLOWS[safe_index]
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.075, 0.065, 0.055)
	dark.metallic = 0.72
	dark.roughness = 0.34
	var trim := StandardMaterial3D.new()
	trim.albedo_color = glow.darkened(0.32)
	trim.metallic = 0.84
	trim.roughness = 0.24
	trim.emission_enabled = true
	trim.emission = glow
	trim.emission_energy_multiplier = 0.65
	var gem_material := StandardMaterial3D.new()
	gem_material.albedo_color = glow.lightened(0.2)
	gem_material.metallic = 0.28
	gem_material.roughness = 0.18
	gem_material.emission_enabled = true
	gem_material.emission = glow
	gem_material.emission_energy_multiplier = 1.4
	_add_box(root, "CacheBase", Vector3(1.25, 0.62, 0.82), Vector3(0.0, 0.42, 0.0), dark)
	_add_box(root, "CacheLowerTrim", Vector3(1.31, 0.10, 0.88), Vector3(0.0, 0.18, 0.0), trim)
	_add_box(root, "CacheLid", Vector3(1.31, 0.26, 0.88), Vector3(0.0, 0.84, 0.0), dark, Vector3(-0.10, 0.0, 0.0))
	_add_box(root, "CacheLidTrim", Vector3(1.35, 0.08, 0.92), Vector3(0.0, 0.98, 0.0), trim)
	_add_box(root, "CacheLock", Vector3(0.20, 0.30, 0.12), Vector3(0.0, 0.61, 0.47), gem_material)
	var rune := MeshInstance3D.new()
	rune.name = "CacheRune"
	var rune_mesh := SphereMesh.new()
	rune_mesh.radius = 0.16
	rune_mesh.height = 0.38
	rune.mesh = rune_mesh
	rune.position = Vector3(0.0, 1.36, 0.0)
	rune.material_override = gem_material
	root.add_child(rune)
	var marker := Label3D.new()
	marker.name = "SecretMarker"
	marker.text = "SECRET"
	marker.font_size = 28
	marker.pixel_size = 0.009
	marker.position = Vector3(0.0, 1.72, 0.0)
	marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.modulate = glow.lightened(0.25)
	root.add_child(marker)
	parent.add_child(root)
	return root


static func clear_stage(parent: Node3D) -> void:
	var previous := parent.get_node_or_null(ROOT_NAME)
	if previous != null:
		parent.remove_child(previous)
		previous.free()


static func collect(cache: Node3D) -> bool:
	if not is_instance_valid(cache) or bool(cache.get_meta("collected", false)):
		return false
	cache.set_meta("collected", true)
	cache.visible = false
	return true


static func _add_box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.rotation = rotation
	instance.material_override = material
	parent.add_child(instance)
	return instance
