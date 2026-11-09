extends RefCounted
## Optional three-rune environmental sequence puzzle, reset for each chapter.

const ROOT_NAME := "GeneratedExplorationPuzzle"
const PALETTES := [
	Color(0.18, 0.78, 0.98),
	Color(1.0, 0.27, 0.06),
	Color(0.43, 0.55, 1.0)
]


static func sequence_for_stage(stage_index: int) -> Array[int]:
	match clampi(stage_index, 0, 2):
		0:
			return [2, 1, 3]
		1:
			return [3, 1, 2]
		_:
			return [1, 3, 2]


static func rune_positions(stage_index: int) -> Array[Vector3]:
	match clampi(stage_index, 0, 2):
		0:
			return [Vector3(-7.5, 0.0, -13.0), Vector3(7.5, 0.0, -13.0), Vector3(0.0, 0.0, -9.5)]
		1:
			# The central rune rests on the raised safe causeway (top surface y = 0.06).
			return [Vector3(-12.0, 0.0, -12.0), Vector3(12.0, 0.0, -12.0), Vector3(0.0, 0.06, -5.5)]
		_:
			return [Vector3(-11.0, 0.0, -11.0), Vector3(11.0, 0.0, -11.0), Vector3(0.0, 0.0, 9.0)]


static func clear_stage(parent: Node3D) -> void:
	var previous := parent.get_node_or_null(ROOT_NAME)
	if previous != null:
		parent.remove_child(previous)
		previous.free()


static func build_stage(parent: Node3D, stage_index: int) -> Array[Node3D]:
	clear_stage(parent)
	var safe_index := clampi(stage_index, 0, 2)
	var root := Node3D.new()
	root.name = ROOT_NAME
	root.set_meta("chapter_index", safe_index)
	root.set_meta("solved", false)
	parent.add_child(root)

	var glow: Color = PALETTES[safe_index]
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color(0.075, 0.085, 0.105)
	stone.metallic = 0.46
	stone.roughness = 0.48
	var rune_material := StandardMaterial3D.new()
	rune_material.albedo_color = glow.lightened(0.18)
	rune_material.metallic = 0.38
	rune_material.roughness = 0.2
	rune_material.emission_enabled = true
	rune_material.emission = glow
	rune_material.emission_energy_multiplier = 0.55

	var result: Array[Node3D] = []
	var positions := rune_positions(safe_index)
	for index in range(positions.size()):
		var rune := StaticBody3D.new()
		rune.name = "ResonanceRune_%d" % (index + 1)
		rune.position = positions[index]
		rune.set_meta("rune_index", index + 1)
		rune.set_meta("activated", false)
		var local_rune_material := rune_material.duplicate() as StandardMaterial3D
		rune.set_meta("rune_material", local_rune_material)

		_add_cylinder(rune, "RunePedestal", 0.68, 0.24, Vector3(0.0, 0.12, 0.0), stone)
		_add_cylinder(rune, "RuneColumn", 0.22, 1.08, Vector3(0.0, 0.78, 0.0), stone)
		_add_collision_cylinder(rune, "PedestalCollision", 0.68, 0.24, Vector3(0.0, 0.12, 0.0))
		_add_collision_cylinder(rune, "ColumnCollision", 0.22, 1.08, Vector3(0.0, 0.78, 0.0))
		var crystal_mesh := SphereMesh.new()
		crystal_mesh.radius = 0.25
		crystal_mesh.height = 0.72
		var crystal := MeshInstance3D.new()
		crystal.name = "RuneCrystal"
		crystal.mesh = crystal_mesh
		crystal.position = Vector3(0.0, 1.48, 0.0)
		crystal.material_override = local_rune_material
		rune.add_child(crystal)
		var crystal_collision := CollisionShape3D.new()
		crystal_collision.name = "CrystalCollision"
		var crystal_shape := SphereShape3D.new()
		crystal_shape.radius = 0.25
		crystal_collision.shape = crystal_shape
		crystal_collision.position = crystal.position
		rune.add_child(crystal_collision)

		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = 0.38
		ring_mesh.outer_radius = 0.48
		var ring := MeshInstance3D.new()
		ring.name = "RuneRing"
		ring.mesh = ring_mesh
		ring.position.y = 0.28
		ring.material_override = local_rune_material
		rune.add_child(ring)

		var marker := Label3D.new()
		marker.name = "RuneNumber"
		marker.text = _roman(index + 1)
		marker.font_size = 34
		marker.pixel_size = 0.012
		marker.position = Vector3(0.0, 2.0, 0.0)
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.modulate = glow.lightened(0.28)
		rune.add_child(marker)
		root.add_child(rune)
		result.append(rune)

	var sequence_hint := Label3D.new()
	sequence_hint.name = "PuzzleSequenceHint"
	var sequence := sequence_for_stage(safe_index)
	var sequence_text := "%s  →  %s  →  %s" % [
		_roman(sequence[0]), _roman(sequence[1]), _roman(sequence[2])
	]
	sequence_hint.text = ("ترتيب الرموز القديمة   " + sequence_text) if TranslationServer.get_locale().begins_with("ar") else ("ANCIENT ORDER   " + sequence_text)
	sequence_hint.font_size = 32
	sequence_hint.pixel_size = 0.012
	sequence_hint.position = Vector3(0.0, 2.3, 1.2)
	sequence_hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sequence_hint.modulate = glow.lightened(0.3)
	root.add_child(sequence_hint)
	return result


