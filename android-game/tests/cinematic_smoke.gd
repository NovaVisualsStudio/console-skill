extends SceneTree

const ARENA_SCENE = preload("res://scenes/main.tscn")

func _initialize() -> void:
    call_deferred("_run_tests")

func _finish(exit_code: int, arena: Node) -> void:
    if is_instance_valid(arena):
        if arena is NovaArenaController and is_instance_valid(arena.audio_fx):
            arena.audio_fx.shutdown()
            arena.audio_fx = null
        arena.free()
    await create_timer(0.5).timeout
    await process_frame
    await process_frame
    quit(exit_code)

func _run_tests() -> void:
    var arena := ARENA_SCENE.instantiate() as NovaArenaController
    root.add_child(arena)
    await process_frame
    await process_frame

    if arena.player == null or arena.boss == null or arena.camera_rig == null:
        push_error("Cinematic arena failed to construct its player, boss or camera rig.")
        await _finish(1, arena)
        return
    if not arena.camera_rig.camera.current:
        push_error("Third-person shoulder camera was not made current.")
        await _finish(1, arena)
        return
    if arena.active_enemies.size() != 3:
        push_error("Encounter should contain two guardians and one boss.")
        await _finish(1, arena)
        return
    if arena.combat_started or arena.player.input_enabled:
        push_error("The cinematic opening should lock combat input before the intro completes.")
        await _finish(1, arena)
        return
    for required_node in ["ArenaFloor", "PortalCore", "AtmosphericAsh"]:
        if arena.find_child(required_node, true, false) == null:
            push_error("Missing cinematic environment node: " + required_node)
            await _finish(1, arena)
            return
    if arena.camera_rig.intro_timer <= 0.0:
        push_error("Camera intro sequence did not start.")
        await _finish(1, arena)
        return

    for control_name in ["move_forward", "move_back", "move_left", "move_right", "light_attack", "heavy_attack", "dodge", "guard", "lock_on"]:
        if arena.find_child(control_name, true, false) == null:
            push_error("Missing Android touch control: " + control_name)
            await _finish(1, arena)
            return

    arena.camera_rig.set_lock_target(arena.boss)
    if arena.camera_rig.lock_target != arena.boss:
        push_error("Camera lock-on target assignment failed.")
        await _finish(1, arena)
        return
    arena.camera_rig.shake(0.25, 0.2)
    if arena.camera_rig.shake_timer <= 0.0:
        push_error("Camera impact shake did not start.")
        await _finish(1, arena)
        return

    arena.intro_timer = 0.02
    await create_timer(0.08).timeout
    if not arena.combat_started or not arena.player.input_enabled:
        push_error("Combat handoff from cinematic intro did not enable player input.")
        await _finish(1, arena)
        return
    for enemy in arena.active_enemies:
        if is_instance_valid(enemy) and not enemy.active:
            push_error("An enemy was not activated after the cinematic handoff.")
            await _finish(1, arena)
            return

    # The desktop Tab action must use the same lock-on path as the Android button.
    arena.player.lock_target = null
    arena.camera_rig.clear_lock_target()
    arena.lock_index = -1
    if not InputMap.has_action("lock_on"):
        push_error("Desktop lock-on action was not registered.")
        await _finish(1, arena)
        return
    Input.action_press("lock_on")
    await process_frame
    Input.action_release("lock_on")
    if not is_instance_valid(arena.player.lock_target) or arena.camera_rig.lock_target != arena.player.lock_target:
        push_error("Desktop lock-on input did not select and frame a target.")
        await _finish(1, arena)
        return

    # Verify lock-on rotates the player even without movement input.
    arena.player.rotation.y = 0.0
    arena.boss.global_position = arena.player.global_position + Vector3(4.0, 0.0, 0.0)
    arena.player.lock_target = arena.boss
    for frame in range(8):
        await physics_frame
    if absf(wrapf(arena.player.rotation.y, -PI, PI)) < 0.25:
        push_error("Player lock-on did not rotate the warrior toward a target while idle.")
        await _finish(1, arena)
        return

    arena.boss.take_damage(310)
    if arena.boss.phase != 2 or arena.boss_bar.value != 310:
        push_error("Boss phase transition or boss HUD update failed in the live scene.")
        await _finish(1, arena)
        return

    print("CINEMATIC TESTS PASS: Ashen Gate environment, shoulder camera, intro lock, camera shake, lock-on, combat handoff, enemy activation and boss HUD/phase.")
    await _finish(0, arena)
