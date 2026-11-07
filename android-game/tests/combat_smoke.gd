extends SceneTree

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")

func _initialize() -> void:
    call_deferred("_run_tests")

func _ensure_actions() -> void:
    for action in ["move_left", "move_right", "move_forward", "move_back", "guard", "attack", "heavy_attack", "dodge"]:
        if not InputMap.has_action(action):
            InputMap.add_action(action)

func _wait_attack_ready(player: NovaPlayer) -> void:
    var frames := 0
    while player.attack_cooldown > 0.0 and frames < 90:
        await physics_frame
        frames += 1

func _finish(exit_code: int, test_root: Node) -> void:
    if is_instance_valid(test_root):
        test_root.free()
    await process_frame
    await process_frame
    quit(exit_code)

func _run_tests() -> void:
    _ensure_actions()
    var test_root := Node3D.new()
    root.add_child(test_root)
    var floor_body := StaticBody3D.new()
    floor_body.position = Vector3(0.0, -0.55, 0.0)
    var floor_collision := CollisionShape3D.new()
    var floor_shape := BoxShape3D.new()
    floor_shape.size = Vector3(30.0, 1.0, 30.0)
    floor_collision.shape = floor_shape
    floor_body.add_child(floor_collision)
    test_root.add_child(floor_body)

    var player := PLAYER_SCRIPT.new() as NovaPlayer
    player.position = Vector3.ZERO
    test_root.add_child(player)
    var grunt := ENEMY_SCRIPT.new() as NovaEnemy
    grunt.player = player
    grunt.position = Vector3(0, 0, -2.0)
    test_root.add_child(grunt)
    await process_frame

    if grunt.health != 80 or player.health != 160:
        push_error("Baseline health test failed.")
        await _finish(1, test_root)
        return

    var first_ok := player.perform_light_attack()
    if not first_ok or grunt.health != 48 or player.combo_step != 1:
        push_error("Light attack combo step 1 failed.")
        await _finish(1, test_root)
        return
    await _wait_attack_ready(player)
    var second_ok := player.perform_light_attack()
    if not second_ok or grunt.health != 9 or player.combo_step != 2:
        push_error("Light attack combo step 2 failed.")
        await _finish(1, test_root)
        return
    await _wait_attack_ready(player)
    var third_ok := player.perform_light_attack()
    if not third_ok or grunt.health != 0 or player.combo_step != 3:
        push_error("Light attack combo finisher failed.")
        await _finish(1, test_root)
        return

    var boss := ENEMY_SCRIPT.new() as NovaEnemy
    boss.player = player
    boss.is_boss = true
    boss.position = Vector3(0, 0, -3.0)
    test_root.add_child(boss)
    await process_frame
    if boss.health != 620 or boss.phase != 1:
        push_error("Boss phase 1 setup failed.")
        await _finish(1, test_root)
        return
    boss.take_damage(310)
    if boss.health != 310 or boss.phase != 2 or boss.attack_damage != 38:
        push_error("Boss phase transition did not trigger at 50 percent health.")
        await _finish(1, test_root)
        return

    await _wait_attack_ready(player)
    var boss_health_before_heavy := boss.health
    if not player.perform_heavy_attack() or boss.health != boss_health_before_heavy - 82:
        push_error("Heavy attack damage or stamina path failed.")
        await _finish(1, test_root)
        return

    var health_before_parry := player.health
    player.set_guard(true)
    player.take_damage(28, boss.global_position, true)
    if player.health != health_before_parry:
        push_error("Perfect parry should negate the incoming hit.")
        await _finish(1, test_root)
        return
    await create_timer(0.25).timeout
    player.take_damage(10, boss.global_position, false)
    if player.health != health_before_parry - 3:
        push_error("Guard should reduce non-parried damage to 30 percent.")
        await _finish(1, test_root)
        return
    player.set_guard(false)

    var health_before_dodge := player.health
    if not player.perform_dodge():
        push_error("Dodge activation failed.")
        await _finish(1, test_root)
        return
    if not player.invulnerable:
        push_error("Dodge invulnerability flag was not enabled.")
        await _finish(1, test_root)
        return
    player.take_damage(20, boss.global_position, true)
    if player.health != health_before_dodge:
        push_error("Dodge should avoid damage during invulnerability.")
        await _finish(1, test_root)
        return
    await create_timer(0.46).timeout
    if player.invulnerable:
        push_error("Dodge invulnerability did not expire.")
        await _finish(1, test_root)
        return

    var attacker := ENEMY_SCRIPT.new() as NovaEnemy
    attacker.player = player
    attacker.position = Vector3(0, 0, -1.5)
    test_root.add_child(attacker)
    await process_frame
    attacker.activate()
    var telegraph_frames := 0
    while attacker.current_state != NovaEnemy.BrainState.TELEGRAPH and telegraph_frames < 90:
        await physics_frame
        telegraph_frames += 1
    if attacker.current_state != NovaEnemy.BrainState.TELEGRAPH or not attacker.telegraph_mesh.visible:
        push_error("Enemy attack telegraph did not become visible before striking.")
        await _finish(1, test_root)
        return
    var health_before_enemy_strike := player.health
    await create_timer(0.72).timeout
    if player.health >= health_before_enemy_strike:
        push_error("Enemy did not resolve its telegraphed melee strike.")
        await _finish(1, test_root)
        return

    print("COMBAT TESTS PASS: light combo x3, heavy hit, boss phase transition, perfect parry, guard reduction, dodge invulnerability, enemy telegraph and strike.")
    await _finish(0, test_root)
