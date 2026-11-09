extends SceneTree

const ExplorationSecretDirector = preload("res://scripts/exploration_secret_director.gd")


func _initialize() -> void:
	call_deferred("_run_secret_smoke")


func _run_secret_smoke() -> void:
	var root := Node3D.new()
	root.name = "ExplorationSecretSmoke"
	get_root().add_child(root)
	for chapter in range(3):
		var cache := ExplorationSecretDirector.build_stage(root, chapter)
		if cache == null or cache.name != "GeneratedExplorationSecret":
			_fail(root, "Chapter %d secret cache was not created" % chapter)
			return
		if cache.get_node_or_null("CacheBase") == null or cache.get_node_or_null("CacheLid") == null or cache.get_node_or_null("CacheRune") == null or cache.get_node_or_null("SecretMarker") == null:
			_fail(root, "Chapter %d secret cache is missing visual components" % chapter)
			return
		var expected_positions := [Vector3(-10.6, 0.17, -3.5), Vector3(8.2, 0.07, -7.0), Vector3(-13.0, 0.09, -8.0)]
		if int(cache.get_meta("chapter_index", -1)) != chapter or bool(cache.get_meta("collected", true)):
			_fail(root, "Chapter %d cache metadata is invalid" % chapter)
			return
		if not cache.position.is_equal_approx(expected_positions[chapter]):
			_fail(root, "Chapter %d cache is not aligned with its intended flank traversal platform" % chapter)
			return
		if chapter == 0:
			if not ExplorationSecretDirector.collect(cache) or cache.visible:
				_fail(root, "Secret cache should become collected and hidden")
				return
			if ExplorationSecretDirector.collect(cache):
				_fail(root, "Collected secret cache must not grant a second reward")
				return
		if root.get_child_count() != 1:
			_fail(root, "Building a chapter secret left duplicate cache roots")
			return
	if root.get_child(0).get_meta("chapter_index") != 2:
		_fail(root, "Final chapter did not replace the previous cache")
	root.free()
	print("Exploration secret smoke test passed: three chapter caches, visual integrity, replacement and one-time collection")
	quit(0)


func _fail(root: Node3D, message: String) -> void:
	push_error(message)
	root.free()
	quit(1)
