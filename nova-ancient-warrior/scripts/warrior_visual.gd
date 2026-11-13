extends Node3D
class_name WarriorVisual

var is_enemy := false
var is_boss := false
var boss_kind := "ash_titan"
var enemy_variant := 0
var blade_upgrade := 0
var _phase := 0.0
var _torso_material: StandardMaterial3D
var _armor_material: StandardMaterial3D
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _sword_pivot: Node3D
var _attack_tween: Tween
var _dodge_tween: Tween
var _base_torso_color := Color(0.46, 0.18, 0.11)
var _base_armor_color := Color(0.55, 0.31, 0.13)


func _ready() -> void:
	_build_character()


func set_locomotion(speed_ratio: float, delta: float) -> void:
	var amount := clampf(speed_ratio, 0.0, 1.0)
	_phase += delta * lerpf(2.0, 8.5, amount)
	var swing := sin(_phase) * amount * 0.62
	if is_instance_valid(_left_leg):
		_left_leg.rotation.x = swing
		_right_leg.rotation.x = -swing
		var is_attacking := _attack_tween != null and _attack_tween.is_running()
		if not is_attacking:
			_left_arm.rotation.x = -swing * 0.72
			_right_arm.rotation.x = swing * 0.72


func play_attack(combo_step: int) -> void:
	if not is_instance_valid(_right_arm) or not is_instance_valid(_sword_pivot):
		return
	if _attack_tween != null and _attack_tween.is_running():
		_attack_tween.kill()
	var angles := [0.78, 1.18, 1.62]
	var angle: float = angles[clampi(combo_step, 0, 2)]
	_attack_tween = create_tween()
	_attack_tween.tween_property(_right_arm, "rotation:z", -angle, 0.09)
	_attack_tween.tween_property(_sword_pivot, "rotation:z", 0.95, 0.08)
	_attack_tween.parallel().tween_property(_right_arm, "rotation:x", -0.25, 0.08)
	_attack_tween.tween_property(_right_arm, "rotation:z", 0.0, 0.17)
	_attack_tween.parallel().tween_property(_sword_pivot, "rotation:z", -0.55, 0.17)
	_attack_tween.parallel().tween_property(_right_arm, "rotation:x", 0.0, 0.17)


func play_dodge() -> void:
	if _dodge_tween != null and _dodge_tween.is_running():
		_dodge_tween.kill()
	_dodge_tween = create_tween()
	_dodge_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_dodge_tween.tween_property(self, "rotation:z", -0.24, 0.08)
	_dodge_tween.parallel().tween_property(self, "position:y", -0.12, 0.08)
	_dodge_tween.tween_property(self, "rotation:z", 0.0, 0.18)
	_dodge_tween.parallel().tween_property(self, "position:y", 0.0, 0.18)


func telegraph(enabled: bool) -> void:
	if not is_instance_valid(_torso_material):
		return
	_torso_material.albedo_color = Color(0.78, 0.22, 0.10) if enabled else _base_torso_color


func play_heavy_attack() -> void:
	if not is_instance_valid(_right_arm) or not is_instance_valid(_sword_pivot):
		return
	if _attack_tween != null and _attack_tween.is_running():
		_attack_tween.kill()
	_attack_tween = create_tween()
	_attack_tween.tween_property(_right_arm, "rotation:z", -1.92, 0.22)
	_attack_tween.parallel().tween_property(_right_arm, "rotation:x", -0.55, 0.18)
	_attack_tween.tween_property(_sword_pivot, "rotation:z", 1.32, 0.12)
	_attack_tween.tween_property(_right_arm, "rotation:z", 0.0, 0.28)
	_attack_tween.parallel().tween_property(_right_arm, "rotation:x", 0.0, 0.28)
	_attack_tween.parallel().tween_property(_sword_pivot, "rotation:z", -0.55, 0.28)


func set_blocking(enabled: bool) -> void:
	if not is_instance_valid(_left_arm):
		return
	var target_x := -0.82 if enabled else 0.0
	var target_z := 0.32 if enabled else 0.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_left_arm, "rotation:x", target_x, 0.10)
	tween.parallel().tween_property(_left_arm, "rotation:z", target_z, 0.10)


func play_parry() -> void:
	if is_instance_valid(_armor_material):
		_armor_material.albedo_color = Color(1.0, 0.92, 0.55)
		var tween := create_tween()
		tween.tween_property(_armor_material, "albedo_color", _base_armor_color, 0.32)


