extends RefCounted
## Chapter-specific collision-backed exploration routes and encounter districts.
## Keeps combat lanes readable while connecting the entrance, mid-route, flank objectives and boss chamber.

const PBRMaterials = preload("res://scripts/pbr_material_library.gd")
const ROOT_NAME := "GeneratedCampaignLayout"


static var _active_texture_size := PBRMaterials.TEXTURE_SIZE

static func build_stage(parent: Node3D, stage_index: int, quality: String = "mid") -> void:
	_active_texture_size = PBRMaterials.HIGH_TEXTURE_SIZE if quality.to_lower() == "high" else PBRMaterials.TEXTURE_SIZE
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
	_build_exploration_routes(root, safe_index)


static func _build_boundaries(root: Node3D, stage_index: int) -> void:
	var colors := [
		Color(0.24, 0.22, 0.20),
		Color(0.12, 0.075, 0.065),
		Color(0.085, 0.10, 0.17)
	]
	var material := _material(colors[stage_index], 0.18, 0.88)
	_solid_block(root, "NorthBoundary", Vector3(48.0, 4.0, 0.7), Vector3(0.0, 2.0, -36.0), material)
	_solid_block(root, "SouthBoundary", Vector3(48.0, 4.0, 0.7), Vector3(0.0, 2.0, 36.0), material)
	_solid_block(root, "WestBoundary", Vector3(0.7, 4.0, 72.0), Vector3(-24.0, 2.0, 0.0), material)
	_solid_block(root, "EastBoundary", Vector3(0.7, 4.0, 72.0), Vector3(24.0, 2.0, 0.0), material)


static func _build_sunken_layout(root: Node3D) -> void:
	var stone := _material(Color(0.34, 0.29, 0.23), 0.08, 0.92)
	var trim := _material(Color(0.68, 0.48, 0.25), 0.42, 0.55)
	# Broken processional walkway on the flanks; the central combat lane stays open.
	for side in [-1.0, 1.0]:
		var side_label := "Left" if side < 0.0 else "Right"
		# Three stepped stone rises lead onto a raised flank platform.
		_solid_block(root, "SunkenSidePlatform_%s" % side_label, Vector3(3.0, 0.56, 8.0), Vector3(side * 10.6, 0.28, -3.5), stone)
		for step in range(3):
			var step_x: float = side * (7.0 + float(step) * 0.8)
			var step_height: float = 0.18 + float(step) * 0.18
			var step_name := "SunkenFlankStep_%s_%d" % [side_label, step + 1]
			_solid_block(root, step_name, Vector3(1.0, step_height, 2.2), Vector3(step_x, step_height * 0.5, -3.5), trim)
		for index in range(3):
			var z := -11.0 + float(index) * 7.0
			var pillar_name := "SunkenPillarBase_%s_%d" % [side_label, index + 1]
			_solid_block(root, pillar_name, Vector3(1.5, 0.55, 1.5), Vector3(side * 14.0, 0.275, z), trim)
	_solid_block(root, "SunkenAltarBase", Vector3(5.4, 0.34, 2.2), Vector3(0.0, 0.17, -13.6), stone)
	_solid_block(root, "SunkenAltarTop", Vector3(3.6, 0.24, 1.5), Vector3(0.0, 0.46, -13.6), trim)
	for side in [-1.0, 1.0]:
		# Keep the opening combat spawn ring clear; cover remains on the outer flank.
		var side_label := "Left" if side < 0.0 else "Right"
		_solid_block(root, "SunkenCoverStone_%s" % side_label, Vector3(2.2, 0.82, 1.0), Vector3(side * 10.0, 0.41, 3.4), stone)
	_add_arch(root, "SunkenEntryArch", Vector3(0.48, 5.4, 0.55), stone, trim)


