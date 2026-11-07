extends SceneTree

const CombatRules = preload("res://scripts/combat_rules.gd")


func _initialize() -> void:
	var failures := 0
	failures += _expect_true(
		CombatRules.is_target_in_attack_arc(Vector3.FORWARD, Vector3(0.0, 0.0, -2.0), 2.25),
		"target directly ahead is hittable"
	)
	failures += _expect_false(
		CombatRules.is_target_in_attack_arc(Vector3.FORWARD, Vector3(0.0, 0.0, 2.0), 2.25),
		"target behind player is not hittable"
	)
	failures += _expect_false(
		CombatRules.is_target_in_attack_arc(Vector3.FORWARD, Vector3(0.0, 0.0, -3.0), 2.25),
		"target outside attack range is not hittable"
	)
	failures += _expect_false(
		CombatRules.is_target_in_attack_arc(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), 2.25),
		"zero facing vector is rejected"
	)
	failures += _expect_false(
		CombatRules.is_target_in_attack_arc(Vector3.FORWARD, Vector3.ZERO, 2.25),
		"zero target offset is rejected"
	)
	failures += _expect_true(
		CombatRules.is_target_in_attack_arc(Vector3.FORWARD, Vector3(0.0, 4.0, -2.0), 2.25),
		"vertical separation does not alter the ground-plane attack test"
	)
	if failures > 0:
		push_error("Combat rules smoke test failed: %d assertion(s)" % failures)
		quit(1)
	else:
		print("Combat rules smoke test passed: 6 assertions")
		quit(0)


func _expect_true(value: bool, label: String) -> int:
	if value:
		return 0
	push_error("Expected true: " + label)
	return 1


func _expect_false(value: bool, label: String) -> int:
	if not value:
		return 0
	push_error("Expected false: " + label)
	return 1
