extends SceneTree

const HUMANOID_SCRIPT = preload("res://scripts/humanoid_rig.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var rig := HUMANOID_SCRIPT.new() as NovaHumanoidRig
    root.add_child(rig)
    await process_frame
    await process_frame
    if rig.skeleton == null:
        push_error("Humanoid asset test: rigged character did not import a Skeleton3D.")
        rig.free()
        quit(1)
        return
    if rig.skeleton.get_bone_count() < 60:
        push_error("Humanoid asset test: expected a production humanoid skeleton with at least 60 joints.")
        rig.free()
        quit(1)
        return
    if rig.primary_mesh == null or rig.primary_material == null:
        push_error("Humanoid asset test: character mesh or PBR material was not assigned.")
        rig.free()
        quit(1)
        return
    if rig.animation_player == null or rig.loaded_animation_count < 20:
        push_error("Humanoid animation test: CC0 animation retargeting did not produce enough usable clips. Loaded: %d" % rig.loaded_animation_count)
        rig.free()
        quit(1)
        return
    rig.play_action("idle")
    await process_frame
    var idle_playing := not String(rig.animation_player.current_animation).is_empty()
    rig.play_action("attack", 0.0)
    await process_frame
    var attack_playing := not String(rig.animation_player.current_animation).is_empty()
    if not idle_playing or not attack_playing:
        push_error("Humanoid animation test: idle or combat action did not start.")
        rig.free()
        quit(1)
        return
    print("HUMANOID TEST PASS: %d bones, %d retargeted CC0 clips, mesh/material loaded, idle and attack actions playable." % [rig.skeleton.get_bone_count(), rig.loaded_animation_count])
    rig.free()
    await process_frame
    quit(0)
