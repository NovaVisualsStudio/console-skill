extends SceneTree


func _initialize() -> void:
	var resource := ResourceLoader.load("res://scripts/exploration_puzzle_director.gd", "Script", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null:
		push_error("Exploration puzzle director failed to compile as a standalone script resource")
		quit(1)
		return
	if not resource is GDScript:
		push_error("Exploration puzzle director resource is not a GDScript")
		quit(1)
		return
	print("Exploration puzzle director compile smoke test passed")
	quit(0)
