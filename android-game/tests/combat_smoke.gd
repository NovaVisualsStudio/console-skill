extends SceneTree

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")

func _initialize() -> void:
    call_deferred("_run_tests")

func _ensure_actions() -> void:
    for action in ["move_left", "move_right", "move_forward", "move_back", "guard", "attack", "heavy_attack", "dodge"]:
        if not InputMap.has_action(action):
            InputMap.add_action(action)

func _wait_for_enemy_health(enemy: NovaEnemy, expected: int, max_frames: int = 60) -> void:
    var frames := 0
    while enemy.health != expected and frames < max_frames:
        await physics_frame
        frames += 1

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
    # Keep the combo target alive through the finisher so the test can inspect it after the hit frame.
    grunt.health = 200
    grunt.max_health = 200

    if grunt.health != 200 or player.health != 160:
        push_error("Baseline health test failed.")
        await _finish(1, test_root)
        return

    var first_ok := player.perform_light_attack()
    if not first_ok or grunt.health != 200 or player.combo_step != 1:
        push_error("Light attack should enter startup before applying damage.")
        await _finish(1, test_root)
        return
    await _wait_for_enemy_health(grunt, 168)
    if grunt.health != 168:
        push_error("Light attack combo step 1 active window failed.")
        await _finish(1, test_root)
        return
    await _wait_attack_ready(player)
    var second_ok := player.perform_light_attack()
    if not second_ok or grunt.health != 168 or player.combo_step != 2:
        push_error("Light attack combo step 2 startup failed.")
        await _finish(1, test_root)
        return
    await _wait_for_enemy_health(grunt, 129)
    if grunt.health != 129:
        push_error("Light attack combo step 2 active window failed.")
        await _finish(1, test_root)
        return
    await _wait_attack_ready(player)
    var third_ok := player.perform_light_attack()
    if not third_ok or grunt.health != 129 or player.combo_step != 3:
        push_error("Light attack combo finisher startup failed.")
        await _finish(1, test_root)
        return
    await _wait_for_enemy_health(grunt, 73)
    if grunt.health != 73:
        push_error("Light attack combo finisher active window failed.")
        await _finish(1, test_root)
        return
    await _wait_attack_ready(player)

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
    # Phase two must cycle through distinct, testable attack shapes.
    boss._begin_telegraph()
    if boss.current_attack_pattern != NovaEnemy.AttackPattern.MELEE:
        push_error("Boss phase-two pattern cycle did not start with melee.")
        await _finish(1, test_root)
        return
    if not boss._is_player_in_attack_area(Vector3(0.0, 0.0, -3.0)):
        push_error("Boss melee pattern failed its forward hit-area check.")
        await _finish(1, test_root)
        return
    boss._begin_telegraph()
    if boss.current_attack_pattern != NovaEnemy.AttackPattern.SWEEP:
        push_error("Boss sweep pattern was not selected.")
        await _finish(1, test_root)
        return
    if not boss._is_player_in_attack_area(Vector3(4.5, 0.0, 0.0)):
        push_error("Boss sweep failed its lateral hit-area check.")
        await _finish(1, test_root)
        return
    boss._begin_telegraph()
    if boss.current_attack_pattern != NovaEnemy.AttackPattern.SLAM:
        push_error("Boss slam pattern was not selected.")
        await _finish(1, test_root)
        return
    if not boss._is_player_in_attack_area(Vector3(0.0, 0.0, 6.0)):
        push_error("Boss slam failed its radial hit-area check.")
        await _finish(1, test_root)
        return
    if boss._is_player_in_attack_area(Vector3(0.0, 0.0, 8.0)):
        push_error("Boss slam hit-area exceeded its maximum radius.")
        await _finish(1, test_root)
        return
    boss.telegraph_mesh.scale = Vector3.ONE
    boss.telegraph_mesh.visible = false
    boss.current_state = NovaEnemy.BrainState.CHASE


    await _wait_attack_ready(player)
    var boss_health_before_heavy := boss.health
    var stamina_before_heavy := player.stamina
    if not player.perform_heavy_attack() or boss.health != boss_health_before_heavy:
        push_error("Heavy attack should observe startup before its active hit window.")
        await _finish(1, test_root)
        return
    if not is_equal_approx(player.stamina, stamina_before_heavy - 30.0):
        push_error("Heavy attack should consume exactly 30 stamina.")
        await _finish(1, test_root)
        return
    var stamina_after_heavy := player.stamina
    await create_timer(0.35).timeout
    if not is_equal_approx(player.stamina, stamina_after_heavy):
        push_error("Stamina regenerated before the heavy-attack recovery delay elapsed.")
        await _finish(1, test_root)
        return
    await _wait_for_enemy_health(boss, boss_health_before_heavy - 82)
    if boss.health != boss_health_before_heavy - 82:
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

    var death_target := ENEMY_SCRIPT.new() as NovaEnemy
    death_target.player = player
    death_target.position = Vector3(4.0, 0.0, -2.0)
    test_root.add_child(death_target)
    await process_frame
    death_target.take_damage(999, player.global_position, true)
    await process_frame
    if death_target.current_state != NovaEnemy.BrainState.DEAD or not String(death_target.humanoid.animation_player.current_animation).to_lower().contains("death"):
        push_error("Enemy death should enter DEAD state and play its skeletal death animation.")
        await _finish(1, test_root)
        return
    await create_timer(0.2).timeout
    if not is_instance_valid(death_target):
        push_error("Enemy was freed before its death animation had time to play.")
        await _finish(1, test_root)
        return

    print("COMBAT TESTS PASS: light combo x3, heavy hit, boss phase transition, perfect parry, guard reduction, dodge invulnerability, enemy telegraph, strike and animated death.")
    await _finish(0, test_root)
