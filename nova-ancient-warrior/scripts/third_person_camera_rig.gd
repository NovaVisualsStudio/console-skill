extends RefCounted
## Collision-aware third-person camera placement.
## Keeps the over-shoulder camera outside solid world geometry without querying the player capsule.

const DEFAULT_COLLISION_MASK := 1
const DEFAULT_SURFACE_PADDING := 0.22
const MIN_CAMERA_DISTANCE := 0.42


static func resolve_position(
	world: World3D,
	origin: Vector3,
	desired_position: Vector3,
	exclude: Array[RID] = [],
	collision_mask: int = DEFAULT_COLLISION_MASK,
	surface_padding: float = DEFAULT_SURFACE_PADDING
) -> Vector3:
	if world == null:
		return desired_position
	var ray := PhysicsRayQueryParameters3D.create(
		origin,
		desired_position,
		collision_mask,
		exclude
	)
	ray.collide_with_areas = false
	ray.collide_with_bodies = true
	var hit := world.direct_space_state.intersect_ray(ray)
	if hit.is_empty():
		return desired_position
	var hit_position: Vector3 = hit.get("position", desired_position)
	var hit_normal: Vector3 = hit.get("normal", Vector3.ZERO)
	var safe_position := hit_position + hit_normal * maxf(surface_padding, 0.04)
	var from_origin := safe_position - origin
	if from_origin.length() < MIN_CAMERA_DISTANCE:
		return origin + from_origin.normalized() * MIN_CAMERA_DISTANCE
	return safe_position
