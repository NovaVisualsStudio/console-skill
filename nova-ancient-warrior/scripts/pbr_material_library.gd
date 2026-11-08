extends RefCounted
## Reusable, zero-cost procedural PBR materials for the campaign environment.
## Small seamless noise maps provide albedo variation, roughness breakup and surface normals.

const TEXTURE_SIZE := 128
static var _texture_cache: Dictionary = {}


static func create_surface_material(
	base_color: Color,
	metallic: float,
	roughness: float,
	texture_seed: int,
	uv_scale: float = 2.0,
	emission: Color = Color.BLACK
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = base_color
	material.metallic = clampf(metallic, 0.0, 1.0)
	material.roughness = clampf(roughness, 0.04, 1.0)
	material.albedo_texture = _noise_texture(texture_seed, false, false)
	material.roughness_texture = _noise_texture(texture_seed + 113, false, true)
	material.normal_enabled = true
	material.normal_texture = _noise_texture(texture_seed + 211, true, false)
	material.normal_scale = 0.14
	material.uv1_scale = Vector3.ONE * maxf(uv_scale, 0.1)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
	return material


static func _noise_texture(seed_value: int, normal_map: bool, subtle_ramp: bool) -> NoiseTexture2D:
	var key := "%d:%s:%s" % [seed_value, str(normal_map), str(subtle_ramp)]
	if _texture_cache.has(key):
		return _texture_cache[key] as NoiseTexture2D
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.055
	noise.fractal_octaves = 3
	noise.fractal_gain = 0.42
	noise.fractal_lacunarity = 2.0
	var texture := NoiseTexture2D.new()
	texture.resource_name = "NovaPBR_%s_%d" % ["Normal" if normal_map else "Noise", seed_value]
	texture.width = TEXTURE_SIZE
	texture.height = TEXTURE_SIZE
	texture.generate_mipmaps = true
	texture.seamless = true
	texture.seamless_blend_skirt = 0.18
	texture.noise = noise
	texture.as_normal_map = normal_map
	if normal_map:
		texture.bump_strength = 0.42
	elif subtle_ramp:
		var ramp := Gradient.new()
		ramp.set_color(0, Color(0.86, 0.86, 0.86, 1.0))
		ramp.set_color(1, Color(1.0, 1.0, 1.0, 1.0))
		texture.color_ramp = ramp
	_texture_cache[key] = texture
	return texture


static func cached_texture_count() -> int:
	return _texture_cache.size()
