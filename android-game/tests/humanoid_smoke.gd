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
    if rig.skeleton.get_bone_count() < 50:
        push_error("Humanoid asset test: expected a production humanoid skeleton with at least 50 joints.")
        rig.free()
        quit(1)
        return
    if not rig.uses_realistic_character or rig.attached_clothing_mesh_count < 4:
        push_error("Humanoid asset test: CC0 realistic body and four skinned outfit pieces must load.")
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
    if right_hand_attachment == rig or not (right_hand_attachment is BoneAttachment3D):
        push_error("Humanoid weapon test: right-hand bone attachment failed.")
        rig.free()
        quit(1)
        return
    if rig.animation_player == null or rig.loaded_animation_count < 20:
        push_error("Humanoid animation test: CC0 animation retargeting did not produce enough usable clips. Loaded: %d" % rig.loaded_animation_count)
        rig.free()
        quit(1)
        return
    var available_clips := rig.animation_player.get_animation_list()
    var has_light_melee_clip := false
    var has_heavy_melee_clip := false
    for clip in available_clips:
        var clip_name := String(clip).to_lower()
        var is_melee := clip_name.contains("sword") or clip_name.contains("melee") or clip_name.contains("attack") or clip_name.contains("combo") or clip_name.contains("punch")
        if is_melee and not clip_name.contains("heavy"):
            has_light_melee_clip = true
        if is_melee and clip_name.contains("heavy"):
            has_heavy_melee_clip = true

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
    if has_light_melee_clip and attack_lower.contains("heavy"):
        push_error("Humanoid animation test: light attack incorrectly selected a heavy-only clip: " + attack_name)
        rig.free()
        quit(1)
        return
    rig.play_action("heavy", 0.0)
    await process_frame
    var heavy_name := String(rig.animation_player.current_animation)
    if has_heavy_melee_clip and not heavy_name.to_lower().contains("heavy"):
        push_error("Humanoid animation test: heavy attack did not select a heavy clip: " + heavy_name)
        rig.free()
        quit(1)
        return
    rig.play_action("attack", 0.0)
    await process_frame
    var attack_pose_name := String(rig.animation_player.current_animation)
    var attack_pose_before: Array[Quaternion] = []
    for bone_name in ["upperarm_r", "lowerarm_r", "spine_02"]:
        attack_pose_before.append(rig.skeleton.get_bone_pose_rotation(rig.skeleton.find_bone(bone_name)))
    var attack_bones := ["upperarm_r", "lowerarm_r", "spine_02"]
    var attack_pose_before: Array[Quaternion] = []
    for bone_name in attack_bones:
        attack_pose_before.append(rig.skeleton.get_bone_pose_rotation(rig.skeleton.find_bone(bone_name)))
    await create_timer(0.28).timeout
    var attack_pose_changed := false
    for bone_index in range(attack_bones.size()):
        var target_bone := rig.skeleton.find_bone(attack_bones[bone_index])
        if not attack_pose_before[bone_index].is_equal_approx(rig.skeleton.get_bone_pose_rotation(target_bone)):
            attack_pose_changed = true
    if not attack_pose_changed:
        push_error("Humanoid animation test: melee clip started but did not change an upper-body bone pose.")
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
    var pelvis_index := rig.skeleton.find_bone("pelvis")
    var death_pose_before := rig.skeleton.get_bone_pose_rotation(pelvis_index)
    await create_timer(0.55).timeout
    var death_pose_after := rig.skeleton.get_bone_pose_rotation(pelvis_index)
    if death_pose_before.is_equal_approx(death_pose_after):
        push_error("Humanoid animation test: death clip name changed but did not animate the skeleton pose.")
        rig.free()
        quit(1)
        return
    print("HUMANOID TEST PASS: %d bones, %d retargeted clips, %d skinned outfit meshes, idle=%s, light=%s, heavy=%s, death=%s." % [rig.skeleton.get_bone_count(), rig.loaded_animation_count, rig.attached_clothing_mesh_count, idle_name, attack_pose_name, heavy_name, death_name])
    rig.free()
    await process_frame
    quit(0)
