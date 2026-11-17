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

	var origin := Vector3.ZERO
	var forward := Vector3(0.0, 0.0, -1.0)
	var targets := PackedVector3Array([
		Vector3(0.0, 0.0, -2.0),
		Vector3(0.0, 0.0, -6.0),
		Vector3(2.0, 0.0, 0.0),
		Vector3.ZERO,
		Vector3(0.0, 0.0, 2.0)
	])
	var hits: PackedInt32Array = kernel.call(
		"find_targets_in_attack_arc", origin, forward, targets, 5.0, 45.0
	)
	if hits != PackedInt32Array([0]):
		_fail("Attack-cone query returned unexpected target indices: %s" % str(hits))
		return

	var normalized_forward_hits: PackedInt32Array = kernel.call(
		"find_targets_in_attack_arc", origin, forward * 8.0, targets, 5.0, 45.0
	)
	if normalized_forward_hits != PackedInt32Array([0]):
		_fail("Attack-cone query must normalize the forward vector")
		return

	var zero_forward: PackedInt32Array = kernel.call(
		"find_targets_in_attack_arc", origin, Vector3.ZERO, targets, 5.0, 45.0
	)
	if not zero_forward.is_empty():
		_fail("Zero forward vector must return no candidates")
		return

	var no_range: PackedInt32Array = kernel.call(
		"find_targets_in_attack_arc", origin, forward, targets, 0.0, 45.0
	)
	if not no_range.is_empty():
		_fail("Non-positive range must return no candidates")
		return

	var full_circle: PackedInt32Array = kernel.call(
		"find_targets_in_attack_arc", origin, forward, targets, 7.0, 180.0
	)
	if full_circle != PackedInt32Array([0, 1, 2, 4]):
		_fail("A 180-degree half-angle must include every non-origin target in range")
		return

	var clamped_negative_angle: PackedInt32Array = kernel.call(
		"find_targets_in_attack_arc", origin, forward, targets, 5.0, -30.0
	)
	if clamped_negative_angle != PackedInt32Array([0]):
		_fail("Negative half-angle must clamp to zero degrees")
		return

	var clamped_large_angle: PackedInt32Array = kernel.call(
		"find_targets_in_attack_arc", origin, forward, targets, 7.0, 240.0
	)
	if clamped_large_angle != full_circle:
		_fail("Half-angle above 180 degrees must clamp to 180 degrees")
		return

	print("Nova C++ combat kernel smoke test passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
