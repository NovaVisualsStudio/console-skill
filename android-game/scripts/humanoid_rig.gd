extends Node3D
class_name NovaHumanoidRig

const REALISTIC_CHARACTER_PATH := "res://assets/characters/charactercreator-base-body.glb"
const FALLBACK_CHARACTER_PATH := "res://assets/characters/quaternius-standard-male.glb"
const ANIMATION_SCENE_PATH := "res://assets/animations/UAL2_Standard.glb"

@export var tint_color := Color(0.20, 0.27, 0.34)
@export var character_scale := 1.0
@export var accent_color := Color(0.62, 0.43, 0.20)
@export_enum("hero", "enemy", "boss") var armor_style := "hero"

var model_root: Node3D
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var loaded_animation_count := 0
var primary_mesh: MeshInstance3D
var primary_material: StandardMaterial3D
var hit_flash_material: StandardMaterial3D
var attached_clothing_mesh_count := 0
var uses_realistic_character := false
var _source_skeleton: Skeleton3D

func _ready() -> void:
    _build_character()
    _load_and_retarget_animations()

func _build_character() -> void:
    var character_scene := load(REALISTIC_CHARACTER_PATH) as PackedScene
    uses_realistic_character = character_scene != null
    if character_scene == null:
        character_scene = load(FALLBACK_CHARACTER_PATH) as PackedScene
    if character_scene == null:
        push_error("NOVA could not load either the CC0 realistic human or the Quaternius fallback GLB.")
        return
    model_root = character_scene.instantiate() as Node3D
    if model_root == null:
        push_error("NOVA humanoid GLB did not instantiate as Node3D.")
        return
    model_root.name = "CharacterCreatorRealisticHuman" if uses_realistic_character else "QuaterniusFallbackHuman"
    model_root.scale = Vector3.ONE * character_scale
    add_child(model_root)
    skeleton = _find_skeleton(model_root)
    if skeleton == null:
        push_error("NOVA character GLB is missing its Skeleton3D.")
        return
    skeleton.show_rest_only = false
    if uses_realistic_character:
        var outfit_assets := [
            ["res://assets/characters/charactercreator-tshirt.glb", "OutfitTShirt"],
            ["res://assets/characters/charactercreator-jeans.glb", "OutfitJeans"],
            ["res://assets/characters/charactercreator-boots.glb", "OutfitBoots"],
            ["res://assets/characters/charactercreator-trenchcoat.glb", "OutfitTrenchcoat"],
            ["res://assets/characters/charactercreator-hair-short02.glb", "HairShort02"]
        ]
        for asset in outfit_assets:
            attached_clothing_mesh_count += _attach_skinned_asset(String(asset[0]), String(asset[1]))
    _create_hit_flash_material()
    _apply_character_materials(model_root)
    _build_armor_set()

func _create_hit_flash_material() -> void:
    hit_flash_material = StandardMaterial3D.new()
    hit_flash_material.albedo_color = Color(1.0, 0.12, 0.035, 0.28)
    hit_flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    hit_flash_material.roughness = 0.38
    hit_flash_material.emission_enabled = true
    hit_flash_material.emission = Color(1.0, 0.055, 0.01)
    hit_flash_material.emission_energy_multiplier = 0.0

func _attach_skinned_asset(path: String, asset_label: String) -> int:
    var packed_scene := load(path) as PackedScene
    if packed_scene == null:
        push_warning("NOVA optional CC0 outfit asset is missing: %s" % path)
        return 0
    var instance := packed_scene.instantiate() as Node3D
    if instance == null:
        return 0
    instance.transform = model_root.transform
    add_child(instance)
    var source_skeleton := _find_skeleton(instance)
    if source_skeleton == null or not _skeletons_match(source_skeleton, skeleton):
        push_warning("NOVA outfit skeleton does not match the base human rig: %s" % asset_label)
        instance.queue_free()
        return 0
    var meshes: Array[MeshInstance3D] = []
    _collect_mesh_instances(instance, meshes)
    var attached := 0
    for mesh_instance in meshes:
        if mesh_instance.mesh == null:
            continue
        var original_name := mesh_instance.name
        mesh_instance.reparent(skeleton, true)
        mesh_instance.skeleton = NodePath("..")
        mesh_instance.name = "%s_%s" % [asset_label, original_name]
        mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        attached += 1
    instance.queue_free()
    return attached

