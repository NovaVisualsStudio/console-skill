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
    var armor_attachment_count := 0
    for child in rig.skeleton.get_children():
        if child is BoneAttachment3D:
            armor_attachment_count += 1
    if armor_attachment_count < 8:
        push_error("Humanoid armor test: expected bone-attached armor pieces, found %d." % armor_attachment_count)
        rig.free()
        quit(1)
        return
    var right_hand_attachment := rig.attach_to_bone("hand_r")
    if right_hand_attachment == rig or not right_hand_attachment is BoneAttachment3D:
        push_error("Humanoid weapon test: right-hand bone attachment failed.")
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
    var idle_name := String(rig.animation_player.current_animation)
    var idle_playing := idle_name.to_lower().contains("idle")
    rig.play_action("attack", 0.0)
    await process_frame
    var attack_name := String(rig.animation_player.current_animation)
    var attack_lower := attack_name.to_lower()
    var attack_playing := attack_lower.contains("attack") or attack_lower.contains("sword") or attack_lower.contains("melee") or attack_lower.contains("combo") or attack_lower.contains("punch")
    if not idle_playing or not attack_playing:
        push_error("Humanoid animation test: idle or combat action did not start.")
        rig.free()
        quit(1)
        return
    rig.play_action("death", 0.0)
    await process_frame
    var death_name := String(rig.animation_player.current_animation)
    if not death_name.to_lower().contains("death"):
        push_error("Humanoid animation test: death reaction clip did not start.")
        rig.free()
        quit(1)
        return
    print("HUMANOID TEST PASS: %d bones, %d retargeted CC0 clips, idle=%s, attack=%s, death=%s." % [rig.skeleton.get_bone_count(), rig.loaded_animation_count, idle_name, attack_name, death_name])
    rig.free()
    await process_frame
    quit(0)
