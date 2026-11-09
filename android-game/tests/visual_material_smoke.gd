extends SceneTree

const ARENA_SCENE = preload("res://scenes/main.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _find_mesh_instance(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D:
        return node as MeshInstance3D
    for child in node.get_children():
        var found := _find_mesh_instance(child)
        if found != null:
            return found
    return null

func _validate_pbr(mesh_instance: MeshInstance3D, expected_asset: String, label: String) -> bool:
    if mesh_instance == null:
        push_error("PBR visual test: " + label + " mesh is missing.")
        return false
    var material := mesh_instance.material_override as StandardMaterial3D
    if material == null:
        push_error("PBR visual test: " + label + " has no StandardMaterial3D override.")
        return false
    if material.albedo_texture == null or material.normal_texture == null or material.roughness_texture == null:
        push_error("PBR visual test: " + label + " is missing a diffuse, normal or roughness map.")
        return false
    if not material.normal_enabled:
        push_error("PBR visual test: normal mapping is disabled on " + label + ".")
        return false
    var albedo_path := material.albedo_texture.resource_path.to_lower()
    var normal_path := material.normal_texture.resource_path.to_lower()
    var roughness_path := material.roughness_texture.resource_path.to_lower()
    if not albedo_path.contains(expected_asset + "_diff_1k.jpg"):
        push_error("PBR visual test: incorrect diffuse asset on " + label + ": " + albedo_path)
        return false
    if not normal_path.contains(expected_asset + "_nor_gl_1k.jpg"):
        push_error("PBR visual test: incorrect OpenGL normal asset on " + label + ": " + normal_path)
        return false
    if not roughness_path.contains(expected_asset + "_rough_1k.jpg"):
        push_error("PBR visual test: incorrect roughness asset on " + label + ": " + roughness_path)
        return false
    for texture in [material.albedo_texture, material.normal_texture, material.roughness_texture]:
        var dimensions: Vector2i = texture.get_size()
        if maxi(dimensions.x, dimensions.y) > 1024:
            push_error("PBR visual test: texture exceeds the 1K mobile budget on " + label + ".")
            return false
    return true

func _run() -> void:
    var arena := ARENA_SCENE.instantiate() as NovaArenaController
    root.add_child(arena)
    await process_frame
    var floor_root := arena.find_child("ArenaFloor", true, false)
    var north_wall_root := arena.find_child("NorthWall", true, false)
    var floor_mesh := _find_mesh_instance(floor_root) if floor_root != null else null
    var north_wall_mesh := _find_mesh_instance(north_wall_root) if north_wall_root != null else null
    if not _validate_pbr(floor_mesh, "rock_tile_floor", "arena floor"):
        _finish(1, arena)
        return
    if not _validate_pbr(north_wall_mesh, "stone_wall", "north wall"):
        _finish(1, arena)
        return
    var credit := arena.find_child("PolyHavenCredits", true, false) as Label
    if credit == null or not credit.text.contains("POLY HAVEN"):
        push_error("PBR visual test: in-game Poly Haven credit is missing.")
        _finish(1, arena)
        return
    print("PBR VISUAL TEST PASS: 1K diffuse, OpenGL normal and roughness maps are loaded on floor/walls; in-game CC0 credit is visible.")
    _finish(0, arena)

func _finish(exit_code: int, arena: Node) -> void:
    if is_instance_valid(arena):
        if arena is NovaArenaController and is_instance_valid(arena.audio_fx):
            arena.audio_fx.shutdown()
            arena.audio_fx = null
        arena.free()
    await process_frame
    await process_frame
    quit(exit_code)
