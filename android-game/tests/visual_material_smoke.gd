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

func _get_texture_tier() -> String:
    var tier := OS.get_environment("NOVA_TEXTURE_TIER").to_lower()
    if tier.is_empty():
        tier = String(ProjectSettings.get_setting("nova/graphics/texture_tier", "2k")).to_lower()
    return tier if tier in ["2k", "4k"] else "2k"

func _validate_import_settings(asset_id: String, map_name: String) -> bool:
    var texture_tier := _get_texture_tier()
    var expected_size := 4096 if texture_tier == "4k" else 2048
    var import_path := "res://assets/textures/" + asset_id + "_" + map_name + "_" + texture_tier + ".jpg.import"
    var config := ConfigFile.new()
    if config.load(import_path) != OK:
        push_error("PBR import test: missing or invalid import sidecar: " + import_path)
        return false
    if config.get_value("remap", "importer", "") != "texture":
        push_error("PBR import test: incorrect Godot importer for " + import_path)
        return false
    if int(config.get_value("params", "compress/mode", -1)) != 2:
        push_error("PBR import test: texture is not VRAM-compressed: " + import_path)
        return false
    if not bool(config.get_value("params", "mipmaps/generate", false)):
        push_error("PBR import test: mipmaps are disabled: " + import_path)
        return false
    if int(config.get_value("params", "process/size_limit", 0)) != expected_size:
        push_error("PBR import test: texture import size limit does not match selected tier: " + import_path)
        return false
    if map_name == "nor_gl":
        if int(config.get_value("params", "compress/normal_map", -1)) != 1:
            push_error("PBR import test: RGTC normal-map compression is not enabled: " + import_path)
            return false
        if bool(config.get_value("params", "process/normal_map_invert_y", true)):
            push_error("PBR import test: OpenGL normal map Y is being inverted: " + import_path)
            return false
    return true

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
    if not albedo_path.contains(expected_asset + "_diff_" + _get_texture_tier() + ".jpg"):
        push_error("PBR visual test: incorrect diffuse asset on " + label + ": " + albedo_path)
        return false
    if not normal_path.contains(expected_asset + "_nor_gl_" + _get_texture_tier() + ".jpg"):
        push_error("PBR visual test: incorrect OpenGL normal asset on " + label + ": " + normal_path)
        return false
    if not roughness_path.contains(expected_asset + "_rough_" + _get_texture_tier() + ".jpg"):
        push_error("PBR visual test: incorrect roughness asset on " + label + ": " + roughness_path)
        return false
    for texture in [material.albedo_texture, material.normal_texture, material.roughness_texture]:
        var dimensions: Vector2i = texture.get_size()
        if maxi(dimensions.x, dimensions.y) > (4096 if _get_texture_tier() == "4k" else 2048):
            push_error("PBR visual test: texture exceeds the selected texture tier on " + label + ".")
            return false
    return true

func _count_torch_lights(node: Node) -> int:
    var count := 0
    if node is OmniLight3D and node.is_in_group("nova_torch_lights"):
        count += 1
    for child in node.get_children():
        count += _count_torch_lights(child)
    return count

func _validate_torch_lights(node: Node) -> bool:
    if node is OmniLight3D and node.is_in_group("nova_torch_lights"):
        var light := node as OmniLight3D
        if light.shadow_enabled or light.omni_range > 7.0 or light.light_energy <= 0.0:
            return false
    for child in node.get_children():
        if not _validate_torch_lights(child):
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
        await _finish(1, arena)
        return
    if not _validate_pbr(north_wall_mesh, "stone_wall", "north wall"):
        await _finish(1, arena)
        return
    var pillar_mesh := arena.find_child("AncientPillar", true, false) as MeshInstance3D
    var dais_mesh := arena.find_child("RitualDais", true, false) as MeshInstance3D
    if not _validate_pbr(pillar_mesh, "stone_wall", "column shaft"):
        await _finish(1, arena)
        return
    if not _validate_pbr(dais_mesh, "rock_tile_floor", "ritual dais"):
        await _finish(1, arena)
        return
    var torch_light_count := _count_torch_lights(arena)
    if torch_light_count != 4:
        push_error("PBR visual test: expected four low-cost torch lights, found %d." % torch_light_count)
        await _finish(1, arena)
        return
    if not _validate_torch_lights(arena):
        push_error("PBR visual test: a torch light has shadows enabled or exceeds the mobile range budget.")
        await _finish(1, arena)
        return
    for asset_id in ["rock_tile_floor", "stone_wall"]:
        for map_name in ["diff", "nor_gl", "rough"]:
            if not _validate_import_settings(asset_id, map_name):
                await _finish(1, arena)
                return
    for asset_id in ["metal_plate", "leather_red_02"]:
        for map_name in ["diff", "nor_gl", "rough"]:
            if not _validate_import_settings(asset_id, map_name):
                await _finish(1, arena)
                return
    if not _validate_import_settings("metal_plate", "metal"):
        await _finish(1, arena)
        return
    var world_environment := arena.find_child("WorldEnvironment", true, false) as WorldEnvironment
    if world_environment == null or world_environment.environment == null:
        push_error("Cinematic lighting test: WorldEnvironment is missing.")
        await _finish(1, arena)
        return
    var scene_environment := world_environment.environment
    if not scene_environment.glow_enabled or scene_environment.glow_intensity < 0.15:
        push_error("Cinematic lighting test: restrained bloom/glow is not configured.")
        await _finish(1, arena)
        return
    if arena.find_child("CinematicFaceFill", true, false) == null or arena.find_child("CinematicArmorRim", true, false) == null:
        push_error("Cinematic lighting test: face fill or armor rim light is missing.")
        await _finish(1, arena)
        return
    var credit := arena.find_child("PolyHavenCredits", true, false) as Label
    if credit == null or not credit.text.contains("POLY HAVEN"):
        push_error("PBR visual test: in-game Poly Haven credit is missing.")
        await _finish(1, arena)
        return
    print("PBR VISUAL TEST PASS: six arena maps and seven character armor/leather maps at %s are verified; four shadowless torch lights meet the 7m range budget; CC0 credit is visible." % _get_texture_tier().to_upper())
    await _finish(0, arena)

func _finish(exit_code: int, arena: Node) -> void:
    if is_instance_valid(arena):
        if arena is NovaArenaController and is_instance_valid(arena.audio_fx):
            arena.audio_fx.shutdown()
            arena.audio_fx = null
        arena.free()
    # Give AudioServer time to release the just-stopped WAV streams and playbacks.
    await create_timer(0.5).timeout
    await process_frame
    await process_frame
    quit(exit_code)
