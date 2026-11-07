extends SceneTree

const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const ENEMY_SCRIPT = preload("res://scripts/enemy.gd")

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var test_root := Node3D.new()
    root.add_child(test_root)

    if not InputMap.has_action("guard"):
        InputMap.add_action("guard")

    var player := PLAYER_SCRIPT.new() as NovaPlayer
    player.position = Vector3.ZERO
    test_root.add_child(player)

    var enemy := ENEMY_SCRIPT.new() as NovaEnemy
    enemy.player = player
    enemy.position = Vector3(0, 0, -1.5)
    test_root.add_child(enemy)

    await process_frame

    enemy.take_damage(20)
    if enemy.health != 60:
        push_error("Enemy damage test failed: expected 60 HP after 20 damage.")
        quit(1)
        return

    player.perform_attack()
    if enemy.health != 26:
        push_error("Melee test failed: expected a forward hit to deal 34 damage.")
        quit(1)
        return

    Input.action_press("guard")
    player.take_damage(10)
    Input.action_release("guard")
    if player.health != 157:
        push_error("Guard test failed: expected 70 percent damage reduction.")
        quit(1)
        return

    player.perform_dodge()
    player.take_damage(10)
    if player.health != 157:
        push_error("Dodge test failed: player should be invulnerable during dodge.")
        quit(1)
        return

    enemy.take_damage(100)
    if enemy.health != 0:
        push_error("Enemy defeat test failed: health should clamp at zero.")
        quit(1)
        return

    print("COMBAT TESTS PASS: damage, melee range, guard reduction, dodge invulnerability, enemy defeat.")
    quit(0)
