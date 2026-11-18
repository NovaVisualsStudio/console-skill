extends SceneTree

const CampaignLayout = preload("res://scripts/campaign_layout.gd")


func _initialize() -> void:
	call_deferred("_run_layout_smoke")


func _run_layout_smoke() -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	var expected_landmarks := [
		"SunkenAltarBase",
		"EmberCauseway",
		"ObsidianThroneDais"
	]
	var expected_routes := ["SunkenFlankStep_Left_1", "EmberFlankStep_Left_1", "ObsidianSideWalk_Left_1"]
	for chapter in range(3):
		CampaignLayout.build_stage(root, chapter, "high")
		var layout := root.get_node_or_null("GeneratedCampaignLayout")
		if layout == null:
			_fail(root, "Campaign layout root missing for chapter %d" % chapter)
			return
		if layout.get_child_count() < 12:
			_fail(root, "Campaign layout has too few structural pieces for chapter %d" % chapter)
			return
		if layout.get_node_or_null(expected_landmarks[chapter]) == null or layout.get_node_or_null(expected_routes[chapter]) == null:
			_fail(root, "Chapter %d landmark is missing" % chapter)
			return
		var required_routes := [
			"ExplorationTrail_Entry", "ExplorationTrail_Mid", "ExplorationTrail_Boss",
			"ExplorationBranch_Entry", "ExplorationBranch_Mid", "ExplorationBranch_Boss",
			"RouteGate_Entry_Lintel", "RouteGate_Mid_Lintel", "RouteGate_Boss_Lintel"
		]
		for route_name in required_routes:
			var route_body := layout.get_node_or_null(route_name) as StaticBody3D
			if route_body == null or not route_body.get_node_or_null("Collision") is CollisionShape3D:
				_fail(root, "Chapter %d route segment %s must be collision-backed" % [chapter, route_name])
				return
		var entry := layout.get_node("ExplorationTrail_Entry") as StaticBody3D
		var middle := layout.get_node("ExplorationTrail_Mid") as StaticBody3D
		var boss := layout.get_node("ExplorationTrail_Boss") as StaticBody3D
		if _z_overlap(entry, middle) < 0.5 or _z_overlap(middle, boss) < 0.5:
			_fail(root, "Chapter %d main trail sections must physically overlap without gaps" % chapter)
			return
		var colliders := 0
		for node in layout.get_children():
			if node is StaticBody3D and node.get_node_or_null("Collision") is CollisionShape3D:
				colliders += 1
		if colliders < 16:
			_fail(root, "Chapter %d has insufficient collision-backed geometry" % chapter)
			return
	if root.get_child_count() != 1:
		_fail(root, "Replacing a campaign layout left duplicate roots")
		return
	root.free()
	print("Campaign layout smoke test passed: 3 unique collision-backed chapter layouts")
	quit(0)


func _z_overlap(first: StaticBody3D, second: StaticBody3D) -> float:
	var first_shape := first.get_node("Collision").shape as BoxShape3D
	var second_shape := second.get_node("Collision").shape as BoxShape3D
	var first_min := first.position.z - first_shape.size.z * 0.5
	var first_max := first.position.z + first_shape.size.z * 0.5
	var second_min := second.position.z - second_shape.size.z * 0.5
	var second_max := second.position.z + second_shape.size.z * 0.5
	return minf(first_max, second_max) - maxf(first_min, second_min)


func _fail(root: Node3D, message: String) -> void:
	push_error(message)
	root.free()
	quit(1)