static func _build_ember_layout(root: Node3D) -> void:
	var basalt := _material(Color(0.105, 0.075, 0.07), 0.24, 0.72)
	var ember := _material(Color(0.62, 0.13, 0.035), 0.12, 0.5, Color(0.95, 0.08, 0.015))
	# A broad safe central spine separates the lava channels already evaluated by StageHazardRules.
	_solid_block(root, "EmberCauseway", Vector3(3.3, 0.06, 25.0), Vector3(0.0, 0.03, -0.2), basalt)
	for side in [-1.0, 1.0]:
		var side_label := "Left" if side < 0.0 else "Right"
		for index in range(3):
			var z := -10.0 + float(index) * 9.0
			_solid_block(root, "EmberFlankBastion_%s_%d" % [side_label, index + 1], Vector3(2.6, 0.42, 2.6), Vector3(side * 12.2, 0.21, z), basalt)
			_solid_block(root, "EmberBrazier_%s_%d" % [side_label, index + 1], Vector3(0.72, 1.25, 0.72), Vector3(side * 12.2, 1.045, z), ember)
	_solid_block(root, "EmberBossDais", Vector3(6.0, 0.28, 2.4), Vector3(0.0, 0.14, -13.8), basalt)
	# Safe stepping shelves create optional flank lines around the central causeway.
	for side in [-1.0, 1.0]:
		var side_label := "Left" if side < 0.0 else "Right"
		for index in range(3):
			var z := -7.0 + float(index) * 7.0
			# A lower approach stone and a taller landing make this an actual jump route.
			_solid_block(root, "EmberFlankApproach_%s_%d" % [side_label, index + 1], Vector3(1.6, 0.21, 2.0), Vector3(side * 6.6, 0.105, z), basalt)
			var flank_name := "EmberFlankStep_%s_%d" % [side_label, index + 1]
			_solid_block(root, flank_name, Vector3(2.0, 0.42, 2.0), Vector3(side * 8.2, 0.21, z), basalt)
		_solid_block(root, "EmberCoverBlock_%s" % side_label, Vector3(1.8, 1.0, 1.4), Vector3(side * 5.0, 0.5, 5.8), ember)
	_add_arch(root, "EmberEntryArch", Vector3(0.48, 5.8, 0.55), basalt, ember)


static func _build_obsidian_layout(root: Node3D) -> void:
	var obsidian := _material(Color(0.075, 0.09, 0.16), 0.62, 0.28)
	var rune := _material(Color(0.20, 0.32, 0.78), 0.46, 0.32, Color(0.10, 0.20, 0.9))
	# Symmetric cover plinths and a throne dais frame the final boss without blocking approach.
	for side in [-1.0, 1.0]:
		var side_label := "Left" if side < 0.0 else "Right"
		_solid_block(root, "ObsidianCoverPlinth_%s" % side_label, Vector3(2.5, 0.62, 3.2), Vector3(side * 11.2, 0.31, 1.0), obsidian)
		for index in range(3):
			var z := -10.0 + float(index) * 8.0
			_solid_block(root, "ObsidianRunePillar_%s_%d" % [side_label, index + 1], Vector3(1.0, 3.6, 1.0), Vector3(side * 14.0, 1.8, z), rune)
	_solid_block(root, "ObsidianThroneDais", Vector3(7.0, 0.42, 3.0), Vector3(0.0, 0.21, -13.8), obsidian)
	_solid_block(root, "ObsidianThroneStep", Vector3(4.8, 0.22, 1.2), Vector3(0.0, 0.53, -12.2), rune)
	for side in [-1.0, 1.0]:
		var side_label := "Left" if side < 0.0 else "Right"
		for index in range(3):
			var z: float = [-8.0, -4.0, 4.0][index]
			# A half-height approach step leads to the raised obsidian walkway.
			_solid_block(root, "ObsidianWalkApproach_%s_%d" % [side_label, index + 1], Vector3(2.2, 0.30, 2.2), Vector3(side * 10.8, 0.15, z), obsidian)
			var walk_name := "ObsidianSideWalk_%s_%d" % [side_label, index + 1]
			_solid_block(root, walk_name, Vector3(2.2, 0.60, 2.6), Vector3(side * 13.0, 0.30, z), obsidian)
		# Keep the opening combat spawn ring clear; guard stones sit beyond the approach lane.
		_solid_block(root, "ObsidianGuardStone_%s" % side_label, Vector3(2.0, 0.9, 1.1), Vector3(side * 10.0, 0.45, 3.6), obsidian)
	_add_arch(root, "ObsidianEntryArch", Vector3(0.48, 6.2, 0.55), obsidian, rune)


