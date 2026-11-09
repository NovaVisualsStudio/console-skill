extends SceneTree

const ARENA_SCENE = preload("res://scenes/main.tscn")

func _initialize() -> void:
    call_deferred("_run")

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

func _run() -> void:
    var arena := ARENA_SCENE.instantiate() as NovaArenaController
    root.add_child(arena)
    await create_timer(3.4).timeout
    for frame in range(300):
        await process_frame
    if arena.player == null or arena.boss == null or arena.camera_rig == null:
        push_error("Runtime smoke test: arena did not construct required gameplay systems.")
        await _finish(1, arena)
        return
    if not arena.combat_started or not arena.player.input_enabled:
        push_error("Runtime smoke test: cinematic intro did not hand control to the player.")
        await _finish(1, arena)
        return
    if arena.active_enemies.size() != 3:
        push_error("Runtime smoke test: encounter population changed unexpectedly.")
        await _finish(1, arena)
        return
    print("RUNTIME TEST PASS: 300 frames, arena alive, cinematic handoff complete, player enabled and three enemies present.")
    await _finish(0, arena)