func _skeletons_match(first: Skeleton3D, second: Skeleton3D) -> bool:
    if first.get_bone_count() != second.get_bone_count():
        return false
    for bone_index in range(first.get_bone_count()):
        if first.get_bone_name(bone_index).to_lower() != second.get_bone_name(bone_index).to_lower():
            return false
    return true

func _collect_mesh_instances(node: Node, output: Array[MeshInstance3D]) -> void:
    for child in node.get_children():
        if child is MeshInstance3D:
            output.append(child as MeshInstance3D)
        _collect_mesh_instances(child, output)

func _apply_character_materials(root: Node) -> void:
    var armor := StandardMaterial3D.new()
    armor.albedo_color = tint_color
    armor.metallic = 0.48
    armor.roughness = 0.52
    armor.metallic_specular = 0.62
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color(0.48, 0.30, 0.21)
    skin.metallic = 0.0
    skin.roughness = 0.78
    var hair := StandardMaterial3D.new()
    hair.albedo_color = Color(0.045, 0.027, 0.018)
    hair.roughness = 0.92
    var eyes := StandardMaterial3D.new()
    eyes.albedo_color = Color(0.035, 0.025, 0.02)
    eyes.roughness = 0.24
    for child in root.get_children():
        if child is MeshInstance3D:
            var mesh_instance := child as MeshInstance3D
            var mesh_name := mesh_instance.name.to_lower()
            var has_source_material := false
            if mesh_instance.mesh != null:
                for surface_index in range(mesh_instance.mesh.get_surface_count()):
                    if mesh_instance.get_active_material(surface_index) != null:
                        has_source_material = true
                        break
            if not has_source_material:
                if mesh_name.contains("eye"):
                    mesh_instance.material_override = eyes
                elif mesh_name.contains("eyebrow") or mesh_name.contains("hair"):
                    mesh_instance.material_override = hair
                elif mesh_name.contains("head"):
                    mesh_instance.material_override = skin
                else:
                    mesh_instance.material_override = armor
            if primary_mesh == null or mesh_name.contains("body") or mesh_name.contains("base_body"):
                primary_mesh = mesh_instance
            mesh_instance.material_overlay = hit_flash_material
            mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        _apply_character_materials(child)
    primary_material = hit_flash_material
