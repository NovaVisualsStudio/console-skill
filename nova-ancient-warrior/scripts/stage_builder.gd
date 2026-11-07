extends RefCounted
## Lightweight, procedural campaign dressing. Geometry is decorative and avoids extra physics bodies.

static func build_stage(parent: Node3D, stage_index: int) -> void:
	var previous := parent.get_node_or_null("GeneratedStageDressing")
	if previous != null:
		parent.remove_child(previous)
		previous.free()
	var root := Node3D.new()
	root.name = "GeneratedStageDressing"
	parent.add_child(root)
	match clampi(stage_index, 0, 2):
		0:
			_build_sunken_ruins(root)
		1:
			_build_ember_causeway(root)
		_:
			_build_obsidian_throne(root)


static func _build_sunken_ruins(root: Node3D) -> void:
	var stone := _mat(Color(0.32, 0.28, 0.23), 0.04, 0.94)
	var trim := _mat(Color(0.61, 0.43, 0.25), 0.28, 0.72)
	for side in [-1.0, 1.0]:
		for i in range(4):
			var z := -10.0 + float(i) * 6.2
			_box(root, "RuinColumn", Vector3(0.9, 5.8, 0.9), Vector3(side * 15.2, 2.9, z), stone)
			_box(root, "RuinCapital", Vector3(1.45, 0.34, 1.45), Vector3(side * 15.2, 5.85, z), trim)
	for i in range(5):
		var x := -8.0 + float(i) * 4.0
		_box(root, "BrokenLintel", Vector3(0.8, 0.65, 1.1), Vector3(x, 0.35, -15.4), stone, Vector3(0.0, 0.0, randf_range(-0.18, 0.18)))
	_box(root, "DistantGate", Vector3(8.5, 0.65, 0.5), Vector3(0.0, 5.5, -15.7), trim)
	var trap_steel := _mat(Color(0.68, 0.48, 0.26), 0.62, 0.3, Color(0.28, 0.12, 0.025))
	_box(root, "SpikeTrapPlate", Vector3(12.2, 0.08, 1.0), Vector3(0.0, 0.04, 8.4), stone)
	for i in range(9):
		var x := -5.0 + float(i) * 1.25
		_spike(root, "RuinSpike", 0.22, 0.66, Vector3(x, 0.39, 8.4), trap_steel)


static func _build_ember_causeway(root: Node3D) -> void:
	var basalt := _mat(Color(0.105, 0.075, 0.075), 0.18, 0.78)
	var hot := _mat(Color(0.95, 0.14, 0.025), 0.08, 0.42, Color(1.0, 0.08, 0.015))
	for i in range(7):
		var x := -12.0 + float(i) * 4.0
		_box(root, "BasaltSpire", Vector3(0.9, randf_range(3.0, 6.5), 1.1), Vector3(x, 1.8, -15.1), basalt, Vector3(0.0, 0.0, randf_range(-0.10, 0.10)))
		if i != 3:
			_box(root, "LavaChannel", Vector3(0.22, 0.025, 21.0), Vector3(x * 0.56, 0.02, 0.0), hot)
	for side in [-1.0, 1.0]:
		for i in range(3):
			_cylinder(root, "ObsidianPillar", 0.52, 5.0, Vector3(side * 14.8, 2.5, -8.0 + float(i) * 8.0), basalt)


static func _build_obsidian_throne(root: Node3D) -> void:
	var obsidian := _mat(Color(0.075, 0.085, 0.15), 0.55, 0.26)
	var rune := _mat(Color(0.20, 0.34, 0.80), 0.45, 0.3, Color(0.12, 0.24, 0.95))
	rune.emission_energy_multiplier = 0.38
	for side in [-1.0, 1.0]:
		for i in range(4):
			var z := -12.0 + float(i) * 7.0
			_cylinder(root, "ThroneColumn", 0.58, 7.2, Vector3(side * 15.0, 3.6, z), obsidian)
			_box(root, "RunicBand", Vector3(1.35, 0.12, 1.35), Vector3(side * 15.0, 5.1, z), rune)
	_box(root, "ThroneBase", Vector3(5.8, 1.0, 2.8), Vector3(0.0, 0.5, -13.8), obsidian)
	_box(root, "ThroneSeat", Vector3(4.0, 2.8, 1.0), Vector3(0.0, 2.2, -14.5), obsidian)
	_box(root, "ThroneBack", Vector3(5.0, 4.8, 0.65), Vector3(0.0, 5.8, -15.0), obsidian)
	for i in range(5):
		var x := -4.0 + float(i) * 2.0
		if i != 2:
			_box(root, "RunicFloorLine", Vector3(0.08, 0.02, 16.0), Vector3(x, 0.025, -1.5), rune)

static func set_rune_intensity(parent: Node3D, intensity: float) -> void:
	var root := parent.get_node_or_null("GeneratedStageDressing")
	if root == null:
		return
	var material := root.get_node_or_null("RunicFloorLine") as MeshInstance3D
	if material == null:
		return
	var rune := material.material_override as StandardMaterial3D
	if rune != null:
		rune.emission_energy_multiplier = lerpf(0.38, 2.6, clampf(intensity, 0.0, 1.0))


static func _box(parent: Node3D, node_name: String, size: Vector3, position: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
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


static func _spike(parent: Node3D, node_name: String, radius: float, height: float, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 6
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position
	instance.material_override = material
	parent.add_child(instance)
	return instance


static func _cylinder(parent: Node3D, node_name: String, radius: float, height: float, position: Vector3, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.86
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


static func _mat(color: Color, metallic: float, roughness: float, emission: Color = Color.BLACK) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
	return material
