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


func _fail(root: Node3D, message: String) -> void:
	push_error(message)
	root.free()
	quit(1)
