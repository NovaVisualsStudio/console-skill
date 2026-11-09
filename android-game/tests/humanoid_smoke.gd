extends SceneTree

const HUMANOID_SCRIPT = preload("res://scripts/humanoid_rig.gd")

func _initialize() -> void:
    call_deferred("_run")

func _count_pbr_surface_meshes(node: Node, asset_id: String, tier: String) -> int:
    var count := 0
    if node is MeshInstance3D:
        var mesh_instance := node as MeshInstance3D
        var material := mesh_instance.material_override as StandardMaterial3D
        if material != null and material.albedo_texture != null:
            if material.albedo_texture.resource_path.to_lower().contains(asset_id + "_diff_" + tier + ".jpg"):
                if material.normal_enabled and material.normal_texture != null and material.roughness_texture != null:
                    count += 1
    for child in node.get_children():
        count += _count_pbr_surface_meshes(child, asset_id, tier)
    return count

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
    if not rig.uses_realistic_character or rig.attached_clothing_mesh_count < 5:
        push_error("Humanoid asset test: CC0 realistic body, four outfit pieces and short hair must load.")
        rig.free()
        quit(1)
        return
    if rig.primary_mesh == null or rig.primary_material == null:
        push_error("Humanoid asset test: character mesh or PBR material was not assigned.")
        rig.free()
        quit(1)
        return
    if rig.primary_material == rig.hit_flash_material:
        push_error("Humanoid material test: primary surface material must not alias the transient hit-flash overlay.")
        rig.free()
        quit(1)
        return
    var hair_mesh_found := false
    for child in rig.skeleton.get_children():
        if child is MeshInstance3D and String(child.name).to_lower().contains("hairshort02"):
            hair_mesh_found = true
    if not hair_mesh_found:
        push_error("Humanoid appearance test: skinned CC0 short-hair mesh was not attached to the hero skeleton.")
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
    var texture_tier := OS.get_environment("NOVA_TEXTURE_TIER").to_lower()
    if texture_tier.is_empty():
        texture_tier = String(ProjectSettings.get_setting("nova/graphics/texture_tier", "2k")).to_lower()
    var metal_armor_meshes := _count_pbr_surface_meshes(rig.skeleton, "metal_plate", texture_tier)
    var leather_armor_meshes := _count_pbr_surface_meshes(rig.skeleton, "leather_red_02", texture_tier)
    if metal_armor_meshes < 1 or leather_armor_meshes < 1:
        push_error("Humanoid PBR test: metal plate or leather CC0 maps were not applied to bone-attached armor.")
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
    var first_retarget_build_count := NovaHumanoidRig.get_retargeted_animation_build_count()
    var cached_peer := HUMANOID_SCRIPT.new() as NovaHumanoidRig
    root.add_child(cached_peer)
    await process_frame
    await process_frame
    if cached_peer.animation_player == null or cached_peer.loaded_animation_count != rig.loaded_animation_count:
        push_error("Humanoid cache test: a second matching rig did not receive the shared animation library.")
        cached_peer.free()
        rig.free()
        quit(1)
        return
    if NovaHumanoidRig.get_retargeted_animation_build_count() != first_retarget_build_count:
        push_error("Humanoid cache test: matching humanoid re-ran animation retargeting instead of sharing the cached library.")
        cached_peer.free()
        rig.free()
        quit(1)
        return
    cached_peer.queue_free()
    await process_frame
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

    rig.play_locomotion("walk", 0.55)
    await process_frame
    if rig.animation_player.current_animation.is_empty() or rig.animation_player.speed_scale < 0.70:
        push_error("Humanoid locomotion test: walk transition or cadence scaling failed.")
        rig.free()
        quit(1)
        return
    rig.play_locomotion("run", 1.0)
    await process_frame
    if rig.animation_player.current_animation.is_empty() or rig.animation_player.speed_scale < 1.15:
        push_error("Humanoid locomotion test: run transition or cadence scaling failed.")
        rig.free()
        quit(1)
        return
    # Exercise the optional-run fallback even when the imported pack lacks a run clip.
    var selected_walk_clip := String(rig._animation_selection_cache.get("walk", ""))
    rig._animation_selection_cache["run"] = ""
    rig.play_locomotion("run", 1.0)
    await process_frame
    if selected_walk_clip.is_empty() or rig.animation_player.current_animation != selected_walk_clip:
        push_error("Humanoid locomotion test: run did not safely fall back to the cached walk clip.")
        rig.free()
        quit(1)
        return
    rig._animation_selection_cache.erase("run")
    rig.play_locomotion("run", 1.0)
    if not rig._animation_selection_cache.has("run") or not rig._animation_selection_cache.has("walk"):
        push_error("Humanoid performance test: locomotion selection was not cached.")
        rig.free()
        quit(1)
        return
    var cached_locomotion_count := rig._animation_selection_cache.size()
    var animation_scans_before_repeat := rig._animation_clip_list_fetch_count
    for _repeat in range(8):
        rig.play_locomotion("run", 1.0)
    if rig._animation_selection_cache.size() != cached_locomotion_count:
        push_error("Humanoid performance test: repeated locomotion lookup expanded the cache.")
        rig.free()
        quit(1)
        return
    if rig._animation_clip_list_fetch_count != animation_scans_before_repeat:
        push_error("Humanoid performance test: locomotion fetched the animation list again after caching.")
        rig.free()
        quit(1)
        return
    rig.play_attack_variant(2, false, 0.0)
    if not rig._attack_variant_cache.has("light_2"):
        push_error("Humanoid performance test: combo animation was not cached.")
        rig.free()
        quit(1)
        return
    var cached_attack_count := rig._attack_variant_cache.size()
    var animation_scans_before_attack_repeat := rig._animation_clip_list_fetch_count
    rig.play_attack_variant(2, false, 0.0)
    if rig._attack_variant_cache.size() != cached_attack_count:
        push_error("Humanoid performance test: repeated combo lookup expanded the cache.")
        rig.free()
        quit(1)
        return
    if rig._animation_clip_list_fetch_count != animation_scans_before_attack_repeat:
        push_error("Humanoid performance test: repeated combo fetched the animation list again after caching.")
        rig.free()
        quit(1)
        return
    await process_frame
    await process_frame
    if String(rig.animation_player.current_animation).is_empty():
        push_error("Humanoid animation test: combo variant selection returned no usable clip.")
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
    print("HUMANOID TEST PASS: %d bones, %d retargeted clips, %d skinned outfit meshes, %d metal and %d leather PBR meshes, idle=%s, light=%s, heavy=%s, death=%s." % [rig.skeleton.get_bone_count(), rig.loaded_animation_count, rig.attached_clothing_mesh_count, metal_armor_meshes, leather_armor_meshes, idle_name, attack_pose_name, heavy_name, death_name])
    rig.free()
    await process_frame
    quit(0)