static func _build_exploration_routes(root: Node3D, stage_index: int) -> void:
	var path_colors := [
		Color(0.40, 0.34, 0.27),
		Color(0.18, 0.11, 0.085),
		Color(0.12, 0.15, 0.24)
	]
	var accent_colors := [
		Color(0.78, 0.55, 0.28),
		Color(0.95, 0.20, 0.055),
		Color(0.30, 0.48, 0.95)
	]
	var path_material := _material(path_colors[stage_index], 0.18, 0.82)
	var accent_material := _material(accent_colors[stage_index], 0.48, 0.42, accent_colors[stage_index] * 0.35)
	# Overlapping collision-backed trail sections connect the entrance, mid district and boss approach.
	_solid_block(root, "ExplorationTrail_Entry", Vector3(8.0, 0.06, 24.0), Vector3(0.0, -0.03, 24.0), path_material)
	_solid_block(root, "ExplorationTrail_Mid", Vector3(8.0, 0.06, 26.0), Vector3(0.0, -0.03, 1.0), path_material)
	_solid_block(root, "ExplorationTrail_Boss", Vector3(10.0, 0.06, 26.0), Vector3(0.0, -0.03, -23.0), path_material)
	# Broad cross-routes connect the main trail to both flank objectives in every district.
	_solid_block(root, "ExplorationBranch_Entry", Vector3(42.0, 0.06, 4.0), Vector3(0.0, -0.03, 15.0), path_material)
	_solid_block(root, "ExplorationBranch_Mid", Vector3(42.0, 0.06, 4.0), Vector3(0.0, -0.03, -1.0), path_material)
	_solid_block(root, "ExplorationBranch_Boss", Vector3(42.0, 0.06, 4.0), Vector3(0.0, -0.03, -17.0), path_material)
	_add_route_gate(root, "RouteGate_Entry", 13.0, path_material, accent_material)
	_add_route_gate(root, "RouteGate_Mid", -3.0, path_material, accent_material)
	_add_route_gate(root, "RouteGate_Boss", -19.0, path_material, accent_material)
	match stage_index:
		0:
			_solid_block(root, "SunkenRouteObelisk", Vector3(1.0, 3.2, 1.0), Vector3(-21.0, 1.6, 15.0), accent_material)
			_solid_block(root, "SunkenRouteMarker", Vector3(1.0, 2.4, 1.0), Vector3(21.0, 1.2, -17.0), accent_material)
		1:
			_solid_block(root, "EmberRouteObelisk", Vector3(1.2, 3.6, 1.2), Vector3(21.0, 1.8, 15.0), accent_material)
			_solid_block(root, "EmberRouteMarker", Vector3(1.0, 2.8, 1.0), Vector3(-21.0, 1.4, -17.0), accent_material)
		_:
			_solid_block(root, "ObsidianRouteObelisk", Vector3(1.0, 4.0, 1.0), Vector3(-21.0, 2.0, 15.0), accent_material)
			_solid_block(root, "ObsidianRouteMarker", Vector3(1.0, 3.2, 1.0), Vector3(21.0, 1.6, -17.0), accent_material)


static func _add_route_gate(root: Node3D, prefix: String, z_position: float, stone: Material, accent: Material) -> void:
	_solid_block(root, prefix + "_Left", Vector3(0.65, 4.6, 0.8), Vector3(-8.5, 2.3, z_position), stone)
	_solid_block(root, prefix + "_Right", Vector3(0.65, 4.6, 0.8), Vector3(8.5, 2.3, z_position), stone)
	_solid_block(root, prefix + "_Lintel", Vector3(18.0, 0.48, 1.0), Vector3(0.0, 4.72, z_position), accent)


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
	var seed_value := int(absf(color.r * 997.0 + color.g * 467.0 + color.b * 193.0 + metallic * 61.0)) + 1
	return PBRMaterials.create_surface_material(color, metallic, roughness, seed_value, 2.4, emission, _active_texture_size)
