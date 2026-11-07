extends SceneTree

const CombatRules = preload("res://scripts/combat_rules.gd")


func _initialize() -> void:
	var failures := 0
	failures += _expect_true(CombatRules.is_target_in_attack_arc(Vector3.FORWARD, Vector3(0.0, 0.0, -2.0), 2.25), "target ahead is hittable")
	failures += _expect_false(CombatRules.is_target_in_attack_arc(Vector3.FORWARD, Vector3(0.0, 0.0, 2.0), 2.25), "target behind player is not hittable")
	failures += _expect_false(CombatRules.is_target_in_attack_arc(Vector3.FORWARD, Vector3(0.0, 0.0, -3.0), 2.25), "target outside attack range is not hittable")
	failures += _expect_false(CombatRules.is_target_in_attack_arc(Vector3.ZERO, Vector3(0.0, 0.0, -1.0), 2.25), "zero facing is rejected")
	failures += _expect_false(CombatRules.is_target_in_attack_arc(Vector3.FORWARD, Vector3.ZERO, 2.25), "zero offset is rejected")
	failures += _expect_true(CombatRules.is_target_in_attack_arc(Vector3.FORWARD, Vector3(0.0, 4.0, -2.0), 2.25), "ground-plane arc ignores vertical offset")
	failures += _expect_true(CombatRules.can_receive_hit(0.0), "expired invulnerability permits hit")
	failures += _expect_false(CombatRules.can_receive_hit(0.5), "active invulnerability blocks hit")
	failures += _expect_equal(CombatRules.combo_damage(0), 24, "combo one damage")
	failures += _expect_equal(CombatRules.combo_damage(1), 30, "combo two damage")
	failures += _expect_equal(CombatRules.combo_damage(2), 48, "combo finisher damage")
	failures += _expect_equal(CombatRules.combo_damage(99), 48, "combo step clamps safely")
	failures += _expect_true(CombatRules.combo_range(2) > CombatRules.combo_range(0), "finisher has wider range")
	failures += _expect_equal(CombatRules.heavy_attack_damage(), 68, "heavy attack damage")
	failures += _expect_true(CombatRules.heavy_attack_range() > CombatRules.combo_range(2), "heavy attack has longest reach")
	failures += _expect_true(CombatRules.should_start_enemy_windup(1.5, 0.0), "normal enemy begins windup in range")
	failures += _expect_false(CombatRules.should_start_enemy_windup(2.0, 0.0), "normal enemy does not begin windup early")
	failures += _expect_false(CombatRules.should_start_enemy_windup(1.5, 0.4), "enemy respects cooldown")
	failures += _expect_true(CombatRules.should_start_enemy_windup(4.8, 0.0, 5.0), "Warlord uses a longer attack tell")
	failures += _expect_false(CombatRules.should_start_enemy_windup(5.2, 0.0, 5.0), "boss tell still has a bounded range")
	failures += _expect_equal(CombatRules.CAMPAIGN_WAVES, 9, "campaign has nine encounters")
	var expected_counts := [4, 5, 1, 5, 6, 1, 6, 7, 1]
	for wave in range(1, 10):
		failures += _expect_equal(CombatRules.wave_enemy_count(wave), expected_counts[wave - 1], "wave %d enemy count" % wave)
	failures += _expect_true(CombatRules.is_boss_wave(3), "chapter one boss")
	failures += _expect_true(CombatRules.is_boss_wave(6), "chapter two boss")
	failures += _expect_true(CombatRules.is_boss_wave(9), "chapter three boss")
	failures += _expect_false(CombatRules.is_boss_wave(8), "regular wave is not a boss encounter")
	failures += _expect_equal(CombatRules.chapter_for_wave(1), 1, "wave one belongs to chapter one")
	failures += _expect_equal(CombatRules.chapter_for_wave(4), 2, "wave four belongs to chapter two")
	failures += _expect_equal(CombatRules.chapter_for_wave(7), 3, "wave seven belongs to chapter three")
	failures += _expect_equal(CombatRules.boss_kind_for_wave(3), "ash_titan", "first boss identity")
	failures += _expect_equal(CombatRules.boss_kind_for_wave(6), "ember_warlord", "second boss identity")
	failures += _expect_equal(CombatRules.boss_kind_for_wave(9), "obsidian_sovereign", "final boss identity")
	failures += _expect_equal(CombatRules.boss_phase(100, 100), 1, "boss phase one threshold")
	failures += _expect_equal(CombatRules.boss_phase(66, 100), 2, "boss phase two threshold")
	failures += _expect_equal(CombatRules.boss_phase(33, 100), 3, "boss phase three threshold")
	failures += _expect_equal(CombatRules.wave_enemy_health(9), 560, "final boss has highest health")
	failures += _expect_equal(CombatRules.wave_enemy_damage(9), 34, "final boss has highest damage")
	if failures > 0:
		push_error("Combat rules smoke test failed: %d assertion(s)" % failures)
		quit(1)
	else:
		print("Combat rules smoke test passed: campaign, boss patterns, combos, parry ranges and damage rules")
		quit(0)


func _expect_equal(actual: Variant, expected: Variant, label: String) -> int:
	if actual == expected:
		return 0
	push_error("Expected %s, got %s: %s" % [str(expected), str(actual), label])
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
