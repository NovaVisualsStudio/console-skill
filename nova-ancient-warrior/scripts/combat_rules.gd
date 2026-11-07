extends RefCounted

const DEFAULT_ATTACK_DOT_THRESHOLD := 0.2


static func is_target_in_attack_arc(
	facing: Vector3,
	target_offset: Vector3,
	max_distance: float,
	dot_threshold: float = DEFAULT_ATTACK_DOT_THRESHOLD
) -> bool:
	if max_distance <= 0.0 or target_offset.length_squared() <= 0.000001:
		return false
	var flat_facing := Vector3(facing.x, 0.0, facing.z)
	var flat_target := Vector3(target_offset.x, 0.0, target_offset.z)
	if flat_facing.length_squared() <= 0.000001 or flat_target.length_squared() <= 0.000001:
		return false
	if flat_target.length_squared() > max_distance * max_distance:
		return false
	return flat_facing.normalized().dot(flat_target.normalized()) >= dot_threshold


static func can_receive_hit(invulnerability_remaining: float) -> bool:
	return invulnerability_remaining <= 0.0