func _build_armor_set() -> void:
    var steel := StandardMaterial3D.new()
    steel.albedo_color = tint_color.lightened(0.10)
    steel.metallic = 0.76
    steel.roughness = 0.40
    var trim := StandardMaterial3D.new()
    trim.albedo_color = accent_color
    trim.metallic = 0.84
    trim.roughness = 0.31
    var leather := StandardMaterial3D.new()
    leather.albedo_color = tint_color.darkened(0.28)
    leather.roughness = 0.88
    _add_bone_piece("spine_02", _box_mesh(Vector3(0.48, 0.42, 0.16)), Vector3(0.0, 0.0, 0.07), Vector3.ZERO, Vector3.ONE, steel)
    _add_bone_piece("spine_02", _box_mesh(Vector3(0.40, 0.045, 0.19)), Vector3(0.0, -0.17, 0.16), Vector3.ZERO, Vector3.ONE, trim)
    _add_bone_piece("pelvis", _box_mesh(Vector3(0.48, 0.13, 0.22)), Vector3(0.0, 0.0, 0.04), Vector3.ZERO, Vector3.ONE, trim)
    _add_bone_piece("clavicle_l", _sphere_mesh(0.19), Vector3.ZERO, Vector3.ZERO, Vector3(1.30, 0.78, 1.18), trim)
    _add_bone_piece("clavicle_r", _sphere_mesh(0.19), Vector3.ZERO, Vector3.ZERO, Vector3(1.30, 0.78, 1.18), trim)
    _add_bone_piece("lowerarm_l", _capsule_mesh(0.105, 0.34), Vector3.ZERO, Vector3(0.0, 0.0, 90.0), Vector3(1.0, 1.0, 1.0), steel)
    _add_bone_piece("lowerarm_r", _capsule_mesh(0.105, 0.34), Vector3.ZERO, Vector3(0.0, 0.0, 90.0), Vector3(1.0, 1.0, 1.0), steel)
    _add_bone_piece("calf_l", _box_mesh(Vector3(0.18, 0.36, 0.15)), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, steel)
    _add_bone_piece("calf_r", _box_mesh(Vector3(0.18, 0.36, 0.15)), Vector3.ZERO, Vector3.ZERO, Vector3.ONE, steel)
    if armor_style == "boss":
        for side in [-1.0, 1.0]:
            _add_bone_piece("Head", _horn_mesh(), Vector3(side * 0.15, 0.18, 0.0), Vector3(0.0, 0.0, side * -34.0), Vector3.ONE, trim)

func _add_bone_piece(bone_name: String, mesh: Mesh, local_position: Vector3, local_rotation_degrees: Vector3, local_scale: Vector3, material: Material) -> void:
    var attachment := attach_to_bone(bone_name)
    if attachment == self:
        return
    var piece := MeshInstance3D.new()
    piece.mesh = mesh
    piece.position = local_position
    piece.rotation_degrees = local_rotation_degrees
    piece.scale = local_scale
    piece.material_override = material
    piece.material_overlay = hit_flash_material
    piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    attachment.add_child(piece)

func _box_mesh(size: Vector3) -> BoxMesh:
    var mesh := BoxMesh.new()
    mesh.size = size
    return mesh

func _sphere_mesh(radius: float) -> SphereMesh:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    return mesh

func _capsule_mesh(radius: float, height: float) -> CapsuleMesh:
    var mesh := CapsuleMesh.new()
    mesh.radius = radius
    mesh.height = height
    return mesh

func _horn_mesh() -> CylinderMesh:
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.012
    mesh.bottom_radius = 0.075
    mesh.height = 0.34
    mesh.radial_segments = 8
    return mesh

func _load_and_retarget_animations() -> void:
    if skeleton == null:
        return
    var animation_scene := load(ANIMATION_SCENE_PATH) as PackedScene
    if animation_scene == null:
        push_warning("NOVA CC0 animation pack is not installed. Run tools/fetch_cc0_animations.py.")
        return
    var source_root := animation_scene.instantiate()
    if source_root == null:
        push_warning("NOVA animation pack could not be instantiated.")
        return
    add_child(source_root)
    var source_player := _find_animation_player(source_root)
    _source_skeleton = _find_skeleton(source_root)
    if source_player == null or _source_skeleton == null:
        push_warning("NOVA animation pack needs an AnimationPlayer and Skeleton3D.")
        source_root.queue_free()
        return

    animation_player = AnimationPlayer.new()
    animation_player.name = "HumanoidAnimationPlayer"
    animation_player.root_node = NodePath("..")
    animation_player.playback_default_blend_time = 0.14
    add_child(animation_player)

    var library := AnimationLibrary.new()
    for animation_name in source_player.get_animation_list():
        var source_animation := source_player.get_animation(animation_name)
        if source_animation == null:
            continue
        var retargeted := _retarget_animation(source_animation)
        if retargeted != null and retargeted.get_track_count() > 0:
            var safe_name := String(animation_name)
            if not library.has_animation(safe_name):
                library.add_animation(safe_name, retargeted)
                loaded_animation_count += 1
    if not library.has_animation("NOVA_Death_Fall"):
        library.add_animation("NOVA_Death_Fall", _make_death_fall_animation())
        loaded_animation_count += 1
    if library.get_animation_list().size() > 0:
        animation_player.add_animation_library("", library)
    source_root.queue_free()
    if loaded_animation_count == 0:
        push_warning("NOVA animation library imported, but no tracks matched the target humanoid skeleton.")

