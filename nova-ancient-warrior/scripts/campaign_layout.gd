extends RefCounted
## Chapter-specific, collision-backed arena layouts for the Android campaign.
## Keeps combat lanes clear while adding traversable landmarks and physical boundaries.

const ROOT_NAME := "GeneratedCampaignLayout"


static func build_stage(parent: Node3D, stage_index: int) -> void:
	var previous := parent.get_node_or_null(ROOT_NAME)
	if previous != null:
		parent.remove_child(previous)
		previous.free()
	var root := Node3D.new()
	root.name = ROOT_NAME
	parent.add_child(root)
	var safe_index := clampi(stage_index, 0, 2)
	_build_boundaries(root, safe_index)
	match safe_index:
		0:
			_build_sunken_layout(root)
		1:
			_build_ember_layout(root)
		_:
			_build_obsidian_layout(root)


static func _build_boundaries(root: Node3D, stage_index: int) -> void:
	var colors := [
		Color(0.24, 0.22, 0.20),
		Color(0.12, 0.075, 0.065),
		Color(0.085, 0.10, 0.17)
	]
	var material := _material(colors[stage_index], 0.18, 0.88)
	_solid_block(root, "NorthBoundary", Vector3(35.0, 4.0, 0.7), Vector3(0.0, 2.0, -17.5), material)
	_solid_block(root, "SouthBoundary", Vector3(35.0, 4.0, 0.7), Vector3(0.0, 2.0, 17.5), material)
	_solid_block(root, "WestBoundary", Vector3(0.7, 4.0, 35.0), Vector3(-17.5, 2.0, 0.0), material)
	_solid_block(root, "EastBoundary", Vector3(0.7, 4.0, 35.0), Vector3(17.5, 2.0, 0.0), material)


static func _build_sunken_layout(root: Node3D) -> void:
	var stone := _material(Color(0.34, 0.29, 0.23), 0.08, 0.92)
	var trim := _material(Color(0.68, 0.48, 0.25), 0.42, 0.55)
	# Broken processional walkway on the flanks; the central combat lane stays open.
	for side in [-1.0, 1.0]:
		_solid_block(root, "SunkenSidePlatform", Vector3(3.0, 0.28, 8.0), Vector3(side * 10.6, 0.14, -3.5), stone)
		for index in range(3):
			var z := -11.0 + float(index) * 7.0
			_solid_block(root, "SunkenPillarBase", Vector3(1.5, 0.55, 1.5), Vector3(side * 14.0, 0.275, z), trim)
	_solid_block(root, "SunkenAltarBase", Vector3(5.4, 0.34, 2.2), Vector3(0.0, 0.17, -13.6), stone)
	_solid_block(root, "SunkenAltarTop", Vector3(3.6, 0.24, 1.5), Vector3(0.0, 0.46, -13.6), trim)
	_add_arch(root, "SunkenEntryArch", Vector3(0.48, 5.4, 0.55), stone, trim)


static func _build_ember_layout(root: Node3D) -> void:
	var basalt := _material(Color(0.105, 0.075, 0.07), 0.24, 0.72)
	var ember := _material(Color(0.62, 0.13, 0.035), 0.12, 0.5, Color(0.95, 0.08, 0.015))
	# A broad safe central spine separates the lava channels already evaluated by StageHazardRules.
	_solid_block(root, "EmberCauseway", Vector3(3.3, 0.06, 25.0), Vector3(0.0, 0.03, -0.2), basalt)
	for side in [-1.0, 1.0]:
		for index in range(3):
			var z := -10.0 + float(index) * 9.0
			_solid_block(root, "EmberFlankBastion", Vector3(2.6, 0.42, 2.6), Vector3(side * 12.2, 0.21, z), basalt)
			_solid_block(root, "EmberBrazier", Vector3(0.72, 1.25, 0.72), Vector3(side * 12.2, 1.045, z), ember)
	_solid_block(root, "EmberBossDais", Vector3(6.0, 0.28, 2.4), Vector3(0.0, 0.14, -13.8), basalt)
	_add_arch(root, "EmberEntryArch", Vector3(0.48, 5.8, 0.55), basalt, ember)


static func _build_obsidian_layout(root: Node3D) -> void:
	var obsidian := _material(Color(0.075, 0.09, 0.16), 0.62, 0.28)
	var rune := _material(Color(0.20, 0.32, 0.78), 0.46, 0.32, Color(0.10, 0.20, 0.9))
	# Symmetric cover plinths and a throne dais frame the final boss without blocking approach.
	for side in [-1.0, 1.0]:
		_solid_block(root, "ObsidianCoverPlinth", Vector3(2.5, 0.62, 3.2), Vector3(side * 11.2, 0.31, 1.0), obsidian)
		for index in range(3):
			var z := -10.0 + float(index) * 8.0
			_solid_block(root, "ObsidianRunePillar", Vector3(1.0, 3.6, 1.0), Vector3(side * 14.0, 1.8, z), rune)
	_solid_block(root, "ObsidianThroneDais", Vector3(7.0, 0.42, 3.0), Vector3(0.0, 0.21, -13.8), obsidian)
	_solid_block(root, "ObsidianThroneStep", Vector3(4.8, 0.22, 1.2), Vector3(0.0, 0.53, -12.2), rune)
	_add_arch(root, "ObsidianEntryArch", Vector3(0.48, 6.2, 0.55), obsidian, rune)


static func _add_arch(root: Node3D, prefix: String, beam_size: Vector3, stone: Material, accent: Material) -> void:
	_solid_block(root, prefix + "Left", Vector3(0.7, beam_size.y, 0.8), Vector3(-4.1, beam_size.y * 0.5, 15.4), stone)
	_solid_block(root, prefix + "Right", Vector3(0.7, beam_size.y, 0.8), Vector3(4.1, beam_size.y * 0.5, 15.4), stone)
	_solid_block(root, prefix + "Lintel", Vector3(8.9, 0.65, 0.95), Vector3(0.0, beam_size.y + 0.1, 15.4), accent)


static func _solid_block(parent: Node3D, node_name: String, size: Vector3, position: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	var mesh := BoxMesh.new()
	mesh.size = size
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	visual.mesh = mesh
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body.add_child(visual)
	var collision := CollisionShape3D.new()
	collision.name = "Collision"
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body)
	return body


static func _material(color: Color, metallic: float, roughness: float, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
	return material
