extends SceneTree

const ARENA_SCENE = preload("res://scenes/main.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var arena := ARENA_SCENE.instantiate() as NovaArenaController
    root.add_child(arena)
    for frame in range(300):
        await process_frame
    if arena.player == null or arena.boss == null or arena.camera_rig == null:
        push_error("Runtime smoke test: arena did not construct required gameplay systems.")
        arena.free()
        await process_frame
        quit(1)
        return
    if not arena.combat_started or not arena.player.input_enabled:
        push_error("Runtime smoke test: cinematic intro did not hand control to the player.")
        arena.free()
        await process_frame
        quit(1)
        return
    if arena.active_enemies.size() != 3:
        push_error("Runtime smoke test: encounter population changed unexpectedly.")
        arena.free()
        await process_frame
        quit(1)
        return
    print("RUNTIME TEST PASS: 300 frames, arena alive, cinematic handoff complete, player enabled and three enemies present.")
    arena.free()
    await process_frame
    await process_frame
    quit(0)
