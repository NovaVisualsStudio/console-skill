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
    # A physical wall between the focus and camera must retract the camera immediately.
    var focus_point := arena.player.global_position + Vector3.UP * arena.camera_rig.look_height
    var desired_camera := arena.player.global_position + Vector3(1.05, 3.0, 6.8)
    var blocker := StaticBody3D.new()
    blocker.name = "CameraOcclusionTestWall"
    blocker.position = focus_point.lerp(desired_camera, 0.55)
    var blocker_shape := CollisionShape3D.new()
    var blocker_box := BoxShape3D.new()
    blocker_box.size = Vector3(3.0, 4.0, 0.65)
    blocker_shape.shape = blocker_box
    blocker.add_child(blocker_shape)
    arena.add_child(blocker)
    await physics_frame
    var safe_camera_position := arena.camera_rig._constrain_camera_position(focus_point, desired_camera)
    if safe_camera_position.distance_to(desired_camera) >= 1.0:
        push_error("Camera collision failed to retract behind a blocking wall.")
        await _finish(1, arena)
        return
    blocker.queue_free()
    await physics_frame

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

    # Exercise the actual Android touch widgets, not just their node names.
    var forward_button := arena.find_child("move_forward", true, false) as Button
    var light_button := arena.find_child("light_attack", true, false) as Button
    var heavy_button := arena.find_child("heavy_attack", true, false) as Button
    var dodge_button := arena.find_child("dodge", true, false) as Button
    var guard_button := arena.find_child("guard", true, false) as Button
    if forward_button == null or light_button == null or heavy_button == null or dodge_button == null or guard_button == null:
        push_error("Android touch controls are missing or are not real Buttons.")
        await _finish(1, arena)
        return

    forward_button.button_down.emit()
    await physics_frame
    if not Input.is_action_pressed("move_forward"):
        push_error("Android movement button did not hold its mapped movement action.")
        await _finish(1, arena)
        return
    forward_button.button_up.emit()
    if Input.is_action_pressed("move_forward"):
        push_error("Android movement button did not release its mapped movement action.")
        await _finish(1, arena)
        return

    light_button.pressed.emit()
    if arena.player.current_state != NovaPlayer.CombatState.ATTACK or arena.player.attack_startup_timer <= 0.0:
        push_error("Android LIGHT button did not start the player's light attack.")
        await _finish(1, arena)
        return
    await create_timer(0.44).timeout
    var stamina_before_touch_heavy := arena.player.stamina
    heavy_button.pressed.emit()
    if arena.player.current_state != NovaPlayer.CombatState.ATTACK or not is_equal_approx(arena.player.stamina, stamina_before_touch_heavy - 30.0):
        push_error("Android HEAVY button did not trigger the stamina-cost heavy attack.")
        await _finish(1, arena)
        return
    await create_timer(0.80).timeout
    guard_button.button_down.emit()
    if not arena.player.guard_active:
        push_error("Android GUARD button did not activate guarding on press.")
        await _finish(1, arena)
        return
    guard_button.button_up.emit()
    if arena.player.guard_active:
        push_error("Android GUARD button did not release guarding on lift.")
        await _finish(1, arena)
        return
    dodge_button.pressed.emit()
    if arena.player.current_state != NovaPlayer.CombatState.DODGE or not arena.player.invulnerable:
        push_error("Android DODGE button did not activate dodge and its invulnerability window.")
        await _finish(1, arena)
        return
    await create_timer(0.46).timeout

    # The desktop Tab action must use the same lock-on path as the Android button.
    arena.player.lock_target = null
    arena.camera_rig.clear_lock_target()
    arena.lock_index = -1
    if not InputMap.has_action("lock_on"):
        push_error("Desktop lock-on action was not registered.")
        await _finish(1, arena)
        return
    var lock_key := InputEventKey.new()
    lock_key.physical_keycode = KEY_TAB
    lock_key.pressed = true
    Input.parse_input_event(lock_key)
    await create_timer(0.05).timeout
    var release_key := InputEventKey.new()
    release_key.physical_keycode = KEY_TAB
    release_key.pressed = false
    Input.parse_input_event(release_key)
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