func phase_change(phase: int) -> void:
	if not is_boss or not is_instance_valid(_armor_material):
		return
	var flash := Color(1.0, 0.78, 0.40) if phase == 2 else Color(0.70, 0.82, 1.0)
	_armor_material.albedo_color = flash
	var tween := create_tween()
	tween.tween_property(_armor_material, "albedo_color", _base_armor_color, 0.52)


func hit_react() -> void:
	if not is_instance_valid(_armor_material):
		return
	_armor_material.albedo_color = Color(1.0, 0.82, 0.48)
	var tween := create_tween()
	tween.tween_property(_armor_material, "albedo_color", _base_armor_color, 0.16)


func _build_character() -> void:
	var skin := _mat(Color(0.57, 0.34, 0.23) if not is_enemy else Color(0.22, 0.29, 0.30), 0.0, 0.9)
	if is_boss:
		match boss_kind:
			"ember_warlord":
				_base_torso_color = Color(0.24, 0.055, 0.025)
				_base_armor_color = Color(0.86, 0.22, 0.055)
			"obsidian_sovereign":
				_base_torso_color = Color(0.055, 0.07, 0.16)
				_base_armor_color = Color(0.34, 0.49, 0.90)
			_:
				_base_torso_color = Color(0.25, 0.045, 0.04)
				_base_armor_color = Color(0.54, 0.13, 0.07)
	elif is_enemy:
		if enemy_variant == 1:
			_base_torso_color = Color(0.16, 0.10, 0.17)
			_base_armor_color = Color(0.42, 0.25, 0.48)
		elif enemy_variant == 2:
			_base_torso_color = Color(0.12, 0.17, 0.18)
			_base_armor_color = Color(0.30, 0.43, 0.48)
		else:
			_base_torso_color = Color(0.12, 0.20, 0.22)
			_base_armor_color = Color(0.22, 0.34, 0.37)
	else:
		_base_torso_color = Color(0.42, 0.13, 0.09)
		_base_armor_color = Color(0.62, 0.37, 0.15)
	_torso_material = _mat(_base_torso_color, 0.0, 0.72)
	_armor_material = _mat(_base_armor_color, 0.52, 0.34)
	var dark := _mat(Color(0.12, 0.10, 0.10) if not is_enemy else (Color(0.055, 0.035, 0.035) if is_boss else Color(0.07, 0.10, 0.12)), 0.12, 0.82)
	var steel := _mat(Color(0.72, 0.78, 0.82), 0.72, 0.24)
	var gold := _mat(Color(0.82, 0.58, 0.22), 0.72, 0.28)
	var cloth := _mat(Color(0.22, 0.06, 0.045) if not is_enemy else Color(0.07, 0.13, 0.16), 0.0, 0.94)

	_add_capsule(self, "Torso", 0.34, 0.86, Vector3(0.0, 1.22, 0.0), _torso_material, 12, 6)
	_add_box(self, "Breastplate", Vector3(0.61, 0.52, 0.16), Vector3(0.0, 1.34, -0.245), _armor_material)
	_add_box(self, "WaistGuard", Vector3(0.55, 0.22, 0.40), Vector3(0.0, 0.88, 0.0), dark)
	_add_box(self, "FrontTasset", Vector3(0.44, 0.34, 0.09), Vector3(0.0, 0.72, -0.24), cloth)
	_add_box(self, "Belt", Vector3(0.60, 0.075, 0.43), Vector3(0.0, 0.96, 0.0), gold)
	_add_box(self, "BeltBuckle", Vector3(0.13, 0.13, 0.045), Vector3(0.0, 0.96, -0.25), steel)

	var head := Node3D.new()
	head.name = "HeadPivot"
	head.position.y = 1.78
	add_child(head)
	_add_sphere(head, "Face", 0.225, 0.42, Vector3(0.0, 0.02, 0.0), skin, 10, 6)
	_add_sphere(head, "Helmet", 0.275, 0.34, Vector3(0.0, 0.15, 0.015), gold if not is_enemy else dark, 10, 5)
	_add_box(head, "NoseGuard", Vector3(0.075, 0.25, 0.09), Vector3(0.0, -0.015, -0.215), steel)
	_add_box(head, "HelmetRidge", Vector3(0.08, 0.23, 0.12), Vector3(0.0, 0.34, 0.0), gold)
	_add_capsule(head, "Plume", 0.055, 0.35, Vector3(0.0, 0.47, 0.03), cloth, 8, 4)

	_left_arm = _build_arm("LeftArm", -1.0, skin, _armor_material, dark, steel, gold)
	_right_arm = _build_arm("RightArm", 1.0, skin, _armor_material, dark, steel, gold)
	_left_leg = _build_leg("LeftLeg", -1.0, dark, cloth, steel, gold)
	_right_leg = _build_leg("RightLeg", 1.0, dark, cloth, steel, gold)

	_add_sphere(self, "LeftShoulder", 0.22, 0.28, Vector3(-0.46, 1.48, 0.0), _armor_material, 8, 5)
	_add_sphere(self, "RightShoulder", 0.22, 0.28, Vector3(0.46, 1.48, 0.0), _armor_material, 8, 5)
	_add_box(self, "ChestEmblem", Vector3(0.11, 0.23, 0.045), Vector3(0.0, 1.37, -0.34), gold)
	if not is_enemy:
		_add_box(self, "WarriorMantle", Vector3(0.56, 0.78, 0.075), Vector3(0.0, 1.02, 0.245), cloth)
		if blade_upgrade > 0 and is_instance_valid(_sword_pivot):
			var blade := _sword_pivot.get_node_or_null("Blade") as MeshInstance3D
			if blade != null:
				var enchanted_steel := _mat(Color(0.72, 0.86, 0.98), 0.72, 0.2)
				enchanted_steel.emission_enabled = true
				enchanted_steel.emission = Color(0.08, 0.24, 0.55) * float(blade_upgrade)
				blade.material_override = enchanted_steel
	if is_boss:
		var crest_material := gold if boss_kind == "ash_titan" else (_mat(Color(0.95, 0.19, 0.04), 0.55, 0.25) if boss_kind == "ember_warlord" else steel)
		_add_box(self, "BossCrown", Vector3(0.48, 0.20, 0.18), Vector3(0.0, 2.18, 0.0), crest_material)
		_add_box(self, "BossLeftSpur", Vector3(0.12, 0.62, 0.16), Vector3(-0.40, 1.55, 0.0), crest_material, Vector3(0.0, 0.0, -0.35))
		_add_box(self, "BossRightSpur", Vector3(0.12, 0.62, 0.16), Vector3(0.40, 1.55, 0.0), crest_material, Vector3(0.0, 0.0, 0.35))

		match boss_kind:
			"ash_titan":
				_add_box(self, "AshTitanMantle", Vector3(1.05, 0.46, 0.52), Vector3(0.0, 1.56, 0.10), dark)
				_add_sphere(self, "AshTitanShoulder", 0.36, 0.42, Vector3(-0.62, 1.55, 0.02), _mat(Color(0.31, 0.20, 0.17), 0.28, 0.86), 8, 5)
				_add_capsule(self, "AshTitanMaulHandle", 0.095, 1.25, Vector3(0.98, 0.68, 0.04), dark, 8, 4)
				_add_box(self, "AshTitanMaulHead", Vector3(0.55, 0.48, 0.44), Vector3(0.98, 1.38, 0.04), steel)
			"ember_warlord":
				var ember_horn_left := _add_capsule(self, "EmberHornLeft", 0.105, 0.68, Vector3(-0.32, 2.26, 0.0), crest_material, 8, 4)
				ember_horn_left.rotation.z = -0.48
				var ember_horn_right := _add_capsule(self, "EmberHornRight", 0.105, 0.68, Vector3(0.32, 2.26, 0.0), crest_material, 8, 4)
				ember_horn_right.rotation.z = 0.48
				var ember_core := _mat(Color(1.0, 0.20, 0.035), 0.18, 0.28)
				ember_core.emission_enabled = true
				ember_core.emission = Color(1.0, 0.08, 0.01)
				_add_sphere(self, "EmberFlameCore", 0.19, 0.24, Vector3(0.0, 1.44, -0.36), ember_core, 10, 6)
			"obsidian_sovereign":
				var obsidian_crystal := _mat(Color(0.30, 0.46, 0.95), 0.72, 0.20)
				obsidian_crystal.emission_enabled = true
				obsidian_crystal.emission = Color(0.08, 0.20, 0.82)
				_add_box(self, "ObsidianCrownSpire", Vector3(0.12, 0.78, 0.14), Vector3(0.0, 2.58, 0.0), obsidian_crystal, Vector3(0.0, 0.0, 0.12))
				_add_sphere(self, "ObsidianRuneOrb", 0.22, 0.28, Vector3(0.72, 1.98, 0.0), obsidian_crystal, 10, 6)
				_add_box(self, "ObsidianRoyalMantle", Vector3(0.88, 0.76, 0.10), Vector3(0.0, 1.15, 0.30), dark)

	if not is_enemy:
		var shield := Node3D.new()
		shield.name = "Shield"
		shield.position = Vector3(-0.63, 0.99, -0.06)
		add_child(shield)
		var shield_mesh := CylinderMesh.new()
		shield_mesh.top_radius = 0.30
		shield_mesh.bottom_radius = 0.30
		shield_mesh.height = 0.11
		var shield_face := MeshInstance3D.new()
		shield_face.mesh = shield_mesh
		shield_face.rotation.x = PI * 0.5
		shield_face.material_override = dark
		shield.add_child(shield_face)
		var shield_boss := MeshInstance3D.new()
		var boss_mesh := SphereMesh.new()
		boss_mesh.radius = 0.10
		boss_mesh.height = 0.16
		shield_boss.mesh = boss_mesh
		shield_boss.position.z = -0.075
		shield_boss.material_override = gold
		shield.add_child(shield_boss)


