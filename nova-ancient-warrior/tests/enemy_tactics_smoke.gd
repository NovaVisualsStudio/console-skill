extends SceneTree

const EnemyTactics = preload("res://scripts/enemy_tactics.gd")


func _initialize() -> void:
	var far_plan := EnemyTactics.plan_movement(12.0, 2.0, 0.0, 0, false, 1, 1.0)
	assert(far_plan.action == EnemyTactics.ACTION_APPROACH, "Distant enemies must close distance")

	var agile_plan := EnemyTactics.plan_movement(4.0, 2.0, 0.5, 1, false, 1, 1.0)
	assert(agile_plan.action == EnemyTactics.ACTION_FLANK, "Agile enemies should flank while recovering")
	assert(float(agile_plan.lateral_weight) > 0.0, "Flank side must be deterministic")

	var boss_plan := EnemyTactics.plan_movement(6.0, 4.8, 0.4, 0, true, 2, -1.0)
	assert(boss_plan.action == EnemyTactics.ACTION_FLANK, "Phase-two bosses should reposition laterally")
	assert(float(boss_plan.lateral_weight) < 0.0, "Boss flank side must respect its assigned sign")

	var strike_plan := EnemyTactics.plan_movement(1.7, 2.0, 0.0, 0, false, 1, 1.0)
	assert(strike_plan.action == EnemyTactics.ACTION_WINDUP, "Ready enemies in range must telegraph")

	var recovery_plan := EnemyTactics.plan_movement(1.7, 2.0, 0.5, 0, false, 1, 1.0)
	assert(recovery_plan.action == EnemyTactics.ACTION_HOLD, "Enemies must not retrigger while cooling down")

	var direction := EnemyTactics.movement_direction(Vector3(0.0, 0.0, -1.0), 1.0)
	assert(direction.length() > 0.99 and direction.length() < 1.01, "Tactical movement must be normalized")
	assert(direction.x < 0.0, "Positive flank sign must produce a leftward orbit for a north-facing player")

	print("Enemy tactics smoke test passed: approach, agile flanks, boss repositioning, telegraph and cooldown")
	quit(0)
