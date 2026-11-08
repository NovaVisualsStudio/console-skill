extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if not ClassDB.class_exists("NovaCombatKernel"):
		_fail("NovaCombatKernel class was not registered by GDExtension")
		return
	var kernel: Object = ClassDB.instantiate("NovaCombatKernel")
	if kernel == null:
		_fail("Could not instantiate NovaCombatKernel")
		return

	var targets := PackedVector3Array([
		Vector3(0.0, 0.0, -2.0),
		Vector3(0.0, 0.0, -6.0),
		Vector3(2.0, 0.0, 0.0),
		Vector3.ZERO
	])
	var hits: PackedInt32Array = kernel.call(
		"find_targets_in_attack_arc",
		Vector3.ZERO,
		Vector3(0.0, 0.0, -1.0),
		targets,
		5.0,
		45.0
	)
	if hits != PackedInt32Array([0]):
		_fail("Attack-cone query returned unexpected target indices: %s" % str(hits))
		return

	var zero_forward: PackedInt32Array = kernel.call(
		"find_targets_in_attack_arc",
		Vector3.ZERO,
		Vector3.ZERO,
		targets,
		5.0,
		45.0
	)
	if not zero_forward.is_empty():
		_fail("Zero forward vector must return no candidates")
		return

	var no_range: PackedInt32Array = kernel.call(
		"find_targets_in_attack_arc",
		Vector3.ZERO,
		Vector3(0.0, 0.0, -1.0),
		targets,
		0.0,
		45.0
	)
	if not no_range.is_empty():
		_fail("Non-positive range must return no candidates")
		return

	print("Nova C++ combat kernel smoke test passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
