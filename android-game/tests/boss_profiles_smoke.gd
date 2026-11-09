extends SceneTree

const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var expected_health := [620, 700, 760]
    var expected_first_patterns := [
        NovaEnemy.AttackPattern.MELEE,
        NovaEnemy.AttackPattern.THRUST,
        NovaEnemy.AttackPattern.SLAM
    ]
    var expected_scales := [1.55, 1.43, 1.66]
    for archetype in range(3):
        var boss := ENEMY_SCRIPT.new() as NovaEnemy
        boss.is_boss = true
        boss.boss_archetype = archetype
        boss.difficulty_scale = 1.0
        root.add_child(boss)
        await process_frame
        if boss.health != expected_health[archetype] or boss.max_health != expected_health[archetype]:
            push_error("Boss profile %d has incorrect base vitality." % archetype)
            boss.free()
            quit(1)
            return
        if not is_equal_approx(boss.humanoid.character_scale, expected_scales[archetype]):
            push_error("Boss profile %d does not have its unique silhouette scale." % archetype)
            boss.free()
            quit(1)
            return
        boss._begin_telegraph()
        if boss.current_attack_pattern != expected_first_patterns[archetype]:
            push_error("Boss profile %d did not start with its signature attack." % archetype)
            boss.free()
            quit(1)
            return
        boss.free()
        await process_frame
    print("BOSS PROFILE TEST PASS: three distinct vitality, silhouette and signature attack profiles.")
    quit(0)
