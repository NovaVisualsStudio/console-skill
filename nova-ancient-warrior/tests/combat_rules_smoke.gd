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
	failures += _expect_true(CombatRules.can_receive_hit(0.0), "player can be hit when invulnerability expires")
	failures += _expect_false(CombatRules.can_receive_hit(0.5), "player ignores hits during invulnerability")
	failures += _expect_equal(CombatRules.combo_damage(0), 24, "first combo strike damage")
	failures += _expect_equal(CombatRules.combo_damage(1), 30, "second combo strike damage")
	failures += _expect_equal(CombatRules.combo_damage(2), 48, "finisher damage")
	failures += _expect_equal(CombatRules.combo_damage(99), 48, "combo step is clamped safely")
	failures += _expect_true(CombatRules.combo_range(2) > CombatRules.combo_range(0), "finisher has wider attack range")
	failures += _expect_true(CombatRules.should_start_enemy_windup(1.5, 0.0), "enemy begins attack windup in range")
	failures += _expect_false(CombatRules.should_start_enemy_windup(2.0, 0.0), "enemy does not begin attack windup outside range")
	failures += _expect_false(CombatRules.should_start_enemy_windup(1.5, 0.4), "enemy respects attack cooldown")
	failures += _expect_equal(CombatRules.wave_enemy_count(1), 4, "first wave has four sentinels")
	failures += _expect_equal(CombatRules.wave_enemy_count(2), 5, "second wave adds one sentinel")
	failures += _expect_equal(CombatRules.wave_enemy_health(3), 260, "boss has a larger health pool")
	failures += _expect_equal(CombatRules.wave_enemy_damage(2), 11, "later wave increases enemy damage")
	failures += _expect_true(CombatRules.is_boss_wave(3), "third wave is the boss encounter")
	failures += _expect_false(CombatRules.is_boss_wave(2), "second wave is not the boss encounter")
	if failures > 0:
		push_error("Combat rules smoke test failed: %d assertion(s)" % failures)
		quit(1)
	else:
		print("Combat rules smoke test passed: 22 assertions")
		quit(0)


func _expect_equal(actual: int, expected: int, label: String) -> int:
	if actual == expected:
		return 0
	push_error("Expected %d, got %d: %s" % [expected, actual, label])
	return 1


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