func _retarget_animation(source: Animation) -> Animation:
    var result := Animation.new()
    result.resource_name = source.resource_name
    result.length = source.length
    result.loop_mode = source.loop_mode
    for track_index in range(source.get_track_count()):
        var source_path := String(source.track_get_path(track_index))
        var separator := source_path.find(":")
        if separator < 0:
            continue
        var source_bone_name := source_path.substr(separator + 1)
        var target_bone_index := skeleton.find_bone(source_bone_name)
        if target_bone_index < 0:
            target_bone_index = _find_target_bone(source_bone_name)
        if target_bone_index < 0:
            continue
        var target_bone_name := skeleton.get_bone_name(target_bone_index)
        var new_track_index := result.add_track(source.track_get_type(track_index))
        var target_path := "%s:%s" % [String(get_path_to(skeleton)), target_bone_name]
        result.track_set_path(new_track_index, NodePath(target_path))
        result.track_set_interpolation_type(new_track_index, source.track_get_interpolation_type(track_index))
        result.track_set_enabled(new_track_index, source.track_is_enabled(track_index))
        for key_index in range(source.track_get_key_count(track_index)):
            result.track_insert_key(
                new_track_index,
                source.track_get_key_time(track_index, key_index),
                source.track_get_key_value(track_index, key_index),
                source.track_get_key_transition(track_index, key_index)
            )
    return result

func _make_death_fall_animation() -> Animation:
    var animation := Animation.new()
    animation.resource_name = "NOVA_Death_Fall"
    animation.length = 1.4
    animation.loop_mode = Animation.LOOP_NONE
    _add_bone_rotation_track(animation, "pelvis", [0.0, 0.42, 0.85, 1.4], [0.0, 42.0, 76.0, 82.0])
    _add_bone_rotation_track(animation, "spine_02", [0.0, 0.42, 0.85, 1.4], [0.0, -22.0, -31.0, -34.0])
    _add_bone_rotation_track(animation, "spine_03", [0.0, 0.42, 0.85, 1.4], [0.0, -14.0, -22.0, -25.0])
    _add_bone_rotation_track(animation, "Head", [0.0, 0.42, 0.85, 1.4], [0.0, 22.0, 34.0, 38.0])
    _add_bone_rotation_track(animation, "upperarm_l", [0.0, 0.42, 0.85, 1.4], [0.0, -38.0, -62.0, -68.0], Vector3(0.0, 0.0, 1.0))
    _add_bone_rotation_track(animation, "upperarm_r", [0.0, 0.42, 0.85, 1.4], [0.0, 38.0, 62.0, 68.0], Vector3(0.0, 0.0, 1.0))
    _add_bone_rotation_track(animation, "lowerarm_l", [0.0, 0.42, 0.85, 1.4], [0.0, 38.0, 58.0, 62.0], Vector3(0.0, 0.0, 1.0))
    _add_bone_rotation_track(animation, "lowerarm_r", [0.0, 0.42, 0.85, 1.4], [0.0, -38.0, -58.0, -62.0], Vector3(0.0, 0.0, 1.0))
    _add_bone_rotation_track(animation, "thigh_l", [0.0, 0.42, 0.85, 1.4], [0.0, 22.0, 40.0, 44.0])
    _add_bone_rotation_track(animation, "thigh_r", [0.0, 0.42, 0.85, 1.4], [0.0, -22.0, -40.0, -44.0])
    return animation

