extends SceneTree


func _initialize() -> void:
	var resource := ResourceLoader.load("res://scripts/exploration_puzzle_director.gd", "Script", ResourceLoader.CACHE_MODE_IGNORE)
	if resource == null:
		push_error("Exploration puzzle director failed to load as a script resource")
		quit(1)
		return
	if not resource is GDScript:
		push_error("Exploration puzzle director resource is not a GDScript")
		quit(1)
		return
	var puzzle_script := resource as GDScript
	var compile_error := puzzle_script.reload()
	if compile_error != OK or not puzzle_script.can_instantiate():
		push_error("Exploration puzzle director failed GDScript compilation: %d" % compile_error)
		quit(1)
		return
	print("Exploration puzzle director compile smoke test passed")
	quit(0)
