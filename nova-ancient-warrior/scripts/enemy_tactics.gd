extends RefCounted
## Deterministic tactical movement planner inspired by modular behavior-tree AI.
## Pure decisions keep enemy movement predictable and independently testable.

const ACTION_APPROACH := "approach"
const ACTION_FLANK := "flank"
const ACTION_HOLD := "hold"
const ACTION_WINDUP := "windup"


static func plan_movement(
	distance: float,
	desired_range: float,
	attack_cooldown: float,
	enemy_variant: int,
	is_boss: bool,
	boss_phase: int,
	flank_sign: float
) -> Dictionary:
	var safe_distance := maxf(0.0, distance)
	var safe_range := maxf(0.1, desired_range)
	var safe_cooldown := maxf(0.0, attack_cooldown)
	var side := -1.0 if flank_sign < 0.0 else 1.0
	var can_flank := enemy_variant == 1 or (is_boss and boss_phase >= 2)

	if safe_distance > safe_range + (3.6 if can_flank else 0.8):
		return {
			"action": ACTION_APPROACH,
			"lateral_weight": 0.0,
			"speed_scale": 1.0
		}

	if safe_distance <= safe_range and safe_cooldown <= 0.0:
		return {
			"action": ACTION_WINDUP,
			"lateral_weight": 0.0,
			"speed_scale": 1.0
		}

	if can_flank and safe_distance > safe_range * 0.72:
		return {
			"action": ACTION_FLANK,
			"lateral_weight": side,
			"speed_scale": 0.72 if is_boss else 0.86
		}

	if safe_distance > safe_range:
		return {
			"action": ACTION_APPROACH,
			"lateral_weight": 0.0,
			"speed_scale": 0.9
		}

	return {
		"action": ACTION_HOLD,
		"lateral_weight": 0.0,
		"speed_scale": 0.0
	}


static func movement_direction(
	to_player: Vector3,
	lateral_weight: float
) -> Vector3:
	var forward := to_player
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return Vector3.ZERO
	forward = forward.normalized()
	var lateral := Vector3(-forward.z, 0.0, forward.x)
	var direction := forward + lateral * clampf(lateral_weight, -1.0, 1.0)
	return direction.normalized()