func _add_bone_rotation_track(animation: Animation, bone_name: String, times: Array, angles: Array, axis: Vector3 = Vector3(1.0, 0.0, 0.0)) -> void:
    var bone_index := _find_target_bone(bone_name)
    if bone_index < 0:
        return
    var actual_bone_name := skeleton.get_bone_name(bone_index)
    var track_index := animation.add_track(Animation.TYPE_ROTATION_3D)
    var target_path := "%s:%s" % [String(get_path_to(skeleton)), actual_bone_name]
    animation.track_set_path(track_index, NodePath(target_path))
    for key_index in range(times.size()):
        var rotation := Quaternion(axis.normalized(), deg_to_rad(float(angles[key_index])))
        animation.track_insert_key(track_index, float(times[key_index]), rotation)

func _find_target_bone(source_name: String) -> int:
    var key := source_name.to_lower().replace("def-", "")
    var aliases := {
        "head": ["head"],
        "neck": ["neck_01", "neck"],
        "hips": ["pelvis", "hips"],
        "spine.001": ["spine_01"],
        "spine.002": ["spine_02"],
        "spine.003": ["spine_03"],
        "shoulder.l": ["clavicle_l"],
        "upper_arm.l": ["upperarm_l", "upper_arm_l"],
        "forearm.l": ["lowerarm_l", "forearm_l"],
        "hand.l": ["hand_l"],
        "thigh.l": ["thigh_l"],
        "shin.l": ["calf_l", "shin_l"],
        "foot.l": ["foot_l"],
        "toe.l": ["ball_l", "ball_leaf_l"],
        "shoulder.r": ["clavicle_r"],
        "upper_arm.r": ["upperarm_r", "upper_arm_r"],
        "forearm.r": ["lowerarm_r", "forearm_r"],
        "hand.r": ["hand_r"],
        "thigh.r": ["thigh_r"],
        "shin.r": ["calf_r", "shin_r"],
        "foot.r": ["foot_r"],
        "toe.r": ["ball_r", "ball_leaf_r"]
    }
    var candidates: Array = aliases.get(key, [key.replace(".", "_")])
    if key == "root":
        candidates = ["root"]
    for candidate in candidates:
        for bone_index in range(skeleton.get_bone_count()):
            if skeleton.get_bone_name(bone_index).to_lower() == String(candidate).to_lower():
                return bone_index
    return -1

func _find_skeleton(root: Node) -> Skeleton3D:
    if root is Skeleton3D:
        return root as Skeleton3D
    for child in root.get_children():
        var found := _find_skeleton(child)
        if found != null:
            return found
    return null

func _find_animation_player(root: Node) -> AnimationPlayer:
    if root is AnimationPlayer:
        return root as AnimationPlayer
    for child in root.get_children():
        var found := _find_animation_player(child)
        if found != null:
            return found
    return null

func attach_to_bone(bone_name: String) -> Node3D:
    if skeleton == null:
        return self
    var bone_index := _find_target_bone(bone_name)
    if bone_index < 0:
        return self
    var actual_bone_name := skeleton.get_bone_name(bone_index)
    var attachment := BoneAttachment3D.new()
    attachment.name = "Attachment_" + actual_bone_name
    attachment.bone_name = actual_bone_name
    skeleton.add_child(attachment)
    return attachment
func play_action(action: String, blend: float = 0.14) -> void:
    if animation_player == null or loaded_animation_count == 0:
        return
    var available := animation_player.get_animation_list()
    var selected := _select_action_animation(action, available)
    if selected.is_empty():
        return
    animation_player.speed_scale = 1.0
    var transition := blend
    if action == "idle":
        transition = maxf(blend, 0.22)
    elif action == "walk" or action == "run":
        transition = maxf(blend, 0.18)
    elif action == "hit" or action == "dodge":
        transition = minf(blend, 0.07)
    _play_animation(selected, transition)

func play_locomotion(action: String, speed_ratio: float) -> void:
    if animation_player == null or loaded_animation_count == 0:
        return
    var selected := _select_action_animation(action, animation_player.get_animation_list())
    if selected.is_empty():
        return
    var ratio := clampf(speed_ratio, 0.45, 1.25)
    animation_player.speed_scale = clampf(0.72 + ratio * 0.48, 0.72, 1.36)
    _play_animation(selected, 0.20)

