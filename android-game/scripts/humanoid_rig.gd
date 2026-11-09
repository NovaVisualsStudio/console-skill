extends Node3D
class_name NovaHumanoidRig

const CHARACTER_SCENE: PackedScene = preload("res://assets/characters/quaternius-standard-male.glb")
const ANIMATION_SCENE_PATH := "res://assets/animations/UAL2_Standard.glb"

@export var tint_color := Color(0.20, 0.27, 0.34)
@export var character_scale := 1.0
@export var accent_color := Color(0.62, 0.43, 0.20)

var model_root: Node3D
var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var loaded_animation_count := 0
var primary_mesh: MeshInstance3D
var primary_material: StandardMaterial3D
var _source_skeleton: Skeleton3D

func _ready() -> void:
    _build_character()
    _load_and_retarget_animations()

func _build_character() -> void:
    model_root = CHARACTER_SCENE.instantiate() as Node3D
    if model_root == null:
        push_error("NOVA humanoid GLB did not instantiate as Node3D.")
        return
    model_root.name = "RiggedWarriorMesh"
    model_root.scale = Vector3.ONE * character_scale
    add_child(model_root)
    _apply_character_materials(model_root)
    skeleton = _find_skeleton(model_root)
    if skeleton == null:
        push_error("NOVA character GLB is missing its Skeleton3D.")
    else:
        skeleton.show_rest_only = false

func _apply_character_materials(root: Node) -> void:
    var armor := StandardMaterial3D.new()
    armor.albedo_color = tint_color
    armor.metallic = 0.48
    armor.roughness = 0.52
    armor.metallic_specular = 0.62
    var skin := StandardMaterial3D.new()
    skin.albedo_color = Color(0.48, 0.30, 0.21)
    skin.roughness = 0.78
    var eyes := StandardMaterial3D.new()
    eyes.albedo_color = Color(0.035, 0.025, 0.02)
    eyes.roughness = 0.24
    for child in root.get_children():
        if child is MeshInstance3D:
            var mesh_instance := child as MeshInstance3D
            var mesh_name := mesh_instance.name.to_lower()
            if mesh_name.contains("eye"):
                mesh_instance.material_override = eyes
            elif mesh_name.contains("eyebrow"):
                mesh_instance.material_override = skin
            else:
                mesh_instance.material_override = armor
                if mesh_name.contains("superhero_male") or primary_mesh == null:
                    primary_mesh = mesh_instance
                    primary_material = armor
            mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        _apply_character_materials(child)

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
            var safe_name := String(animation_name).get_slice("/", -1)
            if not library.has_animation(safe_name):
                library.add_animation(safe_name, retargeted)
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
        var marker := "bone_pose/"
        var marker_index := source_path.find(marker)
        if marker_index < 0:
            continue
        var tail := source_path.substr(marker_index + marker.length())
        var parts := tail.split("/")
        if parts.size() < 2 or not parts[0].is_valid_int():
            continue
        var source_bone_index := int(parts[0])
        if source_bone_index < 0 or source_bone_index >= _source_skeleton.get_bone_count():
            continue
        var source_bone_name := _source_skeleton.get_bone_name(source_bone_index)
        var target_bone_index := _find_target_bone(source_bone_name)
        if target_bone_index < 0:
            continue
        var property_name := parts[1]
        var new_track_index := result.add_track(source.track_get_type(track_index))
        var target_path := "%s:bone_pose/%d/%s" % [String(get_path_to(skeleton)), target_bone_index, property_name]
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
    if skeleton == null or skeleton.find_bone(bone_name) < 0:
        return self
    var attachment := BoneAttachment3D.new()
    attachment.name = "Attachment_" + bone_name
    attachment.bone_name = bone_name
    skeleton.add_child(attachment)
    return attachment

func play_action(action: String, blend: float = 0.14) -> void:
    if animation_player == null or loaded_animation_count == 0:
        return
    var choices := {
        "idle": ["Idle_Loop", "Sword_Idle"],
        "walk": ["Walk_Loop", "Jog_Fwd_Loop"],
        "run": ["Sprint_Loop", "Jog_Fwd_Loop"],
        "attack": ["Sword_Attack", "Sword_Attack_01", "Sword_Attack_Combo_1", "Punch_Cross"],
        "heavy": ["Sword_Attack_Combo_1", "Sword_Attack", "Punch_Cross"],
        "dodge": ["Roll", "Roll_RM"],
        "guard": ["Sword_Idle", "Idle_Loop"],
        "hit": ["Hit_Chest", "Hit_Head"],
        "death": ["Death01"]
    }
    for candidate in choices.get(action, []):
        if animation_player.has_animation(candidate):
            if animation_player.current_animation != candidate or not animation_player.is_playing():
                animation_player.play(candidate, blend)
            return
