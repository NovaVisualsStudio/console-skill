extends RefCounted
## Lightweight chapter exploration objective: recover three seal fragments before each boss.

const ROOT_NAME := "GeneratedMissionRelics"

static func relic_sequence(stage_index: int) -> Array[int]:
	match clampi(stage_index, 0, 2):
		0:
			return [2, 1, 3]
		1:
			return [3, 1, 2]
		_:
			return [1, 3, 2]


static func relic_positions(stage_index: int) -> Array[Vector3]:
	match clampi(stage_index, 0, 2):
		0:
			return [Vector3(-11.6, 0.0, -8.8), Vector3(11.6, 0.0, -8.8), Vector3(0.0, 0.0, 12.0)]
		1:
			return [Vector3(-9.2, 0.0, -10.5), Vector3(9.2, 0.0, -10.5), Vector3(0.0, 0.0, 11.8)]
		_:
			return [Vector3(-9.2, 0.0, 11.5), Vector3(9.2, 0.0, 11.5), Vector3(0.0, 0.0, 14.0)]


static func clear_stage(parent: Node3D) -> void:
	var previous := parent.get_node_or_null(ROOT_NAME)
	if previous != null:
		parent.remove_child(previous)
		previous.free()


static func build_stage(parent: Node3D, stage_index: int) -> Array[Node3D]:
	clear_stage(parent)
	var root := Node3D.new()
	root.name = ROOT_NAME
	parent.add_child(root)

	var palettes: Array[Color] = [
		Color(0.22, 0.82, 0.95),
		Color(1.0, 0.24, 0.07),
		Color(0.38, 0.48, 1.0)
	]
	var glow: Color = palettes[clampi(stage_index, 0, 2)]
	var material := StandardMaterial3D.new()
	material.albedo_color = glow.lightened(0.18)
	material.metallic = 0.52
	material.roughness = 0.24
	material.emission_enabled = true
	material.emission = glow
	material.emission_energy_multiplier = 1.65

	var result: Array[Node3D] = []
	var positions := relic_positions(stage_index)
	for index in range(positions.size()):
		var relic := Node3D.new()
		relic.name = "SealFragment_%d" % (index + 1)
		relic.position = positions[index]
		relic.set_meta("collected", false)
		relic.set_meta("base_y", positions[index].y)
		relic.set_meta("phase", float(index) * 2.1)
		relic.set_meta("sequence_order", index + 1)
		var relic_material := material.duplicate() as StandardMaterial3D
		relic.set_meta("rune_material", relic_material)
		var pedestal := MeshInstance3D.new()
		pedestal.name = "SealPedestal"
		var pedestal_mesh := CylinderMesh.new()
		pedestal_mesh.top_radius = 0.48
		pedestal_mesh.bottom_radius = 0.58
		pedestal_mesh.height = 0.16
		pedestal.mesh = pedestal_mesh
		pedestal.position.y = 0.08
		pedestal.material_override = relic_material
		relic.add_child(pedestal)
		var beacon := MeshInstance3D.new()
		beacon.name = "SealBeacon"
		var beacon_mesh := CylinderMesh.new()
		beacon_mesh.top_radius = 0.035
		beacon_mesh.bottom_radius = 0.09
		beacon_mesh.height = 2.2
		beacon.mesh = beacon_mesh
		beacon.position.y = 1.25
		beacon.material_override = relic_material
		relic.add_child(beacon)
		var crystal := MeshInstance3D.new()
		var crystal_mesh := SphereMesh.new()
		crystal_mesh.radius = 0.34
		crystal_mesh.height = 0.88
		crystal.mesh = crystal_mesh
		crystal.scale = Vector3(0.72, 1.0, 0.72)
		crystal.material_override = relic_material
		relic.add_child(crystal)
		var number_marker := Label3D.new()
		number_marker.text = str(index + 1)
		number_marker.font_size = 40
		number_marker.pixel_size = 0.012
		number_marker.position = Vector3(0.0, 0.72, 0.0)
		number_marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		number_marker.modulate = glow.lightened(0.35)
		relic.add_child(number_marker)
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.34
		ring_mesh.outer_radius = 0.43
		ring.mesh = ring_mesh
		ring.rotation.x = deg_to_rad(90.0)
		ring.material_override = relic_material
		relic.add_child(ring)
		root.add_child(relic)
		result.append(relic)
	set_expected_order(result, relic_sequence(stage_index)[0])
	return result


static func set_expected_order(relics: Array[Node3D], expected_order: int) -> void:
	for relic in relics:
		if not is_instance_valid(relic) or bool(relic.get_meta("collected", false)):
			continue
		var rune_material := relic.get_meta("rune_material") as StandardMaterial3D
		if rune_material == null:
			continue
		var is_expected := int(relic.get_meta("sequence_order", 0)) == expected_order
		rune_material.emission_energy_multiplier = 2.2 if is_expected else 0.55
		rune_material.albedo_color = Color(1.0, 1.0, 1.0) if is_expected else Color(0.62, 0.62, 0.62)


static func collect(relic: Node3D) -> bool:
	if not is_instance_valid(relic) or bool(relic.get_meta("collected", false)):
		return false
	relic.set_meta("collected", true)
	relic.visible = false
	return true