func play_attack_variant(combo_step: int, heavy: bool, blend: float = 0.06) -> void:
    if animation_player == null or loaded_animation_count == 0:
        return
    var available := animation_player.get_animation_list()
    var selected := ""
    if heavy:
        selected = _select_action_animation("heavy", available)
    else:
        var preferred_variants := {
            1: ["light_attack", "sword_attack", "melee_attack", "slash"],
            2: ["slice", "swing", "diagonal", "cross"],
            3: ["chop", "overhead", "stab", "thrust", "finisher"]
        }
        var terms: Array = preferred_variants.get(clampi(combo_step, 1, 3), preferred_variants[1])
        for term in terms:
            for animation_name in available:
                var candidate := String(animation_name)
                var lowered := candidate.to_lower()
                var is_attack_clip := lowered.contains("attack") or lowered.contains("sword") or lowered.contains("melee") or lowered.contains("combo") or lowered.contains("slash") or lowered.contains("slice") or lowered.contains("swing") or lowered.contains("chop") or lowered.contains("stab")
                if is_attack_clip and not lowered.contains("heavy") and lowered.contains(String(term)):
                    selected = candidate
                    break
            if not selected.is_empty():
                break
        if selected.is_empty():
            selected = _select_action_animation("attack", available)
    if selected.is_empty():
        return
    var clip := animation_player.get_animation(selected)
    var desired_duration := 0.66 if heavy else 0.38
    if clip != null and clip.length > 0.05:
        animation_player.speed_scale = clampf(clip.length / desired_duration, 0.65, 2.4)
    _play_animation(selected, blend)

func _select_action_animation(action: String, available: Array[StringName]) -> String:
    var terms := {
        "idle": ["idle_loop", "idle_stand", "idle"],
        "walk": ["walk_loop", "walk", "jog"],
        "run": ["sprint", "run", "jog"],
        "attack": ["light_attack", "sword_attack", "melee_attack", "attack", "combo", "punch"],
        "heavy": ["heavy_attack", "sword_heavy", "heavy_combo", "heavy", "sword_attack", "combo", "attack", "punch"],
        "dodge": ["roll", "dodge", "evade"],
        "guard": ["block", "guard", "sword_idle", "idle"],
        "hit": ["hit", "knockback"],
        "death": ["death"]
    }
    # Never let a light attack silently select a heavy-only clip when a light
    # melee alternative exists in the imported library.
    if action == "attack":
        for animation_name in available:
            var candidate := String(animation_name)
            var lowered := candidate.to_lower()
            if lowered.contains("heavy"):
                continue
            if lowered.contains("light_attack") or lowered.contains("sword_attack") or lowered.contains("melee_attack"):
                return candidate
        for animation_name in available:
            var candidate := String(animation_name)
            var lowered := candidate.to_lower()
            if not lowered.contains("heavy") and (lowered.contains("combo") or lowered.contains("attack") or lowered.contains("punch")):
                return candidate
    elif action == "heavy":
        for animation_name in available:
            var candidate := String(animation_name)
            var lowered := candidate.to_lower()
            if lowered.contains("heavy") and (lowered.contains("attack") or lowered.contains("combo") or lowered.contains("sword")):
                return candidate
    for term in terms.get(action, []):
        for animation_name in available:
            var candidate := String(animation_name)
            if candidate.to_lower() == String(term):
                return candidate
    for term in terms.get(action, []):
        for animation_name in available:
            var candidate := String(animation_name)
            var lowered := candidate.to_lower()
            if action == "attack" and lowered.contains("heavy"):
                continue
            if lowered.contains(String(term)):
                return candidate
    return ""

func _play_animation(animation_name: String, blend: float) -> void:
    if animation_player.current_animation != animation_name or not animation_player.is_playing():
        animation_player.play(animation_name, blend)