func _build_arm(part_name: String, side: float, skin: Material, armor: Material, dark: Material, steel: Material, gold: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = part_name
	pivot.position = Vector3(side * 0.43, 1.48, 0.0)
	add_child(pivot)
	_add_capsule(pivot, "UpperArm", 0.135, 0.48, Vector3(0.0, -0.27, 0.0), skin)
	_add_sphere(pivot, "Elbow", 0.145, 0.19, Vector3(0.0, -0.52, 0.0), dark)
	_add_capsule(pivot, "Forearm", 0.12, 0.43, Vector3(0.0, -0.76, 0.0), skin)
	_add_capsule(pivot, "Bracer", 0.145, 0.32, Vector3(0.0, -0.75, -0.015), steel)
	_add_sphere(pivot, "Hand", 0.125, 0.16, Vector3(0.0, -1.0, -0.015), skin)
	if side > 0.0:
		_sword_pivot = Node3D.new()
		_sword_pivot.name = "SwordPivot"
		_sword_pivot.position = Vector3(0.02, -1.03, -0.04)
		_sword_pivot.rotation.z = -0.55
		pivot.add_child(_sword_pivot)
		_add_box(_sword_pivot, "Blade", Vector3(0.105, 0.86, 0.045), Vector3(0.0, -0.47, -0.01), steel)
		_add_box(_sword_pivot, "CrossGuard", Vector3(0.34, 0.07, 0.09), Vector3(0.0, -0.08, -0.01), gold)
		_add_box(_sword_pivot, "Grip", Vector3(0.075, 0.22, 0.075), Vector3(0.0, 0.07, 0.0), dark)
		_add_sphere(_sword_pivot, "Pommel", 0.065, 0.09, Vector3(0.0, 0.19, 0.0), gold)
	return pivot


func _build_leg(part_name: String, side: float, dark: Material, cloth: Material, steel: Material, gold: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = part_name
	pivot.position = Vector3(side * 0.19, 0.82, 0.0)
	add_child(pivot)
	_add_capsule(pivot, "Thigh", 0.16, 0.48, Vector3(0.0, -0.24, 0.0), cloth)
	_add_sphere(pivot, "Knee", 0.15, 0.18, Vector3(0.0, -0.48, -0.015), gold, 8, 5)
	_add_capsule(pivot, "Shin", 0.13, 0.42, Vector3(0.0, -0.72, 0.0), dark)
	_add_box(pivot, "Greave", Vector3(0.25, 0.34, 0.08), Vector3(0.0, -0.72, -0.13), steel)
	_add_box(pivot, "Boot", Vector3(0.28, 0.17, 0.40), Vector3(0.0, -0.98, -0.10), dark)
	return pivot


func _add_box(parent: Node3D, part_name: String, size: Vector3, offset: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = offset
	instance.rotation = rotation
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _add_capsule(parent: Node3D, part_name: String, radius: float, height: float, offset: Vector3, material: Material, radial: int = 9, rings: int = 4) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = radial
	mesh.rings = rings
	return _add_mesh(parent, part_name, mesh, offset, material)


func _add_sphere(parent: Node3D, part_name: String, radius: float, height: float, offset: Vector3, material: Material, radial: int = 8, rings: int = 5) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = radial
	mesh.rings = rings
	return _add_mesh(parent, part_name, mesh, offset, material)


func _add_mesh(parent: Node3D, part_name: String, mesh: Mesh, offset: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = part_name
	instance.mesh = mesh
	instance.position = offset
	instance.material_override = material
	parent.add_child(instance)
	return instance


func _mat(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return material
