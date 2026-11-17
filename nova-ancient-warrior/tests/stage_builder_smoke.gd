extends SceneTree

const StageBuilder = preload("res://scripts/stage_builder.gd")


func _initialize() -> void:
	call_deferred("_run_stage_smoke")


func _run_stage_smoke() -> void:
	var root := Node3D.new()
	root.name = "StageBuilderSmoke"
	get_root().add_child(root)
	StageBuilder.build_stage(root, 0, "high")
	var dressing := root.get_node_or_null("GeneratedStageDressing")
	if dressing == null or dressing.get_child_count() < 28 or dressing.get_node_or_null("DistantGate") == null or dressing.get_node_or_null("SpikeTrapPlate") == null or dressing.get_node_or_null("RuinSpike") == null or dressing.get_node_or_null("RuinWallPier") == null:
		_fail(root, "Sunken Ruins did not build its distant gate and stone dressing")
		return
	StageBuilder.build_stage(root, 1, "high")
	dressing = root.get_node_or_null("GeneratedStageDressing")
	if dressing == null or dressing.get_child_count() < 25 or dressing.get_node_or_null("LavaChannel") == null or dressing.get_node_or_null("BasaltFracture") == null:
		_fail(root, "Ember Causeway did not build its lava channels")
		return
	if root.get_child_count() != 1:
		_fail(root, "Replacing a stage left duplicate dressing nodes behind")
		return
	StageBuilder.build_stage(root, 2, "high")
	dressing = root.get_node_or_null("GeneratedStageDressing")
	if dressing == null or dressing.get_child_count() < 28 or dressing.get_node_or_null("ThroneBack") == null or dressing.get_node_or_null("RunicFloorLine") == null or dressing.get_node_or_null("ThroneRuneShard") == null:
		_fail(root, "Obsidian Throne did not build the throne geometry")
		return
	root.queue_free()
	print("Stage builder smoke test passed: all three generated chapter environments")
	quit(0)


func _fail(root: Node3D, message: String) -> void:
	push_error(message)
	root.queue_free()
	quit(1)
