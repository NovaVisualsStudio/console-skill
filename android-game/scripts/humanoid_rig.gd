extends Node3D
class_name NovaHumanoidRig

const CHARACTER_SCENE: PackedScene = preload("res://assets/characters/quaternius-standard-male.glb")
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
        _build_armor_set()

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
    var search_terms := {
        "idle": ["idle_loop", "idle_stand", "idle"],
        "walk": ["walk_loop", "walk", "jog"],
        "run": ["sprint", "run", "jog"],
        "attack": ["sword_attack", "melee_attack", "attack", "combo", "punch"],
        "heavy": ["heavy_attack", "sword_attack", "combo", "attack", "punch"],
        "dodge": ["roll", "dodge", "evade"],
        "guard": ["block", "guard", "sword_idle", "idle"],
        "hit": ["hit", "knockback"],
        "death": ["death"]
    }
    var available := animation_player.get_animation_list()
    for term in search_terms.get(action, []):
        for animation_name in available:
            var name_text := String(animation_name)
            if name_text.to_lower() == String(term):
                _play_animation(name_text, blend)
                return
    for term in search_terms.get(action, []):
        for animation_name in available:
            var name_text := String(animation_name)
            if name_text.to_lower().contains(String(term)):
                _play_animation(name_text, blend)
                return

func _play_animation(animation_name: String, blend: float) -> void:
    if animation_player.current_animation != animation_name or not animation_player.is_playing():
        animation_player.play(animation_name, blend)
