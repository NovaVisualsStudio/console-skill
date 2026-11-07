extends SceneTree

const ARENA_SCENE = preload("res://scenes/main.tscn")

func _initialize() -> void:
    call_deferred("_run_tests")

func _run_tests() -> void:
    var arena := ARENA_SCENE.instantiate() as NovaArenaController
    root.add_child(arena)
    await process_frame
    await process_frame

    if arena.player == null or arena.boss == null or arena.camera_rig == null:
        push_error("Cinematic arena failed to construct its player, boss or camera rig.")
        quit(1)
        return
    if not arena.camera_rig.camera.current:
        push_error("Third-person shoulder camera was not made current.")
        quit(1)
        return
    if arena.active_enemies.size() != 3:
        push_error("Encounter should contain two guardians and one boss.")
        quit(1)
        return
    if arena.combat_started or arena.player.input_enabled:
        push_error("The cinematic opening should lock combat input before the intro completes.")
        quit(1)
        return
    for required_node in ["ArenaFloor", "PortalCore", "AtmosphericAsh"]:
        if arena.find_child(required_node, true, false) == null:
            push_error("Missing cinematic environment node: " + required_node)
            quit(1)
            return
    if arena.camera_rig.intro_timer <= 0.0:
        push_error("Camera intro sequence did not start.")
        quit(1)
        return

    arena.camera_rig.set_lock_target(arena.boss)
    if arena.camera_rig.lock_target != arena.boss:
        push_error("Camera lock-on target assignment failed.")
        quit(1)
        return
    arena.camera_rig.shake(0.25, 0.2)
    if arena.camera_rig.shake_timer <= 0.0:
        push_error("Camera impact shake did not start.")
        quit(1)
        return

    arena.intro_timer = 0.02
    await create_timer(0.08).timeout
    if not arena.combat_started or not arena.player.input_enabled:
        push_error("Combat handoff from cinematic intro did not enable player input.")
        quit(1)
        return
    for enemy in arena.active_enemies:
        if is_instance_valid(enemy) and not enemy.active:
            push_error("An enemy was not activated after the cinematic handoff.")
            quit(1)
            return

    arena.boss.take_damage(310)
    if arena.boss.phase != 2 or arena.boss_bar.value != 310:
        push_error("Boss phase transition or boss HUD update failed in the live scene.")
        quit(1)
        return

    print("CINEMATIC TESTS PASS: Ashen Gate environment, shoulder camera, intro lock, camera shake, lock-on, combat handoff, enemy activation and boss HUD/phase.")
    arena.queue_free()
    await process_frame
    quit(0)