static func evaluate_rune(rune_index: int, current_progress: int, sequence: Array[int]) -> Dictionary:
	if current_progress < 0 or current_progress >= sequence.size():
		return {"accepted": false, "progress": clampi(current_progress, 0, sequence.size()), "solved": true, "expected": 0}
	var expected := sequence[current_progress]
	if rune_index != expected:
		return {"accepted": false, "progress": current_progress, "solved": false, "expected": expected}
	var next_progress := current_progress + 1
	return {
		"accepted": true,
		"progress": next_progress,
		"solved": next_progress >= sequence.size(),
		"expected": 0 if next_progress >= sequence.size() else sequence[next_progress]
	}


static func set_expected_order(runes: Array[Node3D], expected_order: int) -> void:
	for rune in runes:
		if not is_instance_valid(rune) or bool(rune.get_meta("activated", false)):
			continue
		var material := rune.get_meta("rune_material") as StandardMaterial3D
		if material == null:
			continue
		var expected := int(rune.get_meta("rune_index", 0)) == expected_order
		material.emission_energy_multiplier = 2.35 if expected else 0.55
		material.albedo_color = Color(1.0, 1.0, 1.0) if expected else Color(0.55, 0.60, 0.67)


static func activate(rune: Node3D) -> bool:
	if not is_instance_valid(rune) or bool(rune.get_meta("activated", false)):
		return false
	rune.set_meta("activated", true)
	var material := rune.get_meta("rune_material") as StandardMaterial3D
	if material != null:
		material.emission_energy_multiplier = 0.12
		material.albedo_color = Color(0.22, 0.32, 0.38)
	var crystal := rune.get_node_or_null("RuneCrystal") as MeshInstance3D
	if crystal != null:
		crystal.scale = Vector3(0.72, 0.72, 0.72)
	return true


static func _roman(value: int) -> String:
	match value:
		1:
			return "I"
		2:
			return "II"
		_:
			return "III"


static func _add_collision_cylinder(parent: StaticBody3D, node_name: String, radius: float, height: float, position: Vector3) -> CollisionShape3D:
	var collision := CollisionShape3D.new()
	collision.name = node_name
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	collision.position = position
	parent.add_child(collision)
	return collision


static func _add_cylinder(parent: Node3D, node_name: String, radius: float, height: float, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.88
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	parent.add_child(instance)
	return instance
